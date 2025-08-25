import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_controller.dart';
import '../new/createrole_page.dart';
import '../tabs/home_page.dart';
import '../tabs/messages_page.dart';
import '../tabs/discover_page.dart';
import '../tabs/profile_page.dart';

class MainPage extends GetView<MainPageController> {
  const MainPage({super.key});

  static const double bottomBarHeight = 60.0; // 底部导航高度
  static const double inputBarHeight = 56.0; // 输入框高度

  @override
  Widget build(BuildContext context) {
    Get.put(MainPageController());
    return Obx(() {
      return Scaffold(
        // 让键盘出现时可以调整布局
        resizeToAvoidBottomInset: true,
        // 让输入框可以延伸到导航栏上方
        extendBody: true,
        body: Stack(
          children: [
            // 背景图片 - 覆盖整个页面包括tabbar区域
            Positioned.fill(
              child: Image.asset(
                'assets/images/common_bg.webp',
                fit: BoxFit.cover,
              ),
            ),

            // 底部模糊效果 - 只对底部50px进行高斯模糊
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 210 + MediaQuery.of(context).padding.bottom,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 主要内容区 - 为底部导航栏预留空间
            Positioned.fill(
              bottom: (bottomBarHeight + MediaQuery.of(context).padding.bottom),
              child: IndexedStack(
                index: controller.currentIndex.value,
                children: const [
                  HomePage(),
                  MessagesPage(),
                  DiscoverPage(),
                  ProfilePage(),
                ],
              ),
            ),

            // // 全局输入框（悬浮在导航栏上方）
            // if (shouldShowInput)
            //   GlobalInputBar(
            //     bottomBarHeight: bottomBarHeight + MediaQuery.of(context).padding.bottom,
            //     height: inputBarHeight,
            //   ),
          ],
        ),
        // 底部导航栏始终显示 - 带毛玻璃效果
        bottomNavigationBar: Container(
          height: bottomBarHeight + MediaQuery.of(context).padding.bottom,
          // 完全透明的背景，没有任何装饰
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              _BottomTab(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
                index: 0,
                controller: controller,
              ),
              _BottomTab(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '消息',
                index: 1,
                controller: controller,
              ),
              _CenterAddButton(
                onTap: () => Get.to(() => const CreateRolePage()),
              ),
              _BottomTab(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: '发现',
                index: 2,
                controller: controller,
              ),
              _BottomTab(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                index: 3,
                controller: controller,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.controller,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final MainPageController controller;

  @override
  Widget build(BuildContext context) {
    final bool isActive = controller.currentIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: Container(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // 方形圆角
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(12), // 方形圆角
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
