import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → App Language** (`1256:20068`) — a single radio card of
// available languages.

class AppLanguageScreen extends ConsumerWidget {
  const AppLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(settingsProvider).appLanguage;
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'App Language',
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
                for (final language in AppLanguage.values)
                  InkWell(
                    onTap: () => notifier.setAppLanguage(language),
                    borderRadius: SkifluxRadii.borderL,
                    child: Padding(
                      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.label,
                              style: SkifluxTypography.uiButtonMedium.copyWith(
                                color: SkifluxColors.contentPrimary,
                              ),
                            ),
                          ),
                          SkifluxRadio<AppLanguage>(
                            value: language,
                            groupValue: selected,
                            onChanged: notifier.setAppLanguage,
                          ),
                        ],
                      ),
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
