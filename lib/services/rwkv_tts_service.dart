import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';

/// RWKV 模型管理服务
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

  Future<void> loadSparkTTS({
    required String modelPath,
    required String wav2vec2Path,
    required String detokenizePath,
    required String bicodecTokenzerPath,
    required Backend backend,
  }) async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    final tokenizerPath = await CommonUtil.fromAssetsToTemp(
      "assets/config/tts/b_rwkv_vocab_v20230424_sparktts.txt",
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
        latestRuntimeAddress: 0,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      debugPrint("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
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
      "assets/config/tts/date-zh.fst",
    );
    final ttsTextNormalizerNumberPath = await CommonUtil.fromAssetsToTemp(
      "assets/config/tts/number-zh.fst",
    );
    final ttsTextNormalizerPhonePath = await CommonUtil.fromAssetsToTemp(
      "assets/config/tts/phone-zh.fst",
    );
    // note: order matters here
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerDatePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerPhonePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerNumberPath));

    isSparkTTSModelLoaded = true;
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
        latestRuntimeAddress: 0,
      ),
    );
    return _initRuntimeCompleter.future;
  }
}
