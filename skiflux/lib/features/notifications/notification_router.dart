/// Routes a notification tap to the matching in-app screen.
///
/// Uses `NotificationItem.type` + `data` deep-link keys documented in the
/// OpenAPI (`episode_id`, `season_id`, `creator_id`, `submission_id`,
/// `transaction_id`, …). Unknown types fall back to the Notifications list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../home/sheets/comments_sheet.dart';
import '../playlists/data/season_providers.dart';
import '../playlists/playlist_screen.dart';
import '../profile/badges_screen.dart';
import '../profile/profile_screen.dart';
import '../streaks/streak_screen.dart';
import '../tasks/data/tasks_store.dart';
import '../tasks/quiz_intro_screen.dart';
import '../tasks/quiz_result_screen.dart';
import '../tasks/submission_task_screen.dart';
import '../tasks/tasks_screen.dart';
import '../wallet/wallet_screen.dart';
import 'data/notifications_store.dart';
import 'notifications_screen.dart';

/// Open the best screen for [notification], after marking it read.
Future<void> openAppNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification notification,
) async {
  ref.read(notificationsProvider.notifier).markRead(notification);
  await openNotificationDeepLink(
    context,
    ref,
    type: notification.type,
    data: notification.data,
    title: notification.title,
    body: notification.body,
  );
}

/// Shared by the in-app list and FCM / local-tray taps.
Future<void> openNotificationDeepLink(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  Map<String, dynamic> data = const {},
  String? title,
  String? body,
}) async {
  final navigator = rootNavigatorKey.currentState ?? Navigator.of(context);
  final t = type.toLowerCase();
  final episodeId = _str(data, const [
    'episode_id',
    'episodeId',
    'episode',
  ]);
  final seasonId = _str(data, const ['season_id', 'seasonId', 'season']);
  final creatorId = _str(data, const [
    'creator_id',
    'creatorId',
    'user_id',
    'userId',
  ]);
  final taskId = _str(data, const ['task_id', 'taskId']);
  // `submission_id` is present on task notifications but maps to a submission
  // row, not LearningTask.id — we resolve via episode_id / task_id instead.
  final skillworld = _str(data, const ['skillworld', 'skill_world']);

  // ── Assessments / learning tasks → result or start screen ──────────
  if (_isTaskType(t) || _isAssessmentType(t)) {
    await ref.read(tasksProvider.notifier).refreshLearningFromBackend();
    if (!context.mounted) return;
    final task = _findTask(ref, taskId: taskId, episodeId: episodeId);
    if (task != null) {
      await _openTaskScreen(navigator, task);
      return;
    }
    // Task list as honest fallback when the row is not in the catalog yet.
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: SafeArea(child: TasksBody())),
      ),
    );
    return;
  }

  // ── New episode / comment on episode ───────────────────────────────
  if (t.contains('comment') || t.contains('reply') || t.contains('voice')) {
    if (episodeId != null) {
      await showCommentsSheet(context, episodeId);
      return;
    }
  }

  if (t.contains('episode') || t.contains('video') || t.contains('watch')) {
    if (seasonId != null) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(
            season: SeasonArg(
              id: seasonId,
              skillworld: skillworld,
            ),
          ),
        ),
      );
      return;
    }
    if (creatorId != null) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(creatorId: creatorId),
        ),
      );
      return;
    }
  }

  // ── Season from followed creator ───────────────────────────────────
  if (t.contains('season') && seasonId != null) {
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistScreen(
          season: SeasonArg(id: seasonId, skillworld: skillworld),
        ),
      ),
    );
    return;
  }

  // ── Creator / follower ─────────────────────────────────────────────
  if ((t.contains('follow') || t.contains('creator')) && creatorId != null) {
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(creatorId: creatorId),
      ),
    );
    return;
  }

  // ── Wallet / coins / referral / deposit / withdraw ──────────────────
  if (_isWalletType(t)) {
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
    );
    return;
  }

  // ── Streaks ────────────────────────────────────────────────────────
  if (t.contains('streak')) {
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const StreakScreen()),
    );
    return;
  }

  // ── Badges / milestones ────────────────────────────────────────────
  if (t.contains('badge') || t.contains('milestone')) {
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const BadgesScreen()),
    );
    return;
  }

  // ── Fallback: notifications list (or stay if already there) ───────
  if (!NotificationsScreen.isOpen) {
    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: NotificationsScreen.routeName),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}

bool _isTaskType(String t) =>
    t.contains('task') ||
    t.contains('submission') ||
    t.contains('revision') ||
    t.contains('deadline');

bool _isAssessmentType(String t) =>
    t.contains('assessment') ||
    t.contains('quiz') ||
    t.contains('perfect_score') ||
    t.contains('exam');

bool _isWalletType(String t) =>
    t.contains('coin') ||
    t.contains('reward') ||
    t.contains('referral') ||
    t.contains('deposit') ||
    t.contains('withdraw') ||
    t.contains('payment') ||
    t.contains('topup') ||
    t.contains('top_up') ||
    t.contains('cashback') ||
    t.contains('wallet') ||
    t.contains('transaction');

LearningTask? _findTask(
  WidgetRef ref, {
  String? taskId,
  String? episodeId,
}) {
  final learning = ref.read(tasksProvider).learning;
  if (taskId != null) {
    for (final t in learning) {
      if (t.id == taskId) return t;
    }
  }
  if (episodeId != null) {
    for (final t in learning) {
      if (t.episodeId == episodeId) return t;
    }
  }
  // submission_id is not the learning-task id; episode match is best effort.
  return null;
}

Future<void> _openTaskScreen(NavigatorState navigator, LearningTask task) async {
  if (task.kind == LearningTaskKind.quiz) {
    final quiz = task.quizForReview ?? task.quiz;
    if (task.status == LearningTaskStatus.completed ||
        task.status == LearningTaskStatus.actionNeeded) {
      final total = quiz?.questions.length ?? 0;
      final correct = task.quizCorrect ?? 0;
      final answers = task.quizAnswers ?? List<int?>.filled(total, null);
      final passPercent = quiz?.passPercent ?? 100;
      final passed = task.status == LearningTaskStatus.completed ||
          (total > 0 && correct * 100 >= passPercent * total);
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(
            taskId: task.id,
            correct: correct,
            total: total > 0 ? total : 1,
            answers: answers,
            passed: passed,
          ),
        ),
      );
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => QuizIntroScreen(taskId: task.id),
      ),
    );
    return;
  }

  if (task.status == LearningTaskStatus.completed) {
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => QuizResultScreen(
          taskId: task.id,
          correct: 1,
          total: 1,
          answers: const [],
          passed: true,
        ),
      ),
    );
    return;
  }

  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => SubmissionTaskScreen(taskId: task.id),
    ),
  );
}

String? _str(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return '$value';
  }
  return null;
}
