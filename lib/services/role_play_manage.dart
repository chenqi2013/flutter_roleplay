import 'package:flutter/material.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_page.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/language_service.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/translations/app_translations.dart';
import 'package:get/get.dart';

BuildContext? currentContext;
LanguageService? languageService;

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

    // 初始化语言服务
    _initializeLanguageService();

    // 直接返回RolePlayChat页面，不创建新的MaterialApp
    // 让宿主应用的导航栈管理所有页面
    return RolePlayChat();
  }

  // 防止重复初始化的标志
  static bool _isInitialized = false;

  /// 初始化语言服务和翻译
  static void _initializeLanguageService() {
    if (_isInitialized) {
      debugPrint('语言服务已初始化，跳过重复初始化');
      return;
    }

    try {
      // 手动设置GetX翻译，即使没有GetMaterialApp
      Get.addTranslations(AppTranslations().keys);
      debugPrint('翻译已添加到GetX');

      // 初始化语言服务
      if (!Get.isRegistered<LanguageService>()) {
        languageService = Get.put(LanguageService());
        debugPrint('LanguageService已注册');
        // 异步加载保存的语言设置
        Future.microtask(() async {
          final savedLocale = await languageService!.getSavedLanguage();
          Get.updateLocale(savedLocale);
          debugPrint('已应用保存的语言: $savedLocale');
        });
      } else {
        languageService = Get.find<LanguageService>();
        debugPrint('LanguageService已存在，直接使用');
      }

      _isInitialized = true;
      debugPrint('语言服务初始化完成');
    } catch (e) {
      debugPrint('语言服务初始化失败: $e');
    }
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

  ///语言切换
  static void changeLocale(Locale locale) {
    debugPrint('切换语言: ${locale.countryCode} ${locale.languageCode}');

    if (Get.isRegistered<LanguageService>()) {
      languageService = Get.find<LanguageService>();
    } else {
      languageService = Get.put(LanguageService());
    }
    languageService?.saveLanguage(locale);
  }

  /// 重置插件状态（用于调试或重新初始化）
  static void resetPlugin() {
    _isInitialized = false;
    debugPrint('插件状态已重置');
  }
}
