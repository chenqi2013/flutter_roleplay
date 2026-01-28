import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_roleplay/constant/constant.dart';

class ModelParamsController extends GetxController {
  final dbHelper = DatabaseHelper();

  // 当前使用的模型
  final Rx<ModelInfo?> currentChatModel = Rx<ModelInfo?>(null);
  final Rx<ModelInfo?> currentTTSModel = Rx<ModelInfo?>(null);

  // TTS语言选择 (中文/英文/日语)
  final RxString ttsLanguage = 'chinese'.obs;
  final List<String> ttsLanguages = ['chinese', 'english_lang', 'japanese'];

  // 风格滑块值 (0.0 - 1.0, 0=无聊的, 1=疯狂的)
  final RxDouble styleValue = 0.5.obs;

  // 语音角色 (帝王等)
  final RxString voiceRole = '帝王'.obs;
  final List<String> voiceRoles = ['帝王', '少女', '青年', '老者', '孩童'];

  // 解码参数相关
  final RxBool showDetailedParams = false.obs; // 是否显示详细参数
  final RxInt presetLevel = 2.obs; // 预设档位 (0-4，对应5个档位)

  // 解码参数值
  final RxDouble temperature = 1.0.obs;
  final RxDouble topP = 0.3.obs;
  final RxDouble presencePenalty = 0.5.obs;
  final RxDouble frequencyPenalty = 0.5.obs;
  final RxDouble penaltyDecay = 0.996.obs;

  // TextEditingController for input fields - 直接初始化
  late final TextEditingController tempController = TextEditingController(
    text: temperature.value.toString(),
  );
  late final TextEditingController topPController = TextEditingController(
    text: topP.value.toString(),
  );
  late final TextEditingController presenceController = TextEditingController(
    text: presencePenalty.value.toString(),
  );
  late final TextEditingController frequencyController = TextEditingController(
    text: frequencyPenalty.value.toString(),
  );
  late final TextEditingController decayController = TextEditingController(
    text: penaltyDecay.value.toString(),
  );

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // 预设档位配置
  List<Map<String, dynamic>> get presetConfigs => [
    {
      'name': 'preset_crazy'.tr,
      'temp': 0.6,
      'topp': 0.8,
      'presence': 2.0,
      'frequency': 0.2,
      'decay': 0.99,
    },
    {
      'name': 'preset_boiling'.tr,
      'temp': 0.8,
      'topp': 0.6,
      'presence': 1.2,
      'frequency': 0.35,
      'decay': 0.993,
    },
    {
      'name': 'preset_daily'.tr,
      'temp': 1.0,
      'topp': 0.3,
      'presence': 0.5,
      'frequency': 0.5,
      'decay': 0.996,
    },
    {
      'name': 'preset_restrained'.tr,
      'temp': 0.5,
      'topp': 0.3,
      'presence': 0.2,
      'frequency': 0.2,
      'decay': 0.996,
    },
    {
      'name': 'preset_blank'.tr,
      'temp': 0.3,
      'topp': 0.3,
      'presence': 0.0,
      'frequency': 0.0,
      'decay': 0.996,
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadModelsAndSettings();
  }

  @override
  void onClose() {
    tempController.dispose();
    topPController.dispose();
    presenceController.dispose();
    frequencyController.dispose();
    decayController.dispose();
    super.onClose();
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
        'load_failed_title'.tr,
        '${'unable_to_load_model_info'.tr}: $e',
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
      ttsLanguage.value = prefs.getString('tts_language') ?? 'chinese';
      styleValue.value = prefs.getDouble('style_value') ?? 0.5;

      // 加载实际的音色名称（从全局变量或SharedPreferences）
      final savedAudioName = prefs.getString(ttsAudioNameKey) ?? ttsAudioName;
      // 从文件名提取显示名称（去掉扩展名和前缀）
      voiceRole.value = _extractVoiceName(savedAudioName);

      // 加载解码参数
      presetLevel.value = prefs.getInt('preset_level') ?? 2;
      temperature.value = prefs.getDouble('temperature') ?? 1.0;
      topP.value = prefs.getDouble('top_p') ?? 0.3;
      presencePenalty.value = prefs.getDouble('presence_penalty') ?? 0.5;
      frequencyPenalty.value = prefs.getDouble('frequency_penalty') ?? 0.5;
      penaltyDecay.value = prefs.getDouble('penalty_decay') ?? 0.996;

      // 更新输入框
      _updateTextControllers();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  /// 从音频文件名提取显示名称
  String _extractVoiceName(String audioFileName) {
    // 例如: "Chinese(PRC)_Acheron_3.wav" -> "Acheron"
    try {
      // 去掉扩展名
      final nameWithoutExt = audioFileName
          .replaceAll('.wav', '')
          .replaceAll('.mp3', '');
      // 按下划线分割
      final parts = nameWithoutExt.split('_');
      // 如果有多个部分，取中间的名称部分
      if (parts.length >= 2) {
        return parts[1]; // 返回角色名称部分
      }
      return nameWithoutExt;
    } catch (e) {
      return audioFileName;
    }
  }

  /// 选择TTS语言
  void selectTTSLanguage(String language) async {
    ttsLanguage.value = language;
    // 立即保存到 SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_language', language);
      debugPrint('TTS语言已保存: $language');
    } catch (e) {
      debugPrint('保存TTS语言失败: $e');
    }
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
      return 'style_boring'.tr;
    } else if (styleValue.value > 0.7) {
      return 'style_crazy'.tr;
    } else {
      return 'style_normal'.tr;
    }
  }

  /// 切换详细参数显示
  void toggleDetailedParams() {
    showDetailedParams.value = !showDetailedParams.value;
  }

  /// 设置预设档位
  void setPresetLevel(int level) async {
    if (level < 0 || level >= presetConfigs.length) return;

    presetLevel.value = level;
    final config = presetConfigs[level];

    temperature.value = config['temp'];
    topP.value = config['topp'];
    presencePenalty.value = config['presence'];
    frequencyPenalty.value = config['frequency'];
    penaltyDecay.value = config['decay'];

    _updateTextControllers();
    
    // 立即保存到 SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('preset_level', level);
      await prefs.setDouble('temperature', temperature.value);
      await prefs.setDouble('top_p', topP.value);
      await prefs.setDouble('presence_penalty', presencePenalty.value);
      await prefs.setDouble('frequency_penalty', frequencyPenalty.value);
      await prefs.setDouble('penalty_decay', penaltyDecay.value);
      debugPrint('解码参数档位已保存: ${config['name']}');
    } catch (e) {
      debugPrint('保存解码参数失败: $e');
    }
  }

  /// 更新 TextEditingController
  void _updateTextControllers() {
    tempController.text = temperature.value.toString();
    topPController.text = topP.value.toString();
    presenceController.text = presencePenalty.value.toString();
    frequencyController.text = frequencyPenalty.value.toString();
    decayController.text = penaltyDecay.value.toString();
  }

  /// 从输入框更新参数值
  void updateParameterFromInput(String paramName, String value) async {
    try {
      final doubleValue = double.parse(value);
      switch (paramName) {
        case 'temp':
          temperature.value = doubleValue;
          break;
        case 'topp':
          topP.value = doubleValue;
          break;
        case 'presence':
          presencePenalty.value = doubleValue;
          break;
        case 'frequency':
          frequencyPenalty.value = doubleValue;
          break;
        case 'decay':
          penaltyDecay.value = doubleValue;
          break;
      }
      
      // 立即保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      switch (paramName) {
        case 'temp':
          await prefs.setDouble('temperature', doubleValue);
          break;
        case 'topp':
          await prefs.setDouble('top_p', doubleValue);
          break;
        case 'presence':
          await prefs.setDouble('presence_penalty', doubleValue);
          break;
        case 'frequency':
          await prefs.setDouble('frequency_penalty', doubleValue);
          break;
        case 'decay':
          await prefs.setDouble('penalty_decay', doubleValue);
          break;
      }
      debugPrint('参数已保存: $paramName = $doubleValue');
    } catch (e) {
      debugPrint('解析参数失败: $e');
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

      // 保存解码参数
      await prefs.setInt('preset_level', presetLevel.value);
      await prefs.setDouble('temperature', temperature.value);
      await prefs.setDouble('top_p', topP.value);
      await prefs.setDouble('presence_penalty', presencePenalty.value);
      await prefs.setDouble('frequency_penalty', frequencyPenalty.value);
      await prefs.setDouble('penalty_decay', penaltyDecay.value);

      Get.snackbar(
        'save_success_title'.tr,
        'model_params_saved'.tr,
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
        'save_failed_title'.tr,
        '${'unable_to_save_config'.tr}: $e',
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
    if (model == null) return 'not_configured'.tr;
    // 从 ID 或路径中提取模型名称
    final name = model.id.split('/').last;
    return name.replaceAll('.bin', '').replaceAll('_', ' ');
  }
}
