/// Centralized error classification for the mobile app.
///
/// Maps raw failures / typed [SkifluxErrorKind] values to user-facing copy
/// and a toast vs modal UI decision. Consumed via [errorHandlerProvider]
/// so features stay on the established Riverpod pattern.
library;

import 'dart:async';

import '../../config/env_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// ── Public types ─────────────────────────────────────────────────────

/// How the UI should present a classified error.
enum ErrorUiType {
  /// Non-blocking — floating SnackBar (app toast pattern).
  toast,

  /// Blocking — dialog that needs acknowledgment (or retry).
  modal,
}

/// Typed failure categories used by feature code and the classifier.
///
/// Prefer throwing [SkifluxFailure] with one of these kinds over raw
/// exceptions when the feature already knows the failure mode.
enum SkifluxErrorKind {
  networkTimeout,
  noConnection,
  likeCommentReactionFailed,
  searchFailed,
  taskSubmission,
  quizSubmission,
  skillCoinWithdrawal,
  bankVerificationFailed,
  paymentMethodActionFailed,
  coinPurchaseFailed,
  authFailed,
  sessionExpired,
  voicenoteFailed,
  contentLoadFailed,
  settingsSaveFailed,

  /// A download was blocked by the user's own "Download on Wi-Fi only"
  /// preference. Not a failure — the app did what it was told — so it is a
  /// toast rather than a modal, and says which setting stopped it.
  downloadWifiOnly,

  /// An offline download did not finish.
  downloadFailed,

  unknown,
}

/// Structured result of classification — never includes raw exception text.
class ClassifiedError {
  const ClassifiedError({
    required this.uiType,
    required this.message,
    required this.kind,
    required this.shouldReportToCrashReporting,
    this.actionLabel,
  });

  final ErrorUiType uiType;
  final String message;
  final SkifluxErrorKind kind;

  /// When true, [ErrorHandler.reportTechnicalError] should be called.
  final bool shouldReportToCrashReporting;

  /// Optional primary button label for modal (defaults to "OK" / "Try Again").
  final String? actionLabel;
}

/// The copy shown for both transport failures.
///
/// Named because two places need to *recognise* it, not just print it: the
/// offline bar covers this exact condition globally, so an inline banner that
/// repeats it word-for-word is redundant. Screens compare against this constant
/// rather than a copy-pasted literal, so rewording the sentence cannot
/// accidentally reintroduce the duplicate.
const kNoConnectionMessage =
    "Couldn't connect. Check your internet and try again.";

/// Typed app failure — preferred throw type from notifiers / services.
class SkifluxFailure implements Exception {
  const SkifluxFailure(this.kind, {this.cause, this.stackTrace});

  final SkifluxErrorKind kind;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SkifluxFailure($kind)';
}

// ── Classifier (Riverpod) ────────────────────────────────────────────

/// Classifies errors and owns the crash-reporting hook.
///
/// Riverpod choice: plain [Provider] — pure functions, no mutable session
/// state. Screens/notifiers call `ref.read(errorHandlerProvider)`.
class ErrorHandler {
  const ErrorHandler();

  /// Classify [error] into UI type + plain-language [ClassifiedError.message].
  ///
  /// Accepts [SkifluxFailure], [SkifluxErrorKind], or any raw [Object].
  /// Never returns exception messages or error codes to the user.
  ClassifiedError classify(Object error) {
    final kind = _resolveKind(error);
    return _forKind(kind);
  }

  SkifluxErrorKind _resolveKind(Object error) {
    if (error is SkifluxErrorKind) return error;
    if (error is SkifluxFailure) return error.kind;

    // Lightweight heuristics for common Dart / platform failures.
    // Prefer explicit [SkifluxFailure] from features.
    final text = error.toString().toLowerCase();
    if (error is TimeoutException ||
        text.contains('timeout') ||
        text.contains('timed out')) {
      return SkifluxErrorKind.networkTimeout;
    }
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('no address associated')) {
      return SkifluxErrorKind.noConnection;
    }
    if (text.contains('unauthorized') ||
        text.contains('unauthenticated') ||
        text.contains('session expired') ||
        text.contains('token expired')) {
      return SkifluxErrorKind.sessionExpired;
    }

    return SkifluxErrorKind.unknown;
  }

  ClassifiedError _forKind(SkifluxErrorKind kind) {
    switch (kind) {
      // ── Toast (non-blocking) ─────────────────────────────────────
      case SkifluxErrorKind.networkTimeout:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: kNoConnectionMessage,
          kind: SkifluxErrorKind.networkTimeout,
          shouldReportToCrashReporting: false,
        );
      case SkifluxErrorKind.noConnection:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: kNoConnectionMessage,
          kind: SkifluxErrorKind.noConnection,
          shouldReportToCrashReporting: false,
        );
      case SkifluxErrorKind.likeCommentReactionFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: "That didn't send. Please try again.",
          kind: SkifluxErrorKind.likeCommentReactionFailed,
          shouldReportToCrashReporting: false,
        );
      case SkifluxErrorKind.searchFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: 'Something went wrong with your search. Please try again.',
          kind: SkifluxErrorKind.searchFailed,
          shouldReportToCrashReporting: false,
        );
      case SkifluxErrorKind.settingsSaveFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: "That change couldn't be saved. Please try again.",
          kind: SkifluxErrorKind.settingsSaveFailed,
          shouldReportToCrashReporting: false,
        );

      // ── Modal (blocking) ─────────────────────────────────────────
      case SkifluxErrorKind.taskSubmission:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "Your submission didn't go through. Please try again. "
              "Your progress hasn't been lost.",
          kind: SkifluxErrorKind.taskSubmission,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.quizSubmission:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "Your submission didn't go through. Please try again. "
              "Your progress hasn't been lost.",
          kind: SkifluxErrorKind.quizSubmission,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.skillCoinWithdrawal:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "We couldn't process your withdrawal. No coins were "
              'deducted. Please try again or contact support.',
          kind: SkifluxErrorKind.skillCoinWithdrawal,
          shouldReportToCrashReporting: true,
          actionLabel: 'OK',
        );
      case SkifluxErrorKind.bankVerificationFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "We couldn't save your bank account. Please check your "
              'details and try again.',
          kind: SkifluxErrorKind.bankVerificationFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.paymentMethodActionFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message: "We couldn't update your payment methods. Please try again.",
          kind: SkifluxErrorKind.paymentMethodActionFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.coinPurchaseFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "We couldn't process your coin purchase. No charges were "
              'made. Please try again.',
          kind: SkifluxErrorKind.coinPurchaseFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.authFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message:
              "We couldn't sign you in. Please check your details and "
              'try again.',
          kind: SkifluxErrorKind.authFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.sessionExpired:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message: 'Your session timed out. Please log in again to continue.',
          kind: SkifluxErrorKind.sessionExpired,
          shouldReportToCrashReporting: true,
          actionLabel: 'Log In',
        );
      case SkifluxErrorKind.voicenoteFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message: "Your voice note couldn't be sent. Tap to retry.",
          kind: SkifluxErrorKind.voicenoteFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.contentLoadFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.modal,
          message: "We couldn't load this. Please try again.",
          kind: SkifluxErrorKind.contentLoadFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );
      case SkifluxErrorKind.downloadWifiOnly:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          // Names the setting, because the app is working as configured and
          // the user is the only one who can change the answer.
          message: "You're on mobile data and downloads are set to Wi-Fi only.",
          kind: SkifluxErrorKind.downloadWifiOnly,
          // Nothing broke.
          shouldReportToCrashReporting: false,
        );
      case SkifluxErrorKind.downloadFailed:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: "That download didn't finish. Please try again.",
          kind: SkifluxErrorKind.downloadFailed,
          shouldReportToCrashReporting: true,
          actionLabel: 'Try Again',
        );

      // ── Fallback ─────────────────────────────────────────────────
      case SkifluxErrorKind.unknown:
        return const ClassifiedError(
          uiType: ErrorUiType.toast,
          message: 'Something went wrong. Please try again.',
          kind: SkifluxErrorKind.unknown,
          shouldReportToCrashReporting: true,
        );
    }
  }

  /// Crash-reporting hook wired directly to Sentry SDK.
  void reportTechnicalError(
    Object error, {
    StackTrace? stackTrace,
    SkifluxErrorKind? kind,
  }) {
    const dsn = EnvConfig.sentryDsn;
    debugPrint(
      '[SkifluxErrorReport] dsn=${dsn.isNotEmpty ? 'configured' : 'none'} '
      'kind=${kind ?? 'unclassified'} '
      'error=$error'
      '${stackTrace != null ? '\n$stackTrace' : ''}',
    );

    if (dsn.isNotEmpty) {
      unawaited(
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          hint: kind != null ? Hint.withMap({'kind': kind.name}) : null,
        ),
      );
    }
  }
}

/// Riverpod access point for the classifier + reporting hook.
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return const ErrorHandler();
});
