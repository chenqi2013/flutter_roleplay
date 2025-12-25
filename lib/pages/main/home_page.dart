import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/widgets/clipped_glass_container_static.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/main/home_controller.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_page.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/pages/params/model_params_page.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/dialog/chat_dialogs.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    // TabBarView 不放在 Obx 中，避免 tab 切换时重建
    // 使用 ScrollConfiguration 完全禁用过度滚动效果，防止 BackdropFilter 高亮
    final tabBarView = ScrollConfiguration(
      behavior: _NoOverscrollBehavior(),
      child: TabBarView(
        controller: controller.tabController,
        // 禁用过度滚动效果，提升滑动流畅度
        physics: const ClampingScrollPhysics(),
        children: [
          // Tab1: 角色聊天页面
          const RolePlayChat(),
          // Tab2: 角色列表页面
          RolesListPage(),
          // Tab3: 模型参数页面
          ModelParamsPage(),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 动态背景层 - 只有背景响应 tab 变化
          _buildDynamicBackground(),
          // 前景内容 - TabBarView 全屏显示，可以滑动到TabBar下方
          tabBarView,
          // 顶部TabBar - 浮在最上层，带高斯模糊效果
          _buildTabBar(context),
        ],
      ),
    );
  }

  // 构建动态背景
  Widget _buildDynamicBackground() {
    // 先用 Obx 获取 imageUrl，避免在 AnimatedBuilder 内部嵌套 Obx
    return Obx(() {
      final imageUrl = roleImage.value;

      return Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: controller.tabController.animation!,
            builder: (context, child) {
              // animation.value: 0.0 = tab0, 1.0 = tab1, 2.0 = tab2
              final animationValue = controller.tabController.animation!.value;
              // 聊天背景只在 tab 0 时完全显示，滑动到其他 tab 时淡出
              final chatBgOpacity = (1.0 - animationValue).clamp(0.0, 1.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 角色/模型背景（底层，始终显示）
                  Image.asset(
                    'packages/flutter_roleplay/assets/svg/rolebg.png',
                    fit: BoxFit.cover,
                  ),
                  // 聊天背景（顶层，根据滑动进度淡入淡出）
                  if (chatBgOpacity > 0)
                    Opacity(
                      opacity: chatBgOpacity,
                      child: _buildChatBackground(imageUrl),
                    ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  // 构建聊天页背景（简化版，移除耗性能的 ImageFiltered）
  Widget _buildChatBackground(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(color: Colors.grey.shade300);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片层
        ChatPageBuilders.buildImageWidget(
          imageUrl,
          fit: BoxFit.cover,
          key: ValueKey('bg_chat_$imageUrl'),
        ),
        // 顶部渐变蒙版（简化版，不使用 ImageFiltered）
        _buildSimpleOverlay(),
      ],
    );
  }

  /// 构建顶部简化渐变蒙版（不使用 ImageFiltered，提升性能）
  Widget _buildSimpleOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // 构建TabBar - 带高斯模糊效果，让背后内容可见
  Widget _buildTabBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1), // 轻微的半透明背景
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // 左侧关闭按钮
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // 关闭页面，与 chat_page_builders 的 onBackPressed 保持一致
                        notifyUpdateRolePlaySessionRequired();
                        Navigator.of(context).pop();
                      },
                      child: ClippedGlassContainerStatic(
                        fallbackBlur: 63.1,
                        color: Colors.black.withValues(alpha: 0.35),
                        hasGradient: true,
                        borderRadius: 70,
                        borderWidth: 0.5,
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'packages/flutter_roleplay/assets/svg/close.svg',
                          height: 12,
                        ),
                      ),
                    ),
                  ),
                  // 自定义 TabBar（玻璃态效果）- 带滑动指示器
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildAnimatedTabBar(),
                    ),
                  ),
                  // 清除消息按钮 - 只在第一个tab（聊天页面）显示
                  Obx(() {
                    if (controller.currentIndex.value != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          // 显示确认弹窗
                          final confirmed =
                              await ChatDialogs.showDeleteHistoryDialog(
                                context,
                              );

                          // 用户确认后才执行清除操作
                          if (confirmed == true) {
                            RolePlayChatController chatController;
                            if (Get.isRegistered<RolePlayChatController>()) {
                              chatController =
                                  Get.find<RolePlayChatController>();
                            } else {
                              chatController = Get.put(
                                RolePlayChatController(),
                              );
                            }
                            await chatController.clearAllChatHistory();

                            // 显示清除成功提示
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('chat_history_cleared'.tr),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                        child: ClippedGlassContainerStatic(
                          fallbackBlur: 63.1,
                          color: Colors.black.withValues(alpha: 0.35),
                          hasGradient: true,
                          borderRadius: 70,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'packages/flutter_roleplay/assets/svg/clear_msg.svg',
                            height: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建带动画的TabBar
  Widget _buildAnimatedTabBar() {
    return Obx(() {
      // 在Obx内部立即获取observable的值
      final chatLabel = roleName.value.isNotEmpty ? roleName.value : '聊天';

      return AnimatedBuilder(
        animation: controller.tabController.animation!,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = (constraints.maxWidth - 16) / 3; // 减去间距
              final animationValue = controller.tabController.animation!.value;

              // 计算指示器的位置
              final indicatorLeft = animationValue * (tabWidth + 8);

              return Stack(
                children: [
                  // 底层：所有Tab文字（未选中状态）
                  Row(
                    children: [
                      Expanded(
                        child: _buildTabText(label: chatLabel, index: 0),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTabText(label: '角色', index: 1)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTabText(label: '模型', index: 2)),
                    ],
                  ),
                  // 顶层：滑动的高亮指示器和文字
                  Positioned(
                    left: indicatorLeft,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: ClippedGlassContainerStatic(
                      fallbackBlur: 63.1,
                      color: Colors.black.withValues(alpha: 0.35),
                      hasGradient: true,
                      borderRadius: 70,
                      borderWidth: 0.5,
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -indicatorLeft,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTabText(
                                        label: chatLabel,
                                        index: 0,
                                        isForHighlight: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTabText(
                                        label: '角色',
                                        index: 1,
                                        isForHighlight: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTabText(
                                        label: '模型',
                                        index: 2,
                                        isForHighlight: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  /// 构建Tab文字
  Widget _buildTabText({
    required String label,
    required int index,
    bool isForHighlight = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isForHighlight
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// 自定义 ScrollBehavior，完全禁用过度滚动效果
/// 防止 TabBarView 水平滑动时 BackdropFilter 出现高亮问题
class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // 不添加任何过度滚动指示器
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 使用 ClampingScrollPhysics 禁用弹性过度滚动
    return const ClampingScrollPhysics();
  }
}
