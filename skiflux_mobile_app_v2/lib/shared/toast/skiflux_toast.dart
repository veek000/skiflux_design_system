/// Generalized toast notifications for the mobile app.
///
/// Lives in the **app** (`shared/toast/`), not the design system package:
/// Figma lists Task Toaster / Modal as not implemented in the DS, and
/// presentation depends on [ScaffoldMessenger] (Material app shell).
/// Uses design-system tokens + Remix icons only — no invented colors.
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Visual / semantic kind of a [SkifluxToast].
enum SkifluxToastType {
  /// Positive confirmation (subscribe, save, unlock, …).
  success,

  /// Non-blocking failure (network, soft send failure, …).
  error,

  /// Neutral status / info (notify prefs, downloads, …).
  info,
}

/// Single entry point for typed, queued floating toasts.
///
/// Built on Material [SnackBar] + [ScaffoldMessenger] so it stays
/// compatible with the existing subscribe/unsubscribe pattern. Types map
/// to existing [SkifluxColors] semantic tokens; default duration is 3.5s.
///
/// **Queuing:** does **not** call [ScaffoldMessenger.hideCurrentSnackBar].
/// Flutter's messenger already queues successive [showSnackBar] calls and
/// shows them one after another — sufficient for this app; no custom queue.
abstract final class SkifluxToast {
  /// Default auto-dismiss (between 3–4s; long enough to read one line).
  static const Duration defaultDuration = Duration(milliseconds: 3500);

  /// Show a toast of [type] with free-form [message] copy.
  static void show(
    BuildContext context, {
    required String message,
    SkifluxToastType type = SkifluxToastType.info,
    Duration duration = defaultDuration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final style = _styleFor(type);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              style.icon,
              size: SkifluxIcons.sizeS,
              color: style.foreground,
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: Text(
                message,
                style: SkifluxTypography.bodyP9Regular.copyWith(
                  color: style.foreground,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: style.background,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: SkifluxRadii.borderM,
        ),
      ),
    );
  }

  /// Convenience: success toast.
  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SkifluxToastType.success);

  /// Convenience: error toast.
  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SkifluxToastType.error);

  /// Convenience: info toast.
  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SkifluxToastType.info);

  static _ToastStyle _styleFor(SkifluxToastType type) {
    switch (type) {
      case SkifluxToastType.success:
        // Positive green fill + inverse (white) label/icon.
        return const _ToastStyle(
          background: SkifluxColors.backgroundPositive,
          foreground: SkifluxColors.contentPrimaryInverse,
          icon: RemixIcons.checkbox_circle_fill,
        );
      case SkifluxToastType.error:
        // Negative red fill + inverse label/icon.
        return const _ToastStyle(
          background: SkifluxColors.backgroundNegative,
          foreground: SkifluxColors.contentPrimaryInverse,
          icon: RemixIcons.error_warning_fill,
        );
      case SkifluxToastType.info:
        // Info blue fill + inverse label/icon.
        return const _ToastStyle(
          background: SkifluxColors.backgroundInfo,
          foreground: SkifluxColors.contentPrimaryInverse,
          icon: RemixIcons.information_fill,
        );
    }
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
