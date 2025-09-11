import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:flutter_roleplay/services/language_service.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:flutter_roleplay/services/chat_stream_service.dart';
import 'package:flutter_roleplay/services/message_branch_manager.dart';

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
  final RWKVChatService modelService = Get.put(RWKVChatService());
  final ChatStreamService _streamService = ChatStreamService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MessageBranchManager _branchManager = MessageBranchManager();

  // 流订阅
  StreamSubscription<String>? _streamSub;

  // 当前会话的分支选择状态 (level -> selectedBranchIndex)
  final RxMap<int, int> selectedBranches = <int, int>{}.obs;
  final RxString currentConversationId = ''.obs;

  // 重新生成模式标志
  bool _isRegeneratingMode = false;

  ModelInfo? modelInfo;

  // 获取生成状态
  RxBool get isGenerating => modelService.isGenerating;

  LanguageService? languageService;

  @override
  void onInit() async {
    super.onInit();
    debugPrint('RolePlayChatController onInit');
    // 设置模型服务回调
    modelService.setOnGenerationComplete(() {
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
    await modelService.loadChatModel();
  }

  // 清空状态 - 委托给模型服务
  Future<void> clearStates() async {
    await modelService.clearStates();
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
    await modelService.clearStates();
  }

  // 停止生成 - 委托给模型服务
  Future<void> stop() async => await modelService.stop();

  // 流式聊天完成 - 委托给模型服务
  Stream<String> streamLocalChatCompletions({String content = '介绍下自己'}) {
    return modelService.streamLocalChatCompletions(content: content);
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
  Future<ChatMessage?> saveUserMessage(String content) async {
    try {
      // 确保有会话ID
      if (currentConversationId.value.isEmpty) {
        initializeNewConversation();
      }

      // 找到父消息ID（最后一条AI消息）
      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);
      int? parentId;

      debugPrint(
        'saveUserMessage: Looking for parent AI message in ${messages.length} messages',
      );
      for (int i = messages.length - 1; i >= 0; i--) {
        debugPrint(
          'Message $i: ${messages[i].isUser ? "User" : "AI"}, id=${messages[i].id}',
        );
        if (!messages[i].isUser && messages[i].id != null) {
          parentId = messages[i].id;
          debugPrint('Found AI parent message with ID: $parentId');
          break;
        }
      }

      if (parentId == null) {
        debugPrint(
          'No AI parent message found, this might be the first user message',
        );
      }

      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: timestamp.millisecondsSinceEpoch, // 使用时间戳作为临时ID
        roleName: roleName.value,
        content: content,
        isUser: true,
        timestamp: timestamp,
        parentId: parentId, // 设置父消息ID
        conversationId: currentConversationId.value,
      );

      // 内存更新由调用方处理

      final id = await _dbHelper.insertMessage(message);
      return message.copyWith(id: id);
    } catch (e) {
      debugPrint('Failed to save user message: $e');
      return null;
    }
  }

  // 保存AI回复到数据库
  Future<void> saveAiMessage(String content) async {
    try {
      // 确保有会话ID
      if (currentConversationId.value.isEmpty) {
        initializeNewConversation();
      }

      // 找到父消息ID（最后一条用户消息）
      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);
      int? parentId;

      debugPrint(
        'saveAiMessage: Looking for parent user message in ${messages.length} messages',
      );
      for (int i = 0; i < messages.length; i++) {
        debugPrint(
          'Message $i: isUser=${messages[i].isUser}, id=${messages[i].id}, content=${messages[i].content.substring(0, math.min(20, messages[i].content.length))}...',
        );
      }

      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isUser) {
          parentId = messages[i].id;
          debugPrint('Found user message with ID: $parentId');
          break;
        }
      }
      debugPrint('Final parentId for AI message: $parentId');

      if (parentId == null) {
        debugPrint(
          'WARNING: No user message found, AI message will not have parent_id',
        );
      }

      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: timestamp.millisecondsSinceEpoch, // 使用时间戳作为临时ID
        roleName: roleName.value,
        content: content,
        isUser: false,
        timestamp: timestamp,
        parentId: parentId,
        conversationId: currentConversationId.value,
      );

      // 更新内存中的消息ID
      for (int i = messages.length - 1; i >= 0; i--) {
        if (!messages[i].isUser &&
            messages[i].content == content &&
            messages[i].id == null) {
          messages[i] = message;
          debugPrint(
            'Updated AI message in memory with timestamp ID: ${message.id}',
          );
          break;
        }
      }

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
          // 如果在重新生成模式，使用分支逻辑保存
          if (_isRegeneratingMode) {
            debugPrint('In regenerating mode, using branch logic to save');
            await _saveRegeneratedMessage(aiMessage);
          } else {
            // 正常模式，使用普通保存
            await saveAiMessage(aiMessage.content);
            debugPrint('AI message saved to database: ${aiMessage.content}');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to save current AI message: $e');
    }
  }

  // 保存重新生成的消息（分支逻辑）
  Future<void> _saveRegeneratedMessage(ChatMessage aiMessage) async {
    try {
      debugPrint('=== Saving regenerated AI message ===');
      debugPrint('AI message content length: ${aiMessage.content.length}');
      debugPrint(
        'AI message preview: ${aiMessage.content.substring(0, math.min(50, aiMessage.content.length))}...',
      );

      // 查找用户消息
      final userMessage = _findUserMessageForRegeneration();
      if (userMessage != null && userMessage.id != null) {
        debugPrint('Creating AI branch with parentId: ${userMessage.id}');
        debugPrint('User message content: ${userMessage.content}');

        final newBranch = await createAIBranch(userMessage, aiMessage.content);
        if (newBranch != null) {
          debugPrint(
            'insertMessage (regenerated branch): ${newBranch.toMap()}',
          );

          // 更新内存中的消息
          final stateManager = ChatStateManager();
          final messages = stateManager.getMessages(roleName.value);
          final index = messages.indexOf(aiMessage);
          if (index != -1) {
            messages[index] = newBranch;
            debugPrint('Updated message at index $index in memory');
          } else {
            debugPrint(
              'WARNING: Could not find AI message in memory to update',
            );
          }

          debugPrint('AI branch created successfully with ID: ${newBranch.id}');
          debugPrint(
            'Branch info: ${newBranch.branchIndex + 1}/${newBranch.totalBranches}',
          );
          debugPrint('=== Regenerated message saved successfully ===');
        } else {
          debugPrint('Failed to create AI branch, using fallback save');
          await saveAiMessage(aiMessage.content);
        }
      } else {
        debugPrint('No user message ID found, using fallback save');
        debugPrint('User message: ${userMessage?.content ?? 'null'}');
        debugPrint('User message ID: ${userMessage?.id ?? 'null'}');
        await saveAiMessage(aiMessage.content);
      }

      // 重置重新生成模式标志
      _isRegeneratingMode = false;
    } catch (e) {
      debugPrint('Failed to save regenerated message: $e');
      _isRegeneratingMode = false;
    }
  }

  // 查找用于重新生成的用户消息
  ChatMessage? _findUserMessageForRegeneration() {
    final stateManager = ChatStateManager();
    final messages = stateManager.getMessages(roleName.value);

    // 找到最后一条用户消息
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        return messages[i];
      }
    }
    return null;
  }

  // ===== 消息分支管理功能 =====

  /// 初始化新会话
  void initializeNewConversation() {
    currentConversationId.value = _branchManager.generateConversationId();
    selectedBranches.clear();
    debugPrint('New conversation initialized: ${currentConversationId.value}');
  }

  /// 保存带有分支信息的用户消息
  Future<ChatMessage?> saveUserMessageWithBranch(String content) async {
    try {
      // 确保有会话ID
      if (currentConversationId.value.isEmpty) {
        initializeNewConversation();
      }

      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);

      // 找到父消息ID（最后一条AI回复）
      int? parentId;
      debugPrint(
        'saveUserMessageWithBranch: Looking for parent AI message in ${messages.length} messages',
      );
      for (int i = messages.length - 1; i >= 0; i--) {
        debugPrint(
          'Message $i: ${messages[i].isUser ? "User" : "AI"}, id=${messages[i].id}',
        );
        if (!messages[i].isUser && messages[i].id != null) {
          parentId = messages[i].id;
          debugPrint('Found AI parent message with ID: $parentId');
          break;
        }
      }

      if (parentId == null) {
        debugPrint('No AI parent message found for user message with branch');
      }

      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: timestamp.millisecondsSinceEpoch, // 使用时间戳作为临时ID
        roleName: roleName.value,
        content: content,
        isUser: true,
        timestamp: timestamp,
        parentId: parentId,
        conversationId: currentConversationId.value,
      );

      final id = await _dbHelper.insertMessage(message);
      return message.copyWith(id: id);
    } catch (e) {
      debugPrint('Failed to save user message with branch: $e');
      return null;
    }
  }

  /// 为AI回复创建新分支
  Future<ChatMessage?> createAIBranch(
    ChatMessage parentMessage,
    String content,
  ) async {
    try {
      debugPrint('--- Creating AI branch ---');
      debugPrint('Parent message ID: ${parentMessage.id}');
      debugPrint('Parent message content: ${parentMessage.content}');
      debugPrint('New AI content length: ${content.length}');
      debugPrint('Role name: ${roleName.value}');

      final newBranch = await _branchManager.createBranch(
        parentMessage,
        content,
        roleName.value,
      );

      debugPrint('AI branch created with database ID: ${newBranch.id}');
      debugPrint('Branch parent_id: ${newBranch.parentId}');
      debugPrint('Branch conversation_id: ${newBranch.conversationId}');
      debugPrint(
        'Created new AI branch: ${newBranch.branchIndex + 1}/${newBranch.totalBranches}',
      );
      debugPrint('--- AI branch creation completed ---');
      return newBranch;
    } catch (e) {
      debugPrint('Failed to create AI branch: $e');
      return null;
    }
  }

  /// 切换分支
  Future<void> switchBranch(int messageLevel, int branchIndex) async {
    try {
      debugPrint('=== Switching branch ===');
      debugPrint('Message level: $messageLevel, Branch index: $branchIndex');
      debugPrint('Current selectedBranches: $selectedBranches');

      selectedBranches[messageLevel] = branchIndex;
      debugPrint('Updated selectedBranches: $selectedBranches');

      // 重新加载当前路径的消息
      await refreshCurrentPath();

      debugPrint('Switched to branch $branchIndex at level $messageLevel');
      debugPrint('=== Branch switch completed ===');
    } catch (e) {
      debugPrint('Failed to switch branch: $e');
    }
  }

  /// 重新生成AI回复（创建新分支）
  Future<void> regenerateResponse(ChatMessage userMessage) async {
    try {
      debugPrint(
        'regenerateResponse called with user message: ${userMessage.content}',
      );
      debugPrint('User message ID: ${userMessage.id}');

      // 设置重新生成模式标志
      _isRegeneratingMode = true;

      // 确保用户消息有ID（如果没有，从数据库查找）
      ChatMessage finalUserMessage = userMessage;
      if (userMessage.id == null) {
        debugPrint('User message has no ID - looking up in database...');
        // 尝试从数据库中查找这条用户消息
        try {
          final dbHelper = DatabaseHelper();
          final allMessages = await dbHelper.getMessagesByRole(roleName.value);

          // 找到内容匹配的最后一条用户消息
          ChatMessage? foundUserMessage;
          for (int i = allMessages.length - 1; i >= 0; i--) {
            if (allMessages[i].isUser &&
                allMessages[i].content == userMessage.content) {
              foundUserMessage = allMessages[i];
              break;
            }
          }

          if (foundUserMessage != null && foundUserMessage.id != null) {
            finalUserMessage = foundUserMessage;
            debugPrint(
              'Found existing user message with ID: ${finalUserMessage.id}',
            );

            // 更新内存中的消息
            final stateManager = ChatStateManager();
            final messages = stateManager.getMessages(roleName.value);
            final userIndex = messages.indexOf(userMessage);
            if (userIndex != -1) {
              messages[userIndex] = finalUserMessage;
            }
          } else {
            debugPrint('User message not found in database, cannot regenerate');
            _isRegeneratingMode = false;
            return;
          }
        } catch (e) {
          debugPrint('Error finding user message in database: $e');
          _isRegeneratingMode = false;
          return;
        }
      }

      // 确保有会话ID
      if (currentConversationId.value.isEmpty) {
        initializeNewConversation();
        debugPrint(
          'Initialized new conversation: ${currentConversationId.value}',
        );
      }

      // 获取当前消息列表
      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);

      // 找到并移除最后一条AI消息（要被替换的消息）
      // 这样在构建AI历史时就不会包含要被替换的回复
      ChatMessage? removedAiMessage;
      int aiMessageIndex = -1;
      for (int i = messages.length - 1; i >= 0; i--) {
        if (!messages[i].isUser) {
          removedAiMessage = messages[i];
          aiMessageIndex = i;
          break;
        }
      }

      // 如果找到了AI消息，先移除它
      if (aiMessageIndex != -1 && removedAiMessage != null) {
        messages.removeAt(aiMessageIndex);
        debugPrint('Removed previous AI message at index $aiMessageIndex');
        debugPrint(
          'Removed AI message content: ${removedAiMessage.content.substring(0, math.min(50, removedAiMessage.content.length))}...',
        );
      }

      // 现在开始生成新的AI回复（此时历史中不包含被移除的AI消息）
      final stream = streamLocalChatCompletions(
        content: finalUserMessage.content,
      );
      debugPrint('Started AI generation stream');

      // 创建临时的AI消息用于显示流式输出
      final tempAiMessage = ChatMessage(
        roleName: roleName.value,
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        parentId: finalUserMessage.id,
        conversationId: currentConversationId.value,
      );

      messages.add(tempAiMessage);
      debugPrint(
        'Added new temporary AI message, total messages: ${messages.length}',
      );
      debugPrint('Temp AI message parentId: ${tempAiMessage.parentId}');

      // 监听流并更新消息内容 (与首次生成逻辑相同)
      _streamSub = stream.listen(
        (chunk) {
          // 更新最后一条消息的内容
          // chunk本身就包含了完整的累积内容，不需要再追加
          if (messages.isNotEmpty && !messages.last.isUser) {
            final index = messages.length - 1;
            messages[index] = messages[index].copyWith(content: chunk);
            // UI会自动响应消息列表的变化
          }
        },
        onError: (error) {
          debugPrint('Error generating response: $error');
          // 移除临时消息
          if (messages.isNotEmpty &&
              !messages.last.isUser &&
              messages.last.content.isEmpty) {
            messages.removeLast();
          }

          // 重置重新生成模式标志
          _isRegeneratingMode = false;
        },
      );

      // 生成完成时会自动调用_saveCurrentAiMessage()，无需额外处理
    } catch (e) {
      debugPrint('Failed to regenerate response: $e');
      // 重置重新生成模式标志
      _isRegeneratingMode = false;
    }
  }

  /// 刷新当前路径的消息
  Future<void> refreshCurrentPath() async {
    try {
      debugPrint('--- Refreshing current path ---');
      debugPrint('Current conversation ID: ${currentConversationId.value}');
      debugPrint('Selected branches: $selectedBranches');

      if (currentConversationId.value.isEmpty) {
        debugPrint('WARNING: No conversation ID, cannot refresh path');
        return;
      }

      final currentPath = await _branchManager.getCurrentPath(
        roleName.value,
        currentConversationId.value,
        selectedBranches,
      );

      debugPrint('Retrieved path with ${currentPath.length} messages');
      for (int i = 0; i < currentPath.length; i++) {
        final msg = currentPath[i];
        debugPrint(
          'Path[$i]: ${msg.isUser ? "User" : "AI"} - ${msg.content.substring(0, math.min(30, msg.content.length))}...',
        );
      }

      // 更新内存中的消息列表
      final stateManager = ChatStateManager();
      final messages = stateManager.getMessages(roleName.value);
      messages.clear();
      messages.addAll(currentPath);

      debugPrint('Refreshed current path with ${currentPath.length} messages');
      debugPrint('--- Path refresh completed ---');
    } catch (e) {
      debugPrint('Failed to refresh current path: $e');
    }
  }

  /// 获取消息的统计信息
  Future<MessageStats?> getMessageStats() async {
    try {
      if (currentConversationId.value.isEmpty) return null;

      return await _branchManager.getMessageStats(
        roleName.value,
        conversationId: currentConversationId.value,
      );
    } catch (e) {
      debugPrint('Failed to get message stats: $e');
      return null;
    }
  }

  /// 加载聊天历史（支持分支）
  Future<List<ChatMessage>> loadChatHistoryWithBranches(String roleName) async {
    try {
      final messages = await _branchManager.getMessageTree(roleName);

      if (messages.isNotEmpty) {
        // 设置当前会话ID为最新的会话
        final latestConversationId = messages.last.conversationId;
        if (latestConversationId != null) {
          currentConversationId.value = latestConversationId;
        }

        // 加载默认路径（所有分支索引为0）
        selectedBranches.clear();
        await refreshCurrentPath();
      }

      return messages;
    } catch (e) {
      debugPrint('Failed to load chat history with branches: $e');
      return [];
    }
  }

  @override
  void onClose() {
    _streamSub?.cancel();
    super.onClose();
  }
}
