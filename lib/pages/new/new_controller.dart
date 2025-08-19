import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/hometabs/jingxuan_controller.dart';
import '../../constant/constant.dart';

class NewController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final RxBool canSubmit = false.obs;
  final RxInt descLength = 0.obs;
  static const int descMaxLength = 600;

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

  void onConfirm() {
    final String n = nameController.text.trim();
    final String d = descController.text.trim();
    if (n.isEmpty || d.isEmpty) {
      Get.snackbar('提示', '请完整填写角色名称与设定');
      return;
    }
    if (descLength.value > descMaxLength) {
      Get.snackbar('提示', '角色设定过长，建议精炼至 $descMaxLength 字以内');
      return;
    }
    roleName.value = n;
    roleDescription.value = d;

    Get.back(result: {'name': n, 'desc': d});
    Get.snackbar('已创建', '新角色"$n"已创建成功，聊天记录已清空');
    JingxuanController? _controller;
    if (Get.isRegistered<JingxuanController>()) {
      _controller = Get.find<JingxuanController>();
    } else {
      _controller = Get.put(JingxuanController());
    }

    _controller?.clearStates();
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }
}
