import 'dart:convert';

class ChatMessage {
  final int? id;
  final String roleName;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  // 消息分叉支持
  final String? parentId; // 父消息ID（用于构建对话树）
  final List<String> branchIds; // 分支消息ID列表
  final int currentBranchIndex; // 当前选中的分支索引
  final bool isBranch; // 是否为分支消息

  ChatMessage({
    this.id,
    required this.roleName,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.parentId,
    this.branchIds = const [],
    this.currentBranchIndex = 0,
    this.isBranch = false,
  });

  // 从数据库行创建对象
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // 解析分支ID列表
    List<String> branchIds = [];
    if (map['branch_ids'] != null && map['branch_ids'] is String) {
      try {
        final decoded = jsonDecode(map['branch_ids'] as String);
        if (decoded is List) {
          branchIds = List<String>.from(decoded);
        }
      } catch (e) {
        // 如果解析失败，使用空列表
        branchIds = [];
      }
    }

    return ChatMessage(
      id: map['id'] as int?,
      roleName: map['role_name'] as String,
      content: map['content'] as String,
      isUser: (map['is_user'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      parentId: map['parent_id'] as String?,
      branchIds: branchIds,
      currentBranchIndex: map['current_branch_index'] as int? ?? 0,
      isBranch: (map['is_branch'] as int? ?? 0) == 1,
    );
  }

  // 转换为数据库行
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_name': roleName,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'parent_id': parentId,
      'branch_ids': branchIds.isNotEmpty ? jsonEncode(branchIds) : null,
      'current_branch_index': currentBranchIndex,
      'is_branch': isBranch ? 1 : 0,
    };
  }

  // 复制对象
  ChatMessage copyWith({
    int? id,
    String? roleName,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? parentId,
    List<String>? branchIds,
    int? currentBranchIndex,
    bool? isBranch,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      parentId: parentId ?? this.parentId,
      branchIds: branchIds ?? this.branchIds,
      currentBranchIndex: currentBranchIndex ?? this.currentBranchIndex,
      isBranch: isBranch ?? this.isBranch,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, roleName: $roleName, content: $content, isUser: $isUser, timestamp: $timestamp)';
  }

  /// 是否有分支
  bool get hasBranches {
    return !isUser && branchIds.isNotEmpty;
  }

  /// 获取分支数量（包括原始消息）
  int get branchCount {
    return branchIds.length + 1; // +1 包括原始消息本身
  }

  /// 生成消息的唯一标识符
  String get messageId {
    return '$roleName-${timestamp.millisecondsSinceEpoch}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatMessage &&
        other.id == id &&
        other.roleName == roleName &&
        other.content == content &&
        other.isUser == isUser &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roleName.hashCode ^
        content.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode;
  }
}
