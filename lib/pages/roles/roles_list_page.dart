import 'package:flutter/material.dart';
import 'package:flutter_roleplay/widgets/clipped_glass_container_static.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_controller.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';
import 'package:flutter_roleplay/widgets/chat_page_builders.dart';

class RolesListPage extends StatelessWidget {
  RolesListPage({super.key});
  final controller = Get.find<RolesListController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(context),
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

      return Stack(
        children: [
          Column(
            children: [
              // //测试
              // TestContainer(
              //   blur: 100,
              //   color: Colors.black.withValues(alpha: 0.35),
              //   hasGradient: true,
              //   borderRadius: 90,
              //   borderWidth: 0.5,
              // ),
              const SizedBox(height: 100),
              // 顶部欢迎文本
              _buildWelcomeHeader(),
              // 角色列表 - GridView
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
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            88,
                          ), // 增加底部 padding 为悬浮按钮留出空间
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // 2列
                                  crossAxisSpacing: 12, // 列间距
                                  mainAxisSpacing: 12, // 行间距
                                  childAspectRatio: 0.7, // 调整宽高比，让卡片更高
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final role = displayRoles[index];
                              return _RoleGridCard(
                                role: role,
                                onTap: () =>
                                    controller.selectRole(role, context),
                                onDelete: () =>
                                    controller.deleteCustomRole(role, context),
                              );
                            }, childCount: displayRoles.length),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
          // 悬浮在底部的创建角色按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCreateRoleButton(context),
          ),
        ],
      );
    });
  }

  /// 构建欢迎头部
  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
              Image.asset(
                'packages/flutter_roleplay/assets/svg/roleicon.png',
                width: 36,
                height: 36,
              ),
              Text(
                'roleplay'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'roleplay_description'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.45),
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
            child: ClippedGlassContainerStatic(
              fallbackBlur: 63.1,
              color: Colors.black.withValues(alpha: 0.35),
              hasGradient: true,
              borderRadius: 70,
              borderWidth: 0.5,
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'create_my_role'.tr,
                  style: const TextStyle(
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
      onLongPress: role.isCustom ? () => _showDeleteDialog(context) : null,
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
                          color: Colors.white,
                          fontSize: 14,
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

              // 更多按钮（仅自定义角色且非当前使用的角色显示）
              if (role.isCustom)
                Obx(
                  () => roleName.value != role.name
                      ? Positioned(
                          top: 10,
                          right: 10,
                          child: _buildMoreButton(context),
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
                    child: Text(
                      'custom'.tr,
                      style: const TextStyle(
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
    // 如果有图片路径，使用 ChatPageBuilders 的缓存图片加载
    if (role.image.isNotEmpty) {
      return ChatPageBuilders.buildImageWidget(role.image, fit: BoxFit.cover);
    }
    // 没有图片时显示渐变背景
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

  /// 构建更多按钮
  Widget _buildMoreButton(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
        shape: BoxShape.circle,
        // border: Border.all(
        //   color: Colors.white.withValues(alpha: 0.15),
        //   width: 0.5,
        // ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.4),
        //     blurRadius: 8,
        //     spreadRadius: 0,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          color: Colors.white.withValues(alpha: 0.95),
          size: 16,
        ),
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        offset: const Offset(-8, 36),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            padding: EdgeInsets.zero,
            value: 'container',
            enabled: false,
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.edit_rounded,
                      label: 'edit'.tr,
                      color: Colors.blue.shade400,
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToEditPage(context);
                      },
                    ),
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.delete_rounded,
                      label: 'delete'.tr,
                      color: Colors.red.shade400,
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showDeleteDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        onSelected: (_) {},
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 跳转到编辑页面
  void _navigateToEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRolePage(editRole: role)),
    ).then((_) {
      // 从编辑页面返回后刷新列表
      final controller = Get.find<RolesListController>();
      controller.loadRoles();
    });
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) => Dialog(
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
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade400,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              // 标题
              Text(
                'delete_role_title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // 内容
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: '${'delete_role_confirm_text'.tr} '),
                    TextSpan(
                      text: '"${role.name}"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' 吗？\n'),
                    TextSpan(
                      text: 'this_cannot_be_undone'.tr,
                      style: TextStyle(
                        color: Colors.red.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
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
                  // 删除按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onDelete();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red.shade600, Colors.red.shade700],
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
      ),
    );
  }
}
