import 'dart:ui';
import 'package:flutter/material.dart';

class ClippedGlassContainerStatic extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double borderWidth;
  final Color color;
  final bool hasGradient;

  /// 备用模糊值（当没有预模糊背景时使用 BackdropFilter）
  final double fallbackBlur;

  const ClippedGlassContainerStatic({
    super.key,
    this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderWidth = 0.5,
    this.color = const Color(0x59000000),
    this.hasGradient = true,
    this.fallbackBlur = 63.1,
  });

  @override
  Widget build(BuildContext context) {
    return blur(
      Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // border: Border.all(
          //   color: Colors.white.withAlpha(100),
          //   width: borderWidth,
          // ),
          color: Colors.grey.shade800.withAlpha(100),
        ),
        child: child,
      ),
    );
  }

  Widget blur(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: child,
      ),
    );
  }
}
