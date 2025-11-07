import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/utils/common_util.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 音频项模型
class AudioItem {
  final String key; // 文件名（不含扩展名）
  final String name; // 显示名称
  final String language; // 语言类型
  final String txt; // 文本

  AudioItem({
    required this.key,
    required this.name,
    required this.language,
    required this.txt,
  });

  // String get wavPath => 'lib/tts/$key.wav';
  // String get jsonPath => 'lib/tts/$key.json';
}

class AudioListController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // TabController
  late TabController tabController;

  // 音频数据
  final RxList<AudioItem> chineseAudios = <AudioItem>[].obs;
  final RxList<AudioItem> englishAudios = <AudioItem>[].obs;
  final RxList<AudioItem> japaneseAudios = <AudioItem>[].obs;

  // 加载状态
  final RxBool isLoading = true.obs;

  // 音频播放器
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 当前播放的音频key
  final RxString currentPlayingKey = ''.obs;

  // 播放状态
  final RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    _loadAudioData();
    _setupAudioPlayerListeners();
  }

  @override
  void onClose() {
    tabController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }

  /// 设置音频播放器监听
  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((event) {
      currentPlayingKey.value = '';
      isPlaying.value = false;
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  /// 加载音频数据
  Future<void> _loadAudioData() async {
    try {
      isLoading.value = true;

      // 读取 pairs.json 文件
      final jsonString = await rootBundle.loadString(
        'packages/flutter_roleplay/assets/lib/tts/pairs.json',
      );
      final Map<String, dynamic> pairsMap = json.decode(jsonString);

      final List<AudioItem> chinese = [];
      final List<AudioItem> english = [];
      final List<AudioItem> japanese = [];

      // 解析数据并分类，同时读取每个音频的 transcription
      for (final entry in pairsMap.entries) {
        final key = entry.key;
        final name = entry.value;

        // 读取对应的 JSON 文件获取 transcription
        String transcription = '';
        try {
          final jsonPath = 'packages/flutter_roleplay/assets/lib/tts/$key.json';
          final jsonContent = await rootBundle.loadString(jsonPath);
          final jsonData = json.decode(jsonContent);
          transcription = jsonData['transcription'] ?? '';
        } catch (e) {
          debugPrint('读取 $key.json 失败: $e');
          transcription = ''; // 如果读取失败，使用空字符串
        }

        if (key.startsWith('Chinese(PRC)_')) {
          chinese.add(
            AudioItem(
              key: key,
              name: name,
              language: 'Chinese',
              txt: transcription,
            ),
          );
        } else if (key.startsWith('English_')) {
          english.add(
            AudioItem(
              key: key,
              name: name,
              language: 'English',
              txt: transcription,
            ),
          );
        } else if (key.startsWith('Japanese_')) {
          japanese.add(
            AudioItem(
              key: key,
              name: name,
              language: 'Japanese',
              txt: transcription,
            ),
          );
        }
      }

      // // 按名称排序
      // chinese.sort((a, b) => a.name.compareTo(b.name));
      // english.sort((a, b) => a.name.compareTo(b.name));
      // japanese.sort((a, b) => a.name.compareTo(b.name));

      chineseAudios.value = chinese;
      englishAudios.value = english;
      japaneseAudios.value = japanese;

      debugPrint(
        '加载音频数据完成: 中文${chinese.length}个, 英文${english.length}个, 日文${japanese.length}个',
      );

      // 打印前几个示例以验证 transcription 是否正确加载
      if (chinese.isNotEmpty) {
        debugPrint('示例音频: ${chinese.first.name} - ${chinese.first.txt}');
      }
    } catch (e) {
      debugPrint('加载音频数据失败: $e');
      Get.snackbar(
        '错误',
        '加载音频数据失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 播放或暂停音频
  Future<void> toggleAudio(AudioItem item) async {
    try {
      // 如果正在播放同一个音频，则暂停
      if (currentPlayingKey.value == item.key && isPlaying.value) {
        await _audioPlayer.pause();
        return;
      }

      // 如果是暂停状态的同一个音频，则继续播放
      if (currentPlayingKey.value == item.key && !isPlaying.value) {
        await _audioPlayer.resume();
        return;
      }

      // 播放新的音频
      currentPlayingKey.value = item.key;
      await _audioPlayer.stop();
      debugPrint(
        'key==${item.key},wavPath==${item.name},jsonPath==${item.language}',
      );
      String path = await CommonUtil.fromAssetsToTemp(
        "assets/lib/tts/${item.key}.wav",
        targetPath: "assets/lib/tts/${item.key}.wav",
      );

      var prefs = await SharedPreferences.getInstance();
      await prefs.setString(ttsAudioNameKey, "${item.key}.wav");
      ttsAudioName = "${item.key}.wav";
      await prefs.setString(ttsAudioTxtKey, item.txt);
      ttsAudioTxt = item.txt;
      await _audioPlayer.play(DeviceFileSource(path));

      debugPrint('开始播放音频: ${item.name} (${item.txt})');
    } catch (e) {
      debugPrint('播放音频失败: $e');
      Get.snackbar(
        '错误',
        '播放音频失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      currentPlayingKey.value = '';
      isPlaying.value = false;
    }
  }

  /// 停止播放
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    currentPlayingKey.value = '';
    isPlaying.value = false;
  }

  /// 获取当前Tab的音频列表
  List<AudioItem> getCurrentTabAudios() {
    switch (tabController.index) {
      case 0:
        return chineseAudios;
      case 1:
        return englishAudios;
      case 2:
        return japaneseAudios;
      default:
        return chineseAudios;
    }
  }
}
