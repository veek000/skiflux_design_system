import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../auth/auth_flow.dart';
import '../auth/data/auth_store.dart';
import '../profile/data/profile_store.dart';
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
    // Real handle when the profile has loaded; plain "Edit profile" while it
    // hasn't (or the load failed) rather than someone else's hardcoded name.
    final handle = ref.watch(meProfileProvider).value?.handle ?? '';
    final profileSubtitle = handle.isEmpty
        ? 'Edit profile'
        : '$handle · Edit profile';

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
                  subtitle: profileSubtitle,
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
                  iconColor: SkifluxColors.contentNotice,
                  title: 'SkillCoin wallet',
                  subtitle: 'Top up and view balance',
                  onTap: () => _push(context, const WalletScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.bank_card_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Payment methods',
                  subtitle: 'Manage cards for coin purchases',
                  onTap: () => _push(context, const PaymentMethodsScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.bank_fill,
                  iconBackground: SkifluxColors.backgroundInfoSubtle,
                  iconColor: SkifluxColors.contentInfo,
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
                  iconBackground: SkifluxColors.backgroundInfoSubtle,
                  iconColor: SkifluxColors.contentInfo,
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
                  iconBackground: SkifluxColors.backgroundNoticeSubtle,
                  iconColor: SkifluxColors.contentNotice,
                  title: 'Auto-play next episode',
                  trailing: SkifluxSwitch(
                    value: settings.autoPlayNext,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setAutoPlayNext(v),
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.globe_fill,
                  iconBackground: SkifluxColors.backgroundDisabled,
                  iconColor: SkifluxColors.contentTertiary,
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
                  iconBackground: SkifluxColors.backgroundNoticeSubtle,
                  iconColor: SkifluxColors.contentNotice,
                  title: 'Help centre',
                  onTap: () => _push(context, const HelpCentreScreen()),
                ),
                SettingsTile(
                  icon: RemixIcons.star_s_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Rate us on the App Store',
                  trailing: const SettingsExternalTrailing(),
                  onTap: () =>
                      SkifluxToast.info(context, 'Opening the App Store…'),
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
                  onTap: () => _logOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
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

  /// Confirm, then the real sign-out: `POST /auth/logout` + keychain clear via
  /// [AuthFlowNotifier.signOut], then the navigation stack is reset to the
  /// auth flow root so no signed-in screen survives behind the back gesture.
  ///
  /// The toast this used to show was theatre — it announced a log-out while
  /// the token pair stayed in the keychain and every screen kept working.
  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Log out?',
      message:
          "You'll need to sign in again to access your profile, "
          'wallet, and downloads.',
      confirmLabel: 'Log out',
      icon: RemixIcons.logout_box_fill,
    );
    if (confirmed != true || !context.mounted) return;
    try {
      // Ends locally signed out even when the server call fails (the
      // repository swallows that case); anything else — an unwritable
      // keychain, say — means the session did NOT end, so it surfaces and
      // navigation stays put.
      await ref.read(authFlowProvider.notifier).signOut();
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      await ErrorDisplay.show(context, ref, error, stackTrace: stackTrace);
      return;
    }
    if (!context.mounted) return;
    // The previous account's profile must not flash for the next one.
    ref.invalidate(meProfileProvider);
    SkifluxToast.info(context, 'You have been logged out');
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthFlow()),
        (route) => false,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Skiflux',
          style: SkifluxTypography.headingH9Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '1.0.0';
            final buildNumber = snapshot.data?.buildNumber ?? '1';
            return Text(
              'Version $version · Build $buildNumber',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            );
          },
        ),
      ],
    );
  }
}
