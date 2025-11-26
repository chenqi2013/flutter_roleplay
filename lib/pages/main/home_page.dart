import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/widgets/clipped_glass_container.dart';
import 'package:flutter_roleplay/widgets/pre_blurred_background.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/main/home_controller.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/pages/params/model_params_page.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 根据当前 Tab 选择背景
      final currentTab = controller.currentIndex.value;
      final Widget backgroundWidget;

      if (currentTab == 0) {
        // 聊天页面使用角色背景
        final imageUrl = roleImage.value;
        backgroundWidget = imageUrl.isEmpty
            ? Container(color: Colors.grey.shade300)
            : ChatPageBuilders.buildImageWidget(imageUrl, fit: BoxFit.cover);
      } else {
        // 角色/模型页面使用 rolebg.png
        backgroundWidget = Image.asset(
          'packages/flutter_roleplay/assets/svg/rolebg.png',
          fit: BoxFit.cover,
        );
      }

      return PreBlurredBackgroundScope(
        backgroundImage: backgroundWidget,
        blurSigma: 63.1,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 动态背景层
              _buildDynamicBackground(),
              // 前景内容
              Column(
                children: [
                  // 顶部TabBar
                  _buildTabBar(context),
                  // 内容区域
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        // Tab1: 角色聊天页面
                        const RolePlayChat(),
                        // Tab2: 角色列表页面
                        RolesListPage(),
                        // Tab3: 模型参数页面
                        ModelParamsPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // 构建动态背景
  Widget _buildDynamicBackground() {
    return Obx(() {
      final currentTab = controller.currentIndex.value;

      // Tab 0（聊天）：使用角色背景图片
      if (currentTab == 0) {
        final imageUrl = roleImage.value;
        if (imageUrl.isEmpty) {
          // 如果没有角色图片，显示默认背景
          return Positioned.fill(child: Container(color: Colors.grey.shade300));
        }
        // 使用ChatPageBuilders的图片加载器，支持网络图片缓存
        // 添加模糊蒙版效果
        return Positioned.fill(
          child: Stack(
            children: [
              // 背景图片层 - 确保完全填充（不被模糊）
              Positioned.fill(
                child: ChatPageBuilders.buildImageWidget(
                  imageUrl,
                  fit: BoxFit.cover,
                  key: ValueKey('bg_chat_$imageUrl'),
                ),
              ),
              // 顶部模糊蒙版层 - 独立的模糊层，不影响主背景
              _buildBlurOverlay(imageUrl),
            ],
          ),
        );
      }

      // Tab 1 和 2（角色、模型）：使用 rolebg.png
      return Positioned.fill(
        child: Image.asset(
          'packages/flutter_roleplay/assets/svg/rolebg.png',
          fit: BoxFit.cover,
        ),
      );
    });
  }

  /// 构建顶部渐进式模糊蒙版
  /// 固定高度120，渐进式模糊效果
  Widget _buildBlurOverlay(String imageUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            children: [
              // 创建一个独立的背景图片层，只显示顶部120高度的部分
              // 使用 ClipRect 裁剪，只显示顶部区域
              Positioned.fill(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 120,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: ChatPageBuilders.buildImageWidget(
                          imageUrl,
                          fit: BoxFit.cover,
                          key: ValueKey('bg_blur_$imageUrl'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 添加颜色渐变遮罩以增强视觉效果
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    // 使用渐变遮罩实现渐进式效果
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4), // 顶部40%透明度
                        Colors.black.withValues(alpha: 0.3), // 中间30%
                        Colors.black.withValues(alpha: 0.15), // 中间15%
                        Colors.black.withValues(alpha: 0.05), // 底部5%
                        Colors.transparent, // 完全透明
                      ],
                      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建TabBar - 完全透明，只显示文字
  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Colors.transparent, // 完全透明
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          return Row(
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
                  child: ClippedGlassContainer(
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
              // 自定义 TabBar（玻璃态效果）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassTab(
                          label: roleName.value.isNotEmpty
                              ? roleName.value
                              : '聊天',
                          index: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGlassTab(label: '角色', index: 1)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGlassTab(label: '模型', index: 2)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// 构建玻璃态 Tab
  Widget _buildGlassTab({required String label, required int index}) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.tabController.animateTo(index);
      },
      child: isSelected
          ? ClippedGlassContainer(
              fallbackBlur: 63.1,
              color: Colors.black.withValues(alpha: 0.35),
              hasGradient: true,
              borderRadius: 70,
              borderWidth: 0.5,
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
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
