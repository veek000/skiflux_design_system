import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/profile/badges_screen.dart';
import 'package:skiflux/features/profile/data/badge_catalogue.dart';
import 'package:skiflux/features/profile/data/badges_repository.dart';

/// The badge rule: every badge in the app ships locally and starts locked;
/// the backend only says which ones this learner has earned.
void main() {
  UserBadge earned(String name, {bool isActive = true}) => UserBadge(
    id: 'ub-$name',
    badge: Badge(
      id: 'b-$name',
      name: name,
      description: '',
      isActive: isActive,
    ),
  );

  group('buildDisplayBadges', () {
    test('shows the whole catalogue, all locked, when nothing is earned', () {
      final badges = buildDisplayBadges(const []);

      expect(badges, hasLength(kBadgeAssets.length));
      expect(badges.every((b) => !b.earned), isTrue);
      // A locked tile states the requirement, not the word "Earned".
      expect(
        badges.firstWhere((b) => b.name == 'Big Earner').caption,
        'Earn 500 coins',
      );
    });

    test('flips exactly the badges the backend listed', () {
      final badges = buildDisplayBadges([
        earned('Top Learner'),
        earned('Super Fan'),
      ]);

      expect(
        badges.where((b) => b.earned).map((b) => b.name),
        ['Top Learner', 'Super Fan'],
      );
      expect(
        badges.firstWhere((b) => b.name == 'Top Learner').caption,
        'Earned',
      );
      // Everything else stays locked rather than disappearing.
      expect(badges, hasLength(kBadgeAssets.length));
    });

    test('is_active is the platform flag, not the award', () {
      // An admin retiring a badge platform-wide must not un-earn it for the
      // learners already holding it. Presence in the response is the award.
      final badges = buildDisplayBadges([
        earned('Referral Pro', isActive: false),
      ]);

      expect(badges.firstWhere((b) => b.name == 'Referral Pro').earned, isTrue);
    });

    test('matches names loosely, since Badge carries no slug', () {
      final badges = buildDisplayBadges([earned('  10   days   STREAK ')]);

      expect(badges.firstWhere((b) => b.name == '10 Days Streak').earned, isTrue);
    });

    test('a badge this build has no art for earns nothing and crashes nothing', () {
      final badges = buildDisplayBadges([
        earned('Badge From A Newer Release'),
        earned('Speed Learner'),
      ]);

      expect(badges, hasLength(kBadgeAssets.length));
      expect(badges.where((b) => b.earned).map((b) => b.name), [
        'Speed Learner',
      ]);
    });

    test('every catalogue entry has art and a locked caption', () {
      for (final name in kBadgeAssets.keys) {
        expect(badgeAssetFor(name), isNotNull, reason: name);
        expect(kBadgeLockedCaptions[name], isNotNull, reason: name);
      }
    });
  });
}

