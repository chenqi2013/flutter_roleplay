import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

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
    this.onRegeneratePressed,
    this.onBranchChanged,
    this.showBranchIndicator = false,
  });

  final ChatMessage message;
  final VoidCallback? onRegeneratePressed;
  final Function(int branchIndex)? onBranchChanged;
  final bool showBranchIndicator;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  var cacheDir = '';

  @override
  void initState() {
    super.initState();
    // 如果消息有音频文件，初始化 AudioPlayer
    if (widget.message.audioFileName != null &&
        widget.message.audioFileName!.isNotEmpty) {
      _initAudioPlayer();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();

    // 监听播放完成事件
    _audioPlayer!.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    // 监听播放状态变化
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _isPlaying == false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  // 播放或暂停音频
  Future<void> _toggleAudio() async {
    if (widget.message.audioFileName == null) return;
    if (_audioPlayer == null) {
      _initAudioPlayer();
    }
    if (cacheDir.isEmpty) {
      cacheDir = (await getTemporaryDirectory()).path;
      debugPrint('cacheDir: $cacheDir');
    }
    try {
      if (_isPlaying) {
        // 暂停
        await _audioPlayer!.pause();
      } else {
        // 播放
        final audioPath = '$cacheDir/${widget.message.audioFileName}';
        debugPrint('Playing audio from: $audioPath');
        await _audioPlayer!.play(DeviceFileSource(audioPath));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
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
          decoration: const BoxDecoration(
            // 渐变边框
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1AFFFFFF), // 10% 白色
                Color(0x99FFFFFF), // 60% 白色
                Color(0x1AFFFFFF), // 10% 白色
                Color(0x99FFFFFF), // 60% 白色
              ],
              stops: [0.0, 0.25, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0), // 边框宽度
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                  child: Text(
                    widget.message.content.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Source Han Sans SC',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    // 检查是否为空消息（正在生成中）
    final bool isGenerating = widget.message.content.trim().isEmpty;

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

    final segments = _parseText(widget.message.content);

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
              // 音频图标（如果有音频文件）
              if (widget.message.audioFileName != null &&
                  widget.message.audioFileName!.isNotEmpty)
                _buildAudioIcon(),

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
              if ((widget.showBranchIndicator &&
                      widget.message.totalBranches > 1) ||
                  (!widget.message.isUser &&
                      widget.onRegeneratePressed != null))
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
          if (widget.showBranchIndicator && widget.message.totalBranches > 1)
            _buildBranchIndicator(),

          // 间距
          if ((widget.showBranchIndicator &&
                  widget.message.totalBranches > 1) &&
              (!widget.message.isUser && widget.onRegeneratePressed != null))
            const SizedBox(width: 12),

          // 重新生成按钮（对于AI消息）
          if (!widget.message.isUser && widget.onRegeneratePressed != null)
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
        if (widget.message.branchIndex > 0)
          GestureDetector(
            onTap: () =>
                widget.onBranchChanged?.call(widget.message.branchIndex - 1),
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
          '${widget.message.branchIndex + 1} / ${widget.message.totalBranches}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 8),

        // 右箭头
        if (widget.message.branchIndex < widget.message.totalBranches - 1)
          GestureDetector(
            onTap: () =>
                widget.onBranchChanged?.call(widget.message.branchIndex + 1),
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
          'Regenerate button tapped for message: ${widget.message.content.substring(0, math.min(50, widget.message.content.length))}...',
        );
        widget.onRegeneratePressed?.call();
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

  /// 构建音频图标
  Widget _buildAudioIcon() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleAudio,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isPlaying
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPlaying
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  else
                    Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    (widget.message.audioDuration != null &&
                            widget.message.audioDuration! > 0
                        ? '${widget.message.audioDuration}s'
                        : ''),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
