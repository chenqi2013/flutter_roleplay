import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:isolate';

import 'dart:async';

import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/pages/params/role_params_controller.dart';
import 'package:flutter_roleplay/dialog/download_dialog.dart';

/// RWKV 聊天模型管理服务
class RWKVChatService extends GetxController {
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
  String? rmpack;

  StreamController<String>? localChatController;
  bool isNeedSaveAiMessage = false;

  // 回调函数
  Function(String)? _onMessageGenerated;
  Function()? _onGenerationComplete;
  RolePlayChatController? _controller;
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
    // 首先尝试从本地加载已保存的模型信息
    ModelInfo? modelInfo = await _loadModelFromLocal();
    RolePlayChatController? controller;
    if (Get.isRegistered<RolePlayChatController>()) {
      controller = Get.find<RolePlayChatController>();
    } else {
      controller = Get.put(RolePlayChatController());
    }
    controller?.modelInfo = modelInfo;

    // 设置模型下载完成回调，当外部应用通知下载完成时重新加载模型
    setGlobalModelDownloadCompleteCallback((ModelInfo? info) async {
      debugPrint('modelDownloadCompleteCallback: ${info?.toString()}');
      if (controller?.modelInfo != null &&
          await CommonUtil.getFileDocumentPath(
                controller!.modelInfo!.modelPath,
              ) !=
              await CommonUtil.getFileDocumentPath(info!.modelPath)) {
        debugPrint('切换了模型');
        loadChatModel();
      } else if (controller?.modelInfo != null &&
          await CommonUtil.getFileDocumentPath(
                controller!.modelInfo!.modelPath,
              ) ==
              await CommonUtil.getFileDocumentPath(info!.modelPath) &&
          await CommonUtil.getFileDocumentPath(
                controller.modelInfo!.statePath,
              ) !=
              await CommonUtil.getFileDocumentPath(info.statePath)) {
        ///仅仅切换了state文件
        debugPrint('仅仅切换了state文件');
        changeStatesFile(
          statePath: await CommonUtil.getFileDocumentPath(info.statePath),
        );
      } else {
        debugPrint('第一次下载，切换了模型');
        controller?.modelInfo = info;
        loadChatModel();
      }
      if (info != null) {
        // 把当前的 modelinfo 保存到本地
        controller?.modelInfo = info;
        RoleParamsController? paramsController;
        if (Get.isRegistered<RoleParamsController>()) {
          paramsController = Get.find<RoleParamsController>();
        } else {
          paramsController = Get.put(RoleParamsController());
        }
        paramsController?.temperature.value = info.temperature ?? 0.6;
        paramsController?.topP.value = info.topP ?? 0.8;
        paramsController?.presencePenalty.value = info.presencePenalty ?? 2.0;
        paramsController?.frequencyPenalty.value = info.frequencyPenalty ?? 0.2;
        paramsController?.penaltyDecay.value = info.penaltyDecay ?? 0.990;
        paramsController?.saveParams();

        await _saveModelInfoToLocal(info);
      }
    });

    setGlobalStateFileChangeCallback((ModelInfo? info) {
      controller?.modelInfo = modelInfo;
      debugPrint('stateFileChangeCallback: ${info?.toString()}');
      clearStates();
    });

    // 检查是否需要下载模型
    if (modelInfo != null &&
        await checkDownloadFile(
          await CommonUtil.getFileDocumentPath(modelInfo.modelPath),
          isLocalFilePath: true,
        )) {
      loadChatModel();
    } else {
      debugPrint('模型不存在，通知外部下载模型');
      // 通知外部应用需要下载模型，而不是在插件内部处理
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyModelDownloadRequired();
      });
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
    String? statePath;

    // 首先尝试从数据库获取保存的模型信息
    try {
      if (_controller == null) {
        if (Get.isRegistered<RolePlayChatController>()) {
          _controller = Get.find<RolePlayChatController>();
        } else {
          _controller = Get.put(RolePlayChatController());
        }
      }
      var modelInfo = _controller?.modelInfo;
      if (modelInfo == null) {
        final databaseHelper = DatabaseHelper();
        modelInfo = await databaseHelper.getActiveModelInfo();
        debugPrint('从数据库获取modelInfo: ${modelInfo?.toString()}');
      }
      if (modelInfo != null &&
          File(
            await CommonUtil.getFileDocumentPath(modelInfo.modelPath),
          ).existsSync()) {
        modelPath = await CommonUtil.getFileDocumentPath(modelInfo.modelPath);
        statePath = await CommonUtil.getFileDocumentPath(modelInfo.statePath);
        backend = modelInfo.backend;
      } else {
        // // 如果数据库中没有有效的模型信息，使用默认方式获取路径
        // modelPath = await getLocalFilePath(downloadUrl);
        // if (!File(modelPath).existsSync()) {
        //   debugPrint('modelPath not exists: $modelPath');
        //   return;
        // }
        debugPrint('没有获取到模型信息');
        return;
      }
    } catch (e) {
      debugPrint('获取数据库模型信息失败: $e');
      return;
    }

    if (Platform.isAndroid && backend == Backend.qnn) {
      for (final lib in qnnLibList) {
        await CommonUtil.fromAssetsToTemp(
          "assets/lib/qnn/$lib",
          targetPath: "assets/lib/$lib",
        );
      }
    }

    final tokenizerPath = await CommonUtil.fromAssetsToTemp(
      "assets/config/chat/b_rwkv_vocab_v20230424.txt",
    );

    // 如果有保存的状态路径，使用它；否则使用默认的 rmpack
    if (File(statePath).existsSync()) {
      rmpack = statePath;
      debugPrint('使用state文件: $statePath');
    }
    // else {
    //   rmpack = await fromAssetsToTemp(
    //     "assets/config/chat/rwkv-9-mix_user6500_system1700.rmpack",
    //   );
    //   debugPrint('使用默认状态文件: $rmpack');
    // }

    isModelLoaded = true;

    // if (Platform.isIOS || Platform.isMacOS) {
    //   modelPath = await fromAssetsToTemp(
    //     "assets/model/othello/RWKV-x070-G1-0.1b-20250307-ctx4096.st",
    //   );
    //   backend = Backend.webRwkv;
    // }

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(
        to_rwkv.ReInitRuntime(
          modelPath: modelPath,
          backend: backend,
          tokenizerPath: tokenizerPath,
        ),
      );
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
    if (rmpack != null) {
      send(to_rwkv.LoadInitialStates(rmpack!));
    }
    // send(to_rwkv.GetLatestRuntimeAddress()); // 已弃用

    _setupModelParameters();
  }

  /// 设置模型参数
  void _setupModelParameters() {
    final prompt =
        "<state src=\"$rmpack\">System: ${roleLanguage.value == 'zh-CN' ? '请你扮演' : 'You are '}${roleName.value}，${roleDescription.value}\n\n";
    debugPrint('set prompt11: $prompt');
    send(to_rwkv.SetPrompt(prompt));
    send(to_rwkv.SetMaxLength(2000));
    // 获取角色参数设置
    try {
      final paramsController = Get.find<RoleParamsController>();
      final params = paramsController.getCurrentParams();
      debugPrint('setupModelParameters: $params');
      send(
        to_rwkv.SetSamplerParams(
          temperature: params['temperature'] as double,
          topK: params['topK'] as int,
          topP: params['topP'] as double,
          presencePenalty: params['presencePenalty'] as double,
          frequencyPenalty: params['frequencyPenalty'] as double,
          penaltyDecay: params['penaltyDecay'] as double,
        ),
      );
    } catch (e) {
      debugPrint(
        'RoleParamsController not found, using default parameters: $e',
      );
      // 使用默认参数
      send(
        to_rwkv.SetSamplerParams(
          temperature: 1.2,
          topK: 500,
          topP: 0.6,
          presencePenalty: 1.5,
          frequencyPenalty: 1.0,
          penaltyDecay: 0.996,
        ),
      );
    }
  }

  /// 设置采样参数
  void setSamplerParams() {
    final paramsController = Get.find<RoleParamsController>();
    final params = paramsController.getCurrentParams();
    debugPrint('setSamplerParams: $params');
    send(
      to_rwkv.SetSamplerParams(
        temperature: params['temperature'] as double,
        topK: params['topK'] as int,
        topP: params['topP'] as double,
        presencePenalty: params['presencePenalty'] as double,
        frequencyPenalty: params['frequencyPenalty'] as double,
        penaltyDecay: params['penaltyDecay'] as double,
      ),
    );
  }

  /// 清空状态
  Future<void> clearStates({String? statePath}) async {
    // prefillSpeed.value = 0;
    // decodeSpeed.value = 0;

    // // 只清空内存中的聊天记录，不删除数据库记录
    // final stateManager = ChatStateManager();
    // stateManager.getMessages(roleName.value).clear();

    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }

    ///切换角色需要clearstate，否则聊天内容会是上一次的角色的。
    // send(to_rwkv.ClearStates());
    debugPrint('ClearStates() 11');
    // if (statePath != null) {
    //   rmpack = statePath;
    // }
    // if (rmpack != null) {
    //   send(to_rwkv.LoadInitialStates(rmpack!));
    // }
    final prompt =
        "<state src=\"$rmpack\">System: ${roleLanguage.value == 'zh-CN' ? '请你扮演' : 'You are '}${roleName.value}，${roleDescription.value}\n\n";
    debugPrint('set prompt22: $prompt');
    send(to_rwkv.SetPrompt(prompt));
  }

  ///切换了state文件
  Future<void> changeStatesFile({String? statePath}) async {
    // prefillSpeed.value = 0;
    // decodeSpeed.value = 0;

    // // 只清空内存中的聊天记录，不删除数据库记录
    // final stateManager = ChatStateManager();
    // stateManager.getMessages(roleName.value).clear();

    final sendPort = _sendPort;
    if (sendPort == null) {
      debugPrint("sendPort is null");
      return;
    }

    ///只有切换了state文件才需要clearstate
    send(to_rwkv.ClearStates());
    debugPrint('ClearStates() 22');
    send(to_rwkv.UnloadInitialStates('$rmpack'));
    if (statePath != null) {
      rmpack = statePath;
    }
    if (rmpack != null) {
      debugPrint('切换了state文件: $rmpack');
      send(to_rwkv.LoadInitialStates(rmpack!));
    }
    final prompt =
        "<state src=\"$rmpack\">System: ${roleLanguage.value == 'zh-CN' ? '请你扮演' : 'You are '}${roleName.value}，${roleDescription.value}\n\n";
    debugPrint('set prompt33: $prompt');
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
  Stream<String> streamLocalChatCompletions({String? content}) {
    content ??= 'introduce_yourself'.tr;
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
      ),
    );
    return _initRuntimeCompleter.future;
  }

  /// 从本地加载模型信息
  Future<ModelInfo?> _loadModelFromLocal() async {
    try {
      final databaseHelper = DatabaseHelper();
      final modelInfo = await databaseHelper.getActiveModelInfo();

      if (modelInfo != null) {
        debugPrint('从本地加载模型信息: ${modelInfo.id}');
        debugPrint('模型路径: ${modelInfo.modelPath}');
        debugPrint('state文件路径: ${modelInfo.statePath}');
        debugPrint('后端类型: ${modelInfo.backend}');

        // 更新全局配置，使用保存的模型信息
        downloadUrl = modelInfo.id; // 使用 id 作为下载 URL 的标识
        backend = modelInfo.backend;

        // 检查模型文件是否存在
        if (File(
          await CommonUtil.getFileDocumentPath(modelInfo.modelPath),
        ).existsSync()) {
          debugPrint('本地模型文件存在，可以直接加载: ${modelInfo.modelPath}');
          // 如果本地文件存在，直接返回，跳过下载检查
          return modelInfo;
        } else {
          debugPrint('本地模型文件不存在: ${modelInfo.modelPath}');
          // 文件不存在时，仍然使用保存的配置，让下载流程处理
          return null;
        }
      } else {
        debugPrint('没有找到本地保存的模型信息，不加载模型');
        return null;
      }
    } catch (e) {
      debugPrint('从本地加载模型信息失败: $e');
      return null;
    }
  }

  /// 保存模型信息到本地
  Future<void> _saveModelInfoToLocal(ModelInfo modelInfo) async {
    try {
      final databaseHelper = DatabaseHelper();
      await databaseHelper.saveModelInfo(modelInfo);
      debugPrint('成功保存模型信息到本地: ${modelInfo.id}');
    } catch (e) {
      debugPrint('保存模型信息到本地失败: $e');
    }
  }

  @override
  void onClose() {
    _getTokensTimer?.cancel();
    localChatController?.close();
    super.onClose();
  }
}
