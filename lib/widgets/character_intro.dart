import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CharacterIntro extends StatefulWidget {
  final String title;
  final String description;
  final String? firstMessage;
  final int maxLines;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final bool showExpandIcon;

  const CharacterIntro({
    super.key,
    required this.title,
    required this.description,
    this.firstMessage,
    this.maxLines = 4,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.showExpandIcon = true,
  });

  @override
  State<CharacterIntro> createState() => _CharacterIntroState();
}

class _CharacterIntroState extends State<CharacterIntro> {
  bool _isExpanded = false;

  /// 检查文本是否需要展开功能
  bool _shouldShowExpandButton() {
    if (!widget.showExpandIcon) return false;

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.description,
        style: const TextStyle(fontSize: 15, height: 1.35),
      ),
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    );

    // 动态获取屏幕宽度并计算容器最大宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.85 - 24; // 85%宽度减去左右padding 12*2
    textPainter.layout(maxWidth: maxWidth);

    // 检查文本是否被截断
    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.backgroundColor ?? Colors.black.withValues(alpha: 0.5);
    final textColor = widget.textColor ?? Colors.white;
    final borderRadius =
        widget.borderRadius ??
        const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(2),
          bottomRight: Radius.circular(14),
        );

    return Column(
      children: [
        // AI生成提示 - 放在简介上方
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'ai_generated_content'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // 角色介绍气泡
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 简介标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 介绍内容
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                    maxLines: _isExpanded ? null : widget.maxLines,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  // 展开/收起按钮 - 只在需要时显示
                  if (_shouldShowExpandButton())
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: textColor.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // 角色首句话气泡（如果提供了firstMessage）
        if (widget.firstMessage != null && widget.firstMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                ),
                child: Text(
                  widget.firstMessage!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // // 引导提示
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        //   decoration: BoxDecoration(
        //     color: Colors.black.withValues(alpha: 0.45),
        //     borderRadius: BorderRadius.circular(14),
        //     border: Border.all(
        //       color: Colors.white.withValues(alpha: 0.15),
        //       width: 0.5,
        //     ),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(Icons.lightbulb_outline, color: Colors.white70, size: 16),
        //       const SizedBox(width: 8),
        //       const Text(
        //         '试试开启继续说',
        //         style: TextStyle(
        //           color: Colors.white,
        //           fontSize: 13,
        //           fontWeight: FontWeight.w400,
        //         ),
        //         textAlign: TextAlign.center,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
