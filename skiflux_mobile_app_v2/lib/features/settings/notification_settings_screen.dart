import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Notifications** (`1256:20787`) — grouped notification
// switches: Activity, Coins & Rewards, Platform. Each toggle is backed by
// [settingsProvider].

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(settingsProvider).notifications;
    final notifier = ref.read(settingsProvider.notifier);

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
          onChanged: (v) => notifier.toggleNotification(pref, v),
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
                  color: SkifluxColors.contentNoticeBold,
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
                  color: SkifluxColors.contentNoticeBold,
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
                  icon: RemixIcons.notification_3_fill,
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
