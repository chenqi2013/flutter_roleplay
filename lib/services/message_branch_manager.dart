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

  /// 创建分支消息
  /// [originalMessage] 原始AI消息
  /// [newContent] 新的回答内容
  /// [roleName] 角色名称
  Future<ChatMessage> createBranch({
    required ChatMessage originalMessage,
    required String newContent,
    required String roleName,
  }) async {
    debugPrint('>>> MessageBranchManager.createBranch 开始');
    debugPrint('    原始消息messageId: ${originalMessage.messageId}');
    debugPrint('    原始消息ID: ${originalMessage.id}');
    debugPrint('    原始消息当前branchIds: ${originalMessage.branchIds}');

    // 创建分支消息
    final branchMessage = ChatMessage(
      roleName: roleName,
      content: newContent,
      isUser: false,
      timestamp: DateTime.now(),
      parentId: originalMessage.messageId,
      isBranch: true,
    );
    debugPrint('    创建分支消息: ${branchMessage.messageId}');

    // 保存分支消息到数据库
    final branchId = await _dbHelper.insertMessage(branchMessage);
    final savedBranchMessage = branchMessage.copyWith(id: branchId);
    debugPrint('    分支消息已保存，数据库ID: $branchId');

    // 更新原始消息的分支列表
    final updatedBranchIds = List<String>.from(originalMessage.branchIds);
    updatedBranchIds.add(savedBranchMessage.messageId);
    debugPrint('    更新后的branchIds: $updatedBranchIds');

    final updatedOriginalMessage = originalMessage.copyWith(
      branchIds: updatedBranchIds,
      currentBranchIndex: updatedBranchIds.length, // 切换到新分支（基于1的索引）
    );
    debugPrint('    设置currentBranchIndex为: ${updatedBranchIds.length}');
    debugPrint('    计算出的branchCount: ${updatedOriginalMessage.branchCount}');
    debugPrint('    计算出的hasBranches: ${updatedOriginalMessage.hasBranches}');

    // 更新数据库中的原始消息
    if (originalMessage.id != null) {
      await _dbHelper.updateMessage(updatedOriginalMessage);
      debugPrint('    原始消息已更新到数据库');
    } else {
      debugPrint('    WARNING: 原始消息没有ID，无法更新数据库');
    }

    debugPrint('>>> MessageBranchManager.createBranch 完成');
    return updatedOriginalMessage; // 返回更新后的原始消息，而不是分支消息
  }

  /// 切换分支
  /// [message] 主消息
  /// [branchIndex] 分支索引（基于1，0表示原始消息）
  /// [roleName] 角色名称
  /// 返回更新后的主消息
  Future<ChatMessage> switchToBranch(
    ChatMessage message,
    int branchIndex,
    String roleName,
  ) async {
    if (branchIndex < 0 || branchIndex > message.branchIds.length) {
      throw ArgumentError('分支索引超出范围: $branchIndex');
    }

    // 更新主消息的当前分支索引
    final updatedMessage = message.copyWith(currentBranchIndex: branchIndex);

    // 保存到数据库
    if (message.id != null) {
      await _dbHelper.updateMessage(updatedMessage);
    }

    debugPrint('切换到分支索引: $branchIndex');
    return updatedMessage;
  }

  /// 获取当前分支的内容
  /// [message] 主消息
  /// [roleName] 角色名称
  Future<String> getCurrentBranchContent(
    ChatMessage message,
    String roleName,
  ) async {
    try {
      // 如果没有分支或当前索引为0，返回原始内容
      if (message.branchIds.isEmpty || message.currentBranchIndex == 0) {
        return message.content;
      }

      // 获取分支内容
      final branchIndex = message.currentBranchIndex - 1; // 转换为基于0的索引
      if (branchIndex >= 0 && branchIndex < message.branchIds.length) {
        final branchId = message.branchIds[branchIndex];
        final branchMessage = await _getBranchMessage(branchId, roleName);
        return branchMessage?.content ?? message.content;
      }

      return message.content;
    } catch (e) {
      debugPrint('获取当前分支内容失败: $e');
      return message.content; // 降级到原始内容
    }
  }

  /// 获取分支消息
  Future<ChatMessage?> _getBranchMessage(
    String branchId,
    String roleName,
  ) async {
    try {
      final messages = await _dbHelper.getMessagesByRole(roleName);
      return messages.firstWhere(
        (msg) => msg.messageId == branchId,
        orElse: () => throw Exception('Branch not found'),
      );
    } catch (e) {
      debugPrint('获取分支消息失败: $e');
      return null;
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
