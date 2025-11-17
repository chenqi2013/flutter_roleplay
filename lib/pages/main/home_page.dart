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
                child: InkWell(
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
              // TabBar
              Expanded(
                child: TabBar(
                  controller: controller.tabController,
                  indicatorColor: Colors.transparent, // 去掉指示器线
                  dividerColor: Colors.transparent, // 去掉分隔线
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(
                      text: roleName.value.isNotEmpty ? roleName.value : '聊天',
                    ),
                    const Tab(text: '角色'),
                    const Tab(text: '模型'),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
