import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/constant/theme.dart';
import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:get/get.dart';
import 'role_params_controller.dart';

class RoleParamsPage extends StatelessWidget {
  const RoleParamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RoleParamsController());
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('role_params_title'.tr),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                _showResetDialog(context, controller);
              },
              child: Text(
                'reset'.tr,
                style: const TextStyle(color: Colors.orange, fontSize: 16),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + safe.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 参数说明卡片
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'params_info_title'.tr,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'params_info_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 温度参数
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'temperature'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'temperature_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildSlider(
                              context: context,
                              value: controller.temperature.value,
                              min: 0.2,
                              max: 2.0,
                              divisions: 18,
                              onChanged: controller.updateTemperature,
                              displayValue: controller.temperature.value
                                  .toStringAsFixed(1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TopP 参数
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'top_p'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'top_p_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildSlider(
                              context: context,
                              value: controller.topP.value,
                              min: 0.0,
                              max: 1.0,
                              divisions: 100,
                              onChanged: controller.updateTopP,
                              displayValue: controller.topP.value
                                  .toStringAsFixed(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Presence Penalty 参数
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'presence_penalty'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'presence_penalty_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildSlider(
                              context: context,
                              value: controller.presencePenalty.value,
                              min: 0.0,
                              max: 2.0,
                              divisions: 100,
                              onChanged: controller.updatePresencePenalty,
                              displayValue: controller.presencePenalty.value
                                  .toStringAsFixed(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Frequency Penalty 参数
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'frequency_penalty'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'frequency_penalty_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildSlider(
                              context: context,
                              value: controller.frequencyPenalty.value,
                              min: 0.0,
                              max: 2.0,
                              divisions: 100,
                              onChanged: controller.updateFrequencyPenalty,
                              displayValue: controller.frequencyPenalty.value
                                  .toStringAsFixed(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Penalty Decay 参数
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'penalty_decay'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'penalty_decay_desc'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildSlider(
                              context: context,
                              value: controller.penaltyDecay.value,
                              min: 0.99,
                              max: 0.999,
                              divisions: 9,
                              onChanged: controller.updatePenaltyDecay,
                              displayValue: controller.penaltyDecay.value
                                  .toStringAsFixed(3),
                              count: 3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // 底部确定按钮
            Positioned(
              left: 16,
              right: 16,
              bottom: safe.bottom + 16,
              child: _PrimaryButton(
                onTap: () {
                  _applyParams(context);
                },
                label: 'apply'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用参数设置
  void _applyParams(BuildContext context) {
    try {
      final chatService = Get.find<RWKVChatService>();
      chatService.setSamplerParams();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('params_applied_success'.tr),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('params_applied_failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('params_apply_failed'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 构建滑块控件
  Widget _buildSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String displayValue,
    int? count,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toStringAsFixed(count ?? 1),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              max.toStringAsFixed(count ?? 1),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.orange,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: Colors.orange,
            overlayColor: Colors.orange.withValues(alpha: 0.2),
            valueIndicatorColor: Colors.orange,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// 显示重置确认对话框
  void _showResetDialog(BuildContext context, RoleParamsController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'reset_params_title'.tr,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'reset_params_desc'.tr,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.resetToDefaults();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('params_reset_success'.tr),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'reset',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }
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
