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
  /// [SkifluxSheetShell] already provides title + close; content is a
  /// single message + primary action — no shell API extension needed.
  static Future<void> _showModal(
    BuildContext context, {
    required String message,
    required String actionLabel,
    VoidCallback? onRetry,
  }) {
    return showSkifluxSheet<void>(
      context: context,
      builder: (ctx) => SkifluxSheetShell(
        title: 'Something went wrong',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SkifluxSpacing.spaceL,
            SkifluxSpacing.spaceL,
            SkifluxSpacing.spaceL,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: SkifluxColors.backgroundNegativeSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    RemixIcons.error_warning_fill,
                    size: 32,
                    color: SkifluxColors.contentNegative,
                  ),
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
              Text(
                message,
                textAlign: TextAlign.center,
                style: SkifluxTypography.bodyP8Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceXl),
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
