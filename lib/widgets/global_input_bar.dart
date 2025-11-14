import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'glass_container.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 输入框
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              // Angular Gradient (角度渐变边框)
              gradient: const SweepGradient(
                colors: [
                  Color(0x1AFFFFFF), // 10% 白色
                  Color(0x99FFFFFF), // 60% 白色
                  Color(0x1AFFFFFF), // 10% 白色
                  Color(0x99FFFFFF), // 60% 白色
                ],
                stops: [0.0, 0.25, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.5), // 边框宽度 0.5px
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 63.1, sigmaY: 63.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(27.5),
                    ),
                    child: Center(
                      child: TextField(
                        enabled: !isLoading, // 加载时禁用输入
                        style: TextStyle(
                          color: isLoading ? Colors.white38 : Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: isLoading
                              ? 'ai_replying'.tr
                              : (roleName.isNotEmpty
                                    ? 'send_message_to'.trParams({
                                        'name': roleName,
                                      })
                                    : 'send_message_to_ai'.tr),
                          hintStyle: TextStyle(
                            color: isLoading ? Colors.white38 : Colors.white,
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
                                sendMessage();
                              },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 发送按钮
        InkWell(
          onTap: isLoading ? null : sendMessage,
          borderRadius: BorderRadius.circular(145),
          child: GlassContainer(
            borderRadius: 145,
            borderWidth: 0,
            padding: const EdgeInsets.all(16),
            child: SvgPicture.asset(
              'packages/flutter_roleplay/assets/svg/send.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isLoading ? Colors.white38 : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void sendMessage() {
    final String v = controller?.text.trim() ?? '';
    if (v.isEmpty) return;
    onSend?.call(v);
    // 清空输入
    controller?.clear();
  }
}
