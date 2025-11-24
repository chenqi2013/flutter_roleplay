import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TestGrassContainer extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsets? padding;

  const TestGrassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.borderWidth,
    this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 63.1, sigmaY: 63.1),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25), // 25%背景色
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.0,
            ),
            image: DecorationImage(
              image: AssetImage(
                "packages/flutter_roleplay/assets/svg/param_container_bg.png",
              ), // 导出的噪声纹理
              fit: BoxFit.cover,
              opacity: 0.1, // 10%
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
