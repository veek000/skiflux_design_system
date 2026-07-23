import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

// Reusable success sheet — the headerless green-check card shared across the
// Settings flow (Card Saved / Card Removed / Bank Account Saved / Downloads
// Cleared / Data Export Requested / Account Deleted / Password Updated). Same
// idiom as the wallet's purchase/withdrawal success sheets, minus the summary
// card. Resolves when dismissed.

Future<void> showSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Done',
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => _SuccessSheet(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
    ),
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
          SkifluxSpacing.spaceL,
          // Headerless card — clear the grabber pill (top 8px + 4px tall).
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
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPositiveSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.check_fill,
                  size: 48,
                  color: SkifluxColors.contentPositive,
                ),
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
