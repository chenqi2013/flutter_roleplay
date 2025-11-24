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
        gradient: const SweepGradient(
          colors: [
            Color(0x1AFFFFFF), // 10% 白色
            Color(0x99FFFFFF), // 60% 白色
            Color(0x1AFFFFFF), // 10% 白色
            Color(0x99FFFFFF), // 60% 白色
          ],
          // stops: [0.0, 0.25, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(0), // 边框宽度 0.5px
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75), // #000000 80% 更暗的背景
              // image: DecorationImage(
              //   image: AssetImage(
              //     'packages/flutter_roleplay/assets/svg/param_container_bg.png',
              //   ),
              //   fit: BoxFit.cover,
              //   opacity: 0.1, // 噪声效果 10%
              // ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
