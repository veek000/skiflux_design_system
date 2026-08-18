import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/sheets/skiflux_sheet.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../../playlists/data/playlists_store.dart';
import '../../profile/data/download_action.dart';
import '../../profile/data/downloads_store.dart';
import '../../profile/data/library_episode.dart';
import '../data/episode_resource.dart';
import '../data/home_feed_store.dart';
import '../../tasks/data/tasks_store.dart';
import '../../tasks/quiz_intro_screen.dart';
import '../../tasks/submission_task_screen.dart';
import 'episode_resources_sheet.dart';
import 'playback_speed_sheet.dart';

// Figma: **Other Video Player Flow 08** (`1256:27071`) — More Menu.

/// Result the sheet can hand back to the feed card.
///
/// Full Screen is opened by the **caller** so it can reuse the live
/// [VideoPlayerController] — pushing from inside the sheet after `pop`
/// completed the sheet future too early and forced a brand-new player
/// that always started at 0:00.
enum MoreMenuResult { fullScreen }

Future<MoreMenuResult?> showMoreMenuSheet(
  BuildContext context, {
  String? episodeId,
  HomeFeedItem? item,
}) {
  return showSkifluxSheet<MoreMenuResult>(
    context: context,
    builder: (_) => _MoreMenuSheet(episodeId: episodeId, item: item),
  );
}

class _MoreMenuSheet extends ConsumerWidget {
  const _MoreMenuSheet({this.episodeId, this.item});

  /// Backend UUID of the episode this menu was opened for; null for demo
  /// catalogue items that only exist client-side.
  final String? episodeId;

  /// The full feed item, when the caller has one. Downloading needs more than
  /// an id — the row that appears in Downloads has to render offline, so the
  /// title, creator and thumbnail travel with it.
  final HomeFeedItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playerPrefsProvider);
    final prefsNotifier = ref.read(playerPrefsProvider.notifier);
    final resources = item?.resources ?? const <EpisodeResource>[];
    final canDownload =
        (item?.hasPlayableVideo ?? false) && (item?.episodeId?.isNotEmpty ?? false);
    return SkifluxSheetShell(
      title: 'More Menu',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          // Both cards are conditional on the episode actually having
          // something behind them. They used to render unconditionally, so an
          // episode with no task offered "View Task" (which silently did
          // nothing) and every episode offered Resources (which opened four
          // hardcoded filenames).
          if (item?.hasTask ?? false) ...[
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
          ],
          if (resources.isNotEmpty) ...[
            _FeatureCard(
              color: SkifluxColors.backgroundHover,
              iconBackground: SkifluxColors.backgroundPrimary,
              icon: RemixIcons.folder_download_fill,
              title: 'Episode Resources',
              subtitle: resources.length == 1
                  ? '1 file or link'
                  : '${resources.length} files and links',
              trailing: RemixIcons.download_2_line,
              onTap: () {
                Navigator.of(context).pop();
                showEpisodeResourcesSheet(context, resources);
              },
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
          ],
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
          // Download / delete offline copy. Hidden when there is nothing to
          // fetch and nothing on disk. When already downloaded the row is
          // "Delete Download" — keeping "Download" invited a no-op toast.
          if (canDownload || _isDownloaded(ref))
            _MenuRow(
              icon: _isDownloaded(ref)
                  ? RemixIcons.delete_bin_fill
                  : RemixIcons.download_fill,
              label: _downloadLabel(ref),
              color: _isDownloaded(ref)
                  ? SkifluxColors.contentNegative
                  : SkifluxColors.contentPrimary,
              onTap: () => _downloadOrDelete(context, ref),
            ),
          _MenuRow(
            icon: RemixIcons.fullscreen_fill,
            label: 'Full Screen',
            // Pop a result — the feed card pushes [FullScreenPlayerScreen]
            // with its live controller so playback continues (TikTok-style).
            onTap: () => Navigator.of(context).pop(MoreMenuResult.fullScreen),
          ),
          // TODO(backend, minor): this toggle stores `captionsOn` and nothing
          // reads it — no player renders captions and `Episode` carries no
          // caption/subtitle track, so the chip flips On/Off over a feature
          // that does not exist (tracker #63 / #61). Either a caption track on
          // Episode (WebVTT URL) or this row should go. Expects:
          // `captions_url` / `subtitles: [{lang, url}]` on Episode.
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
            onTap: () => _notInterested(context, ref),
          ),
          // TODO(backend, blocking): no episode-report endpoint exists in the
          // spec — the toast below is a UX placeholder until one ships —
          // expects: POST /episodes/{id}/report → 204
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

  bool _isDownloaded(WidgetRef ref) {
    final id = episodeId;
    if (id == null) return false;
    for (final d in ref.watch(downloadsProvider)) {
      if (d.episode.id == id && d.isComplete) return true;
    }
    return false;
  }

  bool _isDownloading(WidgetRef ref) {
    final id = episodeId;
    if (id == null) return false;
    for (final d in ref.watch(downloadsProvider)) {
      if (d.episode.id == id && d.isDownloading) return true;
    }
    return false;
  }

  /// "Download Episode" / "Delete Download" / "Downloading…".
  String _downloadLabel(WidgetRef ref) {
    if (_isDownloaded(ref)) return 'Delete Download';
    if (_isDownloading(ref)) return 'Downloading…';
    return 'Download Episode';
  }

  /// Download when missing; remove the offline pack when already complete.
  Future<void> _downloadOrDelete(BuildContext context, WidgetRef ref) async {
    final id = episodeId;
    final feedItem = item;
    Navigator.of(context).pop();
    if (id != null &&
        ref.read(downloadsProvider.notifier).isDownloaded(id)) {
      await ref.read(downloadsProvider.notifier).remove(id);
      if (context.mounted) {
        SkifluxToast.success(context, 'Download deleted');
      }
      return;
    }
    await downloadEpisode(
      context,
      ref,
      feedItem == null ? null : LibraryEpisode.fromFeedItem(feedItem),
    );
  }

  /// `POST /episodes/not-interested` via the feed store — the card is removed
  /// optimistically and restored (with the error surfaced here, sheet still
  /// open) if the server rejects. Demo items with no backend id just toast.
  Future<void> _notInterested(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final id = episodeId;
    if (id == null) {
      navigator.pop();
      SkifluxToast.success(context, "We'll show fewer videos like this");
      return;
    }
    try {
      await ref.read(homeFeedProvider.notifier).notInterested(id);
      if (!context.mounted) return;
      navigator.pop();
      SkifluxToast.success(context, "We'll show fewer videos like this");
    } catch (e, st) {
      if (context.mounted) {
        await ErrorDisplay.show(context, ref, e, stackTrace: st);
      }
    }
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
        MaterialPageRoute(builder: (_) => QuizIntroScreen(taskId: target!.id)),
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
