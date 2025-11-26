import 'dart:ui';
import 'package:flutter/material.dart';

/// 预模糊背景的数据类
class PreBlurredBackgroundData {
  /// 模糊强度
  final double blurSigma;

  /// 背景图片组件（原始的，用于子组件裁切渲染）
  final Widget backgroundImage;

  /// 屏幕尺寸
  final Size screenSize;

  const PreBlurredBackgroundData({
    required this.blurSigma,
    required this.backgroundImage,
    required this.screenSize,
  });
}

/// 预模糊背景作用域
/// 在页面层面预生成模糊背景，子组件通过裁切获取对应区域
class PreBlurredBackgroundScope extends StatefulWidget {
  /// 背景图片组件
  final Widget backgroundImage;

  /// 子组件
  final Widget child;

  /// 模糊强度
  final double blurSigma;

  const PreBlurredBackgroundScope({
    super.key,
    required this.backgroundImage,
    required this.child,
    this.blurSigma = 63.1,
  });

  /// 从 context 获取预模糊背景数据
  static PreBlurredBackgroundData? of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_PreBlurredBackgroundInherited>();
    return scope?.data;
  }

  @override
  State<PreBlurredBackgroundScope> createState() =>
      _PreBlurredBackgroundScopeState();
}

class _PreBlurredBackgroundScopeState extends State<PreBlurredBackgroundScope> {
  Size _screenSize = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  Widget build(BuildContext context) {
    final data = PreBlurredBackgroundData(
      blurSigma: widget.blurSigma,
      backgroundImage: widget.backgroundImage,
      screenSize: _screenSize,
    );

    return _PreBlurredBackgroundInherited(
      data: data,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 层1: 原始清晰背景图
          Positioned.fill(child: widget.backgroundImage),

          // 层2: 预模糊背景图（全屏预渲染，作为视觉参考，会被子组件裁切覆盖）
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: widget.blurSigma,
                    sigmaY: widget.blurSigma,
                    tileMode: TileMode.clamp,
                  ),
                  child: widget.backgroundImage,
                ),
              ),
            ),
          ),

          // 层3: 子内容
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// InheritedWidget 用于传递预模糊背景数据
class _PreBlurredBackgroundInherited extends InheritedWidget {
  final PreBlurredBackgroundData data;

  const _PreBlurredBackgroundInherited({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PreBlurredBackgroundInherited oldWidget) {
    return data.blurSigma != oldWidget.data.blurSigma ||
        data.screenSize != oldWidget.data.screenSize ||
        data.backgroundImage != oldWidget.data.backgroundImage;
  }
}
