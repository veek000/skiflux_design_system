/// When, and how, the app asks to send notifications.
///
/// The timing is the whole problem. On iOS the system prompt is shown **once
/// ever**: decline it and the only way back is a trip to Settings, which
/// almost nobody makes. Asking at cold start — before the user has seen
/// anything worth being notified about — is the reliable way to get declined,
/// and it is why [FcmService.requestPermission] was deliberately left
/// uncalled until this file.
///
/// So two things happen here:
///
///  * **A soft pre-prompt first.** A Skiflux sheet explains what the
///    notifications are for and offers "Not now". Declining *that* costs
///    nothing — the real system prompt is never spent, and the app can ask
///    again another day. Only "Turn on" reaches the OS.
///  * **Asked after sign-in, not before.** The user has committed to an
///    account by then, and the reasons given in the sheet (a creator posting,
///    a streak about to lapse) are true of their account rather than abstract.
///
/// Whether the OS prompt has been spent is recorded so it is never re-shown;
/// the soft prompt has its own, more forgiving, cooldown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../sheets/skiflux_sheet.dart';
import 'fcm_service.dart';
import 'local_notifications.dart';

/// Set once the OS-level prompt has actually been shown. It cannot be shown
/// again on iOS, so this stops the app pretending otherwise.
const _kOsPromptSpent = 'notifications.os_prompt_spent';

/// When the soft pre-prompt was last dismissed with "Not now", as millis since
/// epoch. Declining the soft prompt is not a permanent no.
const _kSoftPromptDeclinedAt = 'notifications.soft_declined_at';

/// How long "Not now" is respected before the soft prompt may appear again.
const _softPromptCooldown = Duration(days: 14);

/// Ask for notification permission, if this is a good moment to.
///
/// Returns true only when permission is granted as a result of this call.
/// Silently does nothing when the prompt has already been spent, when the user
/// recently said "Not now", or when the sheet is declined.
Future<bool> maybeAskForNotificationPermission(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kOsPromptSpent) ?? false) return false;

  final declinedAt = prefs.getInt(_kSoftPromptDeclinedAt);
  if (declinedAt != null) {
    final since = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(declinedAt),
    );
    if (since < _softPromptCooldown) return false;
  }

  if (!context.mounted) return false;
  final wants = await _showPrePrompt(context);
  if (wants != true) {
    // A soft "no" is remembered, but only for the cooldown.
    await prefs.setInt(
      _kSoftPromptDeclinedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    return false;
  }

  // Past this line the OS prompt is spent whatever the answer, so record it
  // before awaiting — a crash mid-prompt must not earn a second ask.
  await prefs.setBool(_kOsPromptSpent, true);
  final granted = await ref.read(fcmServiceProvider).requestPermission();

  // Android 13+ also needs the local-notifications runtime grant for tray
  // lines we post ourselves (foreground push mirror, download progress).
  if (granted) {
    await ref.read(localNotificationsProvider).requestPermission();
  }

  // A grant can produce a token where there was none (iOS registers with APNs
  // only after authorisation), so re-probe rather than waiting for the next
  // cold start.
  if (granted) await ref.read(fcmServiceProvider).getToken();
  return granted;
}

/// The explainer. Deliberately concrete about what gets sent — "stay updated"
/// is what an app says when it intends to send whatever it likes.
Future<bool?> _showPrePrompt(BuildContext context) {
  return showSkifluxSheet<bool>(
    context: context,
    builder: (sheetContext) => SkifluxSheetShell(
      title: 'Turn on notifications?',
      showHeader: false,
      child: Padding(
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
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  color: SkifluxColors.brand100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.notification_3_fill,
                  size: 48,
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              'Turn on notifications?',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              "We'll tell you when a creator you follow posts, when a task "
              'you submitted is reviewed, and before a streak runs out. '
              'Nothing else.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Turn on',
              expanded: true,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Not now',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Clears both records so the prompts can be exercised again.
///
/// For the diagnostics screen: without this the pre-prompt can be seen exactly
/// once per install, which makes it untestable on a real device.
Future<void> resetNotificationPromptState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kOsPromptSpent);
  await prefs.remove(_kSoftPromptDeclinedAt);
}
