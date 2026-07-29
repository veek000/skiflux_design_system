import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'change_password_screen.dart';
import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Security** (`1256:20691`) — a Change Password row plus an
// "Advanced Security" card with Biometric Login and Two-Factor Authentication
// switches.

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Security',
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
              children: [
                SettingsTile(
                  icon: RemixIcons.lock_2_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Change Password',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Advanced Security',
              children: [
                SettingsTile(
                  icon: RemixIcons.fingerprint_2_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Biometric Login',
                  subtitle: 'Use Face ID or Touch ID',
                  trailing: SkifluxSwitch(
                    value: settings.biometricLogin,
                    onChanged: notifier.setBiometricLogin,
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.shield_keyhole_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Require an SMS code to login',
                  trailing: SkifluxSwitch(
                    value: settings.twoFactorAuth,
                    onChanged: notifier.setTwoFactorAuth,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
