import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/utils/external_link.dart';
import '../../shared/widgets/load_failure.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/tasks_store.dart';
import 'quiz_intro_screen.dart';
import 'quiz_result_screen.dart';
import 'submission_task_screen.dart';

// Figma: **Task Flow** (`1256:12977`) — Tasks tab body.
// TF15 Learning (`1256:13693`), TF14 Mission (`2902:13714`),
// TF13 Marketplace empty (`1256:14057`).

/// Body of the bottom-nav Tasks tab (tab bar lives in HomeScreen).
class TasksBody extends ConsumerStatefulWidget {
  const TasksBody({super.key});

  @override
  ConsumerState<TasksBody> createState() => _TasksBodyState();
}

class _TasksBodyState extends ConsumerState<TasksBody> {
  int _segment = 0; // Learning / Mission / Marketplace
  // null = All; otherwise maps to status (Revision → actionNeeded).
  LearningTaskStatus? _filter;

  @override
  void initState() {
    super.initState();
    // Missions otherwise load exactly once, at login; re-sync both sections
    // every time the Tasks tab opens so the lists can't go stale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(tasksProvider.notifier).refreshFromBackend());
    });
  }

  /// Mission CTA tap — async-aware: link missions open their destination
  /// first, the write runs with the card in a pending state, and a failure
  /// surfaces via [ErrorDisplay] instead of silently flipping to Done.
  Future<void> _onMissionAction(MissionTask mission) async {
    if (mission.shouldOpenExternalLink) {
      final uri = Uri.tryParse(mission.externalUrl!);
      if (uri != null) {
        await openExternalUrl(context, uri);
      }
    }
    if (!mounted) return;
    try {
      await ref.read(tasksProvider.notifier).completeMission(mission.id);
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    return Column(
      children: [
        SubscriptionsTopBar(
          title: 'Tasks',
          onSearch: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          onNotification: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        SkifluxSegmentedControl(
          labels: const ['Learning', 'Mission', 'Marketplace'],
          selectedIndex: _segment,
          onChanged: (i) => setState(() => _segment = i),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        Expanded(
          child: switch (_segment) {
            0 => _learningSection(tasks, notifier),
            1 => _missionSection(tasks, notifier),
            _ => _MarketplaceEmpty(
              onKeepLearning: () => setState(() => _segment = 0),
            ),
          },
        ),
      ],
    );
  }

  /// Learning tab body honouring where the list came from: signed-in users
  /// get a loader, an error+retry, or the honest empty state — never seeds.
  Widget _learningSection(TasksState tasks, TasksNotifier notifier) {
    switch (tasks.learningSource) {
      case TaskSectionSource.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskSectionSource.error:
        return LoadFailure(
          error: const SkifluxFailure(SkifluxErrorKind.contentLoadFailed),
          title: "We couldn't load your tasks",
          onRetry: () => unawaited(notifier.refreshLearningFromBackend()),
        );
      case TaskSectionSource.seed:
      case TaskSectionSource.live:
        if (tasks.learning.isEmpty) {
          return const SkifluxEmptyState(
            icon: Icon(
              RemixIcons.task_fill,
              size: SkifluxEmptyState.iconSize,
              color: SkifluxColors.contentBrand,
            ),
            title: 'No tasks yet',
            message:
                'Watch episodes to unlock their tasks — complete them to '
                'earn SkillCoins and XP.',
          );
        }
        return _LearningList(
          state: tasks,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
        );
    }
  }

  Widget _missionSection(TasksState tasks, TasksNotifier notifier) {
    switch (tasks.missionsSource) {
      case TaskSectionSource.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskSectionSource.error:
        return LoadFailure(
          error: const SkifluxFailure(SkifluxErrorKind.contentLoadFailed),
          title: "We couldn't load your missions",
          onRetry: () => unawaited(notifier.refreshMissionsFromBackend()),
        );
      case TaskSectionSource.seed:
      case TaskSectionSource.live:
        if (tasks.missions.isEmpty) {
          return const SkifluxEmptyState(
            icon: Icon(
              RemixIcons.flag_fill,
              size: SkifluxEmptyState.iconSize,
              color: SkifluxColors.contentBrand,
            ),
            title: 'No missions right now',
            message: 'New missions will show up here — check back soon.',
          );
        }
        return _MissionList(state: tasks, onComplete: _onMissionAction);
    }
  }
}

// ── Learning (TF15) ──────────────────────────────────────────────────

class _LearningList extends StatelessWidget {
  const _LearningList({
    required this.state,
    required this.filter,
    required this.onFilter,
  });

  final TasksState state;
  final LearningTaskStatus? filter;
  final ValueChanged<LearningTaskStatus?> onFilter;

  @override
  Widget build(BuildContext context) {
    final tasks = state.learningFiltered(filter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SkifluxUnit.u32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterPill(
                label: 'All',
                count: state.countFor(null),
                selected: filter == null,
                onTap: () => onFilter(null),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              _FilterPill(
                label: 'Pending',
                count: state.countFor(LearningTaskStatus.pending),
                selected: filter == LearningTaskStatus.pending,
                onTap: () => onFilter(LearningTaskStatus.pending),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              _FilterPill(
                label: 'In Review',
                count: state.countFor(LearningTaskStatus.inReview),
                selected: filter == LearningTaskStatus.inReview,
                onTap: () => onFilter(LearningTaskStatus.inReview),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              _FilterPill(
                label: 'Revision',
                count: state.countFor(LearningTaskStatus.actionNeeded),
                selected: filter == LearningTaskStatus.actionNeeded,
                onTap: () => onFilter(LearningTaskStatus.actionNeeded),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              _FilterPill(
                label: 'Completed',
                count: state.countFor(LearningTaskStatus.completed),
                selected: filter == LearningTaskStatus.completed,
                onTap: () => onFilter(LearningTaskStatus.completed),
              ),
            ],
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks in this filter',
                    style: SkifluxTypography.bodyP8Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: SkifluxSpacing.spaceM),
                  itemBuilder: (context, i) => _LearningTaskCard(
                    task: tasks[i],
                    onAction: () => _openTask(context, tasks[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _openTask(BuildContext context, LearningTask task) {
    // "View Result" must NEVER open task details — always the result screen.
    if (task.status == LearningTaskStatus.completed) {
      _openResult(context, task);
      return;
    }
    if (task.kind == LearningTaskKind.quiz) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizIntroScreen(taskId: task.id)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SubmissionTaskScreen(taskId: task.id)),
    );
  }

  void _openResult(BuildContext context, LearningTask task) {
    final quiz = task.quiz;
    if (task.kind == LearningTaskKind.quiz && quiz != null) {
      final total = quiz.questions.length;
      final answers =
          task.quizAnswers ??
          List<int?>.generate(total, (i) => quiz.questions[i].correctIndex);
      final correct = task.quizCorrect ?? total;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            taskId: task.id,
            correct: correct,
            total: total,
            answers: answers,
            passed: correct >= total,
          ),
        ),
      );
      return;
    }
    // Completed submission (or any non-quiz complete) — same result shell
    // with task coin/XP rewards; Review is hidden when there is no quiz.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          taskId: task.id,
          correct: 1,
          total: 1,
          answers: const [],
          passed: true,
        ),
      ),
    );
  }
}

/// Filter pill with count badge (Figma Button Group Pill on TF15).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? SkifluxColors.backgroundBrand
        : SkifluxColors.backgroundPrimary;
    final fg = selected
        ? SkifluxColors.contentPrimaryInverse
        : SkifluxColors.contentTertiary;
    final badgeBg = selected
        ? SkifluxColors.backgroundPrimaryBrand
        : SkifluxColors.backgroundDisabled;
    final badgeFg = selected
        ? SkifluxColors.contentBrand
        : SkifluxColors.contentDisabled;

    return Material(
      color: bg,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceS,
            vertical: SkifluxSpacing.spaceXs,
          ),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: selected
                ? null
                : Border.all(
                    color: SkifluxColors.borderTertiary,
                    width: SkifluxBorderWidth.xs,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceXs,
                ),
                child: Text(
                  label,
                  style: SkifluxTypography.uiButtonSmall.copyWith(color: fg),
                ),
              ),
              Container(
                width: SkifluxSpacing.spaceL,
                height: SkifluxSpacing.spaceL,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: badgeFg,
                    fontSize: 8,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningTaskCard extends StatelessWidget {
  const _LearningTaskCard({required this.task, required this.onAction});

  final LearningTask task;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(task.status);

    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LearningTaskEpisodeHeader(episodeLabel: task.episodeLabel),
          const SizedBox(height: SkifluxSpacing.spaceS),
          // Title + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: SkifluxTypography.headingH9Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceXs),
                    Text(
                      task.description,
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: SkifluxRadii.borderPill,
                ),
                child: Text(
                  task.statusLabel,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: status.fg,
                  ),
                ),
              ),
            ],
          ),
          if (task.feedback != null) ...[
            const SizedBox(height: SkifluxSpacing.spaceS),
            _TaskFeedbackBanner(feedback: task.feedback!),
          ],
          const SizedBox(height: SkifluxSpacing.spaceS),
          // Rewards + CTA. Chips hide when the API declared no reward —
          // and a fractional reward renders exactly ("+2.50", never "+3").
          Row(
            children: [
              if (task.hasCoinReward)
                _RewardChip(
                  icon: RemixIcons.copper_coin_fill,
                  label: '+${task.coinsLabel}',
                  color: SkifluxColors.contentNotice,
                ),
              if (task.hasCoinReward && task.hasXpReward)
                const SizedBox(width: SkifluxSpacing.spaceM),
              if (task.hasXpReward)
                _RewardChip(
                  icon: RemixIcons.flashlight_fill,
                  label: '+${task.xp} XP',
                  color: SkifluxColors.contentBrand,
                ),
              const Spacer(),
              _CardActionButton(
                label: task.actionLabel,
                enabled:
                    task.actionEnabled ||
                    task.status == LearningTaskStatus.completed,
                destructive: task.status == LearningTaskStatus.actionNeeded,
                secondary:
                    task.status == LearningTaskStatus.completed ||
                    task.status == LearningTaskStatus.inReview,
                onPressed: task.status == LearningTaskStatus.inReview
                    ? null
                    : onAction,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static ({Color bg, Color fg}) _statusStyle(LearningTaskStatus s) {
    return switch (s) {
      LearningTaskStatus.completed => (
        bg: SkifluxColors.backgroundPositiveSubtle,
        fg: SkifluxColors.contentPositive,
      ),
      LearningTaskStatus.pending => (
        bg: SkifluxColors.backgroundNoticeSubtle,
        fg: SkifluxColors.contentNotice,
      ),
      LearningTaskStatus.inReview => (
        bg: SkifluxColors.backgroundInfoSubtle,
        fg: SkifluxColors.contentInfo,
      ),
      LearningTaskStatus.actionNeeded => (
        bg: SkifluxColors.backgroundNegativeSubtle,
        fg: SkifluxColors.contentNegative,
      ),
    };
  }
}

class _LearningTaskEpisodeHeader extends StatelessWidget {
  const _LearningTaskEpisodeHeader({required this.episodeLabel});

  final String episodeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: SkifluxColors.backgroundBrand,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            RemixIcons.play_circle_fill,
            size: 20,
            color: SkifluxColors.contentPrimaryInverse,
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        Expanded(
          child: Text(
            episodeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
        Text(
          'View Episode',
          style: SkifluxTypography.uiBadgeTagSmall.copyWith(
            color: SkifluxColors.contentBrand,
          ),
        ),
      ],
    );
  }
}

class _TaskFeedbackBanner extends StatelessWidget {
  const _TaskFeedbackBanner({required this.feedback});

  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            RemixIcons.information_fill,
            size: 20,
            color: SkifluxColors.contentNegative,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              feedback,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentNegative,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SkifluxIcons.sizeS, color: color),
        const SizedBox(width: SkifluxSpacing.space2xs),
        Text(
          label,
          style: SkifluxTypography.uiButtonSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Compact S-height CTA matching list-card buttons (primary / secondary /
/// destructive / disabled).
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.enabled,
    this.destructive = false,
    this.secondary = false,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool destructive;
  final bool secondary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (destructive) {
      return Material(
        color: SkifluxColors.backgroundNegative,
        borderRadius: SkifluxRadii.borderPill,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: SkifluxRadii.borderPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceS,
              vertical: SkifluxSpacing.spaceXs,
            ),
            child: Text(
              label,
              style: SkifluxTypography.uiButtonSmall.copyWith(
                color: SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ),
        ),
      );
    }

    if (secondary || !enabled) {
      return Material(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderPill,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: SkifluxRadii.borderPill,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceS,
              vertical: SkifluxSpacing.spaceXs,
            ),
            decoration: BoxDecoration(
              borderRadius: SkifluxRadii.borderPill,
              border: Border.all(
                color: SkifluxColors.borderTertiary,
                width: SkifluxBorderWidth.xs,
              ),
            ),
            child: Text(
              label,
              style: SkifluxTypography.uiButtonSmall.copyWith(
                color: enabled
                    ? SkifluxColors.contentPrimary
                    : SkifluxColors.contentDisabled,
              ),
            ),
          ),
        ),
      );
    }

    return SkifluxButton(
      label: label,
      size: SkifluxButtonSize.s,
      onPressed: onPressed,
    );
  }
}

// ── Mission (TF14 · card `2902:13732`) ───────────────────────────────

class _MissionList extends StatelessWidget {
  const _MissionList({required this.state, required this.onComplete});

  final TasksState state;
  final ValueChanged<MissionTask> onComplete;

  static const _icons = <String, IconData>{
    'instagram': RemixIcons.instagram_fill,
    'twitter': RemixIcons.twitter_x_fill,
    'facebook': RemixIcons.facebook_circle_fill,
    'linkedin': RemixIcons.linkedin_box_fill,
    'tiktok': RemixIcons.tiktok_fill,
    'telegram': RemixIcons.telegram_fill,
    'whatsapp': RemixIcons.whatsapp_fill,
    'user': RemixIcons.user_add_fill,
    'star': RemixIcons.star_fill,
    'image': RemixIcons.image_add_fill,
  };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: state.missions.length,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceM),
      itemBuilder: (context, i) {
        return _MissionCard(mission: state.missions[i], onComplete: onComplete);
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onComplete});

  final MissionTask mission;
  final ValueChanged<MissionTask> onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.contentSecondaryInverse,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SkifluxColors.contentBrand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _MissionList._icons[mission.iconKey] ?? RemixIcons.flag_fill,
              size: 20,
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  mission.description,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Row(
                  children: [
                    if (mission.hasCoinReward) ...[
                      const Icon(
                        RemixIcons.copper_coin_fill,
                        size: SkifluxIcons.sizeS,
                        color: SkifluxColors.contentNoticeBold,
                      ),
                      const SizedBox(width: SkifluxSpacing.space2xs),
                      Text(
                        // Decimal-exact: a 2.50-coin mission reads "+2.50".
                        '+${mission.coinsLabel}',
                        style: SkifluxTypography.uiButtonSmall.copyWith(
                          color: SkifluxColors.contentNoticeBold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    SkifluxButton(
                      label: mission.completed ? 'Done' : mission.actionLabel,
                      size: SkifluxButtonSize.s,
                      loading: mission.pending,
                      onPressed: mission.completed || mission.pending
                          ? null
                          : () => onComplete(mission),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Marketplace empty (TF13 · `1256:14074`) ──────────────────────────

class _MarketplaceEmpty extends StatelessWidget {
  const _MarketplaceEmpty({required this.onKeepLearning});

  final VoidCallback onKeepLearning;

  @override
  Widget build(BuildContext context) {
    // Figma: column gap Space/S (8) between icon, copy, and Keep Learning —
    // not the generic empty-state's 48px vertical pad + extra XL.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: SkifluxEmptyState.iconSize + 50, // 98
              height: SkifluxEmptyState.iconSize + 50,
              decoration: const BoxDecoration(
                color: SkifluxColors.brand100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                RemixIcons.search_fill,
                size: SkifluxEmptyState.iconSize,
                color: SkifluxColors.contentBrand,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              'Marketplace Coming Soon',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              'We are building the ultimate gig ecosystem. Complete your '
              'learning tasks and earn verified skill badges to prepare for '
              'incoming client contracts.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(label: 'Keep Learning', onPressed: onKeepLearning),
          ],
        ),
      ),
    );
  }
}
