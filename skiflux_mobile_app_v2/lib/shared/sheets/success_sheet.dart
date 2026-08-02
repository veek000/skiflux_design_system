import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

// Reusable success sheet — the headerless green-check card shared across the
// Settings flow (Card Saved / Card Removed / Bank Account Saved / Downloads
// Cleared / Data Export Requested / Account Deleted / Password Updated). Same
// idiom as the wallet's purchase/withdrawal success sheets, minus the summary
// card. Resolves when dismissed.

/// Figma's confirm/success dialog avatar: 72px circle around a 36px glyph
/// for perfectly balanced headerless modal cards.
const double _avatarSize = 72;
const double _glyphSize = 36;

Future<void> showSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Done',
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) =>
        _SuccessSheet(title: title, message: message, buttonLabel: buttonLabel),
  );
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.title,
    required this.message,
    required this.buttonLabel,
  });

  final String title;
  final String message;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceXl,
          SkifluxSpacing.spaceXl,
          SkifluxSpacing.spaceXl,
          SkifluxSpacing.spaceS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPositiveSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.check_fill,
                  size: _glyphSize,
                  color: SkifluxColors.contentPositiveBold,
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceM),
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
              label: buttonLabel,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
