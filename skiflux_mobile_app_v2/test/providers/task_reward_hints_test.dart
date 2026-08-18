/// Learning-task rewards.
///
/// `WatchedEpisodeTaskItem` declares no reward fields at all — unlike
/// `PlatformTaskUser`, which has `xp_reward` and `skillcoin_reward` — so the
/// reward chips on the learning cards had nothing to bind to and never
/// appeared against a live backend. The card was not broken; the payload was
/// silent.
///
/// [WatchedEpisodeTask.rewardHints] gathers every place a reward could
/// plausibly arrive so the chips light up the moment one does, without ever
/// inventing a figure. These pin both halves of that: what is picked up, and
/// what is still (correctly) nothing.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/tasks/data/models/episode_task_models.dart';
import 'package:skiflux/features/tasks/data/tasks_store.dart';

Map<String, dynamic> _row({
  Object? completionCriteria,
  Map<String, dynamic> extra = const {},
}) => {
  'id': 'task-1',
  'episode_id': 'ep-1',
  'episode_title': 'Design Tokens',
  'season_id': 'season-1',
  'season_title': 'Design Systems',
  'kind': 'project_based',
  'status': 'pending',
  'task_brief': 'Build the hero section.',
  // ignore: use_null_aware_elements
  if (completionCriteria != null) 'completion_criteria': completionCriteria,
  ...extra,
};

LearningTask _task(Map<String, dynamic> json) =>
    LearningTask.fromWatched(WatchedEpisodeTask.fromJson(json));

void main() {
  group('learning task rewards', () {
    test('a payload with no reward anywhere shows no chips', () {
      // The live case today. "No reward declared" must render as no chip, not
      // as "+0" and not as an invented default.
      final task = _task(_row());
      expect(task.coins, Decimal.zero);
      expect(task.xp, 0);
      expect(task.hasAnyReward, isFalse);
    });

    test('reads the spec spelling out of completion_criteria', () {
      final task = _task(
        _row(
          completionCriteria: {'skillcoin_reward': '25.50', 'xp_reward': 40},
        ),
      );
      expect(task.coins, Decimal.parse('25.50'));
      expect(task.xp, 40);
      expect(task.hasAnyReward, isTrue);
      // Money is exact — "25.50" must not become 26, or 25.
      expect(task.coinsLabel, '25.50');
    });

    test('reads the short spellings too', () {
      final task = _task(_row(completionCriteria: {'coins': 5, 'xp': 10}));
      expect(task.coins, Decimal.fromInt(5));
      expect(task.xp, 10);
    });

    test('reads a nested reward object', () {
      final task = _task(
        _row(
          completionCriteria: {
            'steps': ['watch', 'submit'],
            'reward': {'coins': '7', 'xp': 15},
          },
        ),
      );
      expect(task.coins, Decimal.fromInt(7));
      expect(task.xp, 15);
    });

    test('reads reward fields sent at the top level of the row', () {
      // If the backend adds `xp_reward` / `skillcoin_reward` to the row the way
      // PlatformTaskUser already has them, this picks them up with no further
      // client change.
      final task = _task(
        _row(extra: {'xp_reward': 60, 'skillcoin_reward': '12'}),
      );
      expect(task.xp, 60);
      expect(task.coins, Decimal.fromInt(12));
    });

    test('completion_criteria wins over a top-level value', () {
      final task = _task(
        _row(
          completionCriteria: {'xp_reward': 99},
          extra: {'xp_reward': 1},
        ),
      );
      expect(task.xp, 99);
    });

    test('a non-scalar under a reward key is ignored, not crashed on', () {
      final task = _task(
        _row(completionCriteria: {'coins': <String>[], 'xp': {}}),
      );
      expect(task.coins, Decimal.zero);
      expect(task.xp, 0);
    });

    test('a criteria blob that is not an object is survivable', () {
      // Spec type is `{}` — anything. A string or a list must not throw.
      expect(() => _task(_row(completionCriteria: 'watch it')), returnsNormally);
      expect(() => _task(_row(completionCriteria: [1, 2])), returnsNormally);
    });

    test('unrelated numeric fields are never mistaken for a reward', () {
      // `sla_time_limit_hours` and `pass_score_percent` are numbers on the same
      // row; only reward-named keys are read.
      final task = _task(
        _row(extra: {'sla_time_limit_hours': 48, 'pass_score_percent': 70}),
      );
      expect(task.hasAnyReward, isFalse);
    });

    test('an assessment carries the same reward into its quiz intro', () {
      final task = _task({
        ..._row(completionCriteria: {'coins': 20, 'xp': 50}),
        'kind': 'assessment',
        'questions': [
          {
            'question_text': 'What is a design token?',
            'option_a': 'A named value',
            'option_b': 'A component',
            'option_c': 'A licence',
            'option_d': 'A file size',
            'correct_option': 'a',
          },
        ],
      });
      expect(task.quiz, isNotNull);
      expect(task.quiz!.rewardCoins, Decimal.fromInt(20));
      expect(task.quiz!.rewardXp, 50);
    });
  });
}

