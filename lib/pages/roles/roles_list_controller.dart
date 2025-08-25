import 'package:flutter_roleplay/util/common_util.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/services/role_api_service.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:flutter_roleplay/constant/constant.dart';

class RolesListController extends GetxController {
  // 响应式状态变量
  final RxList<RoleModel> roles = <RoleModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxBool isLoadingFromCache = false.obs;

  // 数据库辅助类
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    loadRoles();
  }

  /// 加载角色列表 - 优先从网络获取，失败时从本地加载
  Future<void> loadRoles() async {
    try {
      isLoading.value = true;
      error.value = '';

      // 首先尝试从网络加载
      await _loadFromNetwork();
    } catch (e) {
      debugPrint('网络加载失败: $e');
      // 网络加载失败，尝试从本地缓存加载
      await _loadFromCache();
    }
  }

  /// 从网络加载角色列表
  Future<void> _loadFromNetwork() async {
    try {
      debugPrint('正在从网络加载角色列表...');
      final apiRoles = await RoleApiService.getRoles();

      // 保存API角色到本地缓存 (会保留现有的自定义角色)
      await _dbHelper.saveRoles(apiRoles);

      // 重新从本地数据库加载所有角色 (包括API和自定义角色，自定义角色在前)
      final allRoles = await _dbHelper.getRoles();

      roles.value = allRoles;
      isLoading.value = false;
      error.value = '';

      debugPrint('成功从网络加载 ${apiRoles.length} 个API角色，总角色数: ${allRoles.length}');
    } catch (e) {
      debugPrint('网络加载角色失败: $e');
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  /// 从本地缓存加载角色列表
  Future<void> _loadFromCache() async {
    try {
      isLoadingFromCache.value = true;
      debugPrint('正在从本地缓存加载角色列表...');

      final cachedRoles = await _dbHelper.getRoles();

      if (cachedRoles.isNotEmpty) {
        roles.value = cachedRoles;
        error.value = ''; // 清空错误信息

        // // 显示从缓存加载的提示
        // Get.snackbar(
        //   '离线模式',
        //   '已从本地缓存加载 ${cachedRoles.length} 个角色',
        //   snackPosition: SnackPosition.TOP,
        //   duration: const Duration(seconds: 3),
        //   backgroundColor: Get.theme.colorScheme.secondary.withValues(
        //     alpha: 0.8,
        //   ),
        //   colorText: Get.theme.colorScheme.onSecondary,
        // );

        debugPrint('成功从本地缓存加载 ${cachedRoles.length} 个角色');
      } else {
        error.value = '网络连接失败，且本地无缓存数据';
        debugPrint('本地缓存为空，无法加载角色');
      }

      isLoading.value = false;
      isLoadingFromCache.value = false;
    } catch (e) {
      debugPrint('从本地缓存加载角色失败: $e');
      error.value = '加载失败: ${e.toString()}';
      isLoading.value = false;
      isLoadingFromCache.value = false;
    }
  }

  /// 选择角色
  void selectRole(RoleModel role) {
    // 使用统一的切换角色函数
    CommonUtil.switchToRole(role.toMap());

    // 返回上一页
    Get.back();

    // // 显示选择成功的提示
    // Get.snackbar(
    //   '角色切换',
    //   '已切换到 ${role.name}',
    //   snackPosition: SnackPosition.TOP,
    //   duration: const Duration(seconds: 2),
    //   backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.8),
    //   colorText: Get.theme.colorScheme.onPrimary,
    // );
  }

  /// 刷新角色列表 - 强制从网络获取
  Future<void> refreshRoles() async {
    try {
      isLoading.value = true;
      error.value = '';
      await _loadFromNetwork();
    } catch (e) {
      // 刷新时如果网络失败，仍然尝试从缓存加载
      await _loadFromCache();
    }
  }

  /// 重试加载
  void retryLoad() {
    loadRoles();
  }

  /// 仅从本地缓存加载（用于离线模式）
  Future<void> loadFromCacheOnly() async {
    await _loadFromCache();
  }

  /// 检查是否有本地缓存
  Future<bool> hasLocalCache() async {
    return await _dbHelper.hasLocalRoleData();
  }

  /// 获取缓存信息
  Future<String> getCacheInfo() async {
    final hasCache = await _dbHelper.hasLocalRoleData();
    if (!hasCache) {
      return '无本地缓存';
    }

    final count = await _dbHelper.getRoleCount();
    final lastUpdate = await _dbHelper.getLastUpdateTime();

    if (lastUpdate != null) {
      final duration = DateTime.now().difference(lastUpdate);
      String timeAgo;
      if (duration.inDays > 0) {
        timeAgo = '${duration.inDays}天前';
      } else if (duration.inHours > 0) {
        timeAgo = '${duration.inHours}小时前';
      } else if (duration.inMinutes > 0) {
        timeAgo = '${duration.inMinutes}分钟前';
      } else {
        timeAgo = '刚刚';
      }
      return '缓存: $count 个角色，更新于 $timeAgo';
    }

    return '缓存: $count 个角色';
  }

  /// 清空本地缓存
  Future<void> clearCache() async {
    await _dbHelper.clearRoles();
    Get.snackbar(
      '缓存清理',
      '已清空本地角色缓存',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// 检查角色是否为当前角色
  bool isCurrentRole(String roleNameToCheck) {
    return roleNameToCheck == roleName.value;
  }
}
