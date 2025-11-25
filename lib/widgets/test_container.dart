import 'dart:ui';

import 'package:flutter/material.dart';

class TestContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double borderWidth;
  final double blur;
  final Color color;
  final bool hasGradient;

  const TestContainer({
    super.key,
    this.child,
    this.padding,
    this.blur = 100,
    this.color = const Color(0x59000000),
    this.hasGradient = true,
    this.borderRadius = 20,
    this.borderWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Angular Gradient 边框 - 从中心对齐的扫描渐变
        gradient: hasGradient
            ? const SweepGradient(
                center: Alignment.center,
                colors: [
                  Color(0x1AFFFFFF), // 10% 白色
                  Color(0x99FFFFFF), // 60% 白色
                  Color(0x1AFFFFFF), // 10% 白色
                  Color(0x99FFFFFF), // 60% 白色
                  Color(0x1AFFFFFF), // 10% 白色 (闭合渐变)
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth), // 边框宽度 0.5px
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
            ), // Background blur: 100
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color, // #000000 35% Color(0x59000000)
                // Multitone noise: Size 0.5, Density 100%, Opacity 10%
                // image: DecorationImage(
                //   image: AssetImage(
                //     'packages/flutter_roleplay/assets/svg/param_container_bg.png',
                //   ),
                //   fit: BoxFit.cover,
                //   opacity: 0.1, // 噪声 Opacity 10%
                // ),
              ),
              child:
                  child ??
                  const Text(
                    "test",
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
