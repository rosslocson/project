import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String backgroundAsset;
  final AlignmentGeometry alignment;
  final BoxFit fit;

  const AppBackground({
    super.key,
    required this.child,
    this.backgroundAsset = 'assets/images/space_background.jpg',
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: fit,
          alignment: alignment,
        ),
      ),
      child: child,
    );
  }
}
