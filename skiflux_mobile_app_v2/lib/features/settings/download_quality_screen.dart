import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/sheets/success_sheet.dart';
import 'data/settings_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Download Quality** (`1256:20009`) — a radio list of
// quality tiers plus a Storage card (used storage, Wi-Fi-only toggle, Clear
// all downloads). Clearing routes through the "Clear All Downloads?" confirm
// (`1256:20100`) → "Downloads Cleared" success (`1256:20173`).

class DownloadQualityScreen extends ConsumerWidget {
  const DownloadQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Download Quality',
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
            Text(
              'Choose the video quality for downloaded episodes. Higher '
              'quality uses more storage on your device.',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              children: [
                for (final quality in DownloadQuality.values)
                  _QualityRow(
                    quality: quality,
                    groupValue: settings.downloadQuality,
                    onChanged: notifier.setDownloadQuality,
                  ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SettingsSection(
              label: 'Storage',
              children: [
                SettingsTile(
                  icon: RemixIcons.hard_drive_2_fill,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Used storage',
                  trailing: Text(
                    '1.2 GB',
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.wifi_fill,
                  iconBackground: SkifluxColors.backgroundPositiveSubtle,
                  iconColor: SkifluxColors.contentPositive,
                  title: 'Download on Wi-Fi only',
                  trailing: SkifluxSwitch(
                    value: settings.downloadOnWifiOnly,
                    onChanged: notifier.setDownloadOnWifiOnly,
                  ),
                ),
                SettingsTile(
                  icon: RemixIcons.delete_bin_fill,
                  iconBackground: SkifluxColors.backgroundNegativeSubtle,
                  iconColor: SkifluxColors.contentNegative,
                  title: 'Clear all downloads',
                  titleColor: SkifluxColors.contentNegative,
                  onTap: () => _clearAll(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Clear All Downloads?',
      message: 'Are you sure you want to delete 1.2 GB of downloaded '
          'episodes? You will need to download them again to watch offline.',
      confirmLabel: 'Clear download',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !context.mounted) return;
    await showSuccessSheet(
      context,
      title: 'Downloads Cleared',
      message: 'All downloaded episodes have been successfully removed.',
    );
  }
}

/// A quality option row: title + size caption + trailing radio (no icon).
class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.quality,
    required this.groupValue,
    required this.onChanged,
  });

  final DownloadQuality quality;
  final DownloadQuality groupValue;
  final ValueChanged<DownloadQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(quality),
      borderRadius: SkifluxRadii.borderL,
      child: Padding(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quality.label,
                    style: SkifluxTypography.uiButtonMedium.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.space2xs),
                  Text(
                    quality.caption,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxRadio<DownloadQuality>(
              value: quality,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
