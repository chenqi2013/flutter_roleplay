import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart' as mp_audio_stream;
import 'package:rwkv_mobile_flutter/from_rwkv.dart' as from_rwkv;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 当前生成的音频文件名
  String? currentAudioFileName;
  // TTS生成完成回调（传递文件名和时长）
  Function(String audioFileName, int audioDuration)? onTTSComplete;
  var appDir = '';
  var cacheDir = '';
  int? modelID = 0;
  ModelInfo? modelInfo; // 保存当前的 TTS 模型信息

  // TTS 开关状态 (默认关闭)
  final RxBool isTTSEnabled = false.obs;
  static const String _ttsEnabledKey = 'tts_enabled';

  @override
  void onInit() async {
    super.onInit();
    debugPrint('RWKVTTSService onInit - 实例hashCode: ${hashCode}');
    _setupReceivePortListener();

    // 加载 TTS 开关状态
    await _loadTTSEnabledState();

    var prefs = await SharedPreferences.getInstance();
    String? audioName = await prefs.getString(ttsAudioNameKey);
    debugPrint('audioName: $audioName');
    if (audioName != null) {
      ttsAudioName = audioName;
    }

    String? audioTxt = await prefs.getString(ttsAudioTxtKey);
    debugPrint('audioTxt: $audioTxt');
    if (audioTxt != null) {
      ttsAudioTxt = audioTxt;
    }

    // 如果 TTS 开启，才加载模型
    Future.delayed(Duration(seconds: 3), () {
      if (isTTSEnabled.value) {
        _loadTTSModelFromDatabase();
      } else {
        debugPrint('TTS 功能已关闭，不加载模型');
      }
    });
  }

  /// 加载 TTS 开关状态
  Future<void> _loadTTSEnabledState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isTTSEnabled.value = prefs.getBool(_ttsEnabledKey) ?? false;
      debugPrint('加载 TTS 开关状态: ${isTTSEnabled.value}');
    } catch (e) {
      debugPrint('加载 TTS 开关状态失败: $e');
      isTTSEnabled.value = false;
    }
  }

  /// 切换 TTS 开关
  Future<void> toggleTTS() async {
    try {
      final newState = !isTTSEnabled.value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsEnabledKey, newState);
      isTTSEnabled.value = newState;

      debugPrint('TTS 开关已切换为: ${isTTSEnabled.value ? "开启" : "关闭"}');
      debugPrint('SharedPreferences 中保存的值: ${prefs.getBool(_ttsEnabledKey)}');

      if (isTTSEnabled.value) {
        // 开启时加载模型
        await _loadTTSModelFromDatabase();
      } else {
        // 关闭时清理资源
        debugPrint('TTS 已关闭，不加载模型');
      }
    } catch (e) {
      debugPrint('切换 TTS 开关失败: $e');
    }
  }

  /// 从数据库加载 TTS 模型信息
  Future<void> _loadTTSModelFromDatabase() async {
    try {
      final databaseHelper = DatabaseHelper();
      modelInfo = await databaseHelper.getModelInfoByType('tts');

      if (modelInfo != null) {
        debugPrint('从数据库加载TTS模型信息: ${modelInfo!.id}');
        debugPrint('TTS模型路径: ${modelInfo!.modelPath}');

        // 检查模型文件是否存在
        final modelPath = await CommonUtil.getFileDocumentPath(
          modelInfo!.modelPath,
        );
        if (File(modelPath).existsSync()) {
          debugPrint('TTS模型文件存在，开始加载: $modelPath');
          loadTTSModel(modelPath: modelPath, backend: modelInfo!.backend);
        } else {
          debugPrint('TTS模型文件不存在: $modelPath');
          debugPrint('需要下载TTS模型');
        }
      } else {
        debugPrint('数据库中没有保存的TTS模型信息');
        debugPrint('需要下载或配置TTS模型');
      }
    } catch (e) {
      debugPrint('从数据库加载TTS模型信息失败: $e');
    }
  }

  /// 保存 TTS 模型信息到数据库
  Future<void> saveTTSModelInfo(ModelInfo newModelInfo) async {
    try {
      final databaseHelper = DatabaseHelper();

      // 确保模型类型为 tts
      final ttsModelInfo = ModelInfo(
        id: newModelInfo.id,
        modelPath: newModelInfo.modelPath,
        statePath: newModelInfo.statePath,
        backend: newModelInfo.backend,
        modelType: RoleplayManageModelType.tts,
      );

      await databaseHelper.saveModelInfo(ttsModelInfo);
      modelInfo = ttsModelInfo;

      debugPrint('成功保存 TTS 模型信息到数据库: ${ttsModelInfo.id}');
      debugPrint('TTS 模型路径: ${ttsModelInfo.modelPath}');
    } catch (e) {
      debugPrint('保存 TTS 模型信息到数据库失败: $e');
    }
  }

  void loadTTSModel({
    required String modelPath,
    required Backend backend,
  }) async {
    if (appDir.isEmpty) {
      appDir = (await getApplicationDocumentsDirectory()).path;
      debugPrint('appDir: $appDir');
      cacheDir = (await getTemporaryDirectory()).path;
      debugPrint('cacheDir: $cacheDir');
    }
    loadSparkTTS(
      modelPath: modelPath,
      wav2vec2Path: "$appDir/wav2vec2-large-xlsr-53.mnn",
      detokenizePath: "$appDir/BiCodecDetokenize.mnn",
      bicodecTokenzerPath: "$appDir/BiCodecTokenize.mnn",
      backend: backend,
    );
  }

  void playTTS(String ttsText) async {
    // 检查 TTS 是否开启
    debugPrint(
      'playTTS 被调用 - 实例hashCode: ${hashCode}, isTTSEnabled.value = ${isTTSEnabled.value}',
    );
    if (!isTTSEnabled.value) {
      debugPrint('TTS 功能未开启，跳过语音生成');
      return;
    }
    debugPrint('TTS 功能已开启，开始生成语音');

    // I/flutter (26008): instructionText:
    // I/flutter (26008): promptWavPath: /data/user/0/com.rwkv.tts/cache/assets/lib/tts/Chinese(PRC)_Kafka_8.wav
    // I/flutter (26008): promptSpeechText: ——我们并不是通过物理移动手段找到「星核」的。
    // I/flutter (26008): outputWavPath: /data/user/0/com.rwkv.tts/cache/1756368658614.output.wav
    // debugPrint('before playTTS: $ttsText');
    ttsText = ttsText.replaceAll(RegExp(r'[\(（][^\)）]*[\)）]'), '');
    // debugPrint('after playTTS: $ttsText');

    var ttsAudioNameTmp = await CommonUtil.fromAssetsToTemp(
      "assets/lib/tts/$ttsAudioName",
    );
    debugPrint('ttsAudioName: $ttsAudioNameTmp');
    // final Kafka_8json = await CommonUtil.fromAssetsToTemp(
    //   "assets/lib/tts/Chinese(PRC)_Hook_21.json",
    // );
    int millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    // 保存当前生成的音频文件名
    currentAudioFileName = '$millisecondsSinceEpoch.wav';
    debugPrint('Current audio file name: $currentAudioFileName');
    _runTTS(
      ttsText: ttsText,
      instructionText: "",
      promptWavPath: ttsAudioNameTmp,
      outputWavPath: "$cacheDir/$millisecondsSinceEpoch.wav",
      promptSpeechText: ttsAudioTxt,
    );
    debugPrint('ttsAudioTxt: $ttsAudioTxt，ttsAudioName: $ttsAudioName');
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
        } else if (message is LoadSteps) {
          debugPrint("receive LoadSteps: ${message.modelID}");
          modelID = message.modelID;
        } else if (message is TTSStreamingBuffer) {
          debugPrint("receive TTSStreamingBuffer: $message");
          _onTTSStreamingBuffer(message);
        } else if (message is IsGenerating) {
          var generating = message.isGenerating;
          isGenerating.value = generating;
          if (!generating) {
            debugPrint('语音生成完成');
            _stopQueryTimer();
            // 回调通知生成完成
            if (currentAudioFileName != null && onTTSComplete != null) {
              debugPrint('Calling onTTSComplete with: $currentAudioFileName');
              // 计算音频时长并回调
              _calculateAndCallbackAudioDuration();
            }
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
        if (modelID != null) {
          send(to_rwkv.ReleaseTTSModels());
          debugPrint('to_rwkv.ReleaseTTSModels()，，释放TTS模型');
          send(to_rwkv.ReleaseModel(modelID: modelID));
          debugPrint('to_rwkv.ReleaseModel(modelID:$modelID)，，释放模型');
          debugPrint('_sendPort != null releaseTTSModels modelID: $modelID');
        }

        // await reInitRuntime(
        //   backend: backend,
        //   modelPath: modelPath,
        //   tokenizerPath: tokenizerPath,
        // );
      } catch (e) {
        debugPrint("initRuntime failed: $e");
        // if (!kDebugMode)
        //   Sentry.captureException(e, stackTrace: StackTrace.current);
        // Alert.error("Failed to load model: $e");
        return;
      }
      _sendPort = null;
    }
    final options = StartOptions(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      sendPort: _receivePort.sendPort,
      rootIsolateToken: rootIsolateToken!,
    );
    await RWKVMobile().runIsolate(options);

    while (_sendPort == null) {
      debugPrint("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
      _getTokensTimer = null;
    }

    // _getTokensTimer = Timer.periodic(const Duration(milliseconds: 225), (
    //   timer,
    // ) async {
    //   send(to_rwkv.GetPrefillAndDecodeSpeed());
    // });

    // send(
    //   to_rwkv.AddTTSModel(
    //     modelPath: modelPath,
    //     backend: backend,
    //     tokenizerPath: tokenizerPath,
    //     wav2vec2Path: wav2vec2Path,
    //     bicodecTokenizerPath: bicodecTokenzerPath,
    //     bicodecDetokenizerPath: detokenizePath,
    //   ),
    // );

    send(
      to_rwkv.LoadSparkTTSModels(
        wav2vec2Path: wav2vec2Path,
        bicodecTokenizerPath: bicodecTokenzerPath,
        bicodecDetokenizerPath: detokenizePath,
      ),
    );
    debugPrint('to_rwkv.AddTTSModel()，，添加TTS模型');

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

  void releaseTTSModel() {
    if (_sendPort == null || !isSparkTTSModelLoaded) {
      return;
    }
    if (isGenerating.value == true) {
      send(to_rwkv.Stop());
      debugPrint('to_rwkv.Stop()，，stop Generating TTS');
    }
    send(to_rwkv.ReleaseTTSModels());
    debugPrint('to_rwkv.ReleaseTTSModels()，，释放TTS模型');
    send(to_rwkv.ReleaseModel(modelID: modelID));
    debugPrint('to_rwkv.ReleaseModel(modelID:$modelID)，，释放模型');
    modelID = null;
    isSparkTTSModelLoaded = false;
    _sendPort = null;
    _initRuntimeCompleter = Completer<void>();
    _getTokensTimer?.cancel();
    _getTokensTimer = null;
    _queryTimer?.cancel();
    _queryTimer = null;
    _asTimer?.cancel();
    _asTimer = null;
    audioStream = null;
    debugPrint('releaseTTSModel success');
  }

  void stopPlayer() {
    AudioPlayer audioPlayer = AudioPlayer();
    if (audioPlayer.state == PlayerState.playing) {
      audioPlayer.stop();
    }
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

  // /// 重新初始化运行时
  // Future<void> reInitRuntime({
  //   required String modelPath,
  //   required Backend backend,
  //   required String tokenizerPath,
  // }) async {
  //   prefillSpeed.value = 0;
  //   decodeSpeed.value = 0;
  //   _initRuntimeCompleter = Completer<void>();
  //   send(
  //     to_rwkv.ReInitRuntime(
  //       modelPath: modelPath,
  //       backend: backend,
  //       tokenizerPath: tokenizerPath,
  //     ),
  //   );
  //   return _initRuntimeCompleter.future;
  // }

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
    send(to_rwkv.GetIsGenerating());
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
    if (!isSparkTTSModelLoaded) {
      // 从数据库获取 TTS 模型信息
      if (modelInfo == null) {
        final databaseHelper = DatabaseHelper();
        modelInfo = await databaseHelper.getModelInfoByType('tts');
      }

      // 如果数据库中没有 TTS 模型信息，直接返回
      if (modelInfo == null) {
        debugPrint('没有TTS模型信息，无法生成语音');
        return;
      }

      // 获取模型文件路径
      final modelPath = await CommonUtil.getFileDocumentPath(
        modelInfo!.modelPath,
      );

      // 检查模型文件是否存在
      if (!File(modelPath).existsSync()) {
        debugPrint('TTS模型文件不存在: $modelPath');
        return;
      }

      debugPrint('加载TTS模型: $modelPath');

      await loadSparkTTS(
        modelPath: modelPath,
        wav2vec2Path: "$appDir/wav2vec2-large-xlsr-53.mnn",
        detokenizePath: "$appDir/BiCodecDetokenize.mnn",
        bicodecTokenzerPath: "$appDir/BiCodecTokenize.mnn",
        backend: modelInfo!.backend,
      );
    }

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
    debugPrint('to_rwkv.StartTTS()，，开始TTS');
    debugPrint(
      "StartTTS: $ttsText, $instructionText, $promptWavPath, $outputWavPath, $promptSpeechText",
    );

    latestBufferLength.value = 0;
    generating.value = true;

    _stopQueryTimer();
    _startQueryTimer();
  }

  void _onTTSStreamingBuffer(from_rwkv.TTSStreamingBuffer res) async {
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

  /// 计算音频时长并回调
  Future<void> _calculateAndCallbackAudioDuration() async {
    try {
      if (currentAudioFileName == null || onTTSComplete == null) {
        return;
      }

      // 确保 cacheDir 已初始化
      if (cacheDir.isEmpty) {
        cacheDir = (await getTemporaryDirectory()).path;
      }

      final audioPath = '$cacheDir/$currentAudioFileName';
      debugPrint('Calculating audio duration for: $audioPath');

      // 使用 AudioPlayer 获取音频时长
      final player = AudioPlayer();
      await player.setSourceDeviceFile(audioPath);

      // 等待音频信息加载
      await Future.delayed(const Duration(milliseconds: 100));

      final duration = await player.getDuration();
      final durationInSeconds = duration?.inSeconds ?? 0;

      debugPrint('Audio duration: $durationInSeconds seconds');

      // 回调传递文件名和时长
      onTTSComplete!(currentAudioFileName!, durationInSeconds);

      // 清理
      await player.dispose();
      currentAudioFileName = null;
    } catch (e) {
      debugPrint('Error calculating audio duration: $e');
      // 出错时仍然回调，但时长为0
      if (currentAudioFileName != null && onTTSComplete != null) {
        onTTSComplete!(currentAudioFileName!, 0);
      }
      currentAudioFileName = null;
    }
  }
}
