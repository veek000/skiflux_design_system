import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Figma component set: **Switch** (`781:30182`)
///
/// Variants: off | on
/// Dimensions: 40×20 (Unit 40 / Unit 20)
///
/// Visual fills extracted from component layers (not all variable-bound):
/// - Track off → `#E5E5E5` = primitive `Neutral/100` / semantic `Content/Secondary Inverse`
/// - Track on → `#5610AB` = `Background/Brand` / `Content/Brand`
/// - Thumb → `#FFFFFF` = `Primary/White`
/// - Track radius 16 = `Radius/L`
/// - Thumb 16×16 = `Space/L`
class SkifluxSwitch extends StatelessWidget {
  const SkifluxSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: SkifluxUnit.u40,
        height: SkifluxUnit.u20,
        padding: const EdgeInsets.all(SkifluxSpacing.space2xs),
        decoration: BoxDecoration(
          color: value
              ? SkifluxColors.backgroundBrand
              : SkifluxColors.contentSecondaryInverse,
          borderRadius: SkifluxRadii.borderL,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: SkifluxSpacing.spaceL,
            height: SkifluxSpacing.spaceL,
            decoration: const BoxDecoration(
              color: SkifluxColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
