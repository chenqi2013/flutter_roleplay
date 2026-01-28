import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class containing reusable dialog components for chat functionality
class ChatDialogs {
  /// Shows a confirmation dialog when AI is generating and user wants to leave/interrupt
  static Future<bool?> showAiInterruptionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 警告图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.orange.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  'confirm_operation'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // 内容
                Text(
                  'ai_interruption_message'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮
                Row(
                  children: [
                    // 取消按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'cancel'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 确认按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'confirm'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog when switching roles while AI is generating
  static Future<bool?> showRoleSwitchDialog(
    BuildContext context,
    String roleName,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 切换图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withValues(alpha: 0.2),
                        Colors.blue.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.blue.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  'role_switch_dialog_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // 内容
                Text(
                  'role_switch_confirm_message'.trParams({'name': roleName}),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮
                Row(
                  children: [
                    // 取消按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'cancel'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 确认按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'confirm'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog for deleting chat history
  static Future<bool?> showDeleteHistoryDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              // border: Border.all(
              //   color: Colors.red.withValues(alpha: 0.2),
              //   width: 1,
              // ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 警告图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.2),
                        Colors.red.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    // border: Border.all(
                    //   color: Colors.red.withValues(alpha: 0.3),
                    //   width: 2,
                    // ),
                  ),
                  child: Icon(
                    Icons.delete_forever,
                    color: Colors.red.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // 标题
                Text(
                  'delete_history_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // 内容
                Text(
                  'delete_history_message'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'delete_irreversible'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮
                Row(
                  children: [
                    // 取消按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '取消',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 删除按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'delete'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
