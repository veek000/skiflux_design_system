import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/toast/skiflux_toast.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Help Centre** (`1256:20730`) — Contact Support (chat +
// email) and Popular Topics links.

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Help Centre',
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
              label: 'Contact Support',
              children: [
                SettingsTile(
                  icon: RemixIcons.chat_3_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Chat with us',
                  subtitle: 'Typically replies in 5 mins',
                  onTap: () => SkifluxToast.info(context, 'Starting a chat…'),
                ),
                SettingsTile(
                  icon: RemixIcons.mail_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Send an email',
                  subtitle: 'support@skiflux.com',
                  trailing: const SettingsExternalTrailing(),
                  onTap: () =>
                      SkifluxToast.info(context, 'Opening your mail app…'),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Popular Topics',
              children: [
                for (final topic in const [
                  'How to withdraw SkillCoins',
                  'Why was my task rejected?',
                  'Earning badges',
                ])
                  SettingsTile(
                    icon: RemixIcons.article_fill,
                    iconBackground: SkifluxColors.backgroundHover,
                    iconColor: SkifluxColors.contentSecondary,
                    title: topic,
                    trailing: const SettingsExternalTrailing(),
                    onTap: () => SkifluxToast.info(context, 'Opening “$topic”…'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
