// import 'dart:ui';
// import 'package:flutter/material.dart';

// class ParamsContainer extends StatelessWidget {
//   final Widget child;
//   final double? borderRadius;
//   final double? borderWidth;
//   final EdgeInsets? padding;

//   const ParamsContainer({
//     super.key,
//     required this.child,
//     this.borderRadius,
//     this.borderWidth,
//     this.padding,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final radius = borderRadius ?? 16.0;
//     final width = borderWidth ?? 0.5;

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(radius),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 63.1, sigmaY: 63.1),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             color: const Color(0x40FFFFFF), // 25% 透明白色
//             borderRadius: BorderRadius.circular(radius),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.3),
//               width: width, // 0.5px 边框
//             ),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }
