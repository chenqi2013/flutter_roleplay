import 'package:rwkv_mobile_flutter/rwkv.dart';

class ModelInfo {
  /// downloadurl
  final String id;

  /// 本地模型路径
  final String modelPath;

  /// 本地state文件路径
  final String statePath;

  /// 后端类型
  final Backend backend;

  final double? temperature;
  final double? topP;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final double? penaltyDecay;

  ModelInfo({
    required this.id,
    required this.modelPath,
    required this.statePath,
    required this.backend,
    this.temperature,
    this.topP,
    this.presencePenalty,
    this.frequencyPenalty,
    this.penaltyDecay,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modelPath': modelPath,
      'statePath': statePath,
      'backend': backend,
      'temperature': temperature,
      'topP': topP,
      'presencePenalty': presencePenalty,
      'frequencyPenalty': frequencyPenalty,
      'penaltyDecay': penaltyDecay,
    };
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'],
      modelPath: json['modelPath'],
      statePath: json['statePath'],
      backend: json['backend'],
      temperature: json['temperature'],
      topP: json['topP'],
      presencePenalty: json['presencePenalty'],
      frequencyPenalty: json['frequencyPenalty'],
      penaltyDecay: json['penaltyDecay'],
    );
  }

  @override
  String toString() {
    return 'ModelInfo(id: $id, modelPath: $modelPath, statePath: $statePath, backend: $backend, temperature: $temperature, topP: $topP, presencePenalty: $presencePenalty, frequencyPenalty: $frequencyPenalty, penaltyDecay: $penaltyDecay)';
  }
}
