import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/constant/theme.dart';
import 'package:get/get.dart';
import 'createrole_controller.dart';

class CreateRolePage extends GetView<CreateRoleController> {
  const CreateRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CreateRoleController());
    final EdgeInsets safe = MediaQuery.of(context).padding;
    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('创建新角色'), centerTitle: true),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + safe.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '新角色名称',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.nameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration('请输入新角色名称'),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '新角色设定',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Obx(
                                () => Text(
                                  '${controller.descLength.value}/${CreateRoleController.descMaxLength}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.descController,
                            maxLines: 10,
                            minLines: 6,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            decoration: _inputDecoration(
                              '请详细描述新角色的背景、性格、说话方式与边界...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 底部毛玻璃确认栏
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safe.bottom),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.2, 0.7, 1.0],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => _PrimaryButton(
                                onTap: controller.canSubmit.value
                                    ? controller.onConfirm
                                    : null,
                                label: '创建角色',
                                enabled: controller.canSubmit.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
    isDense: true,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.2),
        width: 0.6,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.2),
        width: 0.6,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white, width: 1.0),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool enabled;
  const _PrimaryButton({
    required this.onTap,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: enabled
              ? [
                  const Color(0xFF6A8DFF).withValues(alpha: 0.9),
                  const Color(0xFF9B7BFF).withValues(alpha: 0.9),
                ]
              : [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.1),
                ],
        ),
        border: Border.all(
          color: enabled
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: const Color(0xFF6A8DFF).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );

    if (!enabled) return content;

    return GestureDetector(onTap: onTap, child: content);
  }
}
