import 'package:flutter/material.dart';

/// 滚动管理 Mixin
/// 提供自动滚动和用户滚动检测功能
mixin ScrollManagementMixin<T extends StatefulWidget> on State<T> {
  // 滑动检测相关
  bool _isUserScrolling = false;
  
  bool get isUserScrolling => _isUserScrolling;

  /// 获取滚动控制器 - 需要子类实现
  ScrollController get scrollController;

  /// 初始化滚动监听器
  void initScrollListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(_onScrollPositionChanged);
    });
  }

  /// 清理滚动监听器
  void disposeScrollListener() {
    scrollController.removeListener(_onScrollPositionChanged);
  }

  /// 滚动到底部
  void scrollToBottom() {
    if (!scrollController.hasClients || !mounted) return;

    // 只有在用户没有主动滑动到上方时才自动滚动
    if (_isUserScrolling) return;

    // 使用 microtask 而不是 addPostFrameCallback 来减少延迟
    Future.microtask(() {
      if (!scrollController.hasClients || !mounted || _isUserScrolling) return;

      final double currentOffset = scrollController.offset;
      const double bottomOffset = 0.0;

      if (currentOffset > bottomOffset) {
        scrollController.animateTo(
          bottomOffset,
          duration: const Duration(milliseconds: 200), // 减少动画时间
          curve: Curves.easeOut, // 使用更快的曲线
        );
      }
    });
  }

  /// 实时监听滚动位置变化
  void _onScrollPositionChanged() {
    if (!scrollController.hasClients) return;

    final currentOffset = scrollController.offset;

    // 进一步降低阈值，让用户更容易滑动
    // 如果用户滚动到距离底部超过10像素，立即停止自动滚动
    if (currentOffset > 10.0) {
      if (!_isUserScrolling) {
        _isUserScrolling = true;
        debugPrint('检测到用户向上滚动，立即停止自动滚动 - offset: $currentOffset');
      }
    } else {
      // 如果用户回到底部附近（10像素内），恢复自动滚动
      if (_isUserScrolling) {
        _isUserScrolling = false;
        debugPrint('用户回到底部，恢复自动滚动 - offset: $currentOffset');
      }
    }
  }

  /// 处理用户滑动开始
  void onUserScrollStart() {
    // 用户一开始滑动就立即停止自动滚动，确保最快响应
    if (!_isUserScrolling) {
      _isUserScrolling = true;
      debugPrint('用户开始滑动，立即停止自动滚动');
    }
  }

  /// 处理用户滑动结束
  void onUserScrollEnd() {
    // 滑动结束后，快速检查位置并决定是否恢复自动滚动
    if (scrollController.hasClients) {
      final currentOffset = scrollController.offset;
      debugPrint('滑动结束，当前位置: $currentOffset');

      // 如果在底部附近（10像素内），立即恢复自动滚动
      if (currentOffset <= 10.0) {
        _isUserScrolling = false;
        debugPrint('滑动结束时在底部，立即恢复自动滚动');
      } else {
        // 如果在上方，延迟500毫秒后恢复，给用户更快的响应
        debugPrint('滑动结束时在上方，500毫秒后恢复自动滚动');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && scrollController.hasClients) {
            final newOffset = scrollController.offset;
            // 再次检查位置，如果还在上方就保持停止状态
            if (newOffset <= 10.0) {
              _isUserScrolling = false;
              debugPrint('延迟检查后在底部，恢复自动滚动');
            }
          }
        });
      }
    }
  }

  /// 创建滚动通知监听器
  Widget buildScrollNotificationListener({required Widget child}) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          onUserScrollStart();
        } else if (notification is ScrollEndNotification) {
          onUserScrollEnd();
        }
        return false;
      },
      child: child,
    );
  }
}
