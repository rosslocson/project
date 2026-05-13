  import 'package:flutter/material.dart';
  import 'app_theme.dart';

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
      final theme = context.internTheme;

      return Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          color: theme.appBackground,
          image: theme.useSpaceBackground
              ? DecorationImage(
                  image: AssetImage(backgroundAsset),
                  fit: fit,
                  alignment: alignment,
                )
              : null,
        ),
        child: child,
      );
    }
  }
