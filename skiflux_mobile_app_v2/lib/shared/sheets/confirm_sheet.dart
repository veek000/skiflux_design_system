import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

// Reusable confirmation sheet — headerless centered card matching the error
// modal: icon in a tinted circle, centered bold title, centered body, then a
// full-width confirm button over a tertiary "Cancel". Returns true when the
// user confirms, null/false otherwise (backdrop tap or Cancel).

Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = RemixIcons.error_warning_fill,
  bool destructive = true,
}) {
  return showSkifluxSheet<bool>(
    context: context,
    builder: (_) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      destructive: destructive,
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final circleColor = destructive
        ? SkifluxColors.backgroundNegativeSubtle
        : SkifluxColors.brand100;
    final glyphColor = destructive
        ? SkifluxColors.contentNegative
        : SkifluxColors.contentBrand;

    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          // Extra top clearance — headerless card, so the icon must sit
          // clear of the grabber pill (top 8px + 4px tall).
          SkifluxSpacing.space2xl,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: glyphColor),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXl),
            SkifluxButton(
              label: confirmLabel,
              type: destructive
                  ? SkifluxButtonType.negative
                  : SkifluxButtonType.primary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: cancelLabel,
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
