import 'package:flutter/material.dart';
import 'package:flutter_roleplay/pages/audio/audio_list_controller.dart';
import 'package:flutter_roleplay/widgets/params_container.dart';
import 'package:get/get.dart';

class AudioListPage extends StatelessWidget {
  final bool isSelectMode; // 是否为选择模式（用于创建角色时选择音色）
  final String? ttsLanguage; // TTS语言类型（中文/英文/日语）

  AudioListPage({super.key, this.isSelectMode = false, this.ttsLanguage});
  final controller = Get.put(AudioListController());

  @override
  Widget build(BuildContext context) {
    controller.isSelectMode.value = isSelectMode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        image: const DecorationImage(
          image: AssetImage(
            'packages/flutter_roleplay/assets/svg/audio_list_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          // // 顶部拖动条
          // _buildDragHandle(),
          // 标题
          _buildHeader(),
          // 内容
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              // 根据TTS语言类型选择对应的音频列表
              final audios = _getAudiosByLanguage(controller);
              return _buildAudioGrid(audios, controller);
            }),
          ),
        ],
      ),
    );
  }

  /// 根据语言类型获取对应的音频列表
  List<AudioItem> _getAudiosByLanguage(AudioListController controller) {
    if (ttsLanguage == null) {
      return controller.chineseAudios; // 默认中文
    }

    switch (ttsLanguage) {
      case '中文':
        return controller.chineseAudios;
      case '英文':
        return controller.englishAudios;
      case '日语':
        return controller.japaneseAudios;
      default:
        return controller.chineseAudios;
    }
  }

  /// 构建拖动条
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            '你希望拥有什么样的声音',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建音频网格（两列）
  Widget _buildAudioGrid(
    List<AudioItem> audios,
    AudioListController controller,
  ) {
    if (audios.isEmpty) {
      return Center(
        child: Text(
          '暂无音频',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 两列
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4, // 宽高比
      ),
      itemCount: audios.length,
      itemBuilder: (context, index) {
        final audio = audios[index];

        return Obx(() {
          final isCurrentPlaying =
              controller.currentPlayingKey.value == audio.key;
          final isPlaying = isCurrentPlaying && controller.isPlaying.value;
          final isSelected =
              controller.selectedAudioName.value == '${audio.key}.wav';

          return _buildAudioCard(
            controller: controller,
            audio: audio,
            isPlaying: isPlaying,
            isCurrentPlaying: isCurrentPlaying,
            isSelected: isSelected,
            context: context,
          );
        });
      },
    );
  }

  /// 构建音频卡片（GridView样式）
  Widget _buildAudioCard({
    required AudioListController controller,
    required AudioItem audio,
    required bool isPlaying,
    required bool isCurrentPlaying,
    required bool isSelected,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSelectMode) {
          // 选择模式：返回选中的音色数据
          Navigator.of(
            context,
          ).pop({'voice': '${audio.key}.wav', 'voiceTxt': audio.name});
        } else {
          // 非选择模式下点击非播放按钮区域也播放
          controller.toggleAudio(audio);
        }
      },
      child: ParamsContainer(
        borderRadius: 20,
        borderWidth: 0,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 播放按钮（左边）- 独立处理点击事件
            GestureDetector(
              onTap: () {
                // 播放按钮：始终播放音频
                controller.toggleAudio(audio);
              },
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),
            // 名称和信息（右边）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 音频名称
                  Text(
                    audio.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 角色信息
                  Text(
                    _extractCharacterInfo(audio.key),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 选中标识
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  /// 提取角色信息（从key中提取）
  String _extractCharacterInfo(String key) {
    // 例如: "Chinese(PRC)_Kafka_8" -> "Kafka #8"
    final parts = key.split('_');
    if (parts.length >= 3) {
      final characterName = parts[1];
      final number = parts[2];
      return '$characterName #$number';
    } else if (parts.length == 2) {
      return parts[1];
    }
    return key;
  }
}
