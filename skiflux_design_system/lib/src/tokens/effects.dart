import 'package:flutter/material.dart';

/// Elevation / shadow tokens from Figma **local effect styles**.
///
/// Surface/L0–L6 color variables are placeholders (all white in Light).
/// Use these effect styles for real elevation differentiation.
abstract final class SkifluxEffects {
  /// Effect style: `Shadow/L1`
  /// - drop: blur 2, offset (0,0), black @ 8%
  /// - drop: blur 4, offset (0,2), black @ 8%
  static const List<BoxShadow> shadowL1 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 2,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Effect style: `Shadow/L2`
  /// - drop: blur 4, offset (0,0), black @ 8%
  /// - drop: blur 8, offset (0,4), black @ 10%
  static const List<BoxShadow> shadowL2 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 4,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Effect style: `Shadow/L3`
  /// - drop: blur 6, offset (0,0), black @ 8%
  /// - drop: blur 16, offset (0,8), black @ 10%
  static const List<BoxShadow> shadowL3 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Effect style: `Shadow/L4`
  /// - drop: blur 8, offset (0,0), black @ 8%
  /// - drop: blur 20, offset (0,10), black @ 10%
  static const List<BoxShadow> shadowL4 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  /// Effect style: `Shadow/L5`
  /// - drop: blur 10, offset (0,0), black @ 8%
  /// - drop: blur 24, offset (0,12), black @ 10%
  static const List<BoxShadow> shadowL5 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 10,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  /// Effect style: `Shadow/L6`
  /// - drop: blur 12, offset (0,0), black @ 8%
  /// - drop: blur 32, offset (0,16), black @ 10%
  static const List<BoxShadow> shadowL6 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  /// Effect style: `Inner shadow`
  /// - inner: blur ≈0.53, offset (0, ≈1.07), `#FFF8F4` @ 30%
  ///
  /// Flutter has no first-class inner shadow on [BoxDecoration]; expose the
  /// raw values for custom painters / gradient borders when needed.
  static const Color innerShadowColor = Color(0x4DFFF8F4);
  static const double innerShadowBlur = 0.533333420753479;
  static const Offset innerShadowOffset = Offset(0, 1.066666841506958);

  /// Resolve elevation level 1–6 to the matching effect style.
  static List<BoxShadow> shadowForLevel(int level) {
    switch (level) {
      case 1:
        return shadowL1;
      case 2:
        return shadowL2;
      case 3:
        return shadowL3;
      case 4:
        return shadowL4;
      case 5:
        return shadowL5;
      case 6:
        return shadowL6;
      default:
        return const [];
    }
  }
}
