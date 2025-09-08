import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/pages/roles/roles_list_controller.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/pages/new/createrole_page.dart';

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
              onDelete: () => controller.deleteCustomRole(role, context),
            );
          },
        ),
      );
    });
  }
}

class _RoleCard extends StatefulWidget {
  final RoleModel role;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isExpanded = false;

  /// 检查文本是否超过指定行数
  bool _isTextOverflowing(
    String text,
    TextStyle style,
    int maxLines,
    double maxWidth,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('role_${widget.role.id}'),
      direction: widget.role.isCustom
          ? DismissDirection.endToStart
          : DismissDirection.none,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.25, // 侧滑到1/4位置就触发
      },
      confirmDismiss: (direction) async {
        if (!widget.role.isCustom) return false;
        return await _showDeleteConfirmDialog();
      },
      onDismissed: (direction) {
        widget.onDelete();
      },
      background: widget.role.isCustom
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
          onTap: widget.onTap,
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
                        widget.role.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 当前角色选中标识
                    Obx(
                      () => roleName.value == widget.role.name
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            )
                          : const SizedBox.shrink(),
                    ),
                    // 自定义角色操作按钮
                    if (widget.role.isCustom) ...[
                      const SizedBox(width: 8),
                      // 编辑按钮
                      GestureDetector(
                        onTap: () => _handleEditButtonTap(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 删除按钮
                      GestureDetector(
                        onTap: () => _handleDeleteButtonTap(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildDescription(),
                // const SizedBox(height: 8),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     Text(
                //       'tap_to_select'.tr,
                //       style: TextStyle(
                //         color: Colors.blue.shade600,
                //         fontSize: 12,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //     const SizedBox(width: 4),
                //     Icon(
                //       Icons.arrow_forward_ios,
                //       size: 12,
                //       color: Colors.blue.shade600,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示删除角色确认对话框
  Future<bool> _showDeleteConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('delete_confirm_title'.tr),
              content: Text(
                'delete_role_confirm'.trParams({'name': widget.role.name}),
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
  }

  /// 处理右上角编辑按钮点击
  void _handleEditButtonTap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRolePage(editRole: widget.role),
      ),
    );

    // 如果编辑成功，刷新角色列表
    if (result != null) {
      // 获取控制器并刷新列表
      final controller = Get.find<RolesListController>();
      controller.loadRoles();
    }
  }

  /// 处理右上角删除按钮点击
  Future<void> _handleDeleteButtonTap() async {
    final confirmed = await _showDeleteConfirmDialog();
    if (confirmed) {
      widget.onDelete();
    }
  }

  /// 构建可展开的描述组件
  Widget _buildDescription() {
    final descriptionStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 14,
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 检查文本是否超过4行
        final isOverflowing = _isTextOverflowing(
          widget.role.description,
          descriptionStyle,
          4,
          constraints.maxWidth,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.role.description,
              style: descriptionStyle,
              maxLines: _isExpanded ? null : 4,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            // 只有当文本超过4行时才显示展开/收起按钮
            if (isOverflowing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isExpanded ? 'collapse'.tr : 'expand'.tr,
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
