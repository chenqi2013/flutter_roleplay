import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:get/get.dart';

// 全局聊天状态管理
class ChatStateManager {
  static final ChatStateManager _instance = ChatStateManager._internal();
  factory ChatStateManager() => _instance;
  ChatStateManager._internal();

  final Map<String, RxList<ChatMessage>> _chatCache = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();

  RxList<ChatMessage> getMessages(String pageKey) {
    return _chatCache[pageKey] ??= <ChatMessage>[].obs;
  }

  ScrollController getScrollController(String pageKey) {
    return _scrollControllers[pageKey] ??= ScrollController();
  }

  // 添加消息到内存缓存和数据库
  Future<void> addMessage(String pageKey, ChatMessage message) async {
    // 为消息分配时间戳ID
    final timestamp = DateTime.now();
    final messageWithId = message.copyWith(
      id: timestamp.millisecondsSinceEpoch,
      timestamp: timestamp,
    );

    getMessages(pageKey).add(messageWithId);

    // 保存到数据库
    try {
      final result = await _dbHelper.insertMessage(messageWithId);
      debugPrint(
        'User message saved to database: $result, content: ${messageWithId.content}',
      );
    } catch (e) {
      debugPrint('Failed to save message to database: $e');
    }
  }

  // 更新最后一条消息（仅更新内存，不立即保存到数据库）
  void updateLastMessageInMemory(String pageKey, ChatMessage message) {
    final messages = getMessages(pageKey);
    if (messages.isNotEmpty) {
      messages[messages.length - 1] = message;
    }
  }

  // 更新最后一条消息并保存到数据库
  Future<void> updateLastMessage(String pageKey, ChatMessage message) async {
    final messages = getMessages(pageKey);
    if (messages.isNotEmpty) {
      messages[messages.length - 1] = message;

      // 更新数据库中的最后一条消息
      try {
        // 删除最后一条消息并插入新的
        await _dbHelper.deleteLatestMessagesByRole(message.roleName, 1);
        await _dbHelper.insertMessage(message);
      } catch (e) {
        debugPrint('Failed to update message in database: $e');
      }
    }
  }

  // 清空指定角色的聊天记录
  Future<void> clearMessages(String pageKey) async {
    _chatCache[pageKey]?.clear();

    // 从数据库中也删除该角色的所有消息
    try {
      await _dbHelper.deleteMessagesByRole(pageKey);
    } catch (e) {
      debugPrint('Failed to clear messages from database: $e');
    }
  }

  // 从数据库加载指定角色的聊天记录
  Future<void> loadMessagesFromDatabase(String roleName) async {
    try {
      final messages = await _dbHelper.getMessagesByRole(roleName);
      _chatCache[roleName] = messages.obs;
    } catch (e) {
      debugPrint('Failed to load messages from database: $e');
      _chatCache[roleName] = <ChatMessage>[].obs;
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

  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
  }
}
