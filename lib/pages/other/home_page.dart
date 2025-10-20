import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/chat/roleplay_chat_page.dart';
import '../main/main_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mainController = Get.find<MainPageController>();

    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          // 监听Tab变化并通知MainPageController
          tabController.addListener(() {
            mainController.setHomeTabIndex(tabController.index);
          });

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // 顶部栏（带渐变）
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          tabs: const [
                            Tab(text: '助理'),
                            Tab(text: 'FM'),
                            Tab(text: '综合'),
                            Tab(text: '精选'),
                          ],
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          overlayColor: const WidgetStatePropertyAll<Color?>(
                            Colors.transparent,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search, color: Colors.white),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),

                // 内容区
                Expanded(
                  child: TabBarView(
                    children: [
                      // 助理
                      _Section(title: '助理功能', sub: '这里是助理相关的功能和内容'),
                      // FM
                      _Section(title: 'FM功能', sub: '这里是FM相关的功能和内容'),
                      // 综合
                      _Section(title: '综合功能', sub: '这里是综合相关的功能和内容'),
                      // 精选
                      RolePlayChat(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 简单的段落块
class _Section extends StatelessWidget {
  final String title;
  final String sub;
  const _Section({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
