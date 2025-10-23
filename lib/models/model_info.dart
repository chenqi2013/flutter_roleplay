import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:rwkv_mobile_flutter/rwkv.dart';

class ModelInfo {
  /// downloadurl
  final String id;

  /// 本地模型路径
  String modelPath;

  /// 本地state文件路径
  String statePath;

  /// 后端类型
  final Backend backend;

  final double? temperature;
  final double? topP;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final double? penaltyDecay;
  final RoleplayManageModelType? modelType;

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
    this.modelType,
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
      'modelType': modelType,
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
      modelType: json['modelType'],
    );
  }

  @override
  String toString() {
    return 'ModelInfo(id: $id, modelPath: $modelPath, statePath: $statePath, backend: $backend, modelType: $modelType, temperature: $temperature, topP: $topP, presencePenalty: $presencePenalty, frequencyPenalty: $frequencyPenalty, penaltyDecay: $penaltyDecay)';
  }
}
