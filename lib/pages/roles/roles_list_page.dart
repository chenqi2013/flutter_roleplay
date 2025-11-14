import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_controller.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';

class RolesListPage extends StatelessWidget {
  RolesListPage({super.key});
  final controller = Get.find<RolesListController>();
  @override
  Widget build(BuildContext context) {
    // // 每次进入页面时刷新角色列表，确保显示最新的角色数据
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   controller.loadRoles();
    // });
    return Scaffold(
      appBar: AppBar(
        title: Text('roles_list_title'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        );
      }

      if (controller.error.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'load_failed'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: controller.retryLoad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: Text('retry_button'.tr),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // 顶部欢迎文本
          _buildWelcomeHeader(),
          // 角色列表 - GridView + 底部按钮
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshRoles,
              child: Obx(() {
                final displayRoles = controller.displayRoles;
                if (displayRoles.isEmpty &&
                    controller.searchQuery.value.isNotEmpty) {
                  // 显示无搜索结果
                  return _buildNoSearchResults();
                }
                return CustomScrollView(
                  slivers: [
                    // GridView 角色列表
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2列
                              crossAxisSpacing: 12, // 列间距
                              mainAxisSpacing: 12, // 行间距
                              childAspectRatio: 0.7, // 调整宽高比，让卡片更高
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final role = displayRoles[index];
                          return _RoleGridCard(
                            role: role,
                            onTap: () => controller.selectRole(role, context),
                            onDelete: () =>
                                controller.deleteCustomRole(role, context),
                          );
                        }, childCount: displayRoles.length),
                      ),
                    ),
                    // 底部创建角色按钮
                    SliverToBoxAdapter(child: _buildCreateRoleButton(context)),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    });
  }

  /// 构建欢迎头部
  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hi,欢迎来到',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
              Image.asset(
                'packages/flutter_roleplay/assets/svg/roleicon.png',
                width: 36,
                height: 36,
              ),
              Text(
                '扮演',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '请选择你想对话的角色或创建角色。',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.45),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部创建角色按钮
  Widget _buildCreateRoleButton(BuildContext context) {
    return SafeArea(
      child: Center(
        child: GestureDetector(
          onTap: () {
            // 跳转到创建角色页面
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateRolePage()),
            ).then((_) {
              // 从创建页面返回后刷新列表
              controller.loadRoles();
            });
          },
          child: SizedBox(
            width: 126,
            height: 48,
            child: GlassContainer(
              borderRadius: 70,
              borderWidth: 0.5,
              child: const Center(
                child: Text(
                  '创建我的角色',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).marginOnly(bottom: 20);
  }

  /// 构建搜索框（已注释）
  // Widget _buildSearchBar() {
  //   return Container(
  //     margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withValues(alpha: 0.9),
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.1),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Obx(
  //       () => TextField(
  //         onChanged: controller.searchRoles,
  //         decoration: InputDecoration(
  //           hintText: 'search_roles_hint'.tr,
  //           prefixIcon: const Icon(Icons.search, color: Colors.grey),
  //           suffixIcon: controller.searchQuery.value.isNotEmpty
  //               ? IconButton(
  //                   icon: const Icon(Icons.clear, color: Colors.grey),
  //                   onPressed: controller.clearSearch,
  //                 )
  //               : null,
  //           border: InputBorder.none,
  //           contentPadding: const EdgeInsets.symmetric(
  //             horizontal: 16,
  //             vertical: 12,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// 构建无搜索结果页面
  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'no_search_results'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'search_query_hint'.trParams({
                'query': controller.searchQuery.value,
              }),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.clearSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('clear_search'.tr),
          ),
        ],
      ),
    );
  }
}

/// GridView 角色卡片（图片背景 + 底部信息）
class _RoleGridCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoleGridCard({
    required this.role,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: role.isCustom ? _showDeleteDialog : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景图片
              _buildBackgroundImage(),

              // 渐变遮罩（从透明到黑色）
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // 底部信息
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 角色名字
                      Text(
                        role.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 角色简介
                      Text(
                        role.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 选中标识
              Obx(
                () => roleName.value == role.name
                    ? Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 自定义角色标识
              if (role.isCustom)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      '自定义',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildBackgroundImage() {
    // 如果有图片路径，显示图片，否则显示渐变背景
    if (role.image.isNotEmpty) {
      return Image.network(
        role.image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // 加载失败时显示默认渐变背景
          return _buildGradientBackground();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildGradientBackground();
        },
      );
    }
    return _buildGradientBackground();
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.6),
            Colors.blue.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 64,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定要删除角色 "${role.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Get.back();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
