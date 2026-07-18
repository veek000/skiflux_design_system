import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Figma component set: **Spinner** (`146:26378`)
///
/// Variants:
/// - Size: S | M | L
/// - Type: Primary | Inverse | Negative | Mono
///
/// Color mapping from Type:
/// - Primary → `Content/Brand` / `Background/Brand`
/// - Inverse → `Content/Primary Inverse`
/// - Negative → `Content/Negative`
/// - Mono → `Content/Primary`
enum SkifluxSpinnerSize { s, m, l }

enum SkifluxSpinnerType { primary, inverse, negative, mono }

class SkifluxSpinner extends StatelessWidget {
  const SkifluxSpinner({
    super.key,
    this.size = SkifluxSpinnerSize.m,
    this.type = SkifluxSpinnerType.primary,
    this.strokeWidth,
  });

  final SkifluxSpinnerSize size;
  final SkifluxSpinnerType type;
  final double? strokeWidth;

  double get _dimension {
    switch (size) {
      case SkifluxSpinnerSize.s:
        return SkifluxSpacing.spaceL; // 16
      case SkifluxSpinnerSize.m:
        return SkifluxSpacing.spaceXl; // 24
      case SkifluxSpinnerSize.l:
        return SkifluxSpacing.space2xl; // 32
    }
  }

  Color get _color {
    switch (type) {
      case SkifluxSpinnerType.primary:
        return SkifluxColors.contentBrand;
      case SkifluxSpinnerType.inverse:
        return SkifluxColors.contentPrimaryInverse;
      case SkifluxSpinnerType.negative:
        return SkifluxColors.contentNegative;
      case SkifluxSpinnerType.mono:
        return SkifluxColors.contentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? SkifluxBorderWidth.m,
        valueColor: AlwaysStoppedAnimation<Color>(_color),
        backgroundColor: type == SkifluxSpinnerType.inverse
            ? SkifluxColors.overlay50Inverse
            : SkifluxColors.neutral100,
      ),
    );
  }
}
