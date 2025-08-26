import 'package:flutter/material.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_page.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:get/get.dart';

BuildContext? currentContext;

class RoleplayManage {
  static Widget createRolePlayChatPage(
    BuildContext context, {
    VoidCallback? onModelDownloadRequired,
    Function(ModelInfo?)? changeModelCallback,
  }) {
    currentContext = context;

    // 设置全局模型下载回调
    setGlobalModelDownloadCallback(onModelDownloadRequired);

    // 设置全局模型切换回调
    setGlobalModelChangeCallback(changeModelCallback);

    return GetMaterialApp(home: RolePlayChat());
  }

  /// 通知插件模型下载完成，插件将重新加载模型
  /// 外部应用在模型下载完成后调用此方法
  static void onModelDownloadComplete(ModelInfo info) {
    debugPrint('外部应用通知：模型下载完成');
    // 调用全局函数通知模型下载完成
    notifyModelDownloadComplete(info);
  }

  /// state文件切换
  static void onStateFileChange(ModelInfo info) {
    debugPrint('外部应用通知：state文件切换了');
  }
}
