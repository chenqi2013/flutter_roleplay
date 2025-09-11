import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';

// 全局聊天状态管理
class ChatStateManager {
  static final ChatStateManager _instance = ChatStateManager._internal();
  factory ChatStateManager() => _instance;
  ChatStateManager._internal();

  final Map<String, List<ChatMessage>> _chatCache = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ChatMessage> getMessages(String pageKey) {
    return _chatCache[pageKey] ??= [];
  }

  // 获取过滤后的消息（只显示主对话路径）
  List<ChatMessage> getFilteredMessages(String pageKey) {
    final allMessages = getMessages(pageKey);
    return _filterMainConversationPath(allMessages);
  }

  ScrollController getScrollController(String pageKey) {
    return _scrollControllers[pageKey] ??= ScrollController();
  }

  // 添加消息到内存缓存和数据库
  Future<void> addMessage(String pageKey, ChatMessage message) async {
    // 保存到数据库
    try {
      final result = await _dbHelper.insertMessage(message);
      debugPrint(
        'User message saved to database: $result, content: ${message.content}',
      );

      // 创建带数据库ID的消息对象，并添加到缓存
      final messageWithId = message.copyWith(id: result);
      getMessages(pageKey).add(messageWithId);
    } catch (e) {
      debugPrint('Failed to save message to database: $e');
      // 如果保存失败，仍然添加到内存（但没有数据库ID）
      getMessages(pageKey).add(message);
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
      final allMessages = await _dbHelper.getMessagesByRole(roleName);
      _chatCache[roleName] = allMessages;
      debugPrint('载入消息: 总数${allMessages.length}');
    } catch (e) {
      debugPrint('Failed to load messages from database: $e');
      _chatCache[roleName] = [];
    }
  }

  // 过滤出主对话路径的消息
  List<ChatMessage> _filterMainConversationPath(List<ChatMessage> allMessages) {
    final List<ChatMessage> result = [];
    final Map<String, ChatMessage> userMessages = {}; // 用户消息映射 (ID -> Message)

    // 第一遍：收集所有用户消息并建立ID映射
    for (final message in allMessages) {
      if (message.isUser) {
        result.add(message);
        if (message.id != null) {
          userMessages[message.id.toString()] = message;
        }
      }
    }

    // 第二遍：为每个用户消息找到对应的AI回答
    for (final message in allMessages) {
      if (!message.isUser) {
        // 如果是没有parent_id的AI消息（第一次回答），直接添加
        if (message.parentId == null || message.parentId!.isEmpty) {
          result.add(message);
        } else {
          // 如果是分支消息，检查是否是当前选中的分支
          final parentId = message.parentId!;
          final userMessage = userMessages[parentId];

          if (userMessage != null && userMessage.branchIds.isNotEmpty) {
            // 获取当前选中的分支ID
            final currentBranchIndex = userMessage.currentBranchIndex;
            if (currentBranchIndex < userMessage.branchIds.length) {
              final selectedBranchId =
                  userMessage.branchIds[currentBranchIndex];

              // 如果当前消息就是选中的分支，添加到结果中
              if (message.id.toString() == selectedBranchId) {
                result.add(message);
              }
            }
          }
        }
      }
    }

    return result;
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
