import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/notifications/fcm_service.dart';
import '../../shared/notifications/local_notifications.dart';
import '../../shared/notifications/notification_permission.dart';
import '../../shared/toast/skiflux_toast.dart';
import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Notifications** (`1256:20787`) — grouped notification
// switches: Activity, Coins & Rewards, Platform. Backed by [settingsProvider],
// which syncs the seven switches with `GET/PATCH /me/notification-preferences`:
// opening this screen pulls the server's answer, and each flip PATCHes
// optimistically, rolling back (with an error surfaced) when the server
// refuses.

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Hydrate from the backend; on failure the cached values stay on screen.
    unawaited(ref.read(settingsProvider.notifier).syncNotificationPrefs());
  }

  /// Optimistic flip — the notifier already rolled the switch back before
  /// this catch runs, so all that's left is telling the user why it snapped.
  Future<void> _toggle(NotificationPref pref, bool value) async {
    try {
      await ref
          .read(settingsProvider.notifier)
          .setNotificationPref(pref, value);
    } catch (error, stackTrace) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(settingsProvider).notifications;

    SettingsTile tile({
      required NotificationPref pref,
      required IconData icon,
      required Color background,
      required Color color,
      required String title,
      required String subtitle,
    }) {
      return SettingsTile(
        icon: icon,
        iconBackground: background,
        iconColor: color,
        title: title,
        subtitle: subtitle,
        trailing: SkifluxSwitch(
          value: prefs[pref] ?? false,
          onChanged: (v) {
            unawaited(_toggle(pref, v));
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Notifications',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            SettingsSection(
              label: 'Activity',
              children: [
                tile(
                  pref: NotificationPref.newEpisodes,
                  icon: RemixIcons.play_circle_fill,
                  background: SkifluxColors.brand100,
                  color: SkifluxColors.contentBrand,
                  title: 'New episodes',
                  subtitle: 'From creators you follow',
                ),
                tile(
                  pref: NotificationPref.taskUpdates,
                  icon: RemixIcons.checkbox_circle_fill,
                  background: SkifluxColors.backgroundNoticeSubtle,
                  color: SkifluxColors.contentNotice,
                  title: 'Task updates',
                  subtitle: 'Reviews, approvals, revisions',
                ),
                tile(
                  pref: NotificationPref.commentReplies,
                  icon: RemixIcons.chat_3_fill,
                  background: SkifluxColors.backgroundPositiveSubtle,
                  color: SkifluxColors.contentPositive,
                  title: 'Comment replies',
                  subtitle: 'When someone replies to you',
                ),
                tile(
                  pref: NotificationPref.commentLikes,
                  icon: RemixIcons.heart_3_fill,
                  background: SkifluxColors.backgroundNegativeSubtle,
                  color: SkifluxColors.contentNegative,
                  title: 'Comment likes',
                  subtitle: 'When someone likes your comment',
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Coins & Rewards',
              children: [
                tile(
                  pref: NotificationPref.coinEarnings,
                  icon: RemixIcons.copper_coin_fill,
                  background: SkifluxColors.backgroundPositiveSubtle,
                  color: SkifluxColors.contentPositive,
                  title: 'Coin earnings',
                  subtitle: 'When you earn SkillCoins',
                ),
                tile(
                  pref: NotificationPref.badges,
                  icon: RemixIcons.award_fill,
                  background: SkifluxColors.backgroundNoticeSubtle,
                  color: SkifluxColors.contentNotice,
                  title: 'Badges',
                  subtitle: 'When you unlock a new badge',
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Platform',
              children: [
                tile(
                  pref: NotificationPref.platformAnnouncements,
                  icon: RemixIcons.notification_badge_fill,
                  background: SkifluxColors.brand100,
                  color: SkifluxColors.contentBrand,
                  title: 'Platform announcements',
                  subtitle: 'New features and updates',
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: SkifluxSpacing.spaceL),
              const _PushDiagnostics(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Debug-only push diagnostics.
///
/// A push notification cannot be exercised from inside the app: Android only
/// draws one in the tray when the app is backgrounded, and the message has to
/// come from Firebase. What the device *can* do is hand over the two things
/// needed to send one — the registration token and the permission state — so
/// they are surfaced here instead of only in `debugPrint`, which is unreadable
/// on a real handset.
///
/// Wrapped in [kDebugMode] at the call site, so it is compiled out of release.
class _PushDiagnostics extends ConsumerStatefulWidget {
  const _PushDiagnostics();

  @override
  ConsumerState<_PushDiagnostics> createState() => _PushDiagnosticsState();
}

class _PushDiagnosticsState extends ConsumerState<_PushDiagnostics> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  Future<void> _probe() async {
    final token = await ref.read(fcmServiceProvider).getToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fcm = ref.read(fcmServiceProvider);
    final granted = fcm.permissionGranted;
    final token = _token;

    return SettingsSection(
      label: 'Push diagnostics (debug only)',
      children: [
        SettingsTile(
          icon: RemixIcons.shield_check_fill,
          iconBackground: SkifluxColors.backgroundInfoSubtle,
          iconColor: SkifluxColors.contentInfoBold,
          title: 'Permission',
          subtitle: switch (granted) {
            null => 'Not asked yet on this install',
            true => 'Granted',
            false => 'Denied or unavailable',
          },
          onTap: () async {
            // Goes through the same soft pre-prompt the app uses after
            // sign-in, so what is tested is the real flow.
            await maybeAskForNotificationPermission(context, ref);
            if (mounted) setState(() {});
          },
        ),
        SettingsTile(
          icon: RemixIcons.refresh_line,
          iconBackground: SkifluxColors.backgroundNoticeSubtle,
          iconColor: SkifluxColors.contentNotice,
          title: 'Reset prompt state',
          subtitle: 'Lets the pre-prompt appear again on this device',
          onTap: () async {
            await resetNotificationPromptState();
            if (!context.mounted) return;
            SkifluxToast.success(context, 'Prompt state cleared');
          },
        ),
        SettingsTile(
          icon: RemixIcons.notification_badge_fill,
          iconBackground: SkifluxColors.backgroundPositiveSubtle,
          iconColor: SkifluxColors.contentPositive,
          title: 'Send a test notification',
          // A *push* cannot be triggered from in here — the message has to
          // come from Firebase, and Android only draws one in the tray when
          // the app is backgrounded. This posts a local one instead, which
          // exercises everything except the FCM transport: the runtime
          // permission, the channel, and the monochrome tray icon.
          subtitle: 'Posts to the tray now — background the app to see it',
          onTap: () async {
            final sent = await ref.read(localNotificationsProvider).sendTest();
            if (!context.mounted) return;
            if (sent) {
              SkifluxToast.success(context, 'Sent — check your tray');
            } else {
              // Says which of the two it was rather than "nothing happened".
              SkifluxToast.error(
                context,
                fcm.permissionGranted == true
                    ? 'Not supported on this platform'
                    : 'Grant notification permission first',
              );
            }
          },
        ),
        SettingsTile(
          icon: RemixIcons.key_2_fill,
          iconBackground: SkifluxColors.brand100,
          iconColor: SkifluxColors.contentBrand,
          title: 'FCM token',
          subtitle: _loading
              ? 'Reading…'
              : (token == null
                    ? 'Unavailable — no Firebase config, or permission denied'
                    : 'Tap to copy · ${token.substring(0, 12)}…'),
          onTap: token == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: token));
                  if (!context.mounted) return;
                  SkifluxToast.success(context, 'Token copied');
                },
        ),
      ],
    );
  }
}
