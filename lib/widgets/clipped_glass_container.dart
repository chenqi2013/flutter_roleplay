import 'dart:ui';
import 'package:flutter/material.dart';
import 'pre_blurred_background.dart';

/// 裁切玻璃容器
/// 通过裁切预模糊背景层实现玻璃效果，避免实时 BackdropFilter 计算
class ClippedGlassContainer extends StatefulWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double borderWidth;
  final Color color;
  final bool hasGradient;

  /// 备用模糊值（当没有预模糊背景时使用 BackdropFilter）
  final double fallbackBlur;

  const ClippedGlassContainer({
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
  State<ClippedGlassContainer> createState() => _ClippedGlassContainerState();
}

class _ClippedGlassContainerState extends State<ClippedGlassContainer> {
  final GlobalKey _containerKey = GlobalKey();
  Offset _globalPosition = Offset.zero;
  bool _positionCalculated = false;

  @override
  void initState() {
    super.initState();
    _schedulePositionUpdate();
  }

  void _schedulePositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updatePosition();
      }
    });
  }

  void _updatePosition() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newPosition = renderBox.localToGlobal(Offset.zero);

      if (!_positionCalculated || newPosition != _globalPosition) {
        setState(() {
          _globalPosition = newPosition;
          _positionCalculated = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 尝试获取预模糊背景数据
    final blurData = PreBlurredBackgroundScope.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 滚动时更新位置
        _schedulePositionUpdate();
        return false;
      },
      child: _buildContainer(blurData),
    );
  }

  Widget _buildContainer(PreBlurredBackgroundData? blurData) {
    // 外层容器用于渐变边框
    return Container(
      key: _containerKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        // Angular Gradient 边框 - 从中心对齐的扫描渐变
        gradient: widget.hasGradient
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
        padding: EdgeInsets.all(widget.borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.borderRadius - widget.borderWidth,
          ),
          child: blurData != null && _positionCalculated
              ? _buildClippedBlurEffect(blurData)
              : _buildFallbackBlurEffect(),
        ),
      ),
    );
  }

  /// 构建裁切模糊效果（使用预模糊背景裁切）
  Widget _buildClippedBlurEffect(PreBlurredBackgroundData blurData) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 裁切的预模糊背景
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: blurData.screenSize.width,
              maxHeight: blurData.screenSize.height,
              child: Transform.translate(
                offset: -_globalPosition,
                child: RepaintBoundary(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: blurData.blurSigma,
                      sigmaY: blurData.blurSigma,
                      tileMode: TileMode.clamp,
                    ),
                    child: SizedBox(
                      width: blurData.screenSize.width,
                      height: blurData.screenSize.height,
                      child: blurData.backgroundImage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 半透明背景色
        Positioned.fill(child: Container(color: widget.color)),

        // 子内容
        Container(
          padding: widget.padding ?? const EdgeInsets.all(20),
          child:
              widget.child ??
              const Text(
                "test",
                style: TextStyle(fontSize: 32, color: Colors.white),
              ),
        ),
      ],
    );
  }

  /// 备用模糊效果（使用 BackdropFilter）
  Widget _buildFallbackBlurEffect() {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: widget.fallbackBlur,
        sigmaY: widget.fallbackBlur,
      ),
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(color: widget.color),
        child:
            widget.child ??
            const Text(
              "test",
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
      ),
    );
  }
}
