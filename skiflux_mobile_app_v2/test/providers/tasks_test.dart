import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/tasks_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('tasksProvider', () {
    test('build returns seeded learning tasks and missions', () {
      final state = container.read(tasksProvider);
      expect(state.learning, hasLength(6));
      expect(state.missions, hasLength(10));
    });

    test('seed includes completed submission and quiz', () {
      final state = container.read(tasksProvider);
      final completed =
          state.learning.where((t) => t.status == LearningTaskStatus.completed);
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
      expect(
        container.read(tasksProvider).byId('learn-5')?.feedback,
        isNull,
      );
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
      // Should NOT mark completed since passed=false.
      expect(task?.status, LearningTaskStatus.pending);
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

    test('completeMission marks mission as done', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.completeMission('m-ig');
      final mission =
          container.read(tasksProvider).missions.firstWhere((m) => m.id == 'm-ig');
      expect(mission.completed, isTrue);
    });

    test('completeMission on already-completed mission is idempotent', () {
      final notifier = container.read(tasksProvider.notifier);
      notifier.completeMission('m-ig');
      // Complete again — should stay completed (not throw or reset).
      notifier.completeMission('m-ig');
      final mission =
          container.read(tasksProvider).missions.firstWhere((m) => m.id == 'm-ig');
      expect(mission.completed, isTrue);
    });

    test('completeMission on unknown id is no-op', () {
      final notifier = container.read(tasksProvider.notifier);
      const originalCount = 10;
      notifier.completeMission('nonexistent');
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
}
