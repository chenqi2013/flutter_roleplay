import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelParamsController extends GetxController {
  final dbHelper = DatabaseHelper();

  // 当前使用的模型
  final Rx<ModelInfo?> currentChatModel = Rx<ModelInfo?>(null);
  final Rx<ModelInfo?> currentTTSModel = Rx<ModelInfo?>(null);

  // TTS语言选择 (中文/英文/日语)
  final RxString ttsLanguage = '中文'.obs;
  final List<String> ttsLanguages = ['中文', '英文', '日语'];

  // 风格滑块值 (0.0 - 1.0, 0=无聊的, 1=疯狂的)
  final RxDouble styleValue = 0.5.obs;

  // 语音角色 (帝王等)
  final RxString voiceRole = '帝王'.obs;
  final List<String> voiceRoles = ['帝王', '少女', '青年', '老者', '孩童'];

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadModelsAndSettings();
  }

  /// 加载模型和设置
  Future<void> loadModelsAndSettings() async {
    try {
      isLoading.value = true;

      // 从数据库读取当前使用的聊天模型
      final activeChatModel = await dbHelper.getModelInfoByType('chat');
      currentChatModel.value = activeChatModel;

      // 从数据库读取当前使用的TTS模型
      final activeTTSModel = await dbHelper.getModelInfoByType('tts');
      currentTTSModel.value = activeTTSModel;

      // 加载保存的设置
      await loadSettings();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      Get.snackbar(
        '加载失败',
        '无法加载模型信息: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载设置
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      ttsLanguage.value = prefs.getString('tts_language') ?? '中文';
      styleValue.value = prefs.getDouble('style_value') ?? 0.5;
      voiceRole.value = prefs.getString('voice_role') ?? '帝王';
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  /// 选择TTS语言
  void selectTTSLanguage(String language) {
    ttsLanguage.value = language;
  }

  /// 更新风格值
  void updateStyleValue(double value) {
    styleValue.value = value;
  }

  /// 选择语音角色
  void selectVoiceRole(String role) {
    voiceRole.value = role;
  }

  /// 获取风格描述
  String getStyleDescription() {
    if (styleValue.value < 0.3) {
      return '无聊的';
    } else if (styleValue.value > 0.7) {
      return '疯狂的';
    } else {
      return '正常人类';
    }
  }

  /// 保存配置
  Future<void> saveConfiguration() async {
    try {
      isSaving.value = true;

      // 保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_language', ttsLanguage.value);
      await prefs.setDouble('style_value', styleValue.value);
      await prefs.setString('voice_role', voiceRole.value);

      Get.snackbar(
        '保存成功',
        '模型参数配置已保存',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // 延迟后返回
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      debugPrint('保存配置失败: $e');
      Get.snackbar(
        '保存失败',
        '无法保存配置: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// 获取模型显示名称
  String getModelDisplayName(ModelInfo? model) {
    if (model == null) return '未配置';
    // 从 ID 或路径中提取模型名称
    final name = model.id.split('/').last;
    return name.replaceAll('.bin', '').replaceAll('_', ' ');
  }
}
