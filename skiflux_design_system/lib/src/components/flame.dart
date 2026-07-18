import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma component set: **Flame Asset** (`2226:12084` active, `2231:11216`
/// inactive) — the streak flame used on the Streaks screen and Design
/// System page.
///
/// Variants: active (red→amber gradient, `#FBAC74` glow) | inactive
/// (grey gradient, `#E5E5E5` glow). The SVG's baked-in `feDropShadow`
/// filter is not supported by flutter_svg, so the assets ship with the
/// filter stripped and the glow is reproduced here as a blurred, tinted
/// copy of the flame underneath the sharp one — matching the Figma
/// effect (offset 0/4, blur stdDeviation 10).
class SkifluxFlame extends StatelessWidget {
  const SkifluxFlame({
    super.key,
    this.active = true,
    this.height = defaultHeight,
  });

  /// Figma frame size on the Streaks screen: 76.884 × 98.001.
  static const double defaultHeight = 98;
  static const double _aspectRatio = 76.884 / 98.001;

  /// Figma glow colors (drop-shadow fill per variant).
  static const Color _activeGlow = Color(0xFFFBAC74); // Orange/300
  static const Color _inactiveGlow = Color(0xFFE5E5E5); // Neutral/100

  final bool active;
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = active
        ? 'packages/skiflux_design_system/assets/images/flame_active.svg'
        : 'packages/skiflux_design_system/assets/images/flame_inactive.svg';
    final width = height * _aspectRatio;
    final flame = SvgPicture.asset(asset, height: height, width: width);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glow: the flame silhouette, tinted and gaussian-blurred.
        Positioned(
          top: 4, // Figma shadow offset (0, 4)
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SvgPicture.asset(
              asset,
              height: height,
              width: width,
              colorFilter: ColorFilter.mode(
                active ? _activeGlow : _inactiveGlow,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        flame,
      ],
    );
  }
}
