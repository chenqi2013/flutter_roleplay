import 'package:get/get.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/services/role_api_service.dart';
import 'package:flutter_roleplay/constant/constant.dart';

class RolesListController extends GetxController {
  // 响应式状态变量
  final RxList<RoleModel> roles = <RoleModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRoles();
  }

  /// 加载角色列表
  Future<void> loadRoles() async {
    try {
      isLoading.value = true;
      error.value = '';

      final roleList = await RoleApiService.getRoles();

      roles.value = roleList;
      isLoading.value = false;
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
    }
  }

  /// 选择角色
  void selectRole(RoleModel role) {
    // 使用统一的切换角色函数
    switchToRole(role.toMap());

    // 返回上一页
    Get.back();

    // 显示选择成功的提示
    Get.snackbar(
      '角色切换',
      '已切换到 ${role.name}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  /// 刷新角色列表
  Future<void> refreshRoles() async {
    await loadRoles();
  }

  /// 重试加载
  void retryLoad() {
    loadRoles();
  }

  /// 检查角色是否为当前角色
  bool isCurrentRole(String roleNameToCheck) {
    return roleNameToCheck == roleName.value;
  }
}
