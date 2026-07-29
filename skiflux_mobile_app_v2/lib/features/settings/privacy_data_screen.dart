import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/sheets/success_sheet.dart';
import '../auth/data/legal_documents.dart';
import '../auth/screens/legal_screen.dart';
import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Privacy & Data** (`1256:20874`) — data/activity toggles
// plus data-management links: Request my data → "Data Export Requested"
// (`1256:20935`), the two legal documents (`1277:32411` / `1277:32341`), and
// Delete Account → "Delete Account?" (`1256:21069`) → "Account Deleted"
// (`1256:21002`).

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
                  onTap: () => showSuccessSheet(
                    context,
                    title: 'Data Export Requested',
                    message:
                        'Your data export is being processed. We will '
                        'email you a secure download link shortly.',
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
                  onTap: () => _deleteAccount(context),
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

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete Account?',
      message:
          'This action is completely irreversible. All your progress, '
          'badges, and SkillCoins will be permanently wiped.',
      confirmLabel: 'Delete Account',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !context.mounted) return;
    await showSuccessSheet(
      context,
      title: 'Account Deleted',
      message:
          'Your account has been deleted. You will be logged out '
          'shortly.',
    );
  }
}
