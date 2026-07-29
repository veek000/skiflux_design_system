import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

// Reusable confirmation sheet — headerless centered card matching the error
// modal: icon in a tinted circle, centered bold title, centered body, then a
// full-width confirm button over a tertiary "Cancel". Returns true when the
// user confirms, null/false otherwise (backdrop tap or Cancel).

/// Figma's confirm/success dialog avatar: a 98px circle around a 48px glyph
/// (29.4px padding). Neither size exists on the token scale.
const double _avatarSize = 98;
const double _glyphSize = 48;

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
      child: Stack(
        children: [
          Padding(
            // Figma `1256:20160`: card pads 16 at the top, the label block is
            // inset a further 16 either side (32 total), and the sticky button
            // area below carries its own 16/8.
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.space2xl,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.space2xl,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: _glyphSize, color: glyphColor),
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.bodyP8Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
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
          const Positioned(
            top: SkifluxSpacing.spaceL,
            right: SkifluxSpacing.spaceL,
            child: SkifluxSheetCloseButton(),
          ),
        ],
      ),
    );
  }
}
