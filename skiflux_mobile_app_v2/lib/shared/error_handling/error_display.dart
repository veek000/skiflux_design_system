/// UI presentation for [ClassifiedError] results.
///
/// Toast → [SkifluxToast] with [SkifluxToastType.error] (typed, queued).
/// Modal → [showSkifluxSheet] / [SkifluxSheetShell] (same blur + scrim +
/// white card shell as comments, more-menu, share, unlock, etc.).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../sheets/skiflux_sheet.dart';
import '../toast/skiflux_toast.dart';
import 'error_handler.dart';

/// One-call helper: classify → report (if needed) → show toast or modal.
abstract final class ErrorDisplay {
  /// Classify [error] via [errorHandlerProvider] and present the right UI.
  ///
  /// Usage from any [ConsumerWidget] / [ConsumerStatefulWidget]:
  /// ```dart
  /// try {
  ///   ...
  /// } catch (e, st) {
  ///   if (!mounted) return;
  ///   await ErrorDisplay.show(context, ref, e, stackTrace: st);
  /// }
  /// ```
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Object error, {
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    return present(
      context,
      ref.read(errorHandlerProvider),
      error,
      stackTrace: stackTrace,
      onRetry: onRetry,
    );
  }

  /// Same as [show] for widgets that are not yet on Riverpod.
  ///
  /// [ErrorHandler] is pure/stateless (`const ErrorHandler()`), so a
  /// [WidgetRef] is not required. Prefer [show] from Consumer widgets so
  /// the provider remains the single access point when Riverpod is available.
  /// Used by `comments_sheet.dart` until that sheet is migrated.
  static Future<void> showStandalone(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    return present(
      context,
      const ErrorHandler(),
      error,
      stackTrace: stackTrace,
      onRetry: onRetry,
    );
  }

  /// Core classify → report → toast/modal. Prefer [show] / [showStandalone].
  static Future<void> present(
    BuildContext context,
    ErrorHandler handler,
    Object error, {
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) async {
    final classified = handler.classify(error);

    if (classified.shouldReportToCrashReporting) {
      final cause = error is SkifluxFailure ? (error.cause ?? error) : error;
      final st = stackTrace ??
          (error is SkifluxFailure ? error.stackTrace : null);
      handler.reportTechnicalError(
        cause,
        stackTrace: st,
        kind: classified.kind,
      );
    }

    if (!context.mounted) return;

    switch (classified.uiType) {
      case ErrorUiType.toast:
        _showToast(context, classified.message);
      case ErrorUiType.modal:
        await _showModal(
          context,
          message: classified.message,
          actionLabel: classified.actionLabel ?? 'OK',
          onRetry: onRetry,
        );
    }
  }

  /// Toast path — typed error toast via the shared helper (queued; does
  /// not replace an in-flight success/info toast).
  static void _showToast(BuildContext context, String message) {
    SkifluxToast.error(context, message);
  }

  /// Modal path — app-wide overlay shell (blur + scrim + sheet card).
  ///
  /// Headerless variant (`showHeader: false`): no X button, no divider —
  /// content starts directly with the icon. Dismissal via backdrop tap
  /// (showSkifluxSheet scrim) or the primary action button.
  ///
  /// Centered content pattern (icon-in-circle → title → description →
  /// full-width primary button), matching the quiz-result fail state
  /// (`quiz_result_screen.dart`): 98px negative-subtle circle, 48px
  /// negative glyph.
  static Future<void> _showModal(
    BuildContext context, {
    required String message,
    required String actionLabel,
    VoidCallback? onRetry,
  }) {
    return showSkifluxSheet<void>(
      context: context,
      builder: (ctx) => SkifluxSheetShell(
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
              // Icon in a negative-subtle circle — same 98px circle /
              // 48px glyph proportions as the quiz-result fail state.
              Center(
                child: Container(
                  width: 98,
                  height: 98,
                  decoration: const BoxDecoration(
                    color: SkifluxColors.backgroundNegativeSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    RemixIcons.error_warning_fill,
                    size: 48,
                    color: SkifluxColors.contentNegative,
                  ),
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
              Text(
                'Something went wrong',
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
              // Single primary action only — no secondary/Cancel.
              SkifluxButton(
                label: actionLabel,
                expanded: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onRetry?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
