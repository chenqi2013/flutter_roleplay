import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';

/// 文本片段，用于区分普通对话和动作描述
class TextSegment {
  const TextSegment({required this.text, required this.isAction});

  final String text;
  final bool isAction; // true表示括号内的动作描述，false表示普通对话
}

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  /// 解析文本，分离括号内容和普通内容
  List<TextSegment> _parseText(String text) {
    final List<TextSegment> segments = [];
    // 匹配英文括号 () 和中文括号 （）
    final RegExp regex = RegExp(r'[\(（]([^\)）]*)[\)）]');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // 添加括号前的普通文本
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start).trim();
        if (normalText.isNotEmpty) {
          segments.add(TextSegment(text: normalText, isAction: false));
        }
      }

      // 添加括号内的动作描述，保留原始括号
      final fullMatch = match.group(0) ?? ''; // 完整匹配包括括号
      if (fullMatch.isNotEmpty) {
        segments.add(TextSegment(text: fullMatch, isAction: true));
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的普通文本
    if (lastEnd < text.length) {
      final normalText = text.substring(lastEnd).trim();
      if (normalText.isNotEmpty) {
        segments.add(TextSegment(text: normalText, isAction: false));
      }
    }

    // 如果没有匹配到任何括号，将整个文本作为普通文本
    if (segments.isEmpty && text.trim().isNotEmpty) {
      segments.add(TextSegment(text: text.trim(), isAction: false));
    }

    return segments;
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFFFC107),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.content.trim(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    final segments = _parseText(message.content);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(right: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((segment) {
              if (segment.isAction) {
                // 动作描述：斜体、更亮的灰色、较小字号
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    segment.text, // 已经包含原始括号（英文或中文）
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC), // 更亮的灰色
                      fontSize: 15,
                      height: 1.4,
                      fontStyle: FontStyle.italic, // 斜体
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              } else {
                // 普通对话：正常样式
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    segment.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _buildUserBubble(context) : _buildAiBubble(context);
  }
}
