import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/public_user_profile_provider.dart';

/// The spec's `PublicUserProfile`, field for field. The mapping used to guess
/// `display_name`, `league`, `tasks_done` and `skills` — none of which exist —
/// and every miss landed on a demo constant that rendered as this person's own
/// data. These tests pin the real names and prove a miss now reads as absent.
void main() {
  group('parsePublicUserProfile', () {
    test('maps the documented payload', () {
      final profile = parsePublicUserProfile({
        'id': 'u-1',
        'first_name': 'Amara',
        'last_name': 'Okoye',
        'username': 'amara',
        'avatar_url': 'https://cdn/amara.png',
        'bio': 'Designer',
        'xp': 2450,
        'rank': 12,
        'current_level': 'Master',
        'task_done': '8',
        'episode_completed': '31',
        'skillworld': 'Design',
        'earned_badges': [
          {'name': 'Top Learner'},
          {'name': '3 Days Streak'},
        ],
      });

      expect(profile.name, 'Amara Okoye');
      expect(profile.handle, '@amara');
      expect(profile.resolvedInitials, 'AO');
      expect(profile.avatarUrl, 'https://cdn/amara.png');
      expect(profile.league, 'Master');
      expect(profile.xp, 2450);
      expect(profile.leaderboardRank, 12);
      // `task_done` is typed as a string in the schema.
      expect(profile.tasksDone, 8);
      expect(profile.skills, ['Design']);
      // Catalogue order, not payload order.
      expect(profile.badges.map((b) => b.label), ['3 Days Streak', 'Top Learner']);
      expect(
        profile.badges.first.asset,
        'assets/badges/badge_3_days_streak.svg',
      );
    });

    test('an absent field reads as absent, never as a sample value', () {
      final profile = parsePublicUserProfile({'username': 'ghost'});

      // The old defaults were Novice / 350 / #12 / 8 tasks / a demo email and
      // three sample skills — all indistinguishable from real values on screen.
      expect(profile.league, isNull);
      expect(profile.xp, isNull);
      expect(profile.leaderboardRank, isNull);
      expect(profile.tasksDone, isNull);
      expect(profile.email, isNull);
      expect(profile.skills, isEmpty);
      expect(profile.badges, isEmpty);
      expect(profile.completedTasks, isEmpty);
      // A nameless account still reads as someone.
      expect(profile.name, 'ghost');
    });

    test('badge art is matched loosely, and unknown badges are dropped', () {
      final profile = parsePublicUserProfile({
        'username': 'a',
        'earned_badges': [
          {'name': '  3   days   streak '},
          {'name': 'Badge From A Newer Release'},
        ],
      });

      // Case and runs of whitespace do not break the join to local art…
      expect(profile.badges, hasLength(1));
      expect(profile.badges.single.label, '3 Days Streak');
      // …and a badge this build has no art for is skipped, not drawn broken.
    });

    test('accepts earned_badges as plain names or a joined string', () {
      expect(
        parsePublicUserProfile({
          'username': 'a',
          'earned_badges': ['Super Fan'],
        }).badges.single.label,
        'Super Fan',
      );
      expect(
        parsePublicUserProfile({
          'username': 'a',
          'earned_badges': 'Super Fan, Big Earner',
        }).badges.map((b) => b.label),
        ['Big Earner', 'Super Fan'],
      );
    });

    test('skillworld may arrive as a list or a joined string', () {
      expect(
        parsePublicUserProfile({
          'username': 'a',
          'skillworld': ['Design', 'Marketing'],
        }).skills,
        ['Design', 'Marketing'],
      );
      expect(
        parsePublicUserProfile({
          'username': 'a',
          'skillworld': 'Design, Marketing',
        }).skills,
        ['Design', 'Marketing'],
      );
    });

    test('the email the contact row needs is read when present', () {
      // The spec omits it today; the row hides itself until it appears.
      expect(
        parsePublicUserProfile({
          'username': 'a',
          'email': 'amara@skiflux.app',
        }).email,
        'amara@skiflux.app',
      );
    });
  });
}
