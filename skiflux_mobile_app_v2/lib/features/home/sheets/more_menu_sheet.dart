import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../../playlists/data/playlists_store.dart';
import '../../tasks/data/tasks_store.dart';
import '../../tasks/quiz_intro_screen.dart';
import '../../tasks/submission_task_screen.dart';
import 'episode_resources_sheet.dart';
import 'playback_speed_sheet.dart';

// Figma: **Other Video Player Flow 08** (`1256:27071`) — More Menu.

Future<void> showMoreMenuSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _MoreMenuSheet(),
  );
}

class _MoreMenuSheet extends ConsumerWidget {
  const _MoreMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playerPrefsProvider);
    final prefsNotifier = ref.read(playerPrefsProvider.notifier);
    return SkifluxSheetShell(
      title: 'More Menu',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          _FeatureCard(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [SkifluxColors.brand200, SkifluxColors.brand50],
            ),
            iconBackground: SkifluxColors.backgroundHover,
            icon: RemixIcons.clipboard_fill,
            title: 'View Task',
            subtitle: 'See what you need to execute',
            trailing: RemixIcons.arrow_right_s_line,
            onTap: () => _openTask(context, ref),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          _FeatureCard(
            color: SkifluxColors.backgroundHover,
            iconBackground: SkifluxColors.backgroundPrimary,
            icon: RemixIcons.folder_download_fill,
            title: 'Episode Resources',
            subtitle: 'Assets & reference files',
            trailing: RemixIcons.download_2_line,
            onTap: () {
              Navigator.of(context).pop();
              showEpisodeResourcesSheet(context);
            },
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          _MenuRow(
            icon: RemixIcons.speed_fill,
            label: 'Playback Speed',
            chipLabel: prefs.speedLabel,
            chipBackground: SkifluxColors.backgroundPrimaryBrand,
            chipForeground: SkifluxColors.contentBrand,
            onTap: () async {
              Navigator.of(context).pop();
              await showPlaybackSpeedSheet(context);
            },
          ),
          _MenuRow(
            icon: RemixIcons.download_fill,
            label: 'Download Episode',
            onTap: () {
              Navigator.of(context).pop();
              SkifluxToast.info(context, 'Episode queued for download');
            },
          ),
          _MenuRow(
            icon: RemixIcons.fullscreen_fill,
            label: 'Full Screen',
            onTap: () {
              Navigator.of(context).pop();
              SkifluxToast.info(context, 'Full screen player');
            },
          ),
          _MenuRow(
            icon: RemixIcons.closed_captioning_fill,
            label: 'Caption',
            chipLabel: prefs.captionsOn ? 'On' : 'Off',
            chipBackground: prefs.captionsOn
                ? SkifluxColors.backgroundPrimaryBrand
                : SkifluxColors.backgroundHover,
            chipForeground: prefs.captionsOn
                ? SkifluxColors.contentBrand
                : SkifluxColors.contentDisabled,
            onTap: prefsNotifier.toggleCaptions,
          ),
          _MenuRow(
            icon: RemixIcons.arrow_down_double_fill,
            label: 'Auto Scroll',
            chipLabel: prefs.autoScrollOn ? 'On' : 'Off',
            chipBackground: prefs.autoScrollOn
                ? SkifluxColors.backgroundPrimaryBrand
                : SkifluxColors.backgroundHover,
            chipForeground: prefs.autoScrollOn
                ? SkifluxColors.contentBrand
                : SkifluxColors.contentDisabled,
            onTap: prefsNotifier.toggleAutoScroll,
          ),
          _MenuRow(
            icon: RemixIcons.eye_off_fill,
            label: 'Not Interested',
            onTap: () {
              Navigator.of(context).pop();
              SkifluxToast.success(
                context,
                "We'll show fewer videos like this",
              );
            },
          ),
          _MenuRow(
            icon: RemixIcons.flag_fill,
            label: 'Report',
            color: SkifluxColors.contentNegative,
            onTap: () {
              Navigator.of(context).pop();
              SkifluxToast.success(context, 'Thanks for your report');
            },
          ),
        ],
      ),
    );
  }

  void _openTask(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    final tasks = ref.read(tasksProvider).learning;
    // Prefer a pending learning task (submission or quiz).
    LearningTask? target;
    for (final t in tasks) {
      if (t.status == LearningTaskStatus.pending ||
          t.status == LearningTaskStatus.actionNeeded) {
        target = t;
        break;
      }
    }
    target ??= tasks.isNotEmpty ? tasks.first : null;
    if (target == null) return;
    if (target.kind == LearningTaskKind.quiz) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizIntroScreen(taskId: target!.id),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubmissionTaskScreen(taskId: target!.id),
        ),
      );
    }
  }
}


class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    this.color,
    this.gradient,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final Color? color;
  final Gradient? gradient;
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderL,
      child: Container(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: SkifluxRadii.borderL,
        ),
        child: Row(
          children: [
            Container(
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SkifluxTypography.uiButtonLarge.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  Text(
                    subtitle,
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              trailing,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = SkifluxColors.contentPrimary,
    this.chipLabel,
    this.chipBackground = SkifluxColors.backgroundHover,
    this.chipForeground = SkifluxColors.contentDisabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? chipLabel;
  final Color chipBackground;
  final Color chipForeground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: SkifluxUnit.u48,
        child: Row(
          children: [
            Icon(icon, size: SkifluxIcons.sizeM, color: color),
            const SizedBox(width: SkifluxSpacing.spaceL),
            Expanded(
              child: Text(
                label,
                style: SkifluxTypography.uiButtonLarge.copyWith(color: color),
              ),
            ),
            if (chipLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: SkifluxRadii.borderX,
                ),
                child: Text(
                  chipLabel!,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: chipForeground,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
