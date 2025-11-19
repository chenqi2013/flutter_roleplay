import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_roleplay/constant/theme.dart';
import 'package:flutter_roleplay/models/role_model.dart';
import 'package:flutter_roleplay/pages/audio/audio_list_page.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'createrole_controller.dart';

class CreateRolePage extends StatefulWidget {
  final RoleModel? editRole;

  const CreateRolePage({super.key, this.editRole});

  @override
  State<CreateRolePage> createState() => _CreateRolePageState();
}

class _CreateRolePageState extends State<CreateRolePage> {
  bool isInit = false;
  final controller = Get.find<CreateRoleController>();

  @override
  Widget build(BuildContext context) {
    if (!isInit) {
      isInit = true;
      controller.updateEditRole(widget.editRole);
    }
    final EdgeInsets safe = MediaQuery.of(context).padding;
    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: Image.asset(
                'packages/flutter_roleplay/assets/svg/rolebg.png',
                fit: BoxFit.cover,
              ),
            ),
            // 内容区域
            Column(
              children: [
                // 自定义顶部栏
                _buildTopBar(context),
                // 主要内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + safe.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 角色图片选择
                        GlassContainer(
                          borderRadius: 16,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'role_image_label'.tr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ImageSelector(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: 16,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'role_name_label'.tr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: _inputDecoration(
                                  'role_name_hint'.tr,
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: 16,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'role_language_label'.tr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'role_language_hint'.tr,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => Row(
                                  children: [
                                    Expanded(
                                      child: _LanguageOption(
                                        label: 'language_chinese'.tr,
                                        value: 'zh-CN',
                                        isSelected:
                                            controller.selectedLanguage.value ==
                                            'zh-CN',
                                        onTap: () => controller.selectLanguage(
                                          'zh-CN',
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _LanguageOption(
                                        label: 'language_english'.tr,
                                        value: 'en',
                                        isSelected:
                                            controller.selectedLanguage.value ==
                                            'en',
                                        onTap: () => controller.selectLanguage(
                                          'en',
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 音色选择
                        GlassContainer(
                          borderRadius: 16,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '角色音色',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '选择角色专属的语音音色（可选）',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    // 以 modal bottom sheet 方式弹出音色选择页面
                                    final result =
                                        await showModalBottomSheet<
                                          Map<String, dynamic>
                                        >(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.6,
                                            child: const AudioListPage(
                                              isSelectMode: true,
                                            ),
                                          ),
                                        );

                                    // 处理返回的音色数据
                                    if (result != null &&
                                        result['voice'] != null &&
                                        result['voiceTxt'] != null) {
                                      controller.setSelectedVoice(
                                        result['voice'] as String,
                                        result['voiceTxt'] as String,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            controller
                                                    .selectedVoiceTxt
                                                    .value
                                                    .isEmpty
                                                ? '点击选择音色'
                                                : controller
                                                      .selectedVoiceTxt
                                                      .value,
                                            style: TextStyle(
                                              color:
                                                  controller
                                                      .selectedVoiceTxt
                                                      .value
                                                      .isEmpty
                                                  ? Colors.white54
                                                  : Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (controller
                                            .selectedVoiceTxt
                                            .value
                                            .isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              controller.clearSelectedVoice();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white54,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        if (controller
                                            .selectedVoiceTxt
                                            .value
                                            .isEmpty)
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: 16,
                          borderWidth: 0.5,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'role_description_label'.tr,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Obx(
                                    () => Text(
                                      '${controller.descLength.value}/${CreateRoleController.descMaxLength}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.descController,
                                maxLines: 10,
                                minLines: 6,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                decoration: _inputDecoration(
                                  'role_description_hint'.tr,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 创建角色按钮
                        const SizedBox(height: 32),
                        Center(
                          child: Obx(
                            () => GestureDetector(
                              onTap:
                                  controller.canSubmit.value &&
                                      !controller.isCreating.value
                                  ? () => controller.onConfirm(context)
                                  : null,
                              child: SizedBox(
                                width: 126,
                                height: 48,
                                child: GlassContainer(
                                  borderRadius: 70,
                                  borderWidth: 0.5,
                                  child: Center(
                                    child: controller.isCreating.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'create_role_button'.tr,
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
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建顶部栏
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 左侧关闭按钮
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: GlassContainer(
                  borderRadius: 20,
                  borderWidth: 0,
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'packages/flutter_roleplay/assets/svg/close.svg',
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              // 中间标题
              Expanded(
                child: Center(
                  child: Text(
                    widget.editRole != null
                        ? 'edit_role_title'.tr
                        : 'create_role_title'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // 右侧占位，保持标题居中
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
    isDense: true,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.2),
        width: 0.6,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.2),
        width: 0.6,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white, width: 1.0),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class _ImageSelector extends GetView<CreateRoleController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'role_image_hint'.tr,
          //   style: const TextStyle(color: Colors.white54, fontSize: 12),
          // ),
          // const SizedBox(height: 12),
          Row(
            children: [
              // 图片预览区域
              GestureDetector(
                onTap: () => controller.selectImage(context),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.selectedImage.value != null
                          ? const Color(0xFF6A8DFF).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.2),
                      width: controller.selectedImage.value != null ? 1.5 : 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: controller.selectedImage.value != null
                          ? [
                              const Color(0xFF6A8DFF).withValues(alpha: 0.1),
                              const Color(0xFF9B7BFF).withValues(alpha: 0.1),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.1),
                            ],
                    ),
                  ),
                  child: controller.selectedImage.value != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                controller.selectedImage.value!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            // 编辑图标覆盖层
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white60,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tap_to_add'.tr,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // 操作说明区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.selectedImage.value == null) ...[
                      Text(
                        'image_upload_tips'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'image_format_support'.tr,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'image_selected'.tr,
                        style: const TextStyle(
                          color: Color(0xFF6A8DFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'tap_to_change_or_remove'.tr,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 移除按钮
                      GestureDetector(
                        onTap: controller.removeSelectedImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.withValues(alpha: 0.15),
                                Colors.red.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'remove_image'.tr,
                                style: TextStyle(
                                  color: Colors.red[300],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: isSelected
          ? GlassContainer(
              borderRadius: 70,
              borderWidth: 2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
    );
  }
}
