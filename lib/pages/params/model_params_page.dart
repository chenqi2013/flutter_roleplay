import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/params/model_params_controller.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';

class ModelParamsPage extends StatelessWidget {
  ModelParamsPage({super.key});
  final controller = Get.put(ModelParamsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withValues(alpha: 0.3),
              Colors.blue.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 选择聊天模型
                        _buildModelSelector(
                          title: '选择聊天模型',
                          models: controller.chatModels,
                          selectedModel: controller.selectedChatModel.value,
                          onChanged: (model) =>
                              controller.selectChatModel(model),
                        ),
                        const SizedBox(height: 16),

                        // 选择语音模型
                        _buildModelSelector(
                          title: '选择语音模型',
                          models: controller.ttsModels,
                          selectedModel: controller.selectedTTSModel.value,
                          onChanged: (model) =>
                              controller.selectTTSModel(model),
                        ),
                        const SizedBox(height: 16),

                        // TTS语言选择
                        _buildTTSLanguageSelector(),
                        const SizedBox(height: 16),

                        // 风格滑块
                        _buildStyleSlider(),
                        const SizedBox(height: 16),

                        // 语音角色选择
                        _buildVoiceRoleSelector(),
                      ],
                    ),
                  );
                }),
              ),
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '在此处调整',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'packages/flutter_roleplay/assets/svg/modelicon.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 4),
              const Text(
                '模型参数',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '。',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建模型选择器
  Widget _buildModelSelector({
    required String title,
    required List models,
    required dynamic selectedModel,
    required void Function(dynamic) onChanged,
  }) {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: selectedModel,
                  isExpanded: true,
                  dropdownColor: Colors.grey.shade800,
                  style: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: models.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(
                        controller.getModelDisplayName(model),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建TTS语言选择器
  Widget _buildTTSLanguageSelector() {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TTS语言',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: controller.ttsLanguages.map((lang) {
                final isSelected = controller.ttsLanguage.value == lang;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectTTSLanguage(lang),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          lang,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建风格滑块
  Widget _buildStyleSlider() {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '拖动选择风格',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: Colors.white.withValues(alpha: 0.8),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: controller.styleValue.value,
                min: 0.0,
                max: 1.0,
                onChanged: controller.updateStyleValue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '无聊的',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.getStyleDescription(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Text(
                '疯狂的',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建语音角色选择器
  Widget _buildVoiceRoleSelector() {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '为改政选择角色',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: controller.voiceRoles.map((role) {
                final isSelected = controller.voiceRole.value == role;
                return GestureDetector(
                  onTap: () => controller.selectVoiceRole(role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(BuildContext context) {
    return Positioned(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Obx(
            () => GestureDetector(
              onTap: controller.isSaving.value
                  ? null
                  : controller.saveConfiguration,
              child: GlassContainer(
                borderRadius: 16,
                borderWidth: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '保存以上配置',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
