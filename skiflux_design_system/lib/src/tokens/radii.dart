import 'package:flutter/painting.dart';

/// Border radius + stroke width from Figma collection **Border** (Mode 1).
abstract final class SkifluxRadii {
  /// Variable: `Radius/None`
  static const double none = 0;

  /// Variable: `Radius/XS`
  static const double xs = 4;

  /// Variable: `Radius/S`
  static const double s = 8;

  /// Variable: `Radius/M`
  static const double m = 12;

  /// Variable: `Radius/L`
  static const double l = 16;

  /// Variable: `Radius/X`
  static const double x = 24;

  /// Variable: `Radius/XL`
  static const double xl = 32;

  /// Variable: `Radius/Circle`
  static const double circle = 64;

  /// Variable: `Radius/Pill` (999 in Figma → stadium / full pill)
  static const double pill = 999;

  static BorderRadius get borderNone => BorderRadius.circular(none);
  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderS => BorderRadius.circular(s);
  static BorderRadius get borderM => BorderRadius.circular(m);
  static BorderRadius get borderL => BorderRadius.circular(l);
  static BorderRadius get borderX => BorderRadius.circular(x);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderCircle => BorderRadius.circular(circle);
  static BorderRadius get borderPill => BorderRadius.circular(pill);
}

/// Stroke widths from Figma collection **Border** (Mode 1).
abstract final class SkifluxBorderWidth {
  /// Variable: `Width/None`
  static const double none = 0;

  /// Variable: `Width/XS`
  static const double xs = 1;

  /// Variable: `Width/S`
  static const double s = 1.5;

  /// Variable: `Width/M`
  static const double m = 2;

  /// Variable: `Width/L`
  static const double l = 4;

  /// Variable: `Width/XL`
  static const double xl = 8;
}
