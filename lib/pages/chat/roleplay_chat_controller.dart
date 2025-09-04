import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/language_service.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:flutter_roleplay/services/chat_stream_service.dart';

class RolePlayChatController extends GetxController {
  /// Context for showing dialogs - can be set externally
  BuildContext? _context;

  /// Set context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Get current context
  BuildContext? get currentContext => _context ?? Get.context;

  // 服务实例
  final RWKVChatService _modelService = Get.put(RWKVChatService());
  final ChatStreamService _streamService = ChatStreamService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 流订阅
  StreamSubscription<String>? _streamSub;

  ModelInfo? modelInfo;

  // 获取生成状态
  RxBool get isGenerating => _modelService.isGenerating;

  LanguageService? languageService;

  @override
  void onInit() async {
    super.onInit();
    debugPrint('RolePlayChatController onInit');
    // 设置模型服务回调
    _modelService.setOnGenerationComplete(() {
      _saveCurrentAiMessage();
    });
  }

  void changeLanguage() async {
    debugPrint('changeLanguage');
    if (Get.isRegistered<LanguageService>()) {
      languageService = Get.find<LanguageService>();
    } else {
      languageService = Get.put(LanguageService());
    }
    languageService?.loadSavedLanguage();
  }

  // 加载模型 - 委托给模型服务
  Future<void> loadChatModel() async {
    await _modelService.loadChatModel();
  }

  // 清空状态 - 委托给模型服务
  Future<void> clearStates() async {
    await _modelService.clearStates();
  }

  // 彻底清空聊天记录（包括数据库）- 用于用户主动清空
  Future<void> clearAllChatHistory() async {
    // 清空数据库中的聊天记录
    if (roleName.value.isNotEmpty) {
      await clearChatHistoryFromDatabase(roleName.value);
    }

    // 清空内存中的聊天记录
    final stateManager = ChatStateManager();
    stateManager.getMessages(roleName.value).clear();

    // 清空模型状态
    await _modelService.clearStates();
  }

  // 停止生成 - 委托给模型服务
  Future<void> stop() async => await _modelService.stop();

  // 流式聊天完成 - 委托给模型服务
  Stream<String> streamLocalChatCompletions({String content = '介绍下自己'}) {
    return _modelService.streamLocalChatCompletions(content: content);
  }

  // 清空聊天记录 - 简化版
  void clearChatHistory() {
    // 清空内存中的聊天记录
    final stateManager = ChatStateManager();
    stateManager.getMessages(roleName.value).clear();
  }

  // HTTP 流式聊天完成 - 委托给流服务
  Future<Map<String, dynamic>?> requestChatCompletions({
    String content = 'hello',
  }) {
    return _streamService.requestChatCompletions(
      content: content,
      roleName: roleName.value,
      roleDescription: roleDescription.value,
    );
  }

  Stream<String> streamChatCompletions({String content = 'hello'}) {
    return _streamService.streamChatCompletions(
      content: content,
      roleName: roleName.value,
      roleDescription: roleDescription.value,
    );
  }

  // 保存用户消息到数据库
  Future<void> saveUserMessage(String content) async {
    try {
      final message = ChatMessage(
        roleName: roleName.value,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      await _dbHelper.insertMessage(message);
    } catch (e) {
      debugPrint('Failed to save user message: $e');
    }
  }

  // 保存AI回复到数据库
  Future<void> saveAiMessage(String content) async {
    try {
      final message = ChatMessage(
        roleName: roleName.value,
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      );
      int result = await _dbHelper.insertMessage(message);
      debugPrint('saveAiMessage result: $result');
    } catch (e) {
      debugPrint('Failed to save AI message: $e');
    }
  }

  // 从数据库加载指定角色的聊天记录
  Future<List<ChatMessage>> loadChatHistory(String roleName) async {
    try {
      return await _dbHelper.getMessagesByRole(roleName);
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
      return [];
    }
  }

  // 清空指定角色的聊天记录
  Future<void> clearChatHistoryFromDatabase(String roleName) async {
    try {
      await _dbHelper.deleteMessagesByRole(roleName);
    } catch (e) {
      debugPrint('Failed to clear chat history: $e');
    }
  }

  // 获取指定角色的消息数量
  Future<int> getMessageCount(String roleName) async {
    try {
      return await _dbHelper.getMessageCountByRole(roleName);
    } catch (e) {
      debugPrint('Failed to get message count: $e');
      return 0;
    }
  }

  // 保存当前AI回复到数据库
  Future<void> _saveCurrentAiMessage() async {
    try {
      // 获取当前角色的最后一条消息
      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);
      if (messages.isNotEmpty && !messages.last.isUser) {
        final aiMessage = messages.last;
        // 只有当消息内容不为空时才保存
        if (aiMessage.content.isNotEmpty) {
          await saveAiMessage(aiMessage.content);
          debugPrint('AI message saved to database: ${aiMessage.content}');
        }
      }
    } catch (e) {
      debugPrint('Failed to save current AI message: $e');
    }
  }

  @override
  void onClose() {
    _streamSub?.cancel();
    super.onClose();
  }
}
