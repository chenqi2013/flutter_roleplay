import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/services/chat_state_manager.dart';

/// 消息分叉管理器
/// 负责处理对话树的分支创建、切换和管理
class MessageBranchManager {
  static final MessageBranchManager _instance =
      MessageBranchManager._internal();
  factory MessageBranchManager() => _instance;
  MessageBranchManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ChatStateManager _stateManager = ChatStateManager();

  /// 创建分支（基于消息树结构）
  /// [aiMessage] 要重新生成的AI消息
  /// [userMessage] AI消息的父消息（用户消息）
  /// [newContent] 新的分支内容
  /// [roleName] 角色名称
  Future<ChatMessage> createBranch({
    required ChatMessage aiMessage,
    required ChatMessage userMessage,
    required String newContent,
    required String roleName,
  }) async {
    debugPrint('>>> MessageBranchManager.createBranch 开始（新设计）');
    debugPrint('    用户消息ID: ${userMessage.id}');
    debugPrint('    原始AI消息ID: ${aiMessage.id}');

    // 确保用户消息有数据库ID
    if (userMessage.id == null) {
      throw Exception('用户消息必须有数据库ID才能创建分支');
    }

    // 创建新的分支消息，parent_id指向用户消息的数据库ID
    final newBranchMessage = ChatMessage(
      roleName: roleName,
      content: newContent,
      isUser: false,
      timestamp: DateTime.now(),
      parentId: userMessage.id.toString(), // 使用用户消息的数据库ID
    );
    debugPrint('    创建新分支消息，parent_id: ${newBranchMessage.parentId}');

    // 保存新分支消息到数据库
    final branchId = await _dbHelper.insertMessage(newBranchMessage);
    debugPrint('    新分支消息已保存，数据库ID: $branchId');

    // 确保原始AI消息也设置正确的parent_id
    if (aiMessage.id != null &&
        aiMessage.parentId != userMessage.id.toString()) {
      final updatedAiMessage = aiMessage.copyWith(
        parentId: userMessage.id.toString(),
      );
      await _dbHelper.updateMessage(updatedAiMessage);
      debugPrint('    原始AI消息parent_id已更新: ${userMessage.id}');
    } else {
      debugPrint('    原始AI消息parent_id已正确: ${aiMessage.parentId}');
    }

    // 查询同一parent_id下的所有AI消息（分叉）
    final allMessages = await _dbHelper.getMessagesByRole(roleName);
    final branches = allMessages
        .where(
          (msg) => !msg.isUser && msg.parentId == userMessage.id.toString(),
        )
        .toList();

    debugPrint('    找到 ${branches.length} 个分叉消息');

    // 更新用户消息，记录分叉信息（使用数据库ID）
    final branchIds = branches.map((msg) => msg.id.toString()).toList();
    final updatedUserMessage = userMessage.copyWith(
      branchIds: branchIds,
      currentBranchIndex: branches.length - 1, // 指向最新的分叉
    );

    await _dbHelper.updateMessage(updatedUserMessage);
    debugPrint('    用户消息已更新，分叉数: ${branches.length}');
    debugPrint('>>> MessageBranchManager.createBranch 完成');

    return updatedUserMessage;
  }

  /// 切换分支
  /// [userMessage] 用户消息（包含分支信息）
  /// [branchIndex] 分支索引（基于0）
  /// [roleName] 角色名称
  /// 返回更新后的用户消息
  Future<ChatMessage> switchToBranch(
    ChatMessage userMessage,
    int branchIndex,
    String roleName,
  ) async {
    debugPrint('>>> MessageBranchManager.switchToBranch');
    debugPrint('    用户消息ID: ${userMessage.id}');
    debugPrint('    切换到分支索引: $branchIndex');

    // 检查分支索引范围
    if (branchIndex < 0 || branchIndex >= userMessage.branchIds.length) {
      throw ArgumentError(
        '分支索引超出范围: $branchIndex，总分支数: ${userMessage.branchIds.length}',
      );
    }

    // 更新用户消息的当前分支索引
    final updatedUserMessage = userMessage.copyWith(
      currentBranchIndex: branchIndex,
    );

    // 保存到数据库
    if (userMessage.id != null) {
      await _dbHelper.updateMessage(updatedUserMessage);
    }

    debugPrint('>>> MessageBranchManager.switchToBranch 完成');
    return updatedUserMessage;
  }

  /// 获取当前分支的内容
  /// [userMessage] 用户消息（包含分支信息）
  /// [roleName] 角色名称
  Future<String> getCurrentBranchContent(
    ChatMessage userMessage,
    String roleName,
  ) async {
    try {
      debugPrint('>>> MessageBranchManager.getCurrentBranchContent');
      debugPrint('    用户消息ID: ${userMessage.id}');
      debugPrint('    当前分支索引: ${userMessage.currentBranchIndex}');

      // 检查是否有分叉信息
      if (userMessage.branchIds.isEmpty ||
          userMessage.currentBranchIndex >= userMessage.branchIds.length) {
        debugPrint('    没有分叉或索引超出范围，返回空');
        return '';
      }

      // 通过数据库ID直接查找对应的分支消息
      final branchId = userMessage.branchIds[userMessage.currentBranchIndex];
      final allMessages = await _dbHelper.getMessagesByRole(roleName);
      final selectedBranch = allMessages
          .where((msg) => msg.id.toString() == branchId)
          .firstOrNull;

      if (selectedBranch == null) {
        debugPrint('    未找到分支ID为 $branchId 的消息');
        return '';
      }

      debugPrint('    找到分支消息ID: ${selectedBranch.id}');
      debugPrint(
        '    返回分支内容: ${selectedBranch.content.length > 20 ? selectedBranch.content.substring(0, 20) : selectedBranch.content}...',
      );

      return selectedBranch.content;
    } catch (e) {
      debugPrint('获取当前分支内容失败: $e');
      return '';
    }
  }

  /// 删除分支及其后续对话
  Future<void> deleteBranch({
    required ChatMessage message,
    required int branchIndex,
    required String roleName,
  }) async {
    if (branchIndex < 0 || branchIndex >= message.branchIds.length) {
      return;
    }

    final branchIdToDelete = message.branchIds[branchIndex];

    // 从数据库删除分支消息
    // 这里需要实现级联删除逻辑，删除该分支下的所有后续消息

    // 更新主消息的分支列表
    final updatedBranchIds = List<String>.from(message.branchIds);
    updatedBranchIds.removeAt(branchIndex);

    // 调整当前分支索引
    int newCurrentIndex = message.currentBranchIndex;
    if (newCurrentIndex >= branchIndex && newCurrentIndex > 0) {
      newCurrentIndex--;
    }

    final updatedMessage = message.copyWith(
      branchIds: updatedBranchIds,
      currentBranchIndex: newCurrentIndex,
    );

    // 保存到数据库
    if (message.id != null) {
      await _dbHelper.updateMessage(updatedMessage);
    }

    debugPrint('删除分支: $branchIdToDelete');
  }

  /// 从分支点继续对话
  /// [branchMessage] 分支消息
  /// [userInput] 用户输入
  /// [roleName] 角色名称
  Future<void> continueFromBranch({
    required ChatMessage branchMessage,
    required String userInput,
    required String roleName,
  }) async {
    // 添加用户消息
    final userMessage = ChatMessage(
      roleName: roleName,
      content: userInput,
      isUser: true,
      timestamp: DateTime.now(),
      parentId: branchMessage.messageId,
    );

    await _stateManager.addMessage(roleName, userMessage);

    debugPrint('从分支继续对话: ${branchMessage.messageId}');
  }
}
