import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/message_branch_manager.dart';
import 'package:get/get.dart';

/// 文本片段，用于区分普通对话和动作描述
class TextSegment {
  const TextSegment({required this.text, required this.isAction});

  final String text;
  final bool isAction; // true表示括号内的动作描述，false表示普通对话
}

/// 聊天气泡组件
class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.roleName,
    this.userMessage, // 用于获取分支信息
    this.onCopy,
    this.onRegenerate,
    this.onCreateBranch,
    this.onSwitchBranch,
  });

  final ChatMessage message;
  final String roleName;
  final ChatMessage? userMessage; // 对应的用户消息（用于获取分支信息）

  // 回调函数
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onCreateBranch;
  final Function(int branchIndex)? onSwitchBranch;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String? _branchContent; // 只在有分支且需要显示分支内容时使用
  bool _isLoadingBranch = false;
  final MessageBranchManager _branchManager = MessageBranchManager();

  @override
  void initState() {
    super.initState();
    _loadBranchContentIfNeeded();
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在分支索引发生变化时才重新加载
    if (oldWidget.message.currentBranchIndex !=
            widget.message.currentBranchIndex ||
        oldWidget.message.branchIds.length != widget.message.branchIds.length) {
      _loadBranchContentIfNeeded();
    }
  }

  /// 获取当前应该显示的内容
  String get _displayContent {
    // 对于用户消息，直接显示原始内容
    if (widget.message.isUser) {
      return widget.message.content;
    }

    // 对于AI消息，检查对应的用户消息是否有分支
    final userMsg = widget.userMessage;
    if (userMsg == null ||
        userMsg.branchIds.isEmpty ||
        userMsg.currentBranchIndex == 0) {
      return widget.message.content;
    }

    // 如果有分支内容，显示分支内容，否则显示原始内容
    return _branchContent ?? widget.message.content;
  }

  /// 只在需要时加载分支内容
  Future<void> _loadBranchContentIfNeeded() async {
    // 对于用户消息，不需要加载分支内容
    if (widget.message.isUser) {
      return;
    }

    // 对于AI消息，检查对应的用户消息是否有分支
    final userMsg = widget.userMessage;
    if (userMsg == null ||
        userMsg.branchIds.isEmpty ||
        userMsg.currentBranchIndex == 0) {
      if (_branchContent != null) {
        setState(() {
          _branchContent = null;
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingBranch = true;
    });

    try {
      // 对于AI消息，使用对应的用户消息获取分支内容
      final userMsg = widget.userMessage;
      if (userMsg == null) {
        throw Exception('AI消息缺少对应的用户消息');
      }

      final content = await _branchManager.getCurrentBranchContent(
        userMsg,
        widget.roleName,
      );

      if (mounted) {
        setState(() {
          _branchContent = content;
          _isLoadingBranch = false;
        });
      }
    } catch (e) {
      debugPrint('加载分支内容失败: $e');
      if (mounted) {
        setState(() {
          _branchContent = null; // 降级到原始内容
          _isLoadingBranch = false;
        });
      }
    }
  }

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
            widget.message.content.trim(),
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
    final bool isGenerating = _displayContent.trim().isEmpty;

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
            child: Row(
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
            ),
          ),
        ),
      );
    }

    final segments = _parseText(_displayContent);

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

              // 操作按钮（仅在消息不为空时显示）
              if (_displayContent.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮栏
  Widget _buildActionButtons(BuildContext context) {
    // // 详细调试信息
    // debugPrint(
    //   'ChatBubble._buildActionButtons for message ${widget.message.id}',
    // );
    // debugPrint('  isUser: ${widget.message.isUser}');
    // debugPrint('  branchIds: ${widget.message.branchIds}');
    // debugPrint('  branchIds.length: ${widget.message.branchIds.length}');
    // debugPrint('  hasBranches: ${widget.message.hasBranches}');
    // debugPrint('  branchCount: ${widget.message.branchCount}');
    // debugPrint('  currentBranchIndex: ${widget.message.currentBranchIndex}');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 复制按钮
        _buildActionButton(
          icon: Icons.copy,
          onTap: () => _handleCopy(context),
          tooltip: 'copy_message'.tr,
        ),

        const SizedBox(width: 8),

        // 分叉按钮（重新生成）
        _buildActionButton(
          icon: Icons.call_split,
          onTap: () {
            debugPrint('🌿 ChatBubble: 分叉按钮被点击，准备调用回调');
            widget.onCreateBranch?.call();
          },
          tooltip: 'create_branch'.tr,
        ),

        // 分支切换器（仅在AI消息且对应用户消息有分支时显示）
        if (!widget.message.isUser &&
            widget.userMessage?.hasBranches == true) ...[
          const SizedBox(width: 12),
          _buildBranchSwitcher(),
        ],
      ],
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建小尺寸操作按钮（用于分支切换器）
  Widget _buildSmallActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建分支切换器
  Widget _buildBranchSwitcher() {
    // 使用用户消息的分支信息
    final userMsg = widget.userMessage;
    if (userMsg == null || !userMsg.hasBranches) return const SizedBox.shrink();

    final currentIndex = userMsg.currentBranchIndex;
    final totalCount = userMsg.branchCount;

    // 调试信息
    debugPrint(
      '分支切换器: currentIndex=$currentIndex, totalCount=$totalCount, branchIds=${userMsg.branchIds}',
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上一个分支按钮（小尺寸）
        _buildSmallActionButton(
          icon: Icons.keyboard_arrow_left,
          onTap: currentIndex > 0
              ? () => widget.onSwitchBranch?.call(currentIndex - 1)
              : null,
          tooltip: 'Previous Branch',
        ),

        const SizedBox(width: 2),

        // 当前分支索引显示（紧凑版）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 如果正在加载分支，显示小的加载指示器
              if (_isLoadingBranch && currentIndex > 0)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange.withValues(alpha: 0.8),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.call_split,
                  size: 10,
                  color: Colors.orange.withValues(alpha: 0.8),
                ),
              const SizedBox(width: 2),
              Text(
                '${currentIndex + 1}/$totalCount',
                style: TextStyle(
                  color: Colors.orange.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 2),

        // 下一个分支按钮（小尺寸）
        _buildSmallActionButton(
          icon: Icons.keyboard_arrow_right,
          onTap: currentIndex < totalCount - 1
              ? () => widget.onSwitchBranch?.call(currentIndex + 1)
              : null,
          tooltip: 'Next Branch',
        ),
      ],
    );
  }

  /// 处理复制操作
  void _handleCopy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _displayContent));
    widget.onCopy?.call();

    // 显示复制成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('copied_to_clipboard'.tr),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.message.isUser
        ? _buildUserBubble(context)
        : _buildAiBubble(context);
  }
}
