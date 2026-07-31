import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
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
          ],
        ),
      ),
    );
  }
}
