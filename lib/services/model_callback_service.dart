import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/model_info.dart';

/// 模型下载回调函数类型
typedef ModelDownloadCallback = void Function();

/// 全局模型下载回调
ModelDownloadCallback? _globalModelDownloadCallback;

/// 全局模型下载完成回调
Function(ModelInfo?)? _globalModelDownloadCompleteCallback;

/// 设置全局模型下载回调
void setGlobalModelDownloadCallback(ModelDownloadCallback? callback) {
  _globalModelDownloadCallback = callback;
}

/// 设置全局模型下载完成回调
void setGlobalModelDownloadCompleteCallback(Function(ModelInfo?)? callback) {
  _globalModelDownloadCompleteCallback = callback;
}

/// 通知需要下载模型
void notifyModelDownloadRequired() {
  if (_globalModelDownloadCallback != null) {
    debugPrint('通知外部应用需要下载模型');
    _globalModelDownloadCallback!();
  } else {
    debugPrint('未设置模型下载回调，无法通知外部应用');
  }
}

/// 通知外部应用模型下载完成，插件应该重新加载模型
void notifyModelDownloadComplete(ModelInfo info) {
  if (_globalModelDownloadCompleteCallback != null) {
    debugPrint('收到模型下载完成通知，重新加载模型');
    _globalModelDownloadCompleteCallback!(info);
  } else {
    debugPrint('未设置模型下载完成回调');
  }
}
