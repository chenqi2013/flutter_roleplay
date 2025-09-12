import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleParamsController extends GetxController {
  // 参数默认值
  static const double _defaultTemperature = 0.6;
  static const int _defaultTopK = 500;
  static const double _defaultTopP = 0.8;
  static const double _defaultPresencePenalty = 2.0;
  static const double _defaultFrequencyPenalty = 0.2;
  static const double _defaultPenaltyDecay = 0.990;

  // 响应式参数
  final RxDouble temperature = _defaultTemperature.obs;
  final RxInt topK = _defaultTopK.obs;
  final RxDouble topP = _defaultTopP.obs;
  final RxDouble presencePenalty = _defaultPresencePenalty.obs;
  final RxDouble frequencyPenalty = _defaultFrequencyPenalty.obs;
  final RxDouble penaltyDecay = _defaultPenaltyDecay.obs;

  // SharedPreferences 键名
  static const String _temperatureKey = 'role_temperature';
  static const String _topKKey = 'role_top_k';
  static const String _topPKey = 'role_top_p';
  static const String _presencePenaltyKey = 'role_presence_penalty';
  static const String _frequencyPenaltyKey = 'role_frequency_penalty';
  static const String _penaltyDecayKey = 'role_penalty_decay';

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _loadParams();
  }

  /// 加载保存的参数
  Future<void> _loadParams() async {
    _prefs = await SharedPreferences.getInstance();

    temperature.value =
        _prefs?.getDouble(_temperatureKey) ?? _defaultTemperature;
    topK.value = _prefs?.getInt(_topKKey) ?? _defaultTopK;
    topP.value = _prefs?.getDouble(_topPKey) ?? _defaultTopP;
    presencePenalty.value =
        _prefs?.getDouble(_presencePenaltyKey) ?? _defaultPresencePenalty;
    frequencyPenalty.value =
        _prefs?.getDouble(_frequencyPenaltyKey) ?? _defaultFrequencyPenalty;
    penaltyDecay.value =
        _prefs?.getDouble(_penaltyDecayKey) ?? _defaultPenaltyDecay;
  }

  /// 保存参数到本地存储
  Future<void> saveParams() async {
    if (_prefs == null) return;

    await _prefs!.setDouble(_temperatureKey, temperature.value);
    await _prefs!.setInt(_topKKey, topK.value);
    await _prefs!.setDouble(_topPKey, topP.value);
    await _prefs!.setDouble(_presencePenaltyKey, presencePenalty.value);
    await _prefs!.setDouble(_frequencyPenaltyKey, frequencyPenalty.value);
    await _prefs!.setDouble(_penaltyDecayKey, penaltyDecay.value);
    debugPrint('saveParams success');
  }

  /// 更新温度参数
  void updateTemperature(double value) {
    temperature.value = value;
    saveParams();
  }

  /// 更新 TopK 参数
  void updateTopK(int value) {
    topK.value = value;
    saveParams();
  }

  /// 更新 TopP 参数
  void updateTopP(double value) {
    topP.value = value;
    saveParams();
  }

  /// 更新 Presence Penalty 参数
  void updatePresencePenalty(double value) {
    presencePenalty.value = value;
    saveParams();
  }

  /// 更新 Frequency Penalty 参数
  void updateFrequencyPenalty(double value) {
    frequencyPenalty.value = value;
    saveParams();
  }

  /// 更新 Penalty Decay 参数
  void updatePenaltyDecay(double value) {
    penaltyDecay.value = value;
    saveParams();
  }

  /// 重置所有参数为默认值
  void resetToDefaults() {
    temperature.value = _defaultTemperature;
    topK.value = _defaultTopK;
    topP.value = _defaultTopP;
    presencePenalty.value = _defaultPresencePenalty;
    frequencyPenalty.value = _defaultFrequencyPenalty;
    penaltyDecay.value = _defaultPenaltyDecay;
    saveParams();
  }

  /// 获取当前参数值（用于聊天服务）
  Map<String, dynamic> getCurrentParams() {
    return {
      'temperature': temperature.value,
      'topK': topK.value,
      'topP': topP.value,
      'presencePenalty': presencePenalty.value,
      'frequencyPenalty': frequencyPenalty.value,
      'penaltyDecay': penaltyDecay.value,
    };
  }
}
