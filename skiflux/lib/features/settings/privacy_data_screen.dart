import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/toast/skiflux_toast.dart';
import '../auth/data/legal_documents.dart';
import '../auth/screens/legal_screen.dart';
import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Privacy & Data** (`1256:20874`) — data/activity toggles
// plus data-management links and the two legal documents.
//
// "Request my data" and "Delete Account" are drawn but honest about their
// state: the spec has no learner-facing data-export or account-deletion
// endpoint (deactivation exists only as an admin action), so both say
// "coming soon" on tap instead of the fabricated "Data Export Requested" /
// "Account Deleted" success sheets they used to show (`1256:20935`,
// `1256:21069`, `1256:21002`). Wire the sheets back in when the endpoints
// ship — and make Delete Account sign out on success.

class PrivacyDataScreen extends ConsumerWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Privacy & Data',
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
              label: 'Data & activity',
              children: [
                SettingsTile(
                  icon: RemixIcons.history_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Save watch history',
                  trailing: SkifluxSwitch(
                    value: settings.saveWatchHistory,
                    onChanged: notifier.setSaveWatchHistory,
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.eye_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Personalised recommendations',
                  trailing: SkifluxSwitch(
                    value: settings.personalisedRecommendations,
                    onChanged: notifier.setPersonalisedRecommendations,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Data Management',
              children: [
                SettingsTile(
                  icon: RemixIcons.download_cloud_2_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositiveBold,
                  title: 'Request my data',
                  subtitle: 'Coming soon',
                  onTap: () => SkifluxToast.info(
                    context,
                    'Data export is coming soon. Nothing was requested yet.',
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.todo_fill,
                  iconBackground: SkifluxColors.backgroundHover,
                  iconColor: SkifluxColors.contentSecondary,
                  title: 'Terms of service',
                  onTap: () => _openLegal(context, termsOfUse),
                ),
                SettingsTile(
                  icon: RemixIcons.lock_2_fill,
                  iconBackground: SkifluxColors.backgroundInfoSubtle,
                  iconColor: SkifluxColors.contentInfo,
                  title: 'Privacy Policy',
                  onTap: () => _openLegal(context, privacyPolicy),
                ),
                SettingsTile(
                  icon: RemixIcons.user_unfollow_fill,
                  iconBackground: SkifluxColors.backgroundNegativeSubtle,
                  iconColor: SkifluxColors.contentNegative,
                  title: 'Delete Account',
                  titleColor: SkifluxColors.contentNegative,
                  subtitle: 'Coming soon',
                  onTap: () => SkifluxToast.info(
                    context,
                    'Account deletion is coming soon. Contact '
                    'support@skiflux.com to delete your account today.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pushes one of the two legal documents. They are the same screens the auth
  /// flow shows (Figma `1277:32411` / `1277:32341`), reached here by route
  /// rather than by auth stage — so the back chevron just pops.
  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LegalScreen(
          document: document,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

}
