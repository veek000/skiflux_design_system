/// Tasks tab (Figma **Task Flow** `1256:12977`).
///
/// Signed in, both sections are live: learning tasks come from
/// `GET /episodes/watched/tasks` hydrated by `GET /me/submissions`, missions
/// from `GET /me/platform-tasks`. The demo seeds exist only for the
/// signed-out/demo session — a signed-in user never sees fabricated tasks:
/// an empty backend answer renders the honest empty state, and a failed load
/// renders an error with retry (same contract as `home_feed_store.dart`).
library;

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
import '../../wallet/data/wallet_store.dart';
import 'episode_tasks_repository.dart';
import 'models/episode_task_models.dart';
import 'models/platform_task.dart';
import 'platform_tasks_repository.dart';
import 'skillcoin_display.dart';

// ── Enums ────────────────────────────────────────────────────────────

enum TaskCategory { learning, mission, marketplace }

/// Learning-task lifecycle (Figma status chips on TF15).
enum LearningTaskStatus { completed, pending, inReview, actionNeeded }

/// How a learning task is completed.
enum LearningTaskKind { submission, quiz }

/// Where a Tasks section's list came from — drives the tab's honesty states.
enum TaskSectionSource {
  /// Signed-out demo data.
  seed,

  /// A session exists and a fetch is in flight (list is empty meanwhile —
  /// seeds are never shown to a signed-in user, not even during a load).
  loading,

  /// `GET` answered; the list — possibly empty — is the server's.
  live,

  /// A session exists and the fetch failed with nothing live to show:
  /// the tab renders an error + retry, never the seed.
  error,
}

// ── Models ───────────────────────────────────────────────────────────

class LearningTask {
  LearningTask({
    required this.id,
    required this.title,
    required this.description,
    required this.episodeLabel,
    required this.episodeTitle,
    required this.episodeSubtitle,
    required this.status,
    required this.kind,
    required this.coins,
    required this.xp,
    this.feedback,
    this.briefIntro,
    this.briefBullets = const [],
    this.quiz,
    this.episodeId,
    this.acceptedProofTypes = const [],
    this.slaHours = 0,
    this.fromBackend = false,
  });

  /// Adapter: one `GET /episodes/watched/tasks` row (+ its latest
  /// `GET /me/submissions` record, when any) → list card model.
  ///
  /// Rewards: the `WatchedEpisodeTaskItem` schema carries **no** coin/XP
  /// fields; `completion_criteria` (spec type `{}`) is read opportunistically
  /// for `skillcoin_reward`/`xp_reward`-style keys, and when nothing is there
  /// the card simply shows no reward chip rather than inventing "+25".
  factory LearningTask.fromWatched(
    WatchedEpisodeTask task, {
    UserSubmission? latestSubmission,
  }) {
    final isQuiz = task.isAssessment;
    final coins = _criteriaCoins(task.completionCriteria);
    final xp = _criteriaXp(task.completionCriteria);

    var status = statusFrom(task.status, submitted: task.submittedAt != null);
    String? feedback;
    int? quizCorrect;
    if (latestSubmission != null) {
      status = statusFrom(latestSubmission.status, submitted: true);
      if (status == LearningTaskStatus.actionNeeded) {
        feedback = latestSubmission.rejectionReason;
      }
      final score = latestSubmission.scorePercent;
      if (isQuiz && score != null && task.questions.isNotEmpty) {
        quizCorrect = ((score * task.questions.length) / 100).round();
      }
    }

    final questionCount = task.questions.length;
    final passPercent = task.passScorePercent;
    final description = isQuiz
        ? '$questionCount multiple-choice '
              'question${questionCount == 1 ? '' : 's'}'
              '${passPercent != null ? ' · score $passPercent% to pass' : ''}'
        : 'Submit a link or file'
              '${task.slaTimeLimitHours > 0 ? ' · reviewed within ${task.slaTimeLimitHours}hrs' : ''}';

    final quiz = isQuiz && task.questions.isNotEmpty
        ? QuizData(
            introBody: task.taskBrief.isNotEmpty
                ? task.taskBrief
                : 'This assessment is auto-graded and you will receive '
                      'your results immediately.',
            questionCount: questionCount,
            minutes: task.timeLimitMinutes ?? 0,
            passPercent: passPercent ?? 100,
            rewardCoins: coins,
            rewardXp: xp,
            timerSeconds: (task.timeLimitMinutes ?? 0) * 60,
            questions: [
              for (final q in task.questions)
                QuizQuestion(
                  id: q.id,
                  prompt: q.questionText,
                  options: q.options,
                  correctIndex: q.correctIndex,
                ),
            ],
          )
        : null;

    return LearningTask(
        id: task.id,
        title: _titleFromBrief(
          task.taskBrief,
          fallback: isQuiz ? 'Episode Assessment' : 'Episode Task',
        ),
        description: description,
        episodeLabel: task.episodeTitle,
        episodeTitle: task.episodeTitle,
        episodeSubtitle: task.seasonTitle,
        status: status,
        kind: isQuiz ? LearningTaskKind.quiz : LearningTaskKind.submission,
        coins: coins,
        xp: xp,
        feedback: feedback,
        briefIntro: task.taskBrief,
        quiz: quiz,
        episodeId: task.episodeId.isEmpty ? null : task.episodeId,
        acceptedProofTypes: task.acceptedProofTypes,
        slaHours: task.slaTimeLimitHours,
        fromBackend: true,
      )
      ..quizCorrect = quizCorrect;
  }

  final String id;
  final String title;
  final String description;
  final String episodeLabel;
  final String episodeTitle;
  final String episodeSubtitle;
  LearningTaskStatus status;
  final LearningTaskKind kind;

  /// SkillCoin reward — [Decimal], displayed via [coinsLabel] so a fractional
  /// reward is never truncated. Zero means "the API told us nothing" and the
  /// UI hides the chip rather than promising a number.
  final Decimal coins;
  final int xp;

  /// Reviewer note — shown on Action Needed cards; live data carries the
  /// backend's `rejection_reason`.
  String? feedback;

  /// Submission detail: intro paragraph under "The Brief". For live tasks
  /// this is the creator's `task_brief`.
  final String? briefIntro;

  /// Submission detail: checklist bullets (seed-only; the wire brief is one
  /// free-text block).
  final List<String> briefBullets;

  /// Quiz payload when [kind] is quiz.
  final QuizData? quiz;

  /// Backend episode UUID — `POST /episodes/task/submit` keys on this.
  final String? episodeId;

  /// Creator-declared proof types (`["link", "image", "video", "file"]`) —
  /// drives the upload extension allowlist on the submission screen.
  final List<String> acceptedProofTypes;

  /// Creator SLA in hours; 0 when unknown.
  final int slaHours;

  /// True when this row came from the API (submissions go to the backend).
  final bool fromBackend;

  /// Last quiz attempt answers (index per question) — powers View Result.
  List<int?>? quizAnswers;

  /// Correct count from the last quiz attempt (or derived from the backend's
  /// `score_percent` when hydrating).
  int? quizCorrect;

  String get coinsLabel => formatSkillcoin(coins);
  bool get hasCoinReward => coins > Decimal.zero;
  bool get hasXpReward => xp > 0;
  bool get hasAnyReward => hasCoinReward || hasXpReward;

  String get statusLabel => switch (status) {
    LearningTaskStatus.completed => 'Completed',
    LearningTaskStatus.pending => 'Pending',
    LearningTaskStatus.inReview => 'In Review',
    LearningTaskStatus.actionNeeded => 'Action Needed',
  };

  /// Primary CTA on the list card.
  String get actionLabel => switch (status) {
    LearningTaskStatus.completed => 'View Result',
    LearningTaskStatus.pending => 'Start Task',
    LearningTaskStatus.inReview => 'Awaiting Review',
    LearningTaskStatus.actionNeeded => 'Fix & Resubmit',
  };

  bool get actionEnabled =>
      status != LearningTaskStatus.inReview &&
      status != LearningTaskStatus.completed;

  /// Maps the API's free-string statuses (watched-tasks `status` and
  /// `/me/submissions` `pending|approved|rejected|passed|failed`) onto the
  /// four UI states. [submitted] disambiguates "pending": a pending
  /// *submission* is awaiting review, a pending *task* is not started.
  static LearningTaskStatus statusFrom(String raw, {bool submitted = false}) {
    final s = raw.toLowerCase();
    if (s.contains('approv') || s.contains('pass') || s.contains('complet')) {
      return LearningTaskStatus.completed;
    }
    if (s.contains('reject') ||
        s.contains('fail') ||
        s.contains('revis') ||
        s.contains('action')) {
      return LearningTaskStatus.actionNeeded;
    }
    if (s.contains('review')) return LearningTaskStatus.inReview;
    if (s.contains('submit') && !s.contains('not') && !s.contains('un')) {
      return LearningTaskStatus.inReview;
    }
    if (s.contains('pending')) {
      return submitted
          ? LearningTaskStatus.inReview
          : LearningTaskStatus.pending;
    }
    return LearningTaskStatus.pending;
  }

  /// First sentence/line of the brief, clamped for the card; the fallback
  /// labels the task by kind rather than inventing content.
  static String _titleFromBrief(String brief, {required String fallback}) {
    final text = brief.trim();
    if (text.isEmpty) return fallback;
    var line = text.split('\n').first.trim();
    final sentenceEnd = line.indexOf(RegExp(r'[.!?]'));
    if (sentenceEnd > 0) line = line.substring(0, sentenceEnd);
    line = line.trim();
    if (line.length > 60) line = '${line.substring(0, 57).trimRight()}…';
    return line.isEmpty ? fallback : line;
  }

  static Decimal _criteriaCoins(Map<String, dynamic> criteria) {
    for (final key in const [
      'skillcoin_reward',
      'skillcoins',
      'coin_reward',
      'coins',
    ]) {
      final value = criteria[key];
      if (value is num) return Decimal.parse(value.toString());
      if (value is String) {
        final parsed = Decimal.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return Decimal.zero;
  }

  static int _criteriaXp(Map<String, dynamic> criteria) {
    for (final key in const ['xp_reward', 'xp']) {
      final value = criteria[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }
}

class MissionTask {
  MissionTask({
    required this.id,
    required this.title,
    required this.description,
    required this.coins,
    required this.actionLabel,
    required this.iconKey,
    this.completed = false,
    this.claimable = false,
    this.status = PlatformTaskStatus.notStarted,
    this.progressCurrent = 0,
    this.progressTarget = 1,
    this.externalUrl,
    this.manual = true,
    this.fromBackend = false,
  });

  factory MissionTask.fromPlatform(PlatformTask t) {
    final completed = t.completed || t.status == PlatformTaskStatus.claimed;
    final actionLabel = completed
        ? 'Done'
        : t.claimable || t.status == PlatformTaskStatus.claimable
        ? 'Claim'
        : t.status == PlatformTaskStatus.inProgress
        ? 'Continue'
        : t.verificationMode == 'manual' || t.triggerType.isEmpty
        ? 'Start'
        : 'View';
    return MissionTask(
      id: t.id,
      title: t.title,
      description: t.description,
      // Exact Decimal — "2.50" must never round up to 3 on the card.
      coins: t.skillcoinReward,
      actionLabel: actionLabel,
      iconKey: t.icon.isEmpty ? 'star' : t.icon,
      completed: completed,
      claimable: t.claimable || t.status == PlatformTaskStatus.claimable,
      status: t.status,
      progressCurrent: t.progressCurrent,
      progressTarget: t.progressTarget,
      externalUrl: t.externalUrl,
      manual: t.verificationMode == 'manual' || t.triggerType.isEmpty,
      fromBackend: true,
    );
  }

  final String id;
  final String title;
  final String description;

  /// SkillCoin reward as [Decimal]; render via [coinsLabel].
  final Decimal coins;
  final String actionLabel;

  /// Key resolved to Remix in the UI (instagram, twitter/x, …).
  final String iconKey;
  bool completed;
  bool claimable;
  PlatformTaskStatus status;
  int progressCurrent;
  int progressTarget;
  String? externalUrl;

  /// Manual tasks are submitted (then claimed) by the user; automatic ones
  /// are progressed by backend triggers.
  final bool manual;
  bool fromBackend;

  /// A write for this mission is in flight — the card's CTA shows a spinner
  /// and ignores taps until the server answers.
  bool pending = false;

  String get coinsLabel => formatSkillcoin(coins);
  bool get hasCoinReward => coins > Decimal.zero;

  /// Link-type missions must actually visit their destination: the tap opens
  /// [externalUrl] before the start/submit calls. Claims never re-open it.
  bool get shouldOpenExternalLink =>
      externalUrl != null &&
      externalUrl!.isNotEmpty &&
      !completed &&
      !claimable &&
      (status == PlatformTaskStatus.notStarted ||
          status == PlatformTaskStatus.inProgress);
}

class QuizData {
  const QuizData({
    required this.introBody,
    required this.questionCount,
    required this.minutes,
    required this.passPercent,
    required this.rewardCoins,
    required this.rewardXp,
    required this.questions,
    required this.timerSeconds,
  });

  final String introBody;
  final int questionCount;

  /// Estimated/allowed minutes; 0 = unknown (row hidden on the intro).
  final int minutes;
  final int passPercent;

  /// [Decimal] for the same reason as the task rewards.
  final Decimal rewardCoins;
  final int rewardXp;
  final List<QuizQuestion> questions;

  /// 0 = no time limit — the assessment screen then runs untimed.
  final int timerSeconds;

  String get rewardCoinsLabel => formatSkillcoin(rewardCoins);
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.id,
  });

  /// Backend question UUID — required to submit answers. Null on seeds and
  /// when the API omits it (spec gap; see `episode_task_models.dart`).
  final String? id;

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class UploadedFileInfo {
  const UploadedFileInfo({
    required this.name,
    required this.extensionLabel,
    required this.sizeLabel,
    this.path,
  });

  final String name;
  final String extensionLabel;
  final String sizeLabel;
  final String? path;
}

// ── State + Notifier ─────────────────────────────────────────────────

/// Snapshot of the learning + mission lists and where each came from.
class TasksState {
  TasksState({
    required this.learning,
    required this.missions,
    this.learningSource = TaskSectionSource.seed,
    this.missionsSource = TaskSectionSource.seed,
  });

  final List<LearningTask> learning;
  final List<MissionTask> missions;
  final TaskSectionSource learningSource;
  final TaskSectionSource missionsSource;

  TasksState copyWith({
    List<LearningTask>? learning,
    List<MissionTask>? missions,
    TaskSectionSource? learningSource,
    TaskSectionSource? missionsSource,
  }) => TasksState(
    learning: learning ?? this.learning,
    missions: missions ?? this.missions,
    learningSource: learningSource ?? this.learningSource,
    missionsSource: missionsSource ?? this.missionsSource,
  );

  List<LearningTask> learningFiltered(LearningTaskStatus? status) {
    if (status == null) return List.unmodifiable(learning);
    // "Revision" filter maps to Action Needed in the product language.
    return learning.where((t) => t.status == status).toList(growable: false);
  }

  int countFor(LearningTaskStatus? status) {
    if (status == null) return learning.length;
    return learning.where((t) => t.status == status).length;
  }

  LearningTask? byId(String id) {
    for (final t in learning) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Riverpod choice: [NotifierProvider] — learning/mission status mutate
/// via markInReview / markCompleted / recordQuizResult / completeMission.
/// [refreshFromBackend] re-syncs both sections; TasksBody calls it whenever
/// the Tasks tab opens, and the auth flow kicks the missions half at login.
class TasksNotifier extends Notifier<TasksState> {
  bool _missionsInFlight = false;
  bool _learningInFlight = false;

  @override
  TasksState build() {
    return TasksState(learning: _seedLearning(), missions: _seedMissions());
  }

  Future<bool> _hasSession() async {
    try {
      return await ref.read(tokenStoreProvider).hasSession();
    } catch (_) {
      return false;
    }
  }

  /// Re-syncs both tabs. Safe to call on every Tasks-tab open.
  Future<void> refreshFromBackend() async {
    await Future.wait([
      refreshMissionsFromBackend(),
      refreshLearningFromBackend(),
    ]);
  }

  /// Missions ← `GET /me/platform-tasks`.
  ///
  /// Signed out: no-op (seeds are the demo). Signed in: the seed is dropped
  /// before the fetch, an empty answer stays empty, and a failure keeps the
  /// last live list when there is one — otherwise the tab shows error+retry.
  Future<void> refreshMissionsFromBackend() async {
    if (_missionsInFlight) return;
    _missionsInFlight = true;
    try {
      if (!await _hasSession()) return;
      final hadLive = state.missionsSource == TaskSectionSource.live;
      if (!hadLive) {
        state = state.copyWith(
          missions: const [],
          missionsSource: TaskSectionSource.loading,
        );
      }
      try {
        final list = await ref.read(platformTasksRepositoryProvider).list();
        final missions = list
            .where((t) => t.isActive)
            .map(MissionTask.fromPlatform)
            .toList(growable: false);
        state = state.copyWith(
          missions: missions,
          missionsSource: TaskSectionSource.live,
        );
      } catch (_) {
        if (state.missionsSource == TaskSectionSource.live) return;
        state = state.copyWith(
          missions: const [],
          missionsSource: TaskSectionSource.error,
        );
      }
    } finally {
      _missionsInFlight = false;
    }
  }

  /// Learning ← `GET /episodes/watched/tasks`, statuses hydrated from
  /// `GET /me/submissions` (best-effort — the watched payload already carries
  /// a status, so a failed submissions read degrades, not breaks).
  Future<void> refreshLearningFromBackend() async {
    if (_learningInFlight) return;
    _learningInFlight = true;
    try {
      if (!await _hasSession()) return;
      final hadLive = state.learningSource == TaskSectionSource.live;
      if (!hadLive) {
        state = state.copyWith(
          learning: const [],
          learningSource: TaskSectionSource.loading,
        );
      }
      try {
        final repo = ref.read(episodeTasksRepositoryProvider);
        final watched = await repo.getWatchedTasks();
        var submissions = const <UserSubmission>[];
        try {
          submissions = await repo.getMySubmissions();
        } catch (_) {
          // Statuses fall back to the watched-tasks payload.
        }
        state = state.copyWith(
          learning: learningFromBackend(watched, submissions),
          learningSource: TaskSectionSource.live,
        );
      } catch (_) {
        if (state.learningSource == TaskSectionSource.live) return;
        state = state.copyWith(
          learning: const [],
          learningSource: TaskSectionSource.error,
        );
      }
    } finally {
      _learningInFlight = false;
    }
  }

  /// Joins each watched task with its most recent submission.
  static List<LearningTask> learningFromBackend(
    List<WatchedEpisodeTask> watched,
    List<UserSubmission> submissions,
  ) {
    final latestByTask = <String, UserSubmission>{};
    for (final s in submissions) {
      if (s.taskId.isEmpty) continue;
      final prior = latestByTask[s.taskId];
      final priorDate = prior?.sortDate;
      final date = s.sortDate;
      if (prior == null ||
          priorDate == null ||
          (date != null && date.isAfter(priorDate))) {
        latestByTask[s.taskId] = s;
      }
    }
    return [
      for (final task in watched)
        if (task.id.isNotEmpty)
          LearningTask.fromWatched(
            task,
            latestSubmission: latestByTask[task.id],
          ),
    ];
  }

  void markInReview(String id) {
    final t = state.byId(id);
    if (t == null) return;
    t.status = LearningTaskStatus.inReview;
    t.feedback = null;
    state = state.copyWith(learning: List<LearningTask>.of(state.learning));
  }

  void markCompleted(String id) {
    final t = state.byId(id);
    if (t == null) return;
    t.status = LearningTaskStatus.completed;
    state = state.copyWith(learning: List<LearningTask>.of(state.learning));
  }

  /// Persist quiz answers + score and mark the task completed when passed.
  void recordQuizResult({
    required String id,
    required List<int?> answers,
    required int correct,
    required bool passed,
  }) {
    final t = state.byId(id);
    if (t == null) return;
    t.quizAnswers = List<int?>.from(answers);
    t.quizCorrect = correct;
    if (passed) t.status = LearningTaskStatus.completed;
    state = state.copyWith(learning: List<LearningTask>.of(state.learning));
  }

  MissionTask? missionById(String id) {
    for (final m in state.missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _emitMissions() {
    state = state.copyWith(missions: List<MissionTask>.of(state.missions));
  }

  /// Mission CTA: claim when claimable, else start/submit — all against the
  /// backend for live missions. The card flips to Done only on the server's
  /// 2xx; a failure rolls back to the pre-tap state and **rethrows** so the
  /// screen surfaces it (a swallowed claim failure is silently lost coins).
  /// A successful claim also refreshes the wallet so the balance moves.
  Future<void> completeMission(String id) async {
    final mission = missionById(id);
    if (mission == null || mission.completed || mission.pending) return;

    if (!mission.fromBackend) {
      // Demo mission (signed-out): local completion is the whole feature.
      mission.completed = true;
      _emitMissions();
      return;
    }

    final repo = ref.read(platformTasksRepositoryProvider);
    final claiming =
        mission.claimable || mission.status == PlatformTaskStatus.claimable;
    mission.pending = true;
    _emitMissions();
    try {
      PlatformTask? updated;
      if (claiming) {
        updated = await repo.claim(id);
      } else if (mission.status == PlatformTaskStatus.notStarted) {
        updated = await repo.start(id);
        if (mission.manual) {
          // Manual tasks: submit marks claimable (platform-tasks.md).
          updated = await repo.submit(id) ?? updated;
        }
      } else {
        updated = await repo.submit(id);
      }
      if (updated != null) {
        _replaceMission(id, MissionTask.fromPlatform(updated));
      }
      if (claiming) {
        // Coins landed — pull the fresh balance alongside the fresh list.
        unawaited(ref.read(walletProvider.notifier).refreshFromBackend());
      }
      await refreshMissionsFromBackend();
    } finally {
      mission.pending = false;
      final current = missionById(id);
      if (current != null) current.pending = false;
      _emitMissions();
    }
  }

  void _replaceMission(String id, MissionTask replacement) {
    final missions = List<MissionTask>.of(state.missions);
    for (var i = 0; i < missions.length; i++) {
      if (missions[i].id == id) {
        missions[i] = replacement;
        break;
      }
    }
    state = state.copyWith(missions: missions);
  }

  // ── Seeds ────────────────────────────────────────────────────────

  static List<LearningTask> _seedLearning() {
    const briefIntro =
        "You're designing the hero section for FlowBase — a fictional "
        'project management SaaS. Using the design token system from EP 06, '
        'build a clean, scalable hero section.';
    const briefBullets = [
      'Headline, subheadline, and a primary CTA button.',
      'At least one visual element (illustration or mockup).',
      'All colours and text must reference token values — no hardcoded styles.',
      '1440px desktop frame size.',
    ];

    final quiz = QuizData(
      introBody:
          'This assessment tests your knowledge from Episode 05. It is '
          'auto-graded and you will receive your results immediately.',
      questionCount: 3,
      minutes: 2,
      passPercent: 100,
      rewardCoins: Decimal.fromInt(20),
      rewardXp: 50,
      timerSeconds: 6 * 60,
      questions: const [
        QuizQuestion(
          prompt:
              'What is the primary purpose of a Design System in a product?',
          options: [
            'To make the app look more expensive',
            'To ensure consistency and speed up design & development',
            'To replace the need for a designer',
            'To increase the final file size',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          prompt: "What does a 'Design Token' represent in an architecture?",
          options: [
            'A specific, named value like a hex code',
            'A complex UI component',
            'The license fee for using Figma',
            'Introduction to UI Design Thinking',
          ],
          correctIndex: 0,
        ),
        QuizQuestion(
          prompt:
              'In a scalable UI architecture, what is the best practice '
              'for button padding?',
          options: [
            'Use random pixel values visually',
            'Hardcode margins in the CSS for every button',
            'Use spacing tokens from the design system',
            'Introduction to UI Design Thinking',
          ],
          correctIndex: 2,
        ),
      ],
    );

    final coins25 = Decimal.fromInt(25);

    // First card (Figma TF15): completed submission — View Result → result
    // screen (not task details).
    final completedSubmission = LearningTask(
      id: 'learn-1',
      title: 'Design a hero section',
      description: 'Submit a Figma file or screenshot · reviewed within 24hrs',
      episodeLabel: 'EP 06 — Design Systems',
      episodeTitle: 'Introduction to UI Design Thinking',
      episodeSubtitle: 'Episode 1',
      status: LearningTaskStatus.completed,
      kind: LearningTaskKind.submission,
      coins: coins25,
      xp: 25,
      briefIntro: briefIntro,
      briefBullets: briefBullets,
    );

    // Completed quiz with a perfect run — View Result → TF01.
    final completedQuiz =
        LearningTask(
            id: 'learn-1b',
            title: 'Grid & Spacing Quiz',
            description:
                '3 multiple-choice questions · must score 100% to pass',
            episodeLabel: 'EP 05 — Layout Foundations',
            episodeTitle: 'Introduction to UI Design Thinking',
            episodeSubtitle: 'Episode 1',
            status: LearningTaskStatus.completed,
            kind: LearningTaskKind.quiz,
            coins: coins25,
            xp: 25,
            quiz: quiz,
          )
          ..quizAnswers = const [1, 0, 2]
          ..quizCorrect = 3;

    return [
      completedSubmission,
      LearningTask(
        id: 'learn-2',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.pending,
        kind: LearningTaskKind.submission,
        coins: coins25,
        xp: 25,
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
      completedQuiz,
      LearningTask(
        id: 'learn-3',
        title: 'Grid & Spacing Quiz',
        description: '3 multiple-choice questions · must score 100% to pass',
        episodeLabel: 'EP 05 — Layout Foundations',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.pending,
        kind: LearningTaskKind.quiz,
        coins: coins25,
        xp: 25,
        quiz: quiz,
      ),
      LearningTask(
        id: 'learn-4',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.inReview,
        kind: LearningTaskKind.submission,
        coins: coins25,
        xp: 25,
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
      LearningTask(
        id: 'learn-5',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.actionNeeded,
        kind: LearningTaskKind.submission,
        coins: coins25,
        xp: 25,
        feedback:
            'Contrast on secondary buttons is too low for WCAG compliance. '
            'Please adjust and re-submit.',
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
    ];
  }

  static List<MissionTask> _seedMissions() {
    final coins5 = Decimal.fromInt(5);
    final coins7 = Decimal.fromInt(7);
    return [
      MissionTask(
        id: 'm-ig',
        title: 'Follow Instagram',
        description:
            'Join our visual community for design inspiration and creator highlights',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'instagram',
      ),
      MissionTask(
        id: 'm-x',
        title: 'Follow X',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'twitter',
      ),
      MissionTask(
        id: 'm-fb',
        title: 'Follow Facebook',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'facebook',
      ),
      MissionTask(
        id: 'm-li',
        title: 'Follow LinkedIn',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'linkedin',
      ),
      MissionTask(
        id: 'm-tt',
        title: 'Follow TikTok',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'tiktok',
      ),
      MissionTask(
        id: 'm-tg',
        title: 'Join Telegram Community',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins7,
        actionLabel: 'Join',
        iconKey: 'telegram',
      ),
      MissionTask(
        id: 'm-wa',
        title: 'Join WhatsApp Community',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: coins7,
        actionLabel: 'Join',
        iconKey: 'whatsapp',
      ),
      MissionTask(
        id: 'm-creator',
        title: 'Follow First Creator',
        description: 'Spend 10 minutes watching learning episodes',
        coins: coins5,
        actionLabel: 'Follow',
        iconKey: 'user',
      ),
      MissionTask(
        id: 'm-rate',
        title: 'Rate the App',
        description: 'Thank you for rating Skiflux on the App Store!',
        coins: coins5,
        actionLabel: 'Rate',
        iconKey: 'star',
      ),
      MissionTask(
        id: 'm-photo',
        title: 'Upload Profile Picture',
        description:
            'Never miss a new creator announcement, platform tutorial, or update.',
        coins: Decimal.fromInt(25),
        actionLabel: 'Upload',
        iconKey: 'image',
      ),
    ];
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);
