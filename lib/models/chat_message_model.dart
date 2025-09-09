class ChatMessage {
  final int? id;
  final String roleName;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  // 多回答支持（仅对AI消息有效）
  final List<String> alternativeResponses;
  final int currentResponseIndex;

  ChatMessage({
    this.id,
    required this.roleName,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.alternativeResponses = const [],
    this.currentResponseIndex = 0,
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
    List<String>? alternativeResponses,
    int? currentResponseIndex,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      alternativeResponses: alternativeResponses ?? this.alternativeResponses,
      currentResponseIndex: currentResponseIndex ?? this.currentResponseIndex,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, roleName: $roleName, content: $content, isUser: $isUser, timestamp: $timestamp)';
  }

  /// 获取当前显示的内容
  String get currentContent {
    if (isUser || alternativeResponses.isEmpty) {
      return content;
    }

    // 对于AI消息，如果有备选回答，优先显示当前选中的回答
    if (currentResponseIndex < alternativeResponses.length) {
      return alternativeResponses[currentResponseIndex];
    }

    return content; // 兜底显示原始内容
  }

  /// 获取所有回答（包括原始回答）
  List<String> get allResponses {
    if (isUser) return [content];

    final responses = <String>[];
    if (content.isNotEmpty) responses.add(content);
    responses.addAll(alternativeResponses);
    return responses;
  }

  /// 是否有多个回答
  bool get hasMultipleResponses {
    return !isUser && allResponses.length > 1;
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
