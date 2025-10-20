import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

/// 文本片段，用于区分普通对话和动作描述
class TextSegment {
  const TextSegment({required this.text, required this.isAction});

  final String text;
  final bool isAction; // true表示括号内的动作描述，false表示普通对话
}

/// 聊天气泡组件
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onRegeneratePressed,
    this.onBranchChanged,
    this.showBranchIndicator = false,
  });

  final ChatMessage message;
  final VoidCallback? onRegeneratePressed;
  final Function(int branchIndex)? onBranchChanged;
  final bool showBranchIndicator;

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
    // 检查是否为空消息（正在生成中）
    final bool isGenerating = message.content.trim().isEmpty;

    if (isGenerating) {
      // 显示loading指示器
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
            child: _buildThinkingContent(),
          ),
        ),
      );
    }

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
            children: [
              // 消息内容
              ...segments.map((segment) {
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
              }),

              // 分支指示器和重新生成按钮同一行
              if ((showBranchIndicator && message.totalBranches > 1) ||
                  (!message.isUser && onRegeneratePressed != null))
                _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建操作行（分支指示器 + 重新生成按钮）
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // 分支指示器（如果有多个分支）
          if (showBranchIndicator && message.totalBranches > 1)
            _buildBranchIndicator(),

          // 间距
          if ((showBranchIndicator && message.totalBranches > 1) &&
              (!message.isUser && onRegeneratePressed != null))
            const SizedBox(width: 12),

          // 重新生成按钮（对于AI消息）
          if (!message.isUser && onRegeneratePressed != null)
            _buildRegenerateButton(),
        ],
      ),
    );
  }

  /// 构建分支指示器
  Widget _buildBranchIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 左箭头
        if (message.branchIndex > 0)
          GestureDetector(
            onTap: () => onBranchChanged?.call(message.branchIndex - 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.arrow_left,
                color: Colors.white,
                size: 16,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_left,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ),

        const SizedBox(width: 8),

        // 分支信息
        Text(
          '${message.branchIndex + 1} / ${message.totalBranches}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 8),

        // 右箭头
        if (message.branchIndex < message.totalBranches - 1)
          GestureDetector(
            onTap: () => onBranchChanged?.call(message.branchIndex + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.arrow_right,
                color: Colors.white,
                size: 16,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ),
      ],
    );
  }

  /// 构建重新生成按钮
  Widget _buildRegenerateButton() {
    return GestureDetector(
      onTap: () {
        debugPrint(
          'Regenerate button tapped for message: ${message.content.substring(0, math.min(50, message.content.length))}...',
        );
        onRegeneratePressed?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              color: Colors.white.withValues(alpha: 0.8),
              size: 14,
            ),
            // const SizedBox(width: 4),
            // Text(
            //   '重新生成',
            //   style: TextStyle(
            //     color: Colors.white.withValues(alpha: 0.8),
            //     fontSize: 12,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// 构建思考中的内容显示
  Widget _buildThinkingContent() {
    // 尝试获取 RWKVChatService 实例
    if (!Get.isRegistered<RWKVChatService>()) {
      return _buildDefaultThinking();
    }

    final chatService = Get.find<RWKVChatService>();

    return Obx(() {
      final progress = chatService.prefillProgress.value;

      // 如果有进度信息（0-1之间），显示进度
      if (progress > 0 && progress < 1.0) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.7),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      }

      // 否则显示默认的thinking动画
      return _buildDefaultThinking();
    });
  }

  /// 默认的思考中显示
  Widget _buildDefaultThinking() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'thinking'.tr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _buildUserBubble(context) : _buildAiBubble(context);
  }
}
