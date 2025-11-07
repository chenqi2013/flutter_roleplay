import 'package:flutter/material.dart';
import 'package:flutter_roleplay/pages/audio/audio_list_controller.dart';
import 'package:get/get.dart';

class AudioListPage extends StatelessWidget {
  const AudioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '选择音色',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '中文'),
            Tab(text: 'English'),
            Tab(text: '日本語'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            );
          }

          return TabBarView(
            controller: controller.tabController,
            children: [
              _buildAudioList(controller.chineseAudios),
              _buildAudioList(controller.englishAudios),
              _buildAudioList(controller.japaneseAudios),
            ],
          );
        }),
      ),
    );
  }

  /// 构建音频列表
  Widget _buildAudioList(List<AudioItem> audios) {
    if (audios.isEmpty) {
      return const Center(
        child: Text('暂无音频', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: audios.length,
      itemBuilder: (context, index) {
        final audio = audios[index];
        final controller = Get.find<AudioListController>();

        return Obx(() {
          final isCurrentPlaying =
              controller.currentPlayingKey.value == audio.key;
          final isPlaying = isCurrentPlaying && controller.isPlaying.value;

          return _buildAudioCard(
            controller: controller,
            audio: audio,
            isPlaying: isPlaying,
            isCurrentPlaying: isCurrentPlaying,
          );
        });
      },
    );
  }

  /// 构建音频卡片
  Widget _buildAudioCard({
    required AudioListController controller,
    required AudioItem audio,
    required bool isPlaying,
    required bool isCurrentPlaying,
  }) {
    const primaryColor = Colors.purple;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrentPlaying
            ? primaryColor.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlaying ? primaryColor : Colors.grey.shade200,
          width: isCurrentPlaying ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.toggleAudio(audio),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 播放按钮图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrentPlaying
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isCurrentPlaying ? Colors.white : primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // 音频名称
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isCurrentPlaying
                              ? primaryColor
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _extractCharacterInfo(audio.key),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 音频图标
                Icon(
                  Icons.audiotrack_rounded,
                  color: isCurrentPlaying ? primaryColor : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
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
