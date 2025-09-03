import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_page.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../constant/constant.dart';

class CreateRoleController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final RxBool canSubmit = false.obs;
  final RxBool isCreating = false.obs; // 创建状态
  final RxInt descLength = 0.obs;
  final RxString selectedLanguage = 'zh-CN'.obs; // 默认中文
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString imageUrl = ''.obs;
  static const int descMaxLength = 600;

  // 数据库辅助类
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImagePicker _imagePicker = ImagePicker();

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
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      Get.snackbar(
        'tip_title'.tr,
        'language_switch_english'.tr,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // 选择图片
  Future<void> selectImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        // 保存图片到应用目录
        final savedImagePath = await _saveImageToAppDirectory(
          File(pickedFile.path),
        );
        imageUrl.value = savedImagePath;
        Get.snackbar(
          'tip_title'.tr,
          'image_selected_success'.tr,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'tip_title'.tr,
        'image_select_failed'.trParams({'error': e.toString()}),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // 保存图片到应用目录
  Future<String> _saveImageToAppDirectory(File imageFile) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String roleImagesDir = path.join(appDir.path, 'role_images');

    // 创建目录如果不存在
    final Directory dir = Directory(roleImagesDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 生成唯一文件名
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final String newPath = path.join(roleImagesDir, fileName);

    // 复制文件
    await imageFile.copy(newPath);
    return newPath;
  }

  // 移除选中的图片
  void removeSelectedImage() {
    selectedImage.value = null;
    imageUrl.value = '';
  }

  Future<void> onConfirm() async {
    final String n = nameController.text.trim();
    final String d = descController.text.trim();

    if (n.isEmpty || d.isEmpty) {
      Get.snackbar(
        'tip_title'.tr,
        'incomplete_info'.tr,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // 检查是否已存在同名角色
    final existingRoles = await _dbHelper.getRoles();
    final duplicateRole = existingRoles.firstWhereOrNull(
      (role) => role.name == n,
    );
    if (duplicateRole != null) {
      Get.snackbar(
        'tip_title'.tr,
        'duplicate_role_name'.tr,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (descLength.value > descMaxLength) {
      Get.snackbar(
        'tip_title'.tr,
        'description_too_long'.trParams({'count': descMaxLength.toString()}),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      isCreating.value = true;

      // 创建自定义角色模型
      debugPrint('CreateRoleController: 准备创建角色');
      debugPrint('  - 角色名称: $n');
      debugPrint('  - 角色描述长度: ${d.length}');
      debugPrint('  - 选择的图片路径: ${imageUrl.value}');
      debugPrint('  - 图片路径是否为空: ${imageUrl.value.isEmpty}');

      // 确保图片路径正确传递，如果没有选择图片则传递null
      final String? finalImagePath = imageUrl.value.isNotEmpty
          ? imageUrl.value
          : null;
      debugPrint('  - 最终图片路径: $finalImagePath');

      final customRole = RoleModel.createCustom(
        id: 0, // 临时ID，保存时会生成真实ID
        name: n,
        description: d,
        language: selectedLanguage.value,
        image: finalImagePath,
      );

      debugPrint('CreateRoleController: 创建的角色模型');
      debugPrint('  - 角色图片路径: ${customRole.image}');

      // 保存到本地数据库
      final roleId = await _dbHelper.saveCustomRole(customRole);
      debugPrint('自定义角色已保存，ID: $roleId');

      // 更新全局状态 - 直接使用本地图片路径，不依赖 customRole.image
      roleName.value = n;
      roleDescription.value = d;
      roleImage.value =
          finalImagePath ??
          'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common.webp';
      roleLanguage.value = selectedLanguage.value;

      debugPrint('CreateRoleController: 角色创建完成');
      debugPrint('CreateRoleController: 角色名称: $n');
      debugPrint('CreateRoleController: finalImagePath: $finalImagePath');
      debugPrint('CreateRoleController: customRole.image: ${customRole.image}');
      debugPrint('CreateRoleController: 本地图片URL: ${imageUrl.value}');
      debugPrint(
        'CreateRoleController: 设置的roleImage.value: ${roleImage.value}',
      );

      // 验证图片文件是否存在
      if (imageUrl.value.isNotEmpty) {
        final file = File(imageUrl.value);
        debugPrint('CreateRoleController: 图片文件是否存在: ${file.existsSync()}');
        if (!file.existsSync()) {
          debugPrint('CreateRoleController: 警告 - 图片文件不存在: ${imageUrl.value}');
        }
      }

      // 创建角色映射数据 - 使用与全局状态相同的图片路径
      final String finalRoleImage =
          finalImagePath ??
          'https://download.rwkvos.com/rwkvmusic/downloads/1.0/common.webp';
      final roleMap = {
        'name': n,
        'description': d,
        'image': finalRoleImage,
        'language': selectedLanguage.value,
        'isCustom': true,
        'id': roleId,
      };

      debugPrint('CreateRoleController: 创建角色映射数据');
      debugPrint('  - finalImagePath: $finalImagePath');
      debugPrint('  - finalRoleImage: $finalRoleImage');
      debugPrint('  - roleMap[image]: ${roleMap['image']}');
      debugPrint('  - customRole.image: ${customRole.image}');

      // 切换到新创建的角色
      CommonUtil.switchToRole(roleMap);

      // switchToRole 内部已经处理了控制器的清理，这里不需要重复清理
      debugPrint('CreateRoleController: 角色切换完成，准备跳转到聊天页面');

      // 强制触发响应式更新
      usedRoles.refresh();
      roleName.refresh();
      roleImage.refresh();
      roleDescription.refresh();

      // 显示成功提示
      Get.snackbar(
        'create_success_title'.tr,
        'create_success_message'.trParams({'name': n}),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      // 延迟一点时间确保状态更新完成，然后跳转到聊天页面
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('CreateRoleController: 准备跳转到聊天页面');
      debugPrint('  - 跳转前 roleName.value: ${roleName.value}');
      debugPrint('  - 跳转前 roleImage.value: ${roleImage.value}');
      debugPrint('  - 跳转前 usedRoles.length: ${usedRoles.length}');

      // 使用 Get.offAll 替换所有页面，确保完全重建
      Get.offAll(
        () => const RolePlayChat(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('创建角色失败: $e');
      Get.snackbar(
        'create_failed_title'.tr,
        'create_failed_message'.trParams({'error': e.toString()}),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
