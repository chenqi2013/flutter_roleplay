import 'package:flutter/material.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:flutter_roleplay/services/rwkv_tts_service.dart';
import 'package:get/get.dart';
import 'package:rwkv_mobile_flutter/types.dart';

/// 模型下载回调函数类型
typedef ModelDownloadCallback = void Function(RoleplayManageModelType type);

/// 全局模型下载回调
ModelDownloadCallback? _globalModelDownloadCallback;

VoidCallback? _updateRolePlaySessionCallback;

/// 全局模型切换回调
Function(ModelInfo?)? _globalModelChangeCallback;

/// 全局模型下载完成回调
Function(ModelInfo?)? _globalModelDownloadCompleteCallback;

/// 全局state文件切换回调
Function(ModelInfo?)? _globalStateFileChangeCallback;

/// 设置全局模型下载回调
void setGlobalModelDownloadCallback(ModelDownloadCallback? callback) {
  _globalModelDownloadCallback = callback;
}

void setGlobalUpdateRolePlaySessionCallback(VoidCallback? callback) {
  _updateRolePlaySessionCallback = callback;
}

/// 设置全局模型切换回调
void setGlobalModelChangeCallback(Function(ModelInfo?)? callback) {
  _globalModelChangeCallback = callback;
}

/// 设置全局模型下载完成回调
void setGlobalModelDownloadCompleteCallback(Function(ModelInfo?)? callback) {
  _globalModelDownloadCompleteCallback = callback;
}

/// state文件切换
void setGlobalStateFileChangeCallback(Function(ModelInfo?)? callback) {
  _globalStateFileChangeCallback = callback;
}

/// 通知需要下载模型
void notifyModelDownloadRequired(RoleplayManageModelType type) {
  debugPrint('notifyModelDownloadRequired: $type');
  if (_globalModelDownloadCallback != null) {
    debugPrint('通知外部应用需要下载模型');
    _globalModelDownloadCallback!(type);
  } else {
    debugPrint('未设置模型下载回调，无法通知外部应用');
  }
}

/// 通知需要更新角色会话
void notifyUpdateRolePlaySessionRequired() {
  if (_updateRolePlaySessionCallback != null) {
    debugPrint('通知外部应用需要更新角色会话');
    _updateRolePlaySessionCallback!();
  } else {
    debugPrint('未设置角色会话更新回调，无法通知外部应用');
  }
}

/// 通知需要切换模型
void notifyModelChangeRequired() {
  if (_globalModelChangeCallback != null) {
    debugPrint('通知外部应用需要切换模型');
    RolePlayChatController? _controller;
    if (Get.isRegistered<RolePlayChatController>()) {
      _controller = Get.find<RolePlayChatController>();
    } else {
      _controller = Get.put(RolePlayChatController());
    }
    debugPrint('通知外部应用需要切换模型: ${_controller!.modelInfo?.toString()}');
    _globalModelChangeCallback!(_controller.modelInfo);
  } else {
    debugPrint('未设置模型切换回调，无法通知外部应用');
  }
}

/// 通知外部应用模型下载完成，插件应该重新加载模型
void notifyModelDownloadComplete(ModelInfo info) {
  if (_globalModelDownloadCompleteCallback != null) {
    debugPrint('收到模型下载完成通知，重新加载模型');
    _globalModelDownloadCompleteCallback!(info);
  } else {
    debugPrint('未设置模型下载完成回调');
  }

  /// 现在不会走下载完成的回调了
  RWKVChatService chatService;
  RWKVTTSService ttsService;
  if (info.modelType == RoleplayManageModelType.chat) {
    if (Get.isRegistered<RWKVChatService>()) {
      debugPrint('RWKVChatService已注册');
      chatService = Get.find<RWKVChatService>();
    } else {
      debugPrint('RWKVChatService未注册，创建新的实例');
      chatService = Get.put(RWKVChatService());
    }
    debugPrint('chenqi chatService.modelID: ${RoleplayManage.chatModelID}');
    chatService.loadChatModel(info: info);
  } else if (info.modelType == RoleplayManageModelType.tts) {
    if (Get.isRegistered<RWKVTTSService>()) {
      debugPrint('RWKVTTSService已注册');
      ttsService = Get.find<RWKVTTSService>();
    } else {
      debugPrint('RWKVTTSService未注册，创建新的实例');
      ttsService = Get.put(RWKVTTSService());
    }
    debugPrint('chenqi ttsService.modelID: ${RoleplayManage.ttsModelID}');
    ttsService.loadTTSModel(modelPath: info.modelPath, backend: info.backend);
  }
}

/// 通知外部应用state文件改变，插件应该重新clearstate
void notifyStateFileChange(ModelInfo info) {
  if (_globalStateFileChangeCallback != null) {
    debugPrint('收到state文件改变通知，重新加载模型');
    _globalStateFileChangeCallback!(info);
  } else {
    debugPrint('未设置state文件改变回调');
  }
}
