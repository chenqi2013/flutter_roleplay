import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_downloader/downloader.dart';
import 'package:flutter_roleplay/hometabs/roleplay_chat_controller.dart';
import 'package:rxdart/rxdart.dart';

DownloadTask? task;
RxBool isdownloading = false.obs;
RxDouble downloadProgress = 0.0.obs;
RxDouble speed = 0.0.obs;

void showDownloadDialog(
  BuildContext context,
  String description,
  bool isForce,
  String downloadurl,
  String md5,
) {
  debugPrint('showDownloadDialog context=$context');
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 顶部图标
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF6A8DFF).withValues(alpha: 0.8),
                              const Color(0xFF9B7BFF).withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6A8DFF,
                              ).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          isdownloading.value
                              ? Icons.download_rounded
                              : Icons.cloud_download_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 标题
                      Text(
                        isdownloading.value ? '正在下载中...' : '下载模型文件',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // 描述文本
                      Text(
                        isdownloading.value ? '文件比较大，请耐心等待下载完成' : description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // 下载进度条
                      if (isdownloading.value) ...[
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: downloadProgress.value / 100,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF6A8DFF),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 进度和速度信息
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${downloadProgress.value.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${speed.value.toStringAsFixed(2)} MB/s',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 按钮区域
                      if (!isdownloading.value)
                        Row(
                          children: [
                            if (!isForce) ...[
                              Expanded(
                                child: _SecondaryButton(
                                  onTap: () => Navigator.of(context).pop(),
                                  label: '取消',
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: _PrimaryButton(
                                onTap: () => downloadfile(context, downloadurl),
                                label: '开始下载',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<String> getCachePath() async {
  String tempDirPath = '';
  try {
    Directory tempDir = await getApplicationCacheDirectory();
    tempDirPath = tempDir.path;
  } catch (e) {
    print('Error getCachePath: $e');
  }
  return tempDirPath;
}

Future<String> getLocalFilePath(String downloadurl) async {
  String downloadPath = await getCachePath();
  Uri uri = Uri.parse(downloadurl);
  var name = uri.pathSegments.last;
  debugPrint('file name=$name');
  String filePath = '$downloadPath/$name';
  return filePath;
}

Future<bool> checkDownloadFile(String downloadurl) async {
  String downloadPath = await getCachePath();
  Uri uri = Uri.parse(downloadurl);
  var name = uri.pathSegments.last;
  debugPrint('file name=$name');
  String filePath = '$downloadPath/$name';
  bool isExists = false;
  if (File(filePath).existsSync()) {
    debugPrint('file existsSync');
    // var file = File(filePath);
    // var fileBytes = await file.readAsBytes();
    // // 计算 MD5
    // var md5Digest = md5.convert(fileBytes);
    // // 输出 MD5 哈希值
    // if (kDebugMode) print('MD5 hash: ${md5Digest.toString()}');
    // if (md5Digest.toString() == md5Str) {
    //   Get.back();
    //   AppInstaller.installApk(filePath);
    //   return true;
    // } else {
    //   debugPrint('file md5 not match');
    //   return false;
    // }
    isExists = true;
  } else {
    debugPrint('file not existsSync');
  }

  return isExists;
}

void downloadfile(BuildContext context, String downloadurl) async {
  String downloadPath = await getCachePath();
  Uri uri = Uri.parse(downloadurl);
  var name = uri.pathSegments.last;
  debugPrint('file name=$name');
  String filePath = '$downloadPath/$name';
  if (await checkDownloadFile(downloadurl)) {
  } else {
    task = await DownloadTask.create(url: downloadurl, path: filePath);
    debugPrint('download task create url=$downloadurl, path=$filePath');
    task
        ?.events()
        .throttleTime(
          const Duration(milliseconds: 1000),
          trailing: true,
          leading: false,
        )
        .listen(
          (e) {
            if (e.progress >= 0 && e.progress <= 100) {
              downloadProgress.value = e.progress;
              speed.value = e.speedInMB;
              debugPrint(
                'download update: state:${e.state}, speed:${speed.value.toStringAsFixed(2)}MB/s,progress:${downloadProgress.value}',
              );
            }
          },
          onError: (e) {
            debugPrint('download error: $e');
          },
          onDone: () {
            debugPrint('download done');

            Future.delayed(const Duration(milliseconds: 200), () {
              Future.microtask(() {
                Navigator.of(context).pop();
              });
            });

            RolePlayChatController? _controller;
            if (Get.isRegistered<RolePlayChatController>()) {
              _controller = Get.find<RolePlayChatController>();
            } else {
              _controller = Get.put(RolePlayChatController());
            }

            _controller?.loadChatModel();
          },
        );
    // Get.back();
    task?.start();

    /// todo： release包 点击开始下载后 下载对话框会自动消失，所以先这样处理，后面找时间定位问题
    Future.delayed(const Duration(milliseconds: 100), () {
      isdownloading.value = true;
      // showDownloadDialog(context, '', true, '', '');
    });
  }
}

// 主要按钮组件
class _PrimaryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _PrimaryButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A8DFF), Color(0xFF9B7BFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A8DFF).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// 次要按钮组件
class _SecondaryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _SecondaryButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
