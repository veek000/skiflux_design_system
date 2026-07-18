/// Demo leaderboard data backing the Leaderboard screen (Figma Profile
/// Flow 01 `1256:25612`). Static in-memory only, mirroring the other
/// feature stores.
library;

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.username,
    required this.initials,
    required this.xp,
  });

  final int rank;
  final String name;
  final String username;
  final String initials;
  final int xp;

  String get handle => '@$username';

  /// "4,820" — thousands-grouped XP for the badges/podium labels.
  String get xpLabel {
    final digits = '$xp';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$buffer';
  }
}

/// Static demo store. The signed-in user (Amara, see `_MyProfileDemo`)
/// sits at rank #12 — matching the My Profile "#12" leaderboard row —
/// and her row is highlighted in the list.
abstract final class LeaderboardStore {
  /// League pills (Figma Button Group Pill `1256:25615`).
  static const List<String> leagues = [
    'Novice', 'Amateur', 'Senior', 'Expert', 'Professional', 'Veteran',
  ];

  static const int currentRank = 12;
  static const int betterThanPercent = 60;

  /// Ranked entries, podium first. Demo cast reuses the subscriptions
  /// creators plus filler names; XP descends with rank.
  static const List<LeaderboardEntry> entries = [
    LeaderboardEntry(
        rank: 1,
        name: 'Lola Motion',
        username: 'lolamotion',
        initials: 'L',
        xp: 4820),
    LeaderboardEntry(
        rank: 2,
        name: 'Kojo Sketches',
        username: 'kojosketch',
        initials: 'K',
        xp: 4515),
    LeaderboardEntry(
        rank: 3,
        name: 'Design Dan',
        username: 'designdan',
        initials: 'D',
        xp: 4230),
    LeaderboardEntry(
        rank: 4,
        name: 'Pixel Priye',
        username: 'pixelpriye',
        initials: 'P',
        xp: 3980),
    LeaderboardEntry(
        rank: 5,
        name: 'Uche Draws',
        username: 'uchedraws',
        initials: 'U',
        xp: 3760),
    LeaderboardEntry(
        rank: 6,
        name: 'Sade Studio',
        username: 'sadestudio',
        initials: 'S',
        xp: 3540),
    LeaderboardEntry(
        rank: 7,
        name: 'Femi Frames',
        username: 'femiframes',
        initials: 'F',
        xp: 3310),
    LeaderboardEntry(
        rank: 8,
        name: 'Nia Vectors',
        username: 'niavectors',
        initials: 'N',
        xp: 3090),
    LeaderboardEntry(
        rank: 9,
        name: 'Tobi Types',
        username: 'tobitypes',
        initials: 'T',
        xp: 2870),
    LeaderboardEntry(
        rank: 10,
        name: 'Zara Zines',
        username: 'zarazines',
        initials: 'Z',
        xp: 2680),
    LeaderboardEntry(
        rank: 11,
        name: 'Ify Inks',
        username: 'ifyinks',
        initials: 'I',
        xp: 2560),
    LeaderboardEntry(
        rank: 12,
        name: 'Amara Design',
        username: 'amara',
        initials: 'AD',
        xp: 2450),
    LeaderboardEntry(
        rank: 13,
        name: 'Bode Brushes',
        username: 'bodebrushes',
        initials: 'B',
        xp: 2310),
    LeaderboardEntry(
        rank: 14,
        name: 'Chi Canvas',
        username: 'chicanvas',
        initials: 'C',
        xp: 2180),
    LeaderboardEntry(
        rank: 15,
        name: 'Wale Works',
        username: 'waleworks',
        initials: 'W',
        xp: 2040),
  ];

  static List<LeaderboardEntry> get podium => entries.sublist(0, 3);

  static List<LeaderboardEntry> get ranked => entries.sublist(3);
}
