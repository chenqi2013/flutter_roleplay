import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_controller.dart';
import 'package:flutter_roleplay/models/role_model.dart';

class RolesListPage extends GetView<RolesListController> {
  const RolesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 Controller 被注册
    final controller = Get.put(RolesListController());

    // 每次进入页面时刷新角色列表，确保显示最新的角色数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRoles();
    });
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

      return RefreshIndicator(
        onRefresh: controller.refreshRoles,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.roles.length,
          itemBuilder: (context, index) {
            final role = controller.roles[index];
            return _RoleCard(
              role: role,
              onTap: () => controller.selectRole(role, context),
              onDelete: () => controller.deleteCustomRole(role),
            );
          },
        ),
      );
    });
  }
}

class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('role_${role.id}'),
      direction: role.isCustom
          ? DismissDirection.endToStart
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.25, // 侧滑到1/4位置就触发
      },
      confirmDismiss: (direction) async {
        if (!role.isCustom) return false;

        // 显示删除确认对话框
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('delete_confirm_title'.tr),
                  content: Text(
                    'delete_role_confirm'.trParams({'name': role.name}),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('delete'.tr),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: role.isCustom
          ? Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            )
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.grey.shade50.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => roleName.value == role.name
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  role.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 100,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'tap_to_select'.tr,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
