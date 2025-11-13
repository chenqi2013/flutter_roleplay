import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsets? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.borderWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16.0;
    final width = borderWidth ?? 2.0;
    final innerRadius = radius - width;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // 渐变边框
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1AFFFFFF), // 10% 白色
            Color(0x99FFFFFF), // 60% 白色
            Color(0x1AFFFFFF), // 10% 白色
            Color(0x99FFFFFF), // 60% 白色
          ],
          stops: [0.0, 0.25, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(width), // 边框宽度
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
