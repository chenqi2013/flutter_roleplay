import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/main/home_controller.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_page.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_page.dart';
import 'package:flutter_roleplay/pages/params/model_params_page.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 动态背景层
          _buildDynamicBackground(),
          // 前景内容
          Column(
            children: [
              // 顶部TabBar
              _buildTabBar(),
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
    );
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
        return Positioned.fill(
          child: ChatPageBuilders.buildImageWidget(
            imageUrl,
            fit: BoxFit.cover,
            key: ValueKey('bg_chat_$imageUrl'),
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

  // 构建TabBar - 完全透明，只显示文字
  Widget _buildTabBar() {
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
                    Navigator.of(currentContext!).pop();
                  },
                  child: GlassContainer(
                    borderRadius: 20,
                    borderWidth: 0,
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      'packages/flutter_roleplay/assets/svg/close.svg',
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
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
          ? GlassContainer(
              borderRadius: 70,
              borderWidth: 2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
    );
  }
}
