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

  ModelInfo({
    required this.id,
    required this.modelPath,
    required this.statePath,
    required this.backend,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modelPath': modelPath,
      'statePath': statePath,
      'backend': backend,
    };
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'],
      modelPath: json['modelPath'],
      statePath: json['statePath'],
      backend: json['backend'],
    );
  }
}
