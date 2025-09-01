import 'package:flutter/material.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import '../../constant/constant.dart';

class CreateRoleController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final RxBool canSubmit = false.obs;
  final RxBool isCreating = false.obs; // 创建状态
  final RxInt descLength = 0.obs;
  final RxString selectedLanguage = 'zh-CN'.obs; // 默认中文
  static const int descMaxLength = 600;

  // 数据库辅助类
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    // 输入框初始化为空，让用户从头开始创建新角色
    nameController.text = '';
    descController.text = '';

    descLength.value = 0;
    _recomputeCanSubmit();

    nameController.addListener(_recomputeCanSubmit);
    descController.addListener(() {
      descLength.value = descController.text.characters.length;
      _recomputeCanSubmit();
    });
  }

  void _recomputeCanSubmit() {
    final String n = nameController.text.trim();
    final String d = descController.text.trim();
    canSubmit.value = n.isNotEmpty && d.isNotEmpty;
  }

  // 切换语言选择
  void selectLanguage(String language) {
    selectedLanguage.value = language;
    if (language == 'zh-CN') {
      Get.snackbar(
        'tip_title'.tr,
        'language_switch_chinese'.tr,
        colorText: Colors.redAccent,
      );
    } else {
      Get.snackbar(
        'tip_title'.tr,
        'language_switch_english'.tr,
        colorText: Colors.redAccent,
      );
    }
  }

  Future<void> onConfirm() async {
    final String n = nameController.text.trim();
    final String d = descController.text.trim();

    if (n.isEmpty || d.isEmpty) {
      Get.snackbar(
        'tip_title'.tr,
        'incomplete_info'.tr,
        duration: Duration(seconds: 2),
      );
      return;
    }

    if (descLength.value > descMaxLength) {
      Get.snackbar(
        'tip_title'.tr,
        'description_too_long'.trParams({'count': descMaxLength.toString()}),
        duration: Duration(seconds: 2),
      );
      return;
    }

    try {
      isCreating.value = true;

      // 创建自定义角色模型
      final customRole = RoleModel.createCustom(
        id: 0, // 临时ID，保存时会生成真实ID
        name: n,
        description: d,
        language: selectedLanguage.value,
      );

      // 保存到本地数据库
      final roleId = await _dbHelper.saveCustomRole(customRole);
      debugPrint('自定义角色已保存，ID: $roleId');

      // 更新全局状态
      roleName.value = n;
      roleDescription.value = d;
      roleImage.value = customRole.image; // 设置默认头像
      roleLanguage.value = selectedLanguage.value;

      // 创建角色映射数据
      final roleMap = {
        'name': n,
        'description': d,
        'image': customRole.image,
        'language': selectedLanguage.value,
        'isCustom': true,
        'id': roleId,
      };

      // 切换到新创建的角色
      CommonUtil.switchToRole(roleMap);

      // 清理聊天状态
      RolePlayChatController? controller;
      if (Get.isRegistered<RolePlayChatController>()) {
        controller = Get.find<RolePlayChatController>();
      } else {
        controller = Get.put(RolePlayChatController());
      }
      controller?.clearStates();

      // 返回结果并显示成功提示
      Get.back(result: roleMap);

      Get.snackbar(
        'create_success_title'.tr,
        'create_success_message'.trParams({'name': n}),
        duration: Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.8),
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      debugPrint('创建角色失败: $e');
      Get.snackbar(
        'create_failed_title'.tr,
        'create_failed_message'.trParams({'error': e.toString()}),
        duration: Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.8),
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isCreating.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }
}
