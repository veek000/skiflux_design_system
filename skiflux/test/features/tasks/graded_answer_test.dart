import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/tasks/data/models/episode_task_models.dart';

void main() {
  group('GradedAnswer.parseMap', () {
    test('parses flat letter map', () {
      final map = GradedAnswer.parseMap({
        'q1': 'A',
        'q2': 'C',
      });
      expect(map['q1']!.selectedIndex, 0);
      expect(map['q1']!.correctIndex, isNull);
      expect(map['q2']!.selectedIndex, 2);
    });

    test('parses nested selected + correct_answer for review', () {
      final map = GradedAnswer.parseMap({
        'q1': {
          'selected': 'B',
          'correct_answer': 'D',
        },
        'q2': {
          'answer': 'A',
          'correct': 'A',
        },
      });
      expect(map['q1']!.selectedIndex, 1);
      expect(map['q1']!.correctIndex, 3);
      expect(map['q2']!.selectedIndex, 0);
      expect(map['q2']!.correctIndex, 0);
    });

    test('parses list rows with question_id', () {
      final map = GradedAnswer.parseMap([
        {
          'question_id': 'abc',
          'user_answer': 'C',
          'correct_answer': 'B',
        },
      ]);
      expect(map['abc']!.selectedIndex, 2);
      expect(map['abc']!.correctIndex, 1);
    });
  });
}

