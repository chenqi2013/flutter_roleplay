import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_page.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/language_service.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/translations/app_translations.dart';
import 'package:flutter_roleplay/pages/params/role_params_controller.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
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

    // 初始化图片缓存系统
    _initializeImageCache();

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

      // 初始化角色参数控制器
      if (!Get.isRegistered<RoleParamsController>()) {
        Get.put(RoleParamsController());
        debugPrint('RoleParamsController已注册');
      } else {
        debugPrint('RoleParamsController已存在，直接使用');
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

  /// 初始化图片缓存系统
  static void _initializeImageCache() {
    debugPrint('RoleplayManage: 初始化图片缓存系统...');
    Future.microtask(() async {
      try {
        await ChatPageBuilders.initializeImageCache();
        debugPrint('RoleplayManage: 图片缓存系统初始化完成');
      } catch (e) {
        debugPrint('RoleplayManage: 图片缓存系统初始化失败: $e');
      }
    });
  }

  /// 重置插件状态（用于调试或重新初始化）
  static void resetPlugin() {
    _isInitialized = false;
    debugPrint('插件状态已重置');
  }

  /// 一个打开对话的接口
  static Widget goRolePlay(
    String roleName,
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

    // 初始化图片缓存系统
    _initializeImageCache();

    // 直接返回RolePlayChat页面，不创建新的MaterialApp
    // 让宿主应用的导航栈管理所有页面
    debugPrint('goRolePlay: $roleName');
    return RolePlayChat(roleName: roleName);
  }

  /// 一个删除对话的接口
  static void deleteRolePlaySession(String roleName) {
    debugPrint('deleteRolePlaySession: $roleName');
    RolePlayChatController controller;
    if (Get.isRegistered<RolePlayChatController>()) {
      controller = Get.find<RolePlayChatController>();
    } else {
      controller = Get.put(RolePlayChatController());
    }
    controller.clearChatHistoryFromDatabase(roleName);
  }

  ///更新角色记录
  static void updateRolePlaySession(String roleName) {
    debugPrint('updateRolePlaySession: $roleName');
  }

  /// 获取数据库里每一个角色最后一条聊天记录
  /// 返回类型：List<Map<String, ChatMessage>>，每个Map的key为角色图片地址，value为最后一条消息
  static Future<List<Map<String, ChatMessage>>> getRolePlayListSession() async {
    debugPrint('getRolePlayListSession');
    try {
      final dbHelper = DatabaseHelper();
      final roleNames = await dbHelper.getAllRoleNames();
      final List<Map<String, ChatMessage>> rolePlayList = [];

      for (final roleName in roleNames) {
        // 获取每个角色的最新一条消息
        final latestMessages = await dbHelper.getLatestMessagesByRole(
          roleName,
          1,
        );
        if (latestMessages.isNotEmpty) {
          // 通过角色名称获取角色信息（包括图片地址）
          final roleInfo = await _getRoleInfoByName(roleName);
          if (roleInfo != null) {
            // 创建Map，key为图片地址，value为最后一条消息
            final Map<String, ChatMessage> roleMap = {
              roleInfo['image']: latestMessages.first,
            };
            rolePlayList.add(roleMap);
          }
        }
      }

      // 按时间戳倒序排列，最新的在前面
      rolePlayList.sort((a, b) {
        final messageA = a.values.first;
        final messageB = b.values.first;
        return messageB.timestamp.compareTo(messageA.timestamp);
      });

      debugPrint('getRolePlayList: $rolePlayList');
      return rolePlayList;
    } catch (e) {
      debugPrint('getRolePlayList 失败: $e');
      return [];
    }
  }

  /// 通过角色名称获取角色信息
  static Future<Map<String, dynamic>?> _getRoleInfoByName(
    String roleName,
  ) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'roles',
        where: 'name = ?',
        whereArgs: [roleName],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      debugPrint('获取角色信息失败: $e');
      return null;
    }
  }
}
