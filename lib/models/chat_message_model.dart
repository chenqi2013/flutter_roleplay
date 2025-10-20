class ChatMessage {
  final int? id;
  final String roleName; //角色名称
  final String content; //用户的问题或者AI回复
  final bool isUser; //用户或者AI
  final DateTime timestamp;

  // 消息树相关字段
  final int? parentId; // 父消息ID，null表示根消息
  final int branchIndex; // 在同一父消息下的分支索引，默认为0
  final int totalBranches; // 同一父消息下的总分支数
  final String? conversationId; // 会话ID，用于标识同一个对话线程

  ChatMessage({
    this.id,
    required this.roleName,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.parentId,
    this.branchIndex = 0,
    this.totalBranches = 1,
    this.conversationId,
  });

  // 从数据库行创建对象
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      roleName: map['role_name'] as String,
      content: map['content'] as String,
      isUser: (map['is_user'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      parentId: map['parent_id'] as int?,
      branchIndex: map['branch_index'] as int? ?? 0,
      totalBranches: map['total_branches'] as int? ?? 1,
      conversationId: map['conversation_id'] as String?,
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
      'branch_index': branchIndex,
      'total_branches': totalBranches,
      'conversation_id': conversationId,
    };
  }

  // 复制对象
  ChatMessage copyWith({
    int? id,
    String? roleName,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    int? parentId,
    int? branchIndex,
    int? totalBranches,
    String? conversationId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      parentId: parentId ?? this.parentId,
      branchIndex: branchIndex ?? this.branchIndex,
      totalBranches: totalBranches ?? this.totalBranches,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, roleName: $roleName, content: $content, isUser: $isUser, timestamp: $timestamp, parentId: $parentId, branchIndex: $branchIndex, totalBranches: $totalBranches, conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatMessage &&
        other.id == id &&
        other.roleName == roleName &&
        other.content == content &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.parentId == parentId &&
        other.branchIndex == branchIndex &&
        other.totalBranches == totalBranches &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roleName.hashCode ^
        content.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        parentId.hashCode ^
        branchIndex.hashCode ^
        totalBranches.hashCode ^
        conversationId.hashCode;
  }
}
