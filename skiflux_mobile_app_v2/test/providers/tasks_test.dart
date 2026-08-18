import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/episode_tasks_repository.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/models/episode_task_models.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/models/platform_task.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/platform_tasks_repository.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/skillcoin_display.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/tasks_store.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/wallet_store.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('tasksProvider (signed-out seeds)', () {
    test('build returns seeded learning tasks and missions', () {
      final state = container.read(tasksProvider);
      expect(state.learning, hasLength(6));
      expect(state.missions, hasLength(10));
      expect(state.learningSource, TaskSectionSource.seed);
      expect(state.missionsSource, TaskSectionSource.seed);
    });

    test('seed includes completed submission and quiz', () {
      final state = container.read(tasksProvider);
      final completed = state.learning.where(
        (t) => t.status == LearningTaskStatus.completed,
      );
      expect(completed, hasLength(2));
    });

    test('markInReview updates task status', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.markInReview('learn-2');
      final task = container.read(tasksProvider).byId('learn-2');
      expect(task?.status, LearningTaskStatus.inReview);
    });

    test('markInReview on unknown id is no-op', () {
      final notifier = container.read(tasksProvider.notifier);
      final state = container.read(tasksProvider);
      expect(state.learning, hasLength(6));
      notifier.markInReview('nonexistent');
      expect(container.read(tasksProvider).learning, hasLength(6));
    });

    test('markInReview clears feedback', () {
      final notifier = container.read(tasksProvider.notifier);
      // learn-5 has feedback set.
      expect(
        container.read(tasksProvider).byId('learn-5')?.feedback,
        isNotNull,
      );
      notifier.markInReview('learn-5');
      expect(container.read(tasksProvider).byId('learn-5')?.feedback, isNull);
    });

    test('markCompleted updates task status', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.markCompleted('learn-2');
      final task = container.read(tasksProvider).byId('learn-2');
      expect(task?.status, LearningTaskStatus.completed);
    });

    test('recordQuizResult persists answers and score', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.recordQuizResult(
        id: 'learn-3',
        answers: [0, 1, 2],
        correct: 2,
        passed: false,
      );
      final task = container.read(tasksProvider).byId('learn-3');
      expect(task?.quizAnswers, [0, 1, 2]);
      expect(task?.quizCorrect, 2);
      // Failed attempt → actionNeeded (Fix & Resubmit), not pending.
      expect(task?.status, LearningTaskStatus.actionNeeded);
    });

    test('recordQuizResult marks completed when passed', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.recordQuizResult(
        id: 'learn-3',
        answers: [1, 0, 2],
        correct: 3,
        passed: true,
      );
      final task = container.read(tasksProvider).byId('learn-3');
      expect(task?.status, LearningTaskStatus.completed);
    });

    test('recordQuizResult on completed task updates answers', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.recordQuizResult(
        id: 'learn-1b',
        answers: [2, 1, 0],
        correct: 1,
        passed: false,
      );
      final task = container.read(tasksProvider).byId('learn-1b');
      expect(task?.quizAnswers, [2, 1, 0]);
      expect(task?.quizCorrect, 1);
    });

    test('completeMission marks a demo mission as done locally', () async {
      final notifier = container.read(tasksProvider.notifier);
      await notifier.completeMission('m-ig');
      final mission = container
          .read(tasksProvider)
          .missions
          .firstWhere((m) => m.id == 'm-ig');
      expect(mission.completed, isTrue);
    });

    test('completeMission on already-completed mission is idempotent', () async {
      final notifier = container.read(tasksProvider.notifier);
      await notifier.completeMission('m-ig');
      // Complete again — should stay completed (not throw or reset).
      await notifier.completeMission('m-ig');
      final mission = container
          .read(tasksProvider)
          .missions
          .firstWhere((m) => m.id == 'm-ig');
      expect(mission.completed, isTrue);
    });

    test('completeMission on unknown id is no-op', () async {
      final notifier = container.read(tasksProvider.notifier);
      const originalCount = 10;
      await notifier.completeMission('nonexistent');
      expect(container.read(tasksProvider).missions, hasLength(originalCount));
    });

    test('learningFiltered returns filtered list', () {
      final state = container.read(tasksProvider);
      final pending = state.learningFiltered(LearningTaskStatus.pending);
      for (final t in pending) {
        expect(t.status, LearningTaskStatus.pending);
      }
    });

    test('countFor returns correct counts', () {
      final state = container.read(tasksProvider);
      expect(state.countFor(LearningTaskStatus.completed), 2);
      expect(state.countFor(LearningTaskStatus.pending), 2);
      expect(state.countFor(LearningTaskStatus.inReview), 1);
      expect(state.countFor(LearningTaskStatus.actionNeeded), 1);
      expect(state.countFor(null), 6);
    });
  });

  group('formatSkillcoin', () {
    test('whole amounts drop the fraction', () {
      expect(formatSkillcoin(Decimal.parse('500.00')), '500');
      expect(formatSkillcoin(Decimal.fromInt(5)), '5');
      expect(formatSkillcoin(Decimal.zero), '0');
    });

    test('fractional amounts keep two decimals — never rounded to int', () {
      expect(formatSkillcoin(Decimal.parse('2.50')), '2.50');
      expect(formatSkillcoin(Decimal.parse('0.1')), '0.10');
    });

    test('extra precision passes through untouched', () {
      expect(formatSkillcoin(Decimal.parse('0.125')), '0.125');
    });
  });

  group('MissionTask.fromPlatform', () {
    test('keeps a fractional reward exact instead of rounding', () {
      final mission = MissionTask.fromPlatform(
        _platformTask(skillcoinReward: '2.50'),
      );
      expect(mission.coins, Decimal.parse('2.5'));
      expect(mission.coinsLabel, '2.50');
    });

    test('claimed status renders as completed', () {
      final mission = MissionTask.fromPlatform(
        _platformTask(status: PlatformTaskStatus.claimed),
      );
      expect(mission.completed, isTrue);
    });

    test('link mission wants the external URL opened before starting', () {
      final mission = MissionTask.fromPlatform(
        _platformTask(externalUrl: 'https://instagram.com/skiflux'),
      );
      expect(mission.shouldOpenExternalLink, isTrue);
    });

    test('claimable mission never re-opens its link', () {
      final mission = MissionTask.fromPlatform(
        _platformTask(
          externalUrl: 'https://instagram.com/skiflux',
          status: PlatformTaskStatus.claimable,
          claimable: true,
        ),
      );
      expect(mission.shouldOpenExternalLink, isFalse);
      expect(mission.actionLabel, 'Claim');
    });
  });

  group('missions refresh (session honesty)', () {
    test('signed out keeps the demo seed and never calls the API', () async {
      final repo = _FakePlatformTasksRepository(tasks: [_platformTask()]);
      final c = _tasksContainer(platformRepo: repo, signedIn: false);

      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      expect(c.read(tasksProvider).missions, hasLength(10));
      expect(c.read(tasksProvider).missionsSource, TaskSectionSource.seed);
      expect(repo.listCalls, 0);
    });

    test('signed in replaces the seed with the live list', () async {
      final c = _tasksContainer(
        platformRepo: _FakePlatformTasksRepository(tasks: [_platformTask()]),
      );

      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      final state = c.read(tasksProvider);
      expect(state.missions, hasLength(1));
      expect(state.missions.single.fromBackend, isTrue);
      expect(state.missionsSource, TaskSectionSource.live);
    });

    test('signed in with an empty backend list shows empty, not seeds', () async {
      final c = _tasksContainer(
        platformRepo: _FakePlatformTasksRepository(tasks: []),
      );

      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      expect(c.read(tasksProvider).missions, isEmpty);
      expect(c.read(tasksProvider).missionsSource, TaskSectionSource.live);
    });

    test('signed in failure with nothing live is an error state, not seeds',
        () async {
      final c = _tasksContainer(
        platformRepo: _FakePlatformTasksRepository(failList: true),
      );

      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      expect(c.read(tasksProvider).missions, isEmpty);
      expect(c.read(tasksProvider).missionsSource, TaskSectionSource.error);
    });

    test('a failed re-fetch keeps the last live list', () async {
      final repo = _FakePlatformTasksRepository(tasks: [_platformTask()]);
      final c = _tasksContainer(platformRepo: repo);
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      repo.failList = true;
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      expect(c.read(tasksProvider).missions, hasLength(1));
      expect(c.read(tasksProvider).missionsSource, TaskSectionSource.live);
    });

    test('inactive tasks are filtered out', () async {
      final c = _tasksContainer(
        platformRepo: _FakePlatformTasksRepository(
          tasks: [
            _platformTask(),
            _platformTask(id: 'pt-2', isActive: false),
          ],
        ),
      );

      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      expect(c.read(tasksProvider).missions, hasLength(1));
    });
  });

  group('completeMission (backend honesty)', () {
    test('a failed claim rethrows and never flips the card to Done', () async {
      final repo = _FakePlatformTasksRepository(
        tasks: [
          _platformTask(status: PlatformTaskStatus.claimable, claimable: true),
        ],
        failClaim: true,
      );
      final c = _tasksContainer(platformRepo: repo);
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      await expectLater(
        c.read(tasksProvider.notifier).completeMission('pt-1'),
        throwsA(isA<SkifluxFailure>()),
      );

      final mission = c.read(tasksProvider).missions.single;
      expect(mission.completed, isFalse);
      expect(mission.pending, isFalse);
      expect(repo.claimCalls, ['pt-1']);
    });

    test('a failed claim does not touch the wallet', () async {
      final repo = _FakePlatformTasksRepository(
        tasks: [
          _platformTask(status: PlatformTaskStatus.claimable, claimable: true),
        ],
        failClaim: true,
      );
      final wallet = _RecordingWalletNotifier();
      final c = _tasksContainer(platformRepo: repo, wallet: wallet);
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      await expectLater(
        c.read(tasksProvider.notifier).completeMission('pt-1'),
        throwsA(isA<SkifluxFailure>()),
      );
      expect(wallet.refreshes, 0);
    });

    test('a successful claim completes the card and refreshes the wallet',
        () async {
      final repo = _FakePlatformTasksRepository(
        tasks: [
          _platformTask(status: PlatformTaskStatus.claimable, claimable: true),
        ],
      );
      final wallet = _RecordingWalletNotifier();
      final c = _tasksContainer(platformRepo: repo, wallet: wallet);
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      await c.read(tasksProvider.notifier).completeMission('pt-1');
      // Wallet refresh is fired without awaiting — let it run.
      await Future<void>.delayed(Duration.zero);

      final mission = c.read(tasksProvider).missions.single;
      expect(mission.completed, isTrue);
      expect(mission.pending, isFalse);
      expect(repo.claimCalls, ['pt-1']);
      expect(wallet.refreshes, 1);
    });

    test('a not-started manual mission starts then submits, without claiming',
        () async {
      final repo = _FakePlatformTasksRepository(tasks: [_platformTask()]);
      final c = _tasksContainer(platformRepo: repo);
      await c.read(tasksProvider.notifier).refreshMissionsFromBackend();

      await c.read(tasksProvider.notifier).completeMission('pt-1');

      expect(repo.startCalls, ['pt-1']);
      expect(repo.submitCalls, ['pt-1']);
      expect(repo.claimCalls, isEmpty);
      // Submit made it claimable — not Done: rewards land only on claim.
      final mission = c.read(tasksProvider).missions.single;
      expect(mission.completed, isFalse);
      expect(mission.claimable, isTrue);
      expect(mission.actionLabel, 'Claim');
    });
  });

  group('learning refresh (watched tasks + submissions)', () {
    test('signed out keeps the demo seed', () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(watched: [_watchedJson()]),
        signedIn: false,
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      expect(c.read(tasksProvider).learning, hasLength(6));
      expect(c.read(tasksProvider).learningSource, TaskSectionSource.seed);
    });

    test('signed in maps watched tasks onto learning cards', () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(watched: [_watchedJson()]),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      final state = c.read(tasksProvider);
      expect(state.learningSource, TaskSectionSource.live);
      final task = state.learning.single;
      expect(task.id, 'task-1');
      expect(task.fromBackend, isTrue);
      expect(task.kind, LearningTaskKind.submission);
      expect(task.status, LearningTaskStatus.pending);
      expect(task.episodeId, 'ep-1');
      expect(task.acceptedProofTypes, ['link', 'image']);
      expect(task.briefIntro, contains('hero section'));
      // No reward fields exist on the wire — nothing is invented.
      expect(task.hasCoinReward, isFalse);
      expect(task.hasXpReward, isFalse);
    });

    test('an empty watched list is an honest empty state, not seeds',
        () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(watched: []),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      expect(c.read(tasksProvider).learning, isEmpty);
      expect(c.read(tasksProvider).learningSource, TaskSectionSource.live);
    });

    test('signed in failure is an error state, not seeds', () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(failWatched: true),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      expect(c.read(tasksProvider).learning, isEmpty);
      expect(c.read(tasksProvider).learningSource, TaskSectionSource.error);
    });

    test('a rejected submission hydrates Action Needed with the feedback',
        () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(
          watched: [_watchedJson()],
          submissions: [
            _submissionJson(
              status: 'rejected',
              rejectionReason: 'Contrast is too low.',
            ),
          ],
        ),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      final task = c.read(tasksProvider).learning.single;
      expect(task.status, LearningTaskStatus.actionNeeded);
      expect(task.feedback, 'Contrast is too low.');
    });

    test('a pending submission hydrates In Review', () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(
          watched: [_watchedJson()],
          submissions: [_submissionJson(status: 'pending')],
        ),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      expect(
        c.read(tasksProvider).learning.single.status,
        LearningTaskStatus.inReview,
      );
    });

    test('an assessment maps its questions into QuizData', () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(
          watched: [_watchedJson(kind: 'assessment')],
        ),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      final task = c.read(tasksProvider).learning.single;
      expect(task.kind, LearningTaskKind.quiz);
      final quiz = task.quiz!;
      expect(quiz.questions, hasLength(1));
      expect(quiz.questions.single.id, 'q-1');
      expect(quiz.questions.single.correctIndex, 1);
      expect(quiz.passPercent, 70);
      expect(quiz.timerSeconds, 5 * 60);
    });

    test('a passed assessment submission hydrates Completed with the score',
        () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(
          watched: [_watchedJson(kind: 'assessment')],
          submissions: [
            _submissionJson(status: 'passed', scorePercent: 100),
          ],
        ),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      final task = c.read(tasksProvider).learning.single;
      expect(task.status, LearningTaskStatus.completed);
      expect(task.quizCorrect, 1);
    });

    test('a failed submissions read degrades to the watched statuses',
        () async {
      final c = _tasksContainer(
        episodeRepo: _FakeEpisodeTasksRepository(
          watched: [_watchedJson()],
          failSubmissions: true,
        ),
      );

      await c.read(tasksProvider.notifier).refreshLearningFromBackend();

      expect(c.read(tasksProvider).learningSource, TaskSectionSource.live);
      expect(
        c.read(tasksProvider).learning.single.status,
        LearningTaskStatus.pending,
      );
    });
  });

  group('LearningTask.statusFrom', () {
    test('maps the /me/submissions vocabulary', () {
      expect(
        LearningTask.statusFrom('approved', submitted: true),
        LearningTaskStatus.completed,
      );
      expect(
        LearningTask.statusFrom('passed', submitted: true),
        LearningTaskStatus.completed,
      );
      expect(
        LearningTask.statusFrom('rejected', submitted: true),
        LearningTaskStatus.actionNeeded,
      );
      expect(
        LearningTask.statusFrom('failed', submitted: true),
        LearningTaskStatus.actionNeeded,
      );
      expect(
        LearningTask.statusFrom('pending', submitted: true),
        LearningTaskStatus.inReview,
      );
    });

    test('a pending task with no submission is Pending, not In Review', () {
      expect(LearningTask.statusFrom('pending'), LearningTaskStatus.pending);
      expect(
        LearningTask.statusFrom('not_submitted'),
        LearningTaskStatus.pending,
      );
    });

    test('submitted-style statuses read as In Review', () {
      expect(LearningTask.statusFrom('submitted'), LearningTaskStatus.inReview);
      expect(LearningTask.statusFrom('in_review'), LearningTaskStatus.inReview);
    });
  });
}

// ── Fixtures ─────────────────────────────────────────────────────────

PlatformTask _platformTask({
  String id = 'pt-1',
  String skillcoinReward = '5.00',
  PlatformTaskStatus status = PlatformTaskStatus.notStarted,
  bool claimable = false,
  bool completed = false,
  bool isActive = true,
  String? externalUrl,
}) => PlatformTask(
  id: id,
  slug: id,
  title: 'Follow Instagram',
  description: 'Join the community',
  category: 'social',
  triggerType: '',
  actionType: '',
  verificationMode: 'manual',
  progressTarget: 1,
  progressCurrent: 0,
  icon: 'instagram',
  metadata: const {},
  sortOrder: 0,
  xpReward: 10,
  skillcoinReward: Decimal.parse(skillcoinReward),
  status: status,
  claimable: claimable,
  completed: completed,
  isActive: isActive,
  externalUrl: externalUrl,
);

WatchedEpisodeTask _watchedJson({
  String kind = 'project_based',
  String status = 'pending',
}) => WatchedEpisodeTask.fromJson({
  'id': 'task-1',
  'episode_id': 'ep-1',
  'episode_title': 'Design Systems from Scratch',
  'season_id': 'season-1',
  'season_title': 'UI Foundations',
  'kind': kind,
  'status': status,
  'sla_time_limit_hours': 24,
  'sla_deadline': null,
  'task_brief': 'Design a hero section for FlowBase. Use the token system.',
  'accepted_proof_types': ['link', 'image'],
  'pass_score_percent': kind == 'assessment' ? 70 : null,
  'questions': kind == 'assessment'
      ? [
          {
            'id': 'q-1',
            'question_text': 'What is a design token?',
            'option_a': 'A fee',
            'option_b': 'A named value',
            'option_c': 'A component',
            'option_d': 'A file',
            'correct_answer': 'B',
            'order': 1,
          },
        ]
      : [],
  'time_limit_minutes': kind == 'assessment' ? 5 : null,
  'max_attempts': null,
  'completion_criteria': <String, dynamic>{},
  'viewed_at': '2026-07-28T09:00:00Z',
  'submitted_at': null,
  'reviewed_at': null,
});

UserSubmission _submissionJson({
  String status = 'pending',
  String? rejectionReason,
  int? scorePercent,
}) => UserSubmission.fromJson({
  'id': 'sub-1',
  'type': 'project',
  'episode_id': 'ep-1',
  'episode_title': 'Design Systems from Scratch',
  'season_title': 'UI Foundations',
  'skillworld': 'design',
  'task_id': 'task-1',
  'status': status,
  'submission_text': null,
  'submission_url': 'https://figma.com/file/x',
  'submission_file_url': null,
  'proof_type': 'link',
  'cashback_amount': null,
  'rejection_reason': rejectionReason,
  'reviewed_at': null,
  'created_at': '2026-07-29T10:00:00Z',
  'score_percent': scorePercent,
  'passed': null,
  'answers': null,
  'attempt_number': 1,
  'time_taken_seconds': null,
  'submitted_at': '2026-07-29T10:00:00Z',
});

ProviderContainer _tasksContainer({
  _FakePlatformTasksRepository? platformRepo,
  _FakeEpisodeTasksRepository? episodeRepo,
  _RecordingWalletNotifier? wallet,
  bool signedIn = true,
}) {
  final c = ProviderContainer(
    // Riverpod 3 retries a failed build with backoff by default.
    retry: (_, _) => null,
    overrides: [
      tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
      if (platformRepo != null)
        platformTasksRepositoryProvider.overrideWithValue(platformRepo),
      if (episodeRepo != null)
        episodeTasksRepositoryProvider.overrideWithValue(episodeRepo),
      walletProvider.overrideWith(() => wallet ?? _RecordingWalletNotifier()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Stateful fake: claim/submit mutate the list the next refresh returns.
class _FakePlatformTasksRepository extends PlatformTasksRepository {
  _FakePlatformTasksRepository({
    List<PlatformTask> tasks = const [],
    this.failList = false,
    this.failClaim = false,
  })  : tasks = List.of(tasks),
        super(Dio());

  final List<PlatformTask> tasks;
  bool failList;
  final bool failClaim;

  int listCalls = 0;
  final List<String> startCalls = [];
  final List<String> submitCalls = [];
  final List<String> claimCalls = [];

  PlatformTask _byId(String id) => tasks.firstWhere((t) => t.id == id);

  void _replace(PlatformTask updated) {
    final index = tasks.indexWhere((t) => t.id == updated.id);
    if (index >= 0) tasks[index] = updated;
  }

  @override
  Future<List<PlatformTask>> list() async {
    listCalls++;
    if (failList) {
      throw const SkifluxFailure(SkifluxErrorKind.contentLoadFailed);
    }
    return List.of(tasks);
  }

  @override
  Future<PlatformTask?> start(String taskId) async {
    startCalls.add(taskId);
    final updated = _byId(taskId).copyWith(
      status: PlatformTaskStatus.inProgress,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<PlatformTask?> submit(String taskId) async {
    submitCalls.add(taskId);
    final updated = _byId(taskId).copyWith(
      status: PlatformTaskStatus.claimable,
      claimable: true,
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<PlatformTask?> claim(String taskId) async {
    claimCalls.add(taskId);
    if (failClaim) {
      throw const SkifluxFailure(SkifluxErrorKind.taskSubmission);
    }
    final updated = _byId(taskId).copyWith(
      status: PlatformTaskStatus.claimed,
      claimable: false,
      completed: true,
    );
    _replace(updated);
    return updated;
  }
}

class _FakeEpisodeTasksRepository extends EpisodeTasksRepository {
  _FakeEpisodeTasksRepository({
    this.watched = const [],
    this.submissions = const [],
    this.failWatched = false,
    this.failSubmissions = false,
  }) : super(Dio());

  final List<WatchedEpisodeTask> watched;
  final List<UserSubmission> submissions;
  final bool failWatched;
  final bool failSubmissions;

  @override
  Future<List<WatchedEpisodeTask>> getWatchedTasks() async {
    if (failWatched) {
      throw const SkifluxFailure(SkifluxErrorKind.contentLoadFailed);
    }
    return watched;
  }

  @override
  Future<List<UserSubmission>> getMySubmissions({
    String? status,
    String? episodeId,
    int? pageSize,
  }) async {
    if (failSubmissions) {
      throw const SkifluxFailure(SkifluxErrorKind.contentLoadFailed);
    }
    return submissions;
  }
}

/// Counts refreshes instead of hitting the network.
class _RecordingWalletNotifier extends WalletNotifier {
  int refreshes = 0;

  @override
  Future<void> refreshFromBackend() async {
    refreshes++;
  }
}

/// Presence-only session gate, with no platform channel behind it.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}
