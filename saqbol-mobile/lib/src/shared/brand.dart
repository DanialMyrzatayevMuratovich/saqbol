import 'package:flutter/material.dart';

/// The flat shield logo (transparent background).
class SaqLogo extends StatelessWidget {
  const SaqLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/saqbol-icon.png',
      width: size,
      height: size,
      semanticLabel: 'SaqBol',
    );
  }
}

/// The glossy 3D shield used for large hero areas.
class SaqHeroShield extends StatelessWidget {
  const SaqHeroShield({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/shield-3d.png',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
