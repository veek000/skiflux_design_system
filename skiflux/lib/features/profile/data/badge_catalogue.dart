/// The app's badge artwork, and the rule for deciding which are earned.
///
/// **Art is local and complete.** Every badge the platform awards ships in
/// `assets/badges/` and is rendered in one of two states — earned (full
/// colour) or locked (desaturated). The backend supplies no artwork; it only
/// answers *which* badges a learner has.
///
/// **Earned means "the backend listed it," plus clear local progress.**
/// `GET /me/badges` returns `UserBadge[]` (each with `earned_at`). The badges
/// screen also unions [inferredEarnedBadgeNames] from profile stats so a
/// completed first task / 3-day streak is not stuck locked when awarding
/// lags. `Badge.is_active` is a **platform** flag from admin CRUD — not
/// "this learner holds it".
library;

import '../public_user_profile_screen.dart';

/// Badge name → local SVG. The names are the backend's `Badge.name` values.
///
// TODO(backend, minor): `Badge` has no stable slug, so art is matched on the
// display name and a rename would silently unmatch every badge — expects:
// slug: String on the Badge schema
const kBadgeAssets = <String, String>{
  'First Task Completed': 'assets/badges/badge_first_task_completed.svg',
  '3 Days Streak': 'assets/badges/badge_3_days_streak.svg',
  'Top Learner': 'assets/badges/badge_top_learner.svg',
  '10 Days Streak': 'assets/badges/badge_10_days_streak.svg',
  'Big Earner': 'assets/badges/badge_big_earner.svg',
  'Super Fan': 'assets/badges/badge_super_fan.svg',
  'Referral Pro': 'assets/badges/badge_referral_pro.svg',
  'Speed Learner': 'assets/badges/badge_speed_learner.svg',
};

/// What a locked tile says instead of "Earned" — the requirement to meet.
const kBadgeLockedCaptions = <String, String>{
  'First Task Completed': 'Complete first task',
  '3 Days Streak': 'Complete 3 days',
  'Top Learner': 'Top learner rank',
  '10 Days Streak': 'Complete 10 days',
  'Big Earner': 'Earn 500 coins',
  'Super Fan': 'Like 50 videos',
  'Referral Pro': 'Refer 3 friends',
  'Speed Learner': '5 episodes in a day',
};

/// Comparison key for badge names: case- and spacing-insensitive, so
/// "3 days streak" and "3  Days  Streak" both find the same art.
///
/// Deliberately loose because the only join between the backend's badges and
/// the local art is a display string — see the TODO on [kBadgeAssets].
String badgeKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final Map<String, String> _assetsByKey = {
  for (final entry in kBadgeAssets.entries) badgeKey(entry.key): entry.value,
};

final Map<String, String> _namesByKey = {
  for (final name in kBadgeAssets.keys) badgeKey(name): name,
};

/// The local artwork for [name], or null when the backend named a badge this
/// build has no art for — a newly-added badge should be skipped, not drawn as
/// a broken tile.
String? badgeAssetFor(String name) => _assetsByKey[badgeKey(name)];

/// The catalogue's own spelling of [name], for captions and labels.
String badgeDisplayName(String name) => _namesByKey[badgeKey(name)] ?? name;

/// The earned badges from [earnedNames], in catalogue order, dropping any name
/// with no local art.
List<ProfileBadgeItem> badgeItemsFor(Iterable<String> earnedNames) {
  final earned = earnedNames.map(badgeKey).toSet();
  return [
    for (final entry in kBadgeAssets.entries)
      if (earned.contains(badgeKey(entry.key)))
        ProfileBadgeItem(entry.key, entry.value),
  ];
}

/// Profile stats that can unlock catalogue badges on the client when the
/// backend has not yet listed them under `GET /me/badges`.
///
/// Stopgap until server-side awarding is reliable — the UI should not stay
/// fully locked after the learner has clearly met a requirement.
class BadgeProgressHints {
  const BadgeProgressHints({
    this.taskDone = 0,
    this.streakCount = 0,
    this.coins = 0,
    this.episodeCompleted = 0,
  });

  final int taskDone;
  final int streakCount;
  final int coins;
  final int episodeCompleted;
}

/// Catalogue badge names inferred from [hints], for union with API awards.
///
/// Only returns names that exist in [kBadgeAssets]. Does not invent new
/// badges or override a stricter server denial — the screen unions these
/// with whatever `GET /me/badges` already returned.
Set<String> inferredEarnedBadgeNames(BadgeProgressHints hints) {
  final names = <String>{};
  if (hints.taskDone >= 1) names.add('First Task Completed');
  if (hints.streakCount >= 3) names.add('3 Days Streak');
  if (hints.streakCount >= 10) names.add('10 Days Streak');
  if (hints.coins >= 500) names.add('Big Earner');
  // Speed Learner / Super Fan / Referral Pro need signals we do not have
  // locally (same-day episode count, like count, referral count).
  return {
    for (final name in names)
      if (kBadgeAssets.containsKey(name)) name,
  };
}
