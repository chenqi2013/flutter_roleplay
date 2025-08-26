import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:flutter_roleplay/constant/constant.dart';
import 'package:flutter_roleplay/widgets/character_intro.dart';
import 'package:flutter_roleplay/widgets/chat_bubble.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart';
import 'package:flutter_roleplay/utils/chat_dialogs.dart';

/// 聊天页面构建器
class ChatPageBuilders {
  static const double inputBarHeight = 56.0;

  /// 构建单个聊天页面
  static Widget buildSingleChatPage({
    required Widget chatScaffold,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 动态背景图片
        Positioned.fill(
          child: Obx(
            () => roleImage.value.isEmpty
                ? Container(color: Colors.grey.shade300)
                : Image.network(
                    roleImage.value,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
          ),
        ),
        // 前景内容
        chatScaffold,
      ],
    );
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
    required Widget chatListView,
    required Widget inputBar,
  }) {
    final role = usedRoles[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片 - 使用当前页面的角色图片
        Positioned.fill(
          child: Image.network(
            role['image'] as String,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'packages/flutter_roleplay/assets/images/common_bg.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 前景内容
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(
            context: context,
            roleName: role['name'] as String,
            onBackPressed: onBackPressed,
            onClearHistory: onClearHistory,
            onNavigateToRolesList: onNavigateToRolesList,
            onNavigateToCreateRole: onNavigateToCreateRole,
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
        ),
      ],
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
        backgroundColor: Colors.transparent,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        itemCount: messages.length + 1,
        cacheExtent: 1000,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, index),
          );
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
  }) {
    // 如果没有消息，显示角色介绍
    if (messages.isEmpty) {
      return CharacterIntro(
        title: '简介',
        description: roleDescription,
        firstMessage: '',
        maxLines: 4,
        showExpandIcon: _shouldShowExpandIcon(roleDescription, context),
      );
    }

    if (index < messages.length) {
      final int reversedIdx = messages.length - 1 - index;
      final ChatMessage msg = messages[reversedIdx];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatBubble(
          key: ValueKey('${msg.isUser}_${msg.content.hashCode}'),
          message: msg,
        ),
      );
    }

    // 列表最上方显示角色介绍
    return CharacterIntro(
      title: '简介',
      description: roleDescription,
      firstMessage: '',
      maxLines: 4,
      showExpandIcon: _shouldShowExpandIcon(roleDescription, context),
    );
  }

  /// 构建应用栏
  static PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required String roleName,
    required Function() onBackPressed,
    required Function() onClearHistory,
    required Function() onNavigateToRolesList,
    required Function() onNavigateToCreateRole,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: onBackPressed,
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
        // 清空历史记录按钮
        IconButton(
          icon: const Icon(
            Icons.delete_forever,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () async {
            final confirmed = await ChatDialogs.showDeleteHistoryDialog(context);
            if (confirmed == true) {
              onClearHistory();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white, size: 28),
          onPressed: onNavigateToRolesList,
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: onNavigateToCreateRole,
        ),
      ],
    );
  }

  /// 检查是否需要显示展开图标
  static bool _shouldShowExpandIcon(String text, BuildContext context) {
    // 使用更精确的文本测量方法
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.35,
        ),
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
