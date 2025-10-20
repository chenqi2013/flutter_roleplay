import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';

import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/services/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../constant/constant.dart';

class CreateRoleController extends GetxController {
  RoleModel? editRole;

  CreateRoleController({this.editRole});

  /// 更新编辑角色（用于编辑不同角色时）
  void updateEditRole(RoleModel? newEditRole) {
    debugPrint('CreateRoleController: updateEditRole=${newEditRole?.name}');
    editRole = newEditRole;
    // 更新控制器数据
    if (newEditRole != null) {
      nameController.text = newEditRole.name;
      descController.text = newEditRole.description;
      selectedLanguage.value = newEditRole.language;

      // 如果有图片，设置图片URL
      if (newEditRole.image.isNotEmpty) {
        imageUrl.value = newEditRole.image;
      } else {
        imageUrl.value = '';
      }
    } else {
      // 创建模式：输入框初始化为空
      nameController.text = '';
      descController.text = '';
      imageUrl.value = '';
    }

    descLength.value = descController.text.characters.length;
    _recomputeCanSubmit();
  }

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
    debugPrint('CreateRoleController onInit: editRole=${editRole?.name}');

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
  void selectLanguage(String language, BuildContext context) {
    selectedLanguage.value = language;
    if (language == 'zh-CN') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language_switch_chinese'.tr),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language_switch_english'.tr),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 选择图片
  Future<void> selectImage(BuildContext context) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('image_selected_success'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'image_select_failed'.trParams({'error': e.toString()}),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
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

  Future<void> onConfirm(BuildContext context) async {
    final String n = nameController.text.trim();
    final String d = descController.text.trim();

    if (n.isEmpty || d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('incomplete_info'.tr),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 只在创建模式下检查是否已存在同名角色
    if (editRole == null) {
      final existingRoles = await _dbHelper.getRoles();
      final duplicateRole = existingRoles.firstWhereOrNull(
        (role) => role.name == n,
      );
      if (duplicateRole != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('duplicate_role_name'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (descLength.value > descMaxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'description_too_long'.trParams({
              'count': descMaxLength.toString(),
            }),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      isCreating.value = true;

      final bool isEditMode = editRole != null;
      debugPrint('CreateRoleController: ${isEditMode ? '准备更新' : '准备创建'}角色');
      debugPrint('  - 角色名称: $n');
      debugPrint('  - 角色描述长度: ${d.length}');
      debugPrint('  - 选择的图片路径: ${imageUrl.value}');
      debugPrint('  - 图片路径是否为空: ${imageUrl.value.isEmpty}');

      // 确保图片路径正确传递，如果没有选择图片则传递null
      final String? finalImagePath = imageUrl.value.isNotEmpty
          ? imageUrl.value
          : null;
      debugPrint('  - 最终图片路径: $finalImagePath');

      late final RoleModel customRole;
      late final int roleId;

      if (isEditMode) {
        // 编辑模式：更新现有角色
        customRole = RoleModel.createCustom(
          id: editRole!.id,
          name: n,
          description: d,
          language: selectedLanguage.value,
          image: finalImagePath,
        );

        await _dbHelper.updateCustomRole(customRole);
        roleId = editRole!.id;
        debugPrint('自定义角色已更新，ID: $roleId');
      } else {
        // 创建模式：新建角色
        customRole = RoleModel.createCustom(
          id: 0, // 临时ID，保存时会生成真实ID
          name: n,
          description: d,
          language: selectedLanguage.value,
          image: finalImagePath,
        );

        roleId = await _dbHelper.saveCustomRole(customRole);
        debugPrint('自定义角色已保存，ID: $roleId');
      }

      debugPrint('CreateRoleController: ${isEditMode ? '更新' : '创建'}的角色模型');
      debugPrint('  - 角色图片路径: ${customRole.image}');

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

      // 先切换到新创建的角色，这会更新全局状态和usedRoles列表
      CommonUtil.switchToRole(roleMap);

      // switchToRole 内部已经处理了控制器的清理，这里不需要重复清理
      debugPrint('CreateRoleController: 角色切换完成，准备跳转到聊天页面');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'edit_success_message'.trParams({'name': n})
                : 'create_success_message'.trParams({'name': n}),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 延迟一点时间确保状态更新完成，然后返回到聊天页面
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('CreateRoleController: 准备返回到聊天页面');
      debugPrint('  - 返回前 roleName.value: ${roleName.value}');
      debugPrint('  - 返回前 roleImage.value: ${roleImage.value}');
      debugPrint('  - 返回前 usedRoles.length: ${usedRoles.length}');

      // 使用Flutter原生导航返回，不清除导航栈
      Navigator.of(context).pop(roleMap);
    } catch (e) {
      debugPrint('创建角色失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'create_failed_message'.trParams({'error': e.toString()}),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
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
