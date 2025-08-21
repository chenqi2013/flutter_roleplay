import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:get/state_manager.dart';

// 全局贴底输入框组件：自动避让键盘 + 底部导航
class GlobalInputBar extends StatelessWidget {
  final double bottomBarHeight;
  final double height;
  final bool inline; // 置于页面布局最底部（不悬浮）
  final ValueChanged<String>? onSend; // 键盘"发送"提交回调
  final TextEditingController? controller; // 外部可控输入内容
  final bool isLoading; // AI回复中的加载状态
  final String roleName; // 角色名称
  const GlobalInputBar({
    super.key,
    required this.bottomBarHeight,
    required this.height,
    this.inline = false,
    this.onSend,
    this.controller,
    this.isLoading = false,
    this.roleName = '',
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom; // 键盘高度
    final bottomPadding = MediaQuery.of(context).padding.bottom; // 安全区域底部高度

    if (inline) {
      // 页面最底部内嵌模式：不使用悬浮/对齐，由外部控制底部间距
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 8),
        child: _GlassInput(
          height: height,
          onSend: onSend,
          controller: controller,
          isLoading: isLoading,
          roleName: roleName,
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // 键盘弹出时：顶到键盘之上；否则：悬停在底部导航上方
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: (viewInsets > 0)
                ? (viewInsets + 8) // 键盘在时，跟随键盘
                : (bottomBarHeight + 8), // 常规状态，悬停在底部导航上方
          ),
          child: _GlassInput(
            height: height,
            onSend: onSend,
            controller: controller,
            isLoading: isLoading,
            roleName: roleName,
          ),
        ),
      ),
    );
  }
}

// 带渐变/发光样式的输入框组件
class _GlassInput extends StatelessWidget {
  final double height;
  final ValueChanged<String>? onSend;
  final TextEditingController? controller;
  final bool isLoading;
  final String roleName;
  const _GlassInput({
    required this.height,
    this.onSend,
    this.controller,
    this.isLoading = false,
    this.roleName = '',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            // border: Border.all(
            //   color: Colors.white.withValues(alpha: 0.2),
            //   width: 0.5,
            // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withValues(alpha: 0.1),
            //     blurRadius: 20,
            //     offset: const Offset(0, 8),
            //     spreadRadius: 0,
            //   ),
            //   BoxShadow(
            //     color: Colors.white.withValues(alpha: 0.1),
            //     blurRadius: 8,
            //     offset: const Offset(0, -2),
            //     spreadRadius: 0,
            //   ),
            // ],
          ),
          child: Row(
            children: [
              // 麦克风
              _circleBtn(
                child: const Icon(
                  Icons.mic_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              // 输入框
              Expanded(
                child: TextField(
                  enabled: !isLoading, // 加载时禁用输入
                  style: TextStyle(
                    color: isLoading ? Colors.white38 : Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: isLoading
                        ? 'AI正在回复中...'
                        : '发送消息给${roleName.isNotEmpty ? roleName : "AI"}',
                    hintStyle: TextStyle(
                      color: isLoading ? Colors.white38 : Colors.white54,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent, // 背景透明
                    contentPadding: EdgeInsets.zero,
                  ),
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isLoading
                      ? null
                      : (value) {
                          final String v = value.trim();
                          if (v.isEmpty) return;
                          onSend?.call(v);
                          // 清空输入
                          controller?.clear();
                        },
                ),
              ),
              // const SizedBox(width: 12),
              // // 右侧按钮们
              // Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     _circleBtn(
              //       gradient: const [Color(0x66FFC107), Color(0x33FF9800)],
              //       borderColor: const Color(0x88FFC107),
              //       child: const Icon(
              //         Icons.flash_on_outlined,
              //         color: Colors.amber,
              //         size: 26,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Stack(
              //       children: [
              //         _circleBtn(
              //           child: const Icon(
              //             Icons.add,
              //             color: Colors.white,
              //             size: 26,
              //           ),
              //         ),
              //         // Positioned(
              //         //   top: 6,
              //         //   right: 6,
              //         //   child: Container(
              //         //     width: 8,
              //         //     height: 8,
              //         //     decoration: BoxDecoration(
              //         //       color: Colors.red,
              //         //       shape: BoxShape.circle,
              //         //       boxShadow: [
              //         //         BoxShadow(
              //         //           color: Colors.red.withValues(alpha: 0.5),
              //         //           blurRadius: 4,
              //         //           offset: const Offset(0, 1),
              //         //         ),
              //         //       ],
              //         //     ),
              //         //   ),
              //         // ),
              //       ],
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circleBtn({
    List<Color>? gradient,
    Color? borderColor,
    required Widget child,
  }) {
    final List<Color> colorsList =
        gradient ??
        [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.1),
        ];
    final List<double>? stopsList = colorsList.length == 3
        ? const [0.0, 0.6, 1.0]
        : null;
    return Center(child: child);
  }
}
