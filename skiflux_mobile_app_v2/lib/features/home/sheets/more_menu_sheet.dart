import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
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

class _MoreMenuSheet extends StatefulWidget {
  const _MoreMenuSheet();

  @override
  State<_MoreMenuSheet> createState() => _MoreMenuSheetState();
}

class _MoreMenuSheetState extends State<_MoreMenuSheet> {
  final _prefs = PlayerPrefsStore.instance;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefs);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefs);
    super.dispose();
  }

  void _onPrefs() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'More Menu',
      child: ListView(
        shrinkWrap: true,
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
            onTap: () => _openTask(context),
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
            chipLabel: _prefs.speedLabel,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Episode queued for download'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuRow(
            icon: RemixIcons.fullscreen_fill,
            label: 'Full Screen',
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full screen player'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuRow(
            icon: RemixIcons.closed_captioning_fill,
            label: 'Caption',
            chipLabel: _prefs.captionsOn ? 'On' : 'Off',
            chipBackground: _prefs.captionsOn
                ? SkifluxColors.backgroundPrimaryBrand
                : SkifluxColors.backgroundHover,
            chipForeground: _prefs.captionsOn
                ? SkifluxColors.contentBrand
                : SkifluxColors.contentDisabled,
            onTap: () => _prefs.toggleCaptions(),
          ),
          _MenuRow(
            icon: RemixIcons.arrow_down_double_fill,
            label: 'Auto Scroll',
            chipLabel: _prefs.autoScrollOn ? 'On' : 'Off',
            chipBackground: _prefs.autoScrollOn
                ? SkifluxColors.backgroundPrimaryBrand
                : SkifluxColors.backgroundHover,
            chipForeground: _prefs.autoScrollOn
                ? SkifluxColors.contentBrand
                : SkifluxColors.contentDisabled,
            onTap: () => _prefs.toggleAutoScroll(),
          ),
          _MenuRow(
            icon: RemixIcons.eye_off_fill,
            label: 'Not Interested',
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('We\'ll show fewer videos like this'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuRow(
            icon: RemixIcons.flag_fill,
            label: 'Report',
            color: SkifluxColors.contentNegative,
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thanks for your report'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openTask(BuildContext context) {
    Navigator.of(context).pop();
    final tasks = TasksStore.instance.learning;
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
