import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言管理服务
class LanguageService extends GetxController {
  static const String _languageKey = 'app_language';
  static const String _countryKey = 'app_country';

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 中文
    Locale('en', 'US'), // 英文
  ];

  // 默认语言
  static const Locale defaultLocale = Locale('zh', 'CN');

  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    // await loadSavedLanguage();
  }

  /// 获取保存的语言设置
  Future<Locale> getSavedLanguage() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final languageCode = _prefs!.getString(_languageKey);
      // final countryCode = _prefs!.getString(_countryKey);
      Locale? locale;
      if (languageCode != null) {
        // && countryCode != null
        if (languageCode == 'en') {
          locale = Locale('en', 'US');
        } else {
          locale = Locale('zh', 'CN');
        }

        // final locale = Locale(languageCode, countryCode);

        // // // 验证是否为支持的语言
        // // if (supportedLocales.contains(locale)) {
        debugPrint('从本地存储加载语言: ${locale.toString()}');
        return locale;
        // // }
      }

      debugPrint('使用默认语言: ${defaultLocale.toString()}');
      return defaultLocale;
    } catch (e) {
      debugPrint('获取保存的语言失败: $e');
      return defaultLocale;
    }
  }

  /// 保存语言设置
  Future<void> saveLanguage(Locale locale) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      await _prefs!.setString(_languageKey, locale.languageCode);
      await _prefs!.setString(_countryKey, locale.countryCode ?? '');

      debugPrint('语言设置已保存: ${locale.toString()}');
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }
  }

  /// 切换语言
  Future<void> changeLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      debugPrint('不支持的语言: ${locale.toString()}');
      return;
    }

    try {
      // 保存到本地存储
      await saveLanguage(locale);

      // 更新GetX语言设置
      Get.updateLocale(locale);

      debugPrint('语言已切换到: ${locale.toString()}');
    } catch (e) {
      debugPrint('切换语言失败: $e');
    }
  }

  /// 从本地存储加载语言并应用
  Future<void> loadSavedLanguage() async {
    try {
      final savedLocale = await getSavedLanguage();
      Get.updateLocale(savedLocale);
      debugPrint('应用启动时加载语言: ${savedLocale.toString()}');
    } catch (e) {
      debugPrint('加载保存的语言失败: $e');
      // 使用默认语言
      Get.updateLocale(defaultLocale);
    }
  }

  /// 获取当前语言
  Locale getCurrentLanguage() {
    return Get.locale ?? defaultLocale;
  }

  /// 检查是否为中文
  bool isChineseLanguage() {
    final current = getCurrentLanguage();
    return current.languageCode == 'zh';
  }

  /// 检查是否为英文
  bool isEnglishLanguage() {
    final current = getCurrentLanguage();
    return current.languageCode == 'en';
  }

  /// 获取语言显示名称
  String getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }

  /// 切换到下一个语言
  Future<void> toggleLanguage() async {
    final current = getCurrentLanguage();
    final nextLocale = current.languageCode == 'zh'
        ? const Locale('en', 'US')
        : const Locale('zh', 'CN');

    await changeLanguage(nextLocale);
  }
}
