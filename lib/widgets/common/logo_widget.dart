import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const LogoWidget({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 40,
          width: width ?? 40,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
}









