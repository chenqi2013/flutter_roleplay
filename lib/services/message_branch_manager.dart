import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:uuid/uuid.dart';

/// 消息分支管理器
/// 负责管理消息树结构，包括分支创建、切换、删除等功能
class MessageBranchManager {
  static final MessageBranchManager _instance =
      MessageBranchManager._internal();
  factory MessageBranchManager() => _instance;
  MessageBranchManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  /// 获取某个角色的完整消息树
  /// [roleName] 角色名称
  /// [conversationId] 会话ID，如果为null则获取最新会话
  Future<List<ChatMessage>> getMessageTree(
    String roleName, {
    String? conversationId,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'role_name = ?';
    List<dynamic> whereArgs = [roleName];

    if (conversationId != null) {
      whereClause += ' AND conversation_id = ?';
      whereArgs.add(conversationId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage.fromMap(maps[i]);
    });
  }

  /// 获取当前显示的消息路径（从根到叶子的一条路径）
  /// [roleName] 角色名称
  /// [conversationId] 会话ID
  /// [selectedBranches] 每个层级选中的分支索引
  Future<List<ChatMessage>> getCurrentPath(
    String roleName,
    String conversationId,
    Map<int, int> selectedBranches,
  ) async {
    final allMessages = await getMessageTree(
      roleName,
      conversationId: conversationId,
    );
    final List<ChatMessage> path = [];

    debugPrint('=== getCurrentPath Debug ===');
    debugPrint('Total messages in tree: ${allMessages.length}');
    for (int i = 0; i < allMessages.length; i++) {
      final msg = allMessages[i];
      debugPrint(
        'Message $i: ${msg.isUser ? "User" : "AI"}, parentId: ${msg.parentId}, branchIndex: ${msg.branchIndex}, content: ${msg.content.substring(0, math.min(20, msg.content.length))}...',
      );
    }

    // 构建消息层级映射
    final Map<int?, List<ChatMessage>> messagesByParent = {};
    for (final message in allMessages) {
      messagesByParent.putIfAbsent(message.parentId, () => []).add(message);
    }

    debugPrint('Messages by parent:');
    messagesByParent.forEach((parentId, children) {
      debugPrint('  Parent $parentId: ${children.length} children');
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        debugPrint(
          '    [$i] ${child.isUser ? "User" : "AI"}: ${child.content.substring(0, math.min(15, child.content.length))}...',
        );
      }
    });

    // 从根开始构建路径
    int? currentParentId;
    int level = 0;

    debugPrint('Building path with selectedBranches: $selectedBranches');

    while (true) {
      final children = messagesByParent[currentParentId];
      if (children == null || children.isEmpty) {
        debugPrint(
          'No children found for parentId $currentParentId at level $level',
        );
        break;
      }

      // 根据选中的分支索引选择消息
      final selectedIndex = selectedBranches[level] ?? 0;
      debugPrint(
        'Level $level: ${children.length} children, selecting index $selectedIndex',
      );

      if (selectedIndex >= children.length) {
        debugPrint(
          'Selected index $selectedIndex >= children count ${children.length}, breaking',
        );
        break;
      }

      final selectedMessage = children[selectedIndex];
      path.add(selectedMessage);
      debugPrint(
        'Added to path: ${selectedMessage.isUser ? "User" : "AI"} - ${selectedMessage.content.substring(0, math.min(15, selectedMessage.content.length))}...',
      );

      currentParentId = selectedMessage.id;
      level++;
    }

    debugPrint('Final path length: ${path.length}');
    debugPrint('=== getCurrentPath Debug End ===');
    return path;
  }

  /// 为AI回复创建新分支
  /// [parentMessage] 父消息（用户的提问）
  /// [newContent] 新的AI回复内容
  /// [roleName] 角色名称
  Future<ChatMessage> createBranch(
    ChatMessage parentMessage,
    String newContent,
    String roleName,
  ) async {
    final db = await _dbHelper.database;

    // 获取同一父消息下的所有分支
    final existingBranches = await db.query(
      'chat_messages',
      where: 'parent_id = ? AND role_name = ?',
      whereArgs: [parentMessage.id, roleName],
      orderBy: 'branch_index ASC',
    );

    // 计算新分支的索引
    final newBranchIndex = existingBranches.length;
    final totalBranches = newBranchIndex + 1;

    // 更新所有现有分支的总分支数
    for (final branch in existingBranches) {
      await db.update(
        'chat_messages',
        {'total_branches': totalBranches},
        where: 'id = ?',
        whereArgs: [branch['id']],
      );
    }

    // 创建新分支消息
    final newMessage = ChatMessage(
      roleName: roleName,
      content: newContent,
      isUser: false,
      timestamp: DateTime.now(),
      parentId: parentMessage.id,
      branchIndex: newBranchIndex,
      totalBranches: totalBranches,
      conversationId: parentMessage.conversationId,
    );

    // 插入到数据库
    final id = await db.insert('chat_messages', newMessage.toMap());

    return newMessage.copyWith(id: id);
  }

  /// 删除分支
  /// [messageId] 要删除的消息ID
  Future<void> deleteBranch(int messageId) async {
    final db = await _dbHelper.database;

    // 获取要删除的消息信息
    final messageToDelete = await db.query(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );

    if (messageToDelete.isEmpty) return;

    final message = ChatMessage.fromMap(messageToDelete.first);

    // 删除该分支及其所有子消息
    await _deleteMessageAndChildren(messageId);

    // 重新整理同级分支的索引
    await _reorderBranches(message.parentId, message.roleName);
  }

  /// 递归删除消息及其所有子消息
  Future<void> _deleteMessageAndChildren(int messageId) async {
    final db = await _dbHelper.database;

    // 获取所有子消息
    final children = await db.query(
      'chat_messages',
      where: 'parent_id = ?',
      whereArgs: [messageId],
    );

    // 递归删除子消息
    for (final child in children) {
      await _deleteMessageAndChildren(child['id'] as int);
    }

    // 删除当前消息
    await db.delete('chat_messages', where: 'id = ?', whereArgs: [messageId]);
  }

  /// 重新整理分支索引
  Future<void> _reorderBranches(int? parentId, String roleName) async {
    final db = await _dbHelper.database;

    // 获取同一父消息下的所有分支
    final branches = await db.query(
      'chat_messages',
      where: 'parent_id = ? AND role_name = ?',
      whereArgs: [parentId, roleName],
      orderBy: 'branch_index ASC',
    );

    // 重新分配索引
    for (int i = 0; i < branches.length; i++) {
      await db.update(
        'chat_messages',
        {'branch_index': i, 'total_branches': branches.length},
        where: 'id = ?',
        whereArgs: [branches[i]['id']],
      );
    }
  }

  /// 生成新的会话ID
  String generateConversationId() {
    return _uuid.v4();
  }

  /// 获取指定消息的所有分支
  Future<List<ChatMessage>> getBranches(int? parentId, String roleName) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'parent_id = ? AND role_name = ?',
      whereArgs: [parentId, roleName],
      orderBy: 'branch_index ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage.fromMap(maps[i]);
    });
  }

  /// 获取消息的统计信息
  Future<MessageStats> getMessageStats(
    String roleName, {
    String? conversationId,
  }) async {
    final messages = await getMessageTree(
      roleName,
      conversationId: conversationId,
    );

    int totalMessages = messages.length;
    int branchPoints = 0;
    int totalBranches = 0;

    // 按父消息分组统计分支
    final Map<int?, List<ChatMessage>> groupedByParent = {};
    for (final message in messages) {
      groupedByParent.putIfAbsent(message.parentId, () => []).add(message);
    }

    for (final group in groupedByParent.values) {
      if (group.length > 1) {
        branchPoints++;
        totalBranches += group.length;
      }
    }

    return MessageStats(
      totalMessages: totalMessages,
      branchPoints: branchPoints,
      totalBranches: totalBranches,
    );
  }
}

/// 消息统计信息
class MessageStats {
  final int totalMessages; // 总消息数
  final int branchPoints; // 分支点数量
  final int totalBranches; // 总分支数

  MessageStats({
    required this.totalMessages,
    required this.branchPoints,
    required this.totalBranches,
  });
}
