import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_roleplay/pages/params/model_params_controller.dart';
import 'package:flutter_roleplay/widgets/glass_container.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:flutter_roleplay/services/model_callback_service.dart';
import 'package:flutter_roleplay/pages/audio/audio_list_page.dart';
import 'package:flutter_roleplay/constant/constant.dart';

class ModelParamsPage extends StatelessWidget {
  ModelParamsPage({super.key});
  final controller = Get.put(ModelParamsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
                      modelType: RoleplayManageModelType.chat,
                    ),
                    const SizedBox(height: 16),

                    // 当前语音模型
                    _buildModelInfo(
                      title: '选择语音模型',
                      modelType: RoleplayManageModelType.tts,
                    ),
                    const SizedBox(height: 16),

                    // TTS语言选择
                    _buildTTSLanguageSelector(),
                    const SizedBox(height: 16),

                    // 风格滑块
                    _buildStyleSlider(),
                    const SizedBox(height: 16),

                    // 语音角色选择
                    _buildVoiceRoleSelector(context),
                  ],
                ),
              );
            }),
          ),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     IconButton(
          //       onPressed: () => Get.back(),
          //       icon: const Icon(Icons.arrow_back, color: Colors.white),
          //     ),
          //     const Spacer(),
          //   ],
          // ),
          // const SizedBox(height: 8),
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
    required RoleplayManageModelType modelType,
  }) {
    // 根据模型类型选择对应的全局响应式变量
    final modelPathRx = modelType == RoleplayManageModelType.chat
        ? chatmodelPath
        : ttsmodelPath;

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
            () => GestureDetector(
              onTap: () {
                // 点击模型名称打开模型切换
                notifyModelDownloadRequired(modelType);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getModelDisplayName(modelPathRx.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 从模型路径提取显示名称
  String _getModelDisplayName(String path) {
    if (path.isEmpty) return '未配置';

    // 从路径中提取文件名
    final fileName = path.split('/').last;

    // 去掉扩展名和下划线，使其更易读
    return fileName
        .replaceAll('.bin', '')
        .replaceAll('.pth', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
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

  /// 构建解码参数区域
  Widget _buildStyleSlider() {
    return GlassContainer(
      borderRadius: 16,
      borderWidth: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '解码参数',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              Obx(
                () => GestureDetector(
                  onTap: controller.toggleDetailedParams,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.showDetailedParams.value ? '档位模式' : '详细参数',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 动态内容：档位模式 或 详细参数
          Obx(() {
            if (controller.showDetailedParams.value) {
              return _buildDetailedParams();
            } else {
              return _buildPresetLevels();
            }
          }),
        ],
      ),
    );
  }

  /// 构建预设档位（刻度尺样式）
  Widget _buildPresetLevels() {
    return Column(
      children: [
        // 刻度尺
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return Expanded(
              child: Obx(
                () => GestureDetector(
                  onTap: () => controller.setPresetLevel(index),
                  child: Column(
                    children: [
                      // 刻度线
                      Container(
                        height: 12,
                        width: 2,
                        color: controller.presetLevel.value == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 4),
                      // 档位名称
                      Text(
                        controller.presetConfigs[index]['name'],
                        style: TextStyle(
                          color: controller.presetLevel.value == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: controller.presetLevel.value == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // 连接线
        Container(height: 2, color: Colors.white.withValues(alpha: 0.2)),
      ],
    );
  }

  /// 构建详细参数输入
  Widget _buildDetailedParams() {
    return Column(
      children: [
        _buildParamRow('温度', controller.tempController, 'temp'),
        const SizedBox(height: 12),
        _buildParamRow('Top P', controller.topPController, 'topp'),
        const SizedBox(height: 12),
        _buildParamRow('存在惩罚', controller.presenceController, 'presence'),
        const SizedBox(height: 12),
        _buildParamRow('频率惩罚', controller.frequencyController, 'frequency'),
        const SizedBox(height: 12),
        _buildParamRow('惩罚衰减', controller.decayController, 'decay'),
      ],
    );
  }

  /// 构建单个参数行
  Widget _buildParamRow(
    String label,
    TextEditingController textController,
    String paramName,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
        Container(
          width: 80,
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (value) {
              controller.updateParameterFromInput(paramName, value);
            },
          ),
        ),
      ],
    );
  }

  /// 构建语音角色选择器
  Widget _buildVoiceRoleSelector(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () async {
          // 以 modal bottom sheet 方式弹出音色选择页面（半屏）
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: AudioListPage(ttsLanguage: controller.ttsLanguage.value),
            ),
          );
          // 关闭后刷新数据
          controller.loadModelsAndSettings();
        },
        child: GlassContainer(
          borderRadius: 16,
          borderWidth: 0,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择音色',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'packages/flutter_roleplay/assets/svg/voice.svg',
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        Text(
                          controller.voiceRole.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ).marginOnly(left: 6),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            child: SizedBox(
              width: 126,
              height: 48,
              child: GlassContainer(
                borderRadius: 70,
                borderWidth: 0.5,
                // padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}
