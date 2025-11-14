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
    final width = borderWidth ?? 0.5;
    final innerRadius = radius - width;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Angular Gradient (角度渐变边框)
        gradient: SweepGradient(
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
        padding: EdgeInsets.all(width), // 边框宽度 0.5px
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 63.1, sigmaY: 63.1), // Blur 63.1
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                // Colors: #000000 35% + Effects Opacity 10%
                color: Colors.black.withValues(alpha: 0.35),
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
