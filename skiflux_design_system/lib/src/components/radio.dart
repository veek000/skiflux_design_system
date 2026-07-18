import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/icons.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Figma component set: **Radio button** (`198:15908`)
///
/// Variants: Active | Inactive
/// Size: 16×16 (`Space/L`)
/// Active outer fill → `Content/Brand` (`#5610AB`)
/// Active checkmark vector → `Primary/White`
class SkifluxRadio<T> extends StatelessWidget {
  const SkifluxRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: Container(
        width: SkifluxSpacing.spaceL,
        height: SkifluxSpacing.spaceL,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selected ? SkifluxColors.contentBrand : null,
          border: _selected
              ? null
              : Border.all(
                  color: SkifluxColors.borderSecondary,
                  width: SkifluxBorderWidth.xs,
                ),
        ),
        child: _selected
            ? const Icon(
                // Remix Icon (Figma Remix Icons library)
                SkifluxIcons.checkLine,
                size: SkifluxUnit.u10,
                color: SkifluxColors.white,
              )
            : null,
      ),
    );
  }
}
