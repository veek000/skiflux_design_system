/// Destructive text action for a top nav bar's trailing slot — "Clear all" on
/// Downloads and Watch History (Figma `1256:24238`).
///
/// A bare [TextButton] rather than a [SkifluxButton]: the design system's
/// `negative` type is a filled red pill, which is not what these screens draw.
/// Extracted because the same button was written twice, with the same
/// disabled-when-empty rule and the same colour, and a third screen would have
/// copied it again.
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

class ClearAllAction extends StatelessWidget {
  const ClearAllAction({super.key, required this.onPressed, this.label = 'Clear all'});

  /// Null disables the action — pass null when the list is already empty.
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: SkifluxTypography.uiButtonMedium.copyWith(
          // Disabled reads as tertiary rather than a dimmed red, so an empty
          // list doesn't look like a destructive action waiting to happen.
          color: onPressed == null
              ? SkifluxColors.contentDisabled
              : SkifluxColors.contentNegative,
        ),
      ),
    );
  }
}
