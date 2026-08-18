import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/tasks_store.dart';

/// Combined SkillCoins + XP chip (Figma Task Details reward pill).
///
/// Rewards render from the task's [Decimal] coin value (a 2.50-coin task
/// shows "+2.50", never "+3"). Live tasks whose payload carried no reward
/// hide the corresponding chip — the pill never promises a number the
/// backend didn't state — and collapse entirely when both are absent.
class TaskRewardPill extends StatelessWidget {
  const TaskRewardPill({super.key, required this.task});

  final LearningTask task;

  @override
  Widget build(BuildContext context) {
    if (!task.hasAnyReward) return const SizedBox.shrink();
    // Align left so the grey pill hugs content (ListView would otherwise
    // stretch a bare Container to full width).
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceS,
          vertical: SkifluxSpacing.spaceS,
        ),
        decoration: BoxDecoration(
          color: SkifluxColors.backgroundHover,
          borderRadius: SkifluxRadii.borderX,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.hasCoinReward) ...[
              const Icon(
                RemixIcons.copper_coin_fill,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentNoticeBold,
              ),
              const SizedBox(width: SkifluxSpacing.space2xs),
              Text(
                '+${task.coinsLabel} SkillCoins',
                style: SkifluxTypography.uiInputContent.copyWith(
                  color: SkifluxColors.contentNoticeBold,
                ),
              ),
            ],
            if (task.hasCoinReward && task.hasXpReward)
              const SizedBox(width: SkifluxSpacing.spaceS),
            if (task.hasXpReward) ...[
              const Icon(
                RemixIcons.flashlight_fill,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentBrand,
              ),
              const SizedBox(width: SkifluxSpacing.space2xs),
              Text(
                '+${task.xp} XP',
                style: SkifluxTypography.uiInputContent.copyWith(
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Episode row on task detail / quiz intro — taps open the player sheet.
class TaskEpisodeRow extends StatelessWidget {
  const TaskEpisodeRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderX,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderX,
        child: Row(
          children: [
            const SkifluxAvatar(
              size: SkifluxUnit.u48,
              style: SkifluxAvatarStyle.initial,
              initials: 'AD',
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.headingH10Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              child: Icon(
                RemixIcons.arrow_right_s_line,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the existing episode player sheet for a learning task's episode.
///
/// Takes [ref] (not [ProviderScope.containerOf]) so callers that already
/// have a [WidgetRef] use the same pattern as the rest of the app.
void openTaskEpisode(BuildContext context, WidgetRef ref, LearningTask task) {
  final match = RegExp(
    r'EP\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(task.episodeLabel);
  final epNumber = int.tryParse(match?.group(1) ?? '') ?? 1;

  final subs = ref.read(subscriptionsProvider);

  // Prefer a feed episode with the same number; fall back to a synthetic one
  // so the row always opens a real player sheet.
  SubscriptionEpisode? fromFeed;
  for (final e in subs.feed()) {
    if (e.epNumber == epNumber) {
      fromFeed = e;
      break;
    }
  }

  final episode =
      fromFeed ??
      SubscriptionEpisode(
        epNumber: epNumber,
        title: task.episodeTitle,
        creatorUsername: subs.creators.first.username,
        duration: '12:40',
        views: '2.1k',
        postedAgo: '1d ago',
      );

  showEpisodePlayerModal(context, episode);
}
