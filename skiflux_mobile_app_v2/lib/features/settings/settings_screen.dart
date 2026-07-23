import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../wallet/wallet_screen.dart';
import 'app_language_screen.dart';
import 'bank_accounts_screen.dart';
import 'data/settings_store.dart';
import 'download_quality_screen.dart';
import 'edit_profile_screen.dart';
import 'help_centre_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_data_screen.dart';
import 'security_screen.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings Flow 01** (`1256:21198`) — the settings hub reached from
// the gear icon on My Profile. Grouped rows: Account, Payments & Financials,
// Preferences, Support & Legal, then Log out and the app version footer.

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Settings',
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
              label: 'Account',
              children: [
                SettingsTile(
                  icon: RemixIcons.user_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Profile',
                  subtitle: '@amara · Edit profile',
                  onTap: () => _push(context, const EditProfileScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.lock_2_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Password & security',
                  onTap: () => _push(context, const SecurityScreen()),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Payments & Financials',
              children: [
                SettingsTile(
                  icon: RemixIcons.copper_coin_fill,
                  iconBackground: SkifluxColors.backgroundNoticeSubtle,
                  iconColor: SkifluxColors.contentNoticeBold,
                  title: 'SkillCoin wallet',
                  subtitle: 'Top up and view balance',
                  onTap: () => _push(context, const WalletScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.bank_card_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Payment methods',
                  subtitle: 'Manage cards for coin purchases',
                  onTap: () => _push(context, const PaymentMethodsScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.bank_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Withdrawal accounts',
                  subtitle: 'Where you receive your funds',
                  onTap: () => _push(context, const BankAccountsScreen()),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Preferences',
              children: [
                SettingsTile(
                  icon: RemixIcons.notification_3_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Notifications',
                  onTap: () =>
                      _push(context, const NotificationSettingsScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.download_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Download quality',
                  subtitle: settings.downloadQuality.label,
                  onTap: () => _push(context, const DownloadQualityScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.play_circle_fill,
                  iconBackground: SkifluxColors.backgroundInfoSubtle,
                  iconColor: SkifluxColors.contentInfoBold,
                  title: 'Auto-play next episode',
                  trailing: SkifluxSwitch(
                    value: settings.autoPlayNext,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setAutoPlayNext(v),
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.globe_fill,
                  iconBackground: SkifluxColors.backgroundInfoSubtle,
                  iconColor: SkifluxColors.contentInfoBold,
                  title: 'App language',
                  trailing: SettingsValueTrailing(settings.appLanguage.label),
                  onTap: () => _push(context, const AppLanguageScreen()),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Support & Legal',
              children: [
                SettingsTile(
                  icon: RemixIcons.shield_check_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Privacy & data',
                  onTap: () => _push(context, const PrivacyDataScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.question_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Help centre',
                  onTap: () => _push(context, const HelpCentreScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.star_s_fill,
                  iconBackground: SkifluxColors.backgroundNoticeSubtle,
                  iconColor: SkifluxColors.contentNoticeBold,
                  title: 'Rate us on the App Store',
                  trailing: const SettingsExternalTrailing(),
                  onTap: () => SkifluxToast.info(
                    context,
                    'Opening the App Store…',
                  ),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: RemixIcons.logout_box_fill,
                  iconBackground: SkifluxColors.backgroundNegativeSubtle,
                  iconColor: SkifluxColors.contentNegative,
                  title: 'Log out',
                  titleColor: SkifluxColors.contentNegative,
                  onTap: () => _logOut(context),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceXl),
            _Footer(),
            const SizedBox(height: SkifluxSpacing.spaceL),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logOut(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Log out?',
      message: "You'll need to sign in again to access your profile, "
          'wallet, and downloads.',
      confirmLabel: 'Log out',
      icon: RemixIcons.logout_box_fill,
    );
    if (confirmed == true && context.mounted) {
      SkifluxToast.info(context, 'You have been logged out');
    }
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Skiflux',
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          'Version 1.0.0 · Build 100',
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
      ],
    );
  }
}
