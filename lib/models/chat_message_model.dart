class ChatMessage {
  final int? id;
  final String roleName;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.roleName,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  // 从数据库行创建对象
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      roleName: map['role_name'] as String,
      content: map['content'] as String,
      isUser: (map['is_user'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
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
    };
  }

  // 复制对象
  ChatMessage copyWith({
    int? id,
    String? roleName,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, roleName: $roleName, content: $content, isUser: $isUser, timestamp: $timestamp)';
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
