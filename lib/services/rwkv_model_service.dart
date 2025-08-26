import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:isolate';

import 'dart:async';

import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/download_dialog.dart';

/// RWKV 模型管理服务
class RWKVModelService extends GetxController {
  /// Send message to RWKV isolate
  SendPort? _sendPort;

  /// Receive message from RWKV isolate
  late final _receivePort = ReceivePort();

  final RxInt prefillSpeed = 0.obs;
  final RxInt decodeSpeed = 0.obs;
  final RxBool isGenerating = false.obs;

  late Completer<void> _initRuntimeCompleter = Completer<void>();
  Timer? _getTokensTimer;

  bool isModelLoaded = false;
  late String rmpack;

  StreamController<String>? localChatController;
  bool isNeedSaveAiMessage = false;

  // 回调函数
  Function(String)? _onMessageGenerated;
  Function()? _onGenerationComplete;

  @override
  void onInit() async {
    super.onInit();
    _setupReceivePortListener();
    await _checkAndLoadModel();
  }

  /// 设置消息生成回调
  void setOnMessageGenerated(Function(String) callback) {
    _onMessageGenerated = callback;
  }

  /// 设置生成完成回调
  void setOnGenerationComplete(Function() callback) {
    _onGenerationComplete = callback;
  }

  /// 设置接收端口监听器
  void _setupReceivePortListener() {
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        debugPrint("receive SendPort: $message");
      } else {
        if (message is ResponseBufferContent) {
          String result = message.responseBufferContent;
          if (localChatController != null && !localChatController!.isClosed) {
            localChatController!.add(result);
            _onMessageGenerated?.call(result);
          } else {
            debugPrint('localChatController is null or closed');
          }
        } else if (message is Speed) {
          // 处理速度信息
        } else if (message is IsGenerating) {
          var generating = message.isGenerating;
          isGenerating.value = generating;
          if (!generating && isNeedSaveAiMessage) {
            debugPrint('receive IsGenerating: $generating');
            isNeedSaveAiMessage = false;
            _onGenerationComplete?.call();
            if (_getTokensTimer != null) {
              _getTokensTimer!.cancel();
            }
          }
        }
      }
    });
  }

  /// 检查并加载模型
  Future<void> _checkAndLoadModel() async {
    // 设置模型下载完成回调，当外部应用通知下载完成时重新加载模型
    setGlobalModelDownloadCompleteCallback((ModelInfo? info) {
      loadChatModel();

      /// 把当前的modelinfo 保存到本地
    });

    setGlobalStateFileChangeCallback((ModelInfo? info) {
      clearStates();
    });

    // 检查是否需要下载模型
    if (!await checkDownloadFile(downloadUrl)) {
      debugPrint('downloadUrl file not exists');
      // 通知外部应用需要下载模型，而不是在插件内部处理
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyModelDownloadRequired();
      });
    } else {
      loadChatModel();
      debugPrint('downloadUrl file exists');
    }
  }

  /// 加载聊天模型
  Future<void> loadChatModel() async {
    if (isModelLoaded) {
      return;
    }
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    late String modelPath;

    if (Platform.isAndroid && backend == Backend.qnn) {
      for (final lib in qnnLibList) {
        await fromAssetsToTemp(
          "assets/lib/qnn/$lib",
          targetPath: "assets/lib/$lib",
        );
      }
    }

    final tokenizerPath = await fromAssetsToTemp(
      "assets/config/chat/b_rwkv_vocab_v20230424.txt",
    );

    rmpack = await fromAssetsToTemp(
      "assets/config/chat/rwkv-9-mix_user6500_system1700.rmpack",
    );

    modelPath = await getLocalFilePath(downloadUrl);
    if (!File(modelPath).existsSync()) {
      debugPrint('modelPath not exists');
      return;
    }
    isModelLoaded = true;

    if (Platform.isIOS || Platform.isMacOS) {
      modelPath = await fromAssetsToTemp(
        "assets/model/othello/RWKV-x070-G1-0.1b-20250307-ctx4096.st",
      );
      backend = Backend.webRwkv;
    }

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(
        to_rwkv.ReInitRuntime(
          modelPath: modelPath,
          backend: backend,
          tokenizerPath: tokenizerPath,
          latestRuntimeAddress: 0,
        ),
      );
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
    send(to_rwkv.LoadInitialStates(rmpack));
    // send(to_rwkv.GetLatestRuntimeAddress()); // 已弃用

    _setupModelParameters();
  }

  /// 设置模型参数
  void _setupModelParameters() {
    final prompt =
        'System: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    send(to_rwkv.SetPrompt(prompt));
    send(to_rwkv.SetMaxLength(2000));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.5,
        topK: 500,
        topP: 0,
        presencePenalty: 0,
        frequencyPenalty: 0,
        penaltyDecay: 0.996,
      ),
    );
  }

  /// 从资源文件复制到临时目录
  Future<String> fromAssetsToTemp(
    String assetsPath, {
    String? targetPath,
  }) async {
    try {
      // 在插件中加载资源时，先尝试从主应用加载
      ByteData data;
      try {
        data = await rootBundle.load(assetsPath);
      } catch (e) {
        // 如果主应用中没有，则从 flutter_roleplay 包中加载
        debugPrint(
          "Asset not found in main app, loading from package: $assetsPath",
        );
        final packagePath = 'packages/flutter_roleplay/$assetsPath';
        data = await rootBundle.load(packagePath);
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, targetPath ?? assetsPath));
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      return tempFile.path;
    } catch (e) {
      debugPrint("Error loading asset $assetsPath: $e");
      return "";
    }
  }

  /// 清空状态
  Future<void> clearStates() async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;

    // 只清空内存中的聊天记录，不删除数据库记录
    final stateManager = ChatStateManager();
    stateManager.getMessages(roleName.value).clear();

    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }
    send(to_rwkv.ClearStates());
    send(to_rwkv.LoadInitialStates(rmpack));
    final prompt =
        'System: 请你扮演名为${roleName.value}的角色，你的设定是：${roleDescription.value}\n\n';
    send(to_rwkv.SetPrompt(prompt));
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

  /// 停止生成
  Future<void> stop() async => send(to_rwkv.Stop());

  /// 生成聊天回复流
  Stream<String> streamLocalChatCompletions({String content = '介绍下自己'}) {
    debugPrint('streamLocalChatCompletions called with content: $content');
    if (localChatController != null) {
      localChatController!.close();
    }
    localChatController = StreamController<String>();
    debugPrint('Created new localChatController');
    generate(content);
    debugPrint('Called generate method');
    return localChatController!.stream;
  }

  /// 生成回复
  Future<void> generate(String prompt) async {
    prefillSpeed.value = 0;
    decodeSpeed.value = 0;
    isGenerating.value = true;
    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      isGenerating.value = false;
      return;
    }

    final stateManager = ChatStateManager();
    final messages = stateManager.getMessages(roleName.value);
    debugPrint(
      'Current messages count for ${roleName.value}: ${messages.length}',
    );
    var history = <String>[];
    for (var message in messages) {
      var text = message.content;
      if (text.isNotEmpty) {
        history.add(text);
      }
    }
    debugPrint("to_rwkv.history: $history");
    send(to_rwkv.ChatAsync(history, reasoning: false));
    debugPrint('Sent ChatAsync to RWKV');

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
    }
    isNeedSaveAiMessage = true;
    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      send(to_rwkv.GetResponseBufferIds());
      send(to_rwkv.GetPrefillAndDecodeSpeed());
      send(to_rwkv.GetResponseBufferContent());
      await Future.delayed(const Duration(milliseconds: 1000));
      send(to_rwkv.GetIsGenerating());

      // 减少不必要的调用频率
      if (timer.tick % 5 == 0) {
        send(to_rwkv.GetPrefillAndDecodeSpeed());
        send(to_rwkv.GetIsGenerating());
      }
    });
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

  @override
  void onClose() {
    _getTokensTimer?.cancel();
    localChatController?.close();
    super.onClose();
  }
}
