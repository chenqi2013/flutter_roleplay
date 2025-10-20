import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart' as mp_audio_stream;
import 'package:rwkv_mobile_flutter/from_rwkv.dart' as from_rwkv;

/// RWKV tts模型管理服务
class RWKVTTSService extends GetxController {
  /// Send message to RWKV isolate
  SendPort? _sendPort;

  /// Receive message from RWKV isolate
  late final _receivePort = ReceivePort();

  final RxInt prefillSpeed = 0.obs;
  final RxInt decodeSpeed = 0.obs;
  final RxBool isGenerating = false.obs;

  late Completer<void> _initRuntimeCompleter = Completer<void>();
  Timer? _getTokensTimer;

  bool isSparkTTSModelLoaded = false;

  StreamController<String>? localChatController;
  bool isNeedSaveAiMessage = false;

  mp_audio_stream.AudioStream? audioStream;
  final asFull = 0.obs;
  final asExhaust = 0.obs;
  Timer? _asTimer;

  Timer? _queryTimer;
  final generating = false.obs;
  final latestBufferLength = 0.obs;

  @override
  void onInit() async {
    super.onInit();
    _setupReceivePortListener();
    loadSparkTTS(
      modelPath:
          "/data/user/0/com.rwkvzone.chat/app_flutter/rwkv7-0.4B-g1-respark-voice-tunable-ipa-a16w8-8gen3.bin",
      wav2vec2Path:
          "/data/user/0/com.rwkvzone.chat/app_flutter/wav2vec2-large-xlsr-53.mnn",
      detokenizePath:
          "/data/user/0/com.rwkvzone.chat/app_flutter/BiCodecDetokenize.mnn",
      bicodecTokenzerPath:
          "/data/user/0/com.rwkvzone.chat/app_flutter/BiCodecTokenize.mnn",
      backend: Backend.qnn,
    );
  }

  void playTTS(String ttsText) async {
    // ttsText: 贫穷限制了我的想象力
    // I/flutter (26008): instructionText:
    // I/flutter (26008): promptWavPath: /data/user/0/com.rwkv.tts/cache/assets/lib/tts/Chinese(PRC)_Kafka_8.wav
    // I/flutter (26008): promptSpeechText: ——我们并不是通过物理移动手段找到「星核」的。
    // I/flutter (26008): outputWavPath: /data/user/0/com.rwkv.tts/cache/1756368658614.output.wav
    debugPrint("playTTS: $ttsText");
    final Kafka_8wav = await CommonUtil.fromAssetsToTemp(
      "assets/lib/tts/Chinese(PRC)_Kafka_8.wav",
    );
    final Kafka_8json = await CommonUtil.fromAssetsToTemp(
      "assets/lib/tts/Chinese(PRC)_Kafka_8.json",
    );
    _runTTS(
      ttsText: ttsText,
      instructionText: "",
      promptWavPath:
          "/data/user/0/com.rwkvzone.chat/cache/assets/lib/tts/Chinese(PRC)_Kafka_8.wav",
      outputWavPath:
          "/data/user/0/com.rwkvzone.chat/cache/1234567890.output.wav",
      promptSpeechText: "——我们并不是通过物理移动手段找到「星核」的。",
    );
  }

  /// 设置接收端口监听器
  void _setupReceivePortListener() {
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        debugPrint("receive SendPort: $message");
      } else {
        if (message is ResponseBufferContent) {
          // String result = message.responseBufferContent;
        } else if (message is Speed) {
          // 处理速度信息
        } else if (message is TTSStreamingBuffer) {
          debugPrint("receive TTSStreamingBuffer: $message");
          _onTTSStreamingBuffer(message);
        } else if (message is IsGenerating) {
          var generating = message.isGenerating;
          isGenerating.value = generating;
          if (!generating && isNeedSaveAiMessage) {
            debugPrint('receive IsGenerating: $generating');
          }
        }
      }
    });
  }

  // loadSparkTTS: /data/user/0/com.rwkv.tts/app_flutter/respark-0.4B-210ksteps-a16w8-8gen3_combined.bin,
  // /data/user/0/com.rwkv.tts/app_flutter/wav2vec2-large-xlsr-53.mnn,
  // /data/user/0/com.rwkv.tts/app_flutter/BiCodecDetokenize.mnn,
  // /data/user/0/com.rwkv.tts/app_flutter/BiCodecTokenize.mnn, Backend.qnn
  Future<void> loadSparkTTS({
    required String modelPath,
    required String wav2vec2Path,
    required String detokenizePath,
    required String bicodecTokenzerPath,
    required Backend backend,
  }) async {
    debugPrint(
      'loadSparkTTS: $modelPath, $wav2vec2Path, $detokenizePath, $bicodecTokenzerPath, $backend',
    );
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;
    if (Platform.isAndroid && backend == Backend.qnn) {
      for (final lib in qnnLibList) {
        await CommonUtil.fromAssetsToTemp(
          "assets/lib/qnn/$lib",
          targetPath: "assets/lib/$lib",
        );
      }
    }
    final tokenizerPath = await CommonUtil.fromAssetsToTemp(
      "assets/config/chat/vocab_talk.txt",
    );
    // await _ensureQNNCopied();
    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      try {
        send(to_rwkv.ReleaseTTSModels());
        await reInitRuntime(
          backend: backend,
          modelPath: modelPath,
          tokenizerPath: tokenizerPath,
        );
      } catch (e) {
        debugPrint("initRuntime failed: $e");
        // if (!kDebugMode)
        //   Sentry.captureException(e, stackTrace: StackTrace.current);
        // Alert.error("Failed to load model: $e");
        return;
      }
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      debugPrint("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
      _getTokensTimer = null;
    }

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 225), (
      timer,
    ) async {
      send(to_rwkv.GetPrefillAndDecodeSpeed());
    });

    send(
      to_rwkv.LoadSparkTTSModels(
        wav2vec2Path: wav2vec2Path,
        bicodecTokenizerPath: bicodecTokenzerPath,
        bicodecDetokenizerPath: detokenizePath,
      ),
    );

    final ttsTextNormalizerDatePath = await CommonUtil.fromAssetsToTemp(
      "assets/config/chat/date-zh.fst",
    );
    final ttsTextNormalizerNumberPath = await CommonUtil.fromAssetsToTemp(
      "assets/config/chat/number-zh.fst",
    );
    final ttsTextNormalizerPhonePath = await CommonUtil.fromAssetsToTemp(
      "assets/config/chat/phone-zh.fst",
    );
    // note: order matters here
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerDatePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerPhonePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerNumberPath));

    isSparkTTSModelLoaded = true;
    debugPrint('loadSparkTTS success');
  }

  /// 发送消息到 RWKV
  void send(to_rwkv.ToRWKV toRwkv) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }
    sendPort.send(toRwkv);
  }

  /// 重新初始化运行时
  Future<void> reInitRuntime({
    required String modelPath,
    required Backend backend,
    required String tokenizerPath,
  }) async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;
    _initRuntimeCompleter = Completer<void>();
    send(
      to_rwkv.ReInitRuntime(
        modelPath: modelPath,
        backend: backend,
        tokenizerPath: tokenizerPath,
      ),
    );
    return _initRuntimeCompleter.future;
  }

  void _startQueryTimer() {
    _queryTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _pulse(),
    );
  }

  void _pulse() {
    // P.rwkv.send(to_rwkv.GetTTSGenerationProgress());
    send(to_rwkv.GetPrefillAndDecodeSpeed());
    send(to_rwkv.GetTTSStreamingBuffer());
    // P.rwkv.send(to_rwkv.GetTTSOutputFileList());
  }

  void _stopQueryTimer() {
    _queryTimer?.cancel();
    _queryTimer = null;
  }

  Future<void> _runTTS({
    required String ttsText,
    required String instructionText,
    required String promptWavPath,
    required String outputWavPath,
    required String promptSpeechText,
  }) async {
    final audioStream = mp_audio_stream.getAudioStream();
    final res = audioStream.init(
      sampleRate: 16000,
      channels: 1,
      bufferMilliSec: 60000,
      waitingBufferMilliSec: 200,
    );
    audioStream.resetStat();
    if (res != 0) {
      debugPrint("audioStream init failed: $res");
    } else {
      audioStream.resume();
    }

    _asTimer?.cancel();
    _asTimer = null;
    _asTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final stat = audioStream.stat();
      asFull.value = stat.full;
      asExhaust.value = stat.exhaust;
    });

    this.audioStream = audioStream;

    send(
      to_rwkv.StartTTS(
        ttsText: ttsText,
        instructionText: instructionText,
        promptWavPath: promptWavPath,
        outputWavPath: outputWavPath,
        promptSpeechText: promptSpeechText,
      ),
    );

    latestBufferLength.value = 0;
    generating.value = true;

    _stopQueryTimer();
    _startQueryTimer();
  }

  void _onTTSStreamingBuffer(from_rwkv.TTSStreamingBuffer res) async {
    final buffer = res.ttsStreamingBuffer;
    final length = res.ttsStreamingBufferLength;
    final generating = res.generating;
    final allReceived = !generating && this.generating.value;
    final addedLength = length - latestBufferLength.value;
    final rawFloatList = res.rawFloatList.map((e) => e.toDouble() * 1).toList();

    if (addedLength != 0) {
      final float32Data = Float32List.fromList(
        rawFloatList,
      ).sublist(latestBufferLength.value, length);
      audioStream?.push(float32Data);
    }

    this.generating.value = generating;
    latestBufferLength.value = length;

    if (!allReceived) return;
    _stopQueryTimer();
  }

  void _onStreamDone() {
    debugPrint("onStreamDone");
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    debugPrint("error: $error");
    // if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
  }
}
