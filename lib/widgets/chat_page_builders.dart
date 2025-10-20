import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_roleplay/services/rwkv_tts_service.dart';
import 'dart:ui';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/widgets/character_intro.dart';
import 'package:flutter_roleplay/widgets/chat_bubble.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/dialog/chat_dialogs.dart';

/// 聊天页面构建器
class ChatPageBuilders {
  static const double inputBarHeight = 56.0;

  // 图片组件缓存
  static final Map<String, Widget> _imageCache = {};

  // 图片文件缓存映射（URL -> 本地文件路径）
  static final Map<String, String> _imageFileCache = {};

  // 下载中的图片URL集合，避免重复下载
  static final Set<String> _downloadingImages = {};

  /// 获取图片缓存目录
  static Future<Directory> _getImageCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'image_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// 生成缓存文件名（基于URL的MD5）
  static String _generateCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    final extension = path.extension(url).isEmpty
        ? '.webp'
        : path.extension(url);
    return '${digest.toString()}$extension';
  }

  /// 获取缓存的图片文件路径
  static Future<String?> _getCachedImagePath(String url) async {
    try {
      final cacheDir = await _getImageCacheDir();
      final fileName = _generateCacheFileName(url);
      final filePath = path.join(cacheDir.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        debugPrint('ChatPageBuilders: 找到缓存图片: $filePath');
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('ChatPageBuilders: 获取缓存图片路径失败: $e');
      return null;
    }
  }

  /// 下载图片到缓存
  static Future<String?> _downloadAndCacheImage(String url) async {
    // 防止重复下载
    if (_downloadingImages.contains(url)) {
      debugPrint('ChatPageBuilders: 图片正在下载中，跳过: $url');
      return null;
    }

    _downloadingImages.add(url);

    try {
      debugPrint('ChatPageBuilders: 开始下载图片: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Flutter App'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final cacheDir = await _getImageCacheDir();
        final fileName = _generateCacheFileName(url);
        final filePath = path.join(cacheDir.path, fileName);
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        // 更新缓存映射
        _imageFileCache[url] = filePath;

        debugPrint('ChatPageBuilders: 图片下载成功: $filePath');
        return filePath;
      } else {
        debugPrint('ChatPageBuilders: 图片下载失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ChatPageBuilders: 图片下载异常: $e');
      return null;
    } finally {
      _downloadingImages.remove(url);
    }
  }

  /// 清理过期的缓存文件
  static Future<void> cleanupExpiredCache({int maxDays = 31}) async {
    try {
      final cacheDir = await _getImageCacheDir();
      final files = await cacheDir.list().toList();
      final now = DateTime.now();

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > maxDays) {
            await entity.delete();
            debugPrint('ChatPageBuilders: 删除过期缓存文件: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('ChatPageBuilders: 清理缓存失败: $e');
    }
  }

  /// 构建图片组件，支持网络图片和本地图片，带离线缓存
  static Widget _buildImageWidget(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    Key? key,
  }) {
    // 创建缓存key
    final cacheKey = '${imagePath}_${fit.toString()}';

    // 如果组件缓存中存在，直接返回
    if (_imageCache.containsKey(cacheKey)) {
      // debugPrint('ChatPageBuilders: 使用缓存组件: $imagePath');
      return _imageCache[cacheKey]!;
    }

    debugPrint('ChatPageBuilders: 创建新的图片组件: $imagePath');

    // 判断是否为本地文件路径
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      return _buildLocalImageWidget(imagePath, fit, key, cacheKey);
    }

    // 判断是否为网络图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return _buildNetworkImageWithCache(imagePath, fit, key, cacheKey);
    }

    // 其他情况使用默认图片
    debugPrint('ChatPageBuilders: 未知图片路径格式，使用默认图片: $imagePath');
    return _buildDefaultImageWidget(fit, key, cacheKey);
  }

  /// 构建本地图片组件
  static Widget _buildLocalImageWidget(
    String imagePath,
    BoxFit fit,
    Key? key,
    String cacheKey,
  ) {
    final file = File(imagePath.replaceFirst('file://', ''));
    debugPrint(
      'ChatPageBuilders: 本地文件路径 - ${file.path}, 存在: ${file.existsSync()}',
    );

    if (file.existsSync()) {
      final widget = Image.file(
        file,
        fit: fit,
        key: key ?? ValueKey(imagePath),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ChatPageBuilders: 本地图片加载失败: $error');
          return _buildDefaultImageWidget(fit, key, cacheKey);
        },
      );
      _imageCache[cacheKey] = widget;
      return widget;
    } else {
      debugPrint('ChatPageBuilders: 本地文件不存在，使用默认图片');
      return _buildDefaultImageWidget(fit, key, cacheKey);
    }
  }

  /// 构建带缓存的网络图片组件
  static Widget _buildNetworkImageWithCache(
    String imageUrl,
    BoxFit fit,
    Key? key,
    String cacheKey,
  ) {
    // 检查是否已有缓存文件路径
    if (_imageFileCache.containsKey(imageUrl)) {
      final cachedPath = _imageFileCache[imageUrl]!;
      final cachedFile = File(cachedPath);
      if (cachedFile.existsSync()) {
        debugPrint('ChatPageBuilders: 使用内存中的缓存路径: $cachedPath');
        final widget = Image.file(
          cachedFile,
          fit: fit,
          key: key ?? ValueKey(imageUrl),
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ChatPageBuilders: 缓存图片加载失败: $error');
            return _buildDefaultImageWidget(fit, key, cacheKey);
          },
        );
        _imageCache[cacheKey] = widget;
        return widget;
      } else {
        // 缓存文件不存在，清除映射
        _imageFileCache.remove(imageUrl);
      }
    }

    // 先尝试加载网络图片，同时后台下载到缓存
    _preloadAndCacheImage(imageUrl);

    debugPrint('ChatPageBuilders: 加载网络图片: $imageUrl');
    final widget = FutureBuilder<String?>(
      future: _getCachedImagePath(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          // 有缓存文件，使用缓存
          final cachedFile = File(snapshot.data!);
          if (cachedFile.existsSync()) {
            debugPrint('ChatPageBuilders: 使用缓存文件: ${snapshot.data}');
            return Image.file(
              cachedFile,
              fit: fit,
              key: key ?? ValueKey(imageUrl),
              errorBuilder: (context, error, stackTrace) {
                debugPrint('ChatPageBuilders: 缓存图片加载失败: $error');
                return _buildDefaultImageWidget(fit, key, cacheKey);
              },
            );
          }
        }

        // 没有缓存或加载缓存失败，使用网络图片
        return Image.network(
          imageUrl,
          fit: fit,
          key: key ?? ValueKey(imageUrl),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade300,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2.0,
                  color: Colors.blue.shade600,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ChatPageBuilders: 网络图片加载失败: $error');
            return _buildDefaultImageWidget(fit, key, cacheKey);
          },
        );
      },
    );

    _imageCache[cacheKey] = widget;
    return widget;
  }

  /// 构建默认图片组件
  static Widget _buildDefaultImageWidget(
    BoxFit fit,
    Key? key,
    String cacheKey,
  ) {
    final widget = Image.asset(
      'packages/flutter_roleplay/assets/images/common_bg.webp',
      fit: fit,
      key: key,
    );
    _imageCache[cacheKey] = widget;
    return widget;
  }

  /// 预加载并缓存图片（后台进行）
  static void _preloadAndCacheImage(String url) {
    Future.microtask(() async {
      try {
        // 检查是否已经缓存
        final cachedPath = await _getCachedImagePath(url);
        if (cachedPath != null) {
          _imageFileCache[url] = cachedPath;
          return;
        }

        // 下载并缓存
        final downloadedPath = await _downloadAndCacheImage(url);
        if (downloadedPath != null) {
          _imageFileCache[url] = downloadedPath;
          debugPrint('ChatPageBuilders: 后台缓存完成: $downloadedPath');
        }
      } catch (e) {
        debugPrint('ChatPageBuilders: 后台缓存失败: $e');
      }
    });
  }

  /// 初始化图片缓存系统
  static Future<void> initializeImageCache() async {
    try {
      debugPrint('ChatPageBuilders: 初始化图片缓存系统...');

      // 确保缓存目录存在
      await _getImageCacheDir();

      // // 清理过期缓存（默认7天）
      // await cleanupExpiredCache();
    } catch (e) {
      debugPrint('ChatPageBuilders: 初始化图片缓存系统失败: $e');
    }
  }

  /// 清空所有缓存
  static Future<void> clearAllCache() async {
    try {
      debugPrint('ChatPageBuilders: 开始清空所有缓存...');

      // // 清空内存缓存
      // _imageCache.clear();
      // _imageFileCache.clear();

      // 清空文件缓存
      final cacheDir = await _getImageCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('ChatPageBuilders: 缓存目录已删除');
      }

      debugPrint('ChatPageBuilders: 所有缓存已清空');
    } catch (e) {
      debugPrint('ChatPageBuilders: 清空缓存失败: $e');
    }
  }

  /// 清空内存中的组件缓存（强制重新构建图片组件）
  static void clearMemoryCache() {
    // debugPrint('ChatPageBuilders: 清空内存组件缓存，缓存数量: ${_imageCache.length}');
    // debugPrint('ChatPageBuilders: 清空文件缓存映射，映射数量: ${_imageFileCache.length}');
    // _imageCache.clear();
    // _imageFileCache.clear();
  }

  /// 清空特定图片的组件缓存
  static void clearImageCache(String imagePath) {
    final keysToRemove = <String>[];
    for (final key in _imageCache.keys) {
      if (key.startsWith(imagePath)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _imageCache.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      debugPrint(
        'ChatPageBuilders: 清空图片缓存: $imagePath，清除${keysToRemove.length}个组件',
      );
    }
  }

  /// 获取缓存统计信息
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await _getImageCacheDir();
      final files = await cacheDir.list().toList();

      int totalFiles = 0;
      int totalSize = 0;

      for (final entity in files) {
        if (entity is File) {
          totalFiles++;
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'cacheDirectory': cacheDir.path,
        'memoryCacheSize': _imageFileCache.length,
      };
    } catch (e) {
      debugPrint('ChatPageBuilders: 获取缓存统计失败: $e');
      return {
        'totalFiles': 0,
        'totalSizeMB': '0.00',
        'cacheDirectory': '',
        'memoryCacheSize': 0,
      };
    }
  }

  /// 构建单个聊天页面
  static Widget buildSingleChatPage({required Widget chatScaffold}) {
    return Obx(() {
      final imageUrl = roleImage.value;
      debugPrint('buildSingleChatPage: 当前图片URL = $imageUrl');
      debugPrint('buildSingleChatPage: 当前角色名 = ${roleName.value}');

      return Stack(
        key: ValueKey(
          'single_chat_${roleName.value}_$imageUrl',
        ), // 使用角色名和图片URL作为key
        fit: StackFit.expand,
        children: [
          // 动态背景图片
          Positioned.fill(
            child: imageUrl.isEmpty
                ? Container(color: Colors.grey.shade300)
                : _buildImageWidget(imageUrl),
          ),
          // 前景内容
          chatScaffold,
        ],
      );
    });
  }

  /// 构建可滑动的聊天页面
  static Widget buildSwipeableChatPages({
    required PageController pageController,
    required List<Map<String, dynamic>> usedRoles,
    required Function(int) onPageChanged,
    required Function(int) buildPageContent,
  }) {
    return PageView.builder(
      controller: pageController,
      itemCount: usedRoles.length,
      itemBuilder: (context, index) {
        return buildPageContent(index);
      },
      onPageChanged: onPageChanged,
    );
  }

  /// 构建页面内容
  static Widget buildPageContent({
    required int index,
    required List<Map<String, dynamic>> usedRoles,
    required BuildContext context,
    required Function() onBackPressed,
    required Function() onClearHistory,
    required Function() onNavigateToRolesList,
    required Function() onNavigateToCreateRole,
    required Function() onNavigateToChangeModel,
    required Function() onNavigateToRoleParams,
    required Widget chatListView,
    required Widget inputBar,
  }) {
    final role = usedRoles[index];

    return Stack(
      key: ValueKey('page_content_${role['name']}_$index'),
      fit: StackFit.expand,
      children: [
        // 背景图片 - 分离出来，只在角色图片真正变化时更新
        _buildResponsiveBackground(role, index, usedRoles),
        // 前景内容 - 只在标题需要响应式更新时使用 Obx
        _buildResponsiveForeground(
          role: role,
          index: index,
          context: context,
          onBackPressed: onBackPressed,
          onClearHistory: onClearHistory,
          onNavigateToRolesList: onNavigateToRolesList,
          onNavigateToCreateRole: onNavigateToCreateRole,
          onNavigateToChangeModel: onNavigateToChangeModel,
          onNavigateToRoleParams: onNavigateToRoleParams,
          chatListView: chatListView,
          inputBar: inputBar,
        ),
      ],
    );
  }

  /// 构建响应式背景图片
  static Widget _buildResponsiveBackground(
    Map<String, dynamic> role,
    int index,
    List<Map<String, dynamic>> usedRoles,
  ) {
    return Obx(() {
      // // 找到当前活跃角色的索引
      // final currentRoleIndex = usedRoles.indexWhere(
      //   (r) => r['name'] == roleName.value,
      // );

      // // 只有当前活跃的角色页面才使用响应式图片，其他页面使用静态图片
      // final bool isCurrentActivePage = index == currentRoleIndex;
      // final String backgroundImage = isCurrentActivePage
      //     ? roleImage.value
      //     : role['image'] as String;

      return Positioned.fill(
        child: _buildImageWidget(
          roleImage.value,
          key: ValueKey('bg_${index}_${roleImage.value}'),
        ),
      );
    });
  }

  /// 构建响应式前景内容
  static Widget _buildResponsiveForeground({
    required Map<String, dynamic> role,
    required int index,
    required BuildContext context,
    required Function() onBackPressed,
    required Function() onClearHistory,
    required Function() onNavigateToRolesList,
    required Function() onNavigateToCreateRole,
    required Function() onNavigateToChangeModel,
    required Function() onNavigateToRoleParams,
    required Widget chatListView,
    required Widget inputBar,
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildResponsiveAppBar(
        role: role,
        context: context,
        onBackPressed: onBackPressed,
        onClearHistory: onClearHistory,
        onNavigateToRolesList: onNavigateToRolesList,
        onNavigateToCreateRole: onNavigateToCreateRole,
        onNavigateToChangeModel: onNavigateToChangeModel,
        onNavigateToRoleParams: onNavigateToRoleParams,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(child: chatListView),
            inputBar,
          ],
        ),
      ),
    );
  }

  /// 构建响应式 AppBar - 只在角色名称变化时更新
  static PreferredSizeWidget _buildResponsiveAppBar({
    required Map<String, dynamic> role,
    required BuildContext context,
    required Function() onBackPressed,
    required Function() onClearHistory,
    required Function() onNavigateToRolesList,
    required Function() onNavigateToCreateRole,
    required Function() onNavigateToChangeModel,
    required Function() onNavigateToRoleParams,
  }) {
    // 只在当前角色且名称变化时才重新构建 AppBar
    final bool isCurrentRole = role['name'] == roleName.value;
    final String displayName = isCurrentRole
        ? roleName.value
        : role['name'] as String;

    return _buildAppBar(
      context: context,
      title: displayName,
      onBackPressed: onBackPressed,
      onClearHistory: onClearHistory,
      onNavigateToRolesList: onNavigateToRolesList,
      onNavigateToCreateRole: onNavigateToCreateRole,
      onNavigateToChangeModel: onNavigateToChangeModel,
      onNavigateToRoleParams: onNavigateToRoleParams,
    );
  }

  /// 构建聊天脚手架
  static Widget buildChatScaffold({
    required BuildContext context,
    required String roleName,
    required Function() onNavigateToRolesList,
    required Widget chatListView,
    required Widget inputBar,
    bool showDebugButtons = false,
    Function()? onDebugSend,
    Function()? onDebugCheckDatabase,
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.list, color: Colors.white, size: 28),
          onPressed: onNavigateToRolesList,
        ),
        title: Text(
          roleName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug模式下的调试按钮
          if (showDebugButtons && kDebugMode) ...[
            // 调试按钮：测试消息发送
            if (onDebugSend != null)
              IconButton(
                icon: const Icon(
                  Icons.bug_report,
                  color: Colors.orange,
                  size: 24,
                ),
                onPressed: onDebugSend,
              ),
            // 调试按钮：查看数据库消息数量
            if (onDebugCheckDatabase != null)
              IconButton(
                icon: const Icon(Icons.storage, color: Colors.blue, size: 24),
                onPressed: onDebugCheckDatabase,
              ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(child: chatListView),
            inputBar,
          ],
        ),
      ),
    );
  }

  /// 构建聊天列表视图
  static Widget buildChatListView({
    required ScrollController scrollController,
    required List<ChatMessage> messages,
    required String roleDescription,
    required Widget Function(ScrollNotification) onScrollNotification,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        onScrollNotification(notification);
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: messages.length + 1,
        cacheExtent: 1000,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          return RepaintBoundary(child: itemBuilder(context, index));
        },
      ),
    );
  }

  /// 构建列表项
  static Widget buildListItem({
    required BuildContext context,
    required int index,
    required List<ChatMessage> messages,
    required String roleDescription,
    Function(ChatMessage)? onRegeneratePressed,
    Function(ChatMessage, int)? onBranchChanged,
  }) {
    // 如果没有消息，只显示角色介绍
    if (messages.isEmpty) {
      return CharacterIntro(
        title: 'introduction'.tr,
        description: roleDescription,
        firstMessage: '',
        maxLines: 4,
        showExpandIcon: _shouldShowExpandIcon(roleDescription, context),
      );
    }

    // 有消息时的逻辑
    if (index < messages.length) {
      // 显示消息气泡
      final int reversedIdx = messages.length - 1 - index;
      final ChatMessage msg = messages[reversedIdx];

      // 判断是否为最后一条AI消息（即最新的AI回复）
      final bool isLastAIMessage =
          !msg.isUser && reversedIdx == messages.length - 1;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatBubble(
          key: ValueKey('${msg.isUser}_${msg.content.hashCode}'),
          message: msg,
          onRegeneratePressed: isLastAIMessage
              ? () => onRegeneratePressed?.call(msg)
              : null,
          onBranchChanged: (branchIndex) =>
              onBranchChanged?.call(msg, branchIndex),
          showBranchIndicator: !msg.isUser && msg.totalBranches > 1,
        ),
      );
    } else if (index == messages.length) {
      // 在消息列表的最上方（最后一个index）显示角色介绍
      return CharacterIntro(
        title: 'introduction'.tr,
        description: roleDescription,
        firstMessage: '',
        maxLines: 4,
        showExpandIcon: _shouldShowExpandIcon(roleDescription, context),
      );
    }

    // 不应该到达这里，返回空容器
    return const SizedBox.shrink();
  }

  /// 构建应用栏
  static PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required String title,
    required Function() onBackPressed,
    required Function() onClearHistory,
    required Function() onNavigateToRolesList,
    required Function() onNavigateToCreateRole,
    required Function() onNavigateToChangeModel,
    required Function() onNavigateToRoleParams,
  }) {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: onBackPressed,
      ),
      title: Text(
        roleName.value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
          surfaceTintColor: Colors.transparent,
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(-20, 50),
          itemBuilder: (BuildContext context) => [
            _buildSimplePopupMenuItem(
              value: 'clear_history',
              icon: Icons.delete_forever,
              text: 'clear_history'.tr,
            ),
            _buildSimplePopupMenuItem(
              value: 'role_list',
              icon: Icons.list,
              text: 'role_list'.tr,
            ),
            _buildSimplePopupMenuItem(
              value: 'create_role',
              icon: Icons.add,
              text: 'create_role'.tr,
            ),
            _buildSimplePopupMenuItem(
              value: 'change_model',
              icon: Icons.settings,
              text: 'change_model'.tr,
            ),
            _buildSimplePopupMenuItem(
              value: 'role_params',
              icon: Icons.tune,
              text: 'role_params'.tr,
            ),
          ],
          onSelected: (String value) async {
            switch (value) {
              case 'clear_history':
                final confirmed = await ChatDialogs.showDeleteHistoryDialog(
                  context,
                );
                if (confirmed == true) {
                  onClearHistory();
                }
                break;
              case 'role_list':
                onNavigateToRolesList();
                break;
              case 'create_role':
                onNavigateToCreateRole();
                break;
              case 'change_model':
                onNavigateToChangeModel();
                break;
              case 'role_params':
                onNavigateToRoleParams();
                break;
            }
          },
        ),
      ],
    );
  }

  /// 构建现代优雅的弹出菜单项
  static PopupMenuItem<String> _buildSimplePopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 检查是否需要显示展开图标
  static bool _shouldShowExpandIcon(String text, BuildContext context) {
    // 使用更精确的文本测量方法
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 15, height: 1.35),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4, // 对应 CharacterIntro 的 maxLines
    );

    // 动态获取屏幕宽度并计算容器最大宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.85 - 24; // 85%宽度减去左右padding 12*2
    textPainter.layout(maxWidth: maxWidth);

    // 检查文本是否被截断（didExceedMaxLines 表示文本超过了maxLines）
    return textPainter.didExceedMaxLines;
  }
}
