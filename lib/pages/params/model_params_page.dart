import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/params/model_params_controller.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';
import 'package:flutter_roleplay/models/model_info.dart';

class ModelParamsPage extends StatelessWidget {
  ModelParamsPage({super.key});
  final controller = Get.put(ModelParamsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // SVG 背景图
          Positioned.fill(
            child: Image.asset(
              'packages/flutter_roleplay/assets/svg/rolebg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 内容层
          SafeArea(
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
                          // 当前聊天模型
                          _buildModelInfo(
                            title: '选择聊天模型',
                            modelRx: controller.currentChatModel,
                          ),
                          const SizedBox(height: 16),

                          // 当前语音模型
                          _buildModelInfo(
                            title: '选择语音模型',
                            modelRx: controller.currentTTSModel,
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
        ],
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

  /// 构建模型信息展示
  Widget _buildModelInfo({
    required String title,
    required Rx<ModelInfo?> modelRx,
  }) {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 8),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              // decoration: BoxDecoration(
              //   color: Colors.black.withValues(alpha: 0.3),
              //   borderRadius: BorderRadius.circular(12),
              // ),
              child: Text(
                controller.getModelDisplayName(modelRx.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
      child: Row(
        children: [
          Text(
            'TTS语言',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: controller.ttsLanguages.map((lang) {
                    final isSelected = controller.ttsLanguage.value == lang;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectTTSLanguage(lang),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              lang,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white.withValues(alpha: 0.5),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择角色',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Text(
                controller.voiceRole.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(BuildContext context) {
    return Padding(
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
    );
  }
}
