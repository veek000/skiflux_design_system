/// Leaderboard backing the Leaderboard screen (Figma Profile Flow 01
/// `1256:25612`).
///
/// Nothing is seeded. Signed out there is nothing to rank, so the provider
/// resolves empty and the screen shows its empty state; a failed request stays
/// an `AsyncError` so the screen offers a retry rather than printing a sample
/// cast — and, worse, a sample *standing*, which is what made "#12" look like
/// the signed-in user's real position when it was a constant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
import '../../profile/data/models/user_profile.dart';
import '../../profile/data/profile_store.dart';
import 'leaderboard_repository.dart';
import 'models/leaderboard_row.dart';

// TODO(backend, minor): confirm the league vocabulary — the spec's `level`
// filter documents novice | amateur | senior | expert | professional, but the
// design's pill group also carries "Veteran" — expects: the level values the
// leaderboard actually accepts, or the pill dropped from the design
/// League pills (Figma Button Group Pill `1256:25615`).
///
/// The first pill is "All": the endpoint's default is every learner, and the
/// "better than N%" standing only reads correctly against that.
const kLeaderboardLeagues = <String>[
  'All',
  'Novice',
  'Amateur',
  'Senior',
  'Expert',
  'Professional',
  'Veteran',
];

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.username,
    required this.initials,
    required this.xp,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final String username;
  final String initials;
  final int xp;

  /// Remote avatar, null whenever the payload omits it — `SkifluxAvatar` then
  /// draws the [initials] circle.
  final String? avatarUrl;

  /// Whether this row is the signed-in learner, which is what the highlighted
  /// row keys off. Resolved in [LeaderboardNotifier], not sent as-is: see
  /// [LeaderboardNotifier.resolve] for the order of evidence.
  final bool isCurrentUser;

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

/// One answer from `GET /me/leaderboard`, for one league filter.
class LeaderboardData {
  const LeaderboardData({
    required this.entries,
    this.currentRank,
    this.currentLevel,
    this.betterThanPercent,
  });

  static const empty = LeaderboardData(entries: []);

  /// Every entry on the page, sorted by [LeaderboardEntry.rank] ascending —
  /// see `LeaderboardNotifier.resolve`.
  final List<LeaderboardEntry> entries;

  /// The signed-in learner's standing. Null when it is genuinely unknown —
  /// the payload omitted it and they are not on the page — so the screen can
  /// say nothing rather than claim a rank.
  final int? currentRank;

  /// Their league ("Novice" … "Professional"), from the same source as
  /// [currentRank]. Null when unknown.
  final String? currentLevel;

  /// Derived, not sent: the response has no "better than N%" field, so this is
  /// computed from [currentRank] against the total ranked population. Null
  /// whenever either input is missing — see `LeaderboardNotifier._percentileOf`.
  final int? betterThanPercent;

  bool get isEmpty => entries.isEmpty;

  /// The podium — ranks 1, 2 and 3, selected **by rank** rather than by
  /// position.
  ///
  /// `take(3)`/`skip(3)` only produced the right split while the payload
  /// happened to arrive rank-ordered, and nothing guaranteed that: `resolve`
  /// iterates the rows verbatim and the repository defaults a missing rank to
  /// 0. When the order slipped, the table started at whoever was fourth in the
  /// list rather than fourth on the board.
  ///
  /// A filtered league with fewer than three learners simply yields a shorter
  /// podium.
  List<LeaderboardEntry> get podium => entries
      .where((entry) => entry.rank >= 1 && entry.rank <= 3)
      .toList(growable: false);

  /// Everyone the podium doesn't hold: rank 4 and below, plus any row whose
  /// rank is unknown (0) — those belong in the table, not on the podium.
  List<LeaderboardEntry> get ranked => entries
      .where((entry) => entry.rank > 3 || entry.rank < 1)
      .toList(growable: false);

  /// Index of the signed-in learner's row within [ranked], or -1. Drives the
  /// rank card's opening scroll position.
  int get currentIndexInRanked =>
      ranked.indexWhere((entry) => entry.isCurrentUser);
}

/// Which league the pills are currently filtered to — index into
/// [kLeaderboardLeagues]. Kept outside the async provider so a pill tap
/// re-runs `build` instead of the screen holding a second copy of the
/// selection in `setState`.
///
/// [Notifier], not `StateProvider` — the latter is gone in Riverpod 3.x.
class LeaderboardLeagueNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Ignores an out-of-range index rather than filtering by a league that
  /// isn't in the pill group.
  void select(int index) {
    if (index < 0 || index >= kLeaderboardLeagues.length) return;
    state = index;
  }
}

final leaderboardLeagueProvider =
    NotifierProvider<LeaderboardLeagueNotifier, int>(
      LeaderboardLeagueNotifier.new,
    );

final leaderboardProvider =
    AsyncNotifierProvider<LeaderboardNotifier, LeaderboardData>(
      LeaderboardNotifier.new,
    );

class LeaderboardNotifier extends AsyncNotifier<LeaderboardData> {
  /// The spec caps `page_size` at 50. The rank card scrolls, so ask for the
  /// maximum instead of paginating — the list is a leaderboard, not a feed.
  static const pageSize = 50;

  @override
  Future<LeaderboardData> build() async {
    // Every dependency is subscribed to before the first await: a `ref.watch`
    // past an await point is no longer inside the build that owns it.
    final index = ref.watch(leaderboardLeagueProvider);
    // Index 0 is the "All" pill, which sends no `level` filter.
    final level = index == 0 ? null : kLeaderboardLeagues[index].toLowerCase();
    final tokens = ref.read(tokenStoreProvider);
    final repository = ref.read(leaderboardRepositoryProvider);
    // The profile is the fallback identity when the rows carry no "this is
    // you" flag. Subscribed here, awaited below.
    final profile = ref.watch(meProfileProvider.future);

    if (!await tokens.hasSession()) return LeaderboardData.empty;

    final page = await repository.getLeaderboard(
      level: level,
      pageSize: pageSize,
    );

    // A profile that failed to load is not worth failing the board over, so it
    // degrades to "no row highlighted" rather than throwing.
    UserProfile? me;
    try {
      me = await profile;
    } catch (_) {
      me = null;
    }

    return resolve(page, me);
  }

  /// Refetches. Invalidation rather than an in-place reload so the league
  /// subscription above is re-established with it.
  void refresh() => ref.invalidateSelf();

  /// Assembles the screen's model from a page and the signed-in learner.
  ///
  /// Which row is "you" is decided on the best evidence available, in order:
  ///
  /// 1. the row's own `is_me`, which the entry schema now carries;
  /// 2. a username match against `my_position` or `GET /me/profile`;
  /// 3. `my_position`'s rank, matched against the row ranks.
  ///
  /// Rank 3 is last because it is the weakest: a rank only identifies a row if
  /// the standing and the rows were computed over the same filter, which is
  /// not guaranteed for a league-filtered page.
  ///
  /// Static so provider tests can exercise the matching without a container.
  static LeaderboardData resolve(LeaderboardPage page, UserProfile? me) {
    final position = page.myPosition;
    // `my_position` is the better identity source than the cached profile: it
    // comes from the same query as the rows.
    final myUsername = _handle(position?.username) ?? _handle(me?.username);

    var matched = false;
    final entries = <LeaderboardEntry>[];
    for (final row in page.rows) {
      final isMe =
          row.isCurrentUser ||
          (myUsername != null && _handle(row.username) == myUsername);
      matched |= isMe;
      entries.add(_toEntry(row, isCurrentUser: isMe));
    }

    // `my_position` first: the spec sends it beside `results` precisely so the
    // standing survives the learner ranking below the page.
    final currentRank =
        position?.rank ??
        (matched
            ? entries.firstWhere((entry) => entry.isCurrentUser).rank
            : me?.rank);

    // Nothing matched by flag or username, but we know the rank — fall back to
    // marking the row that holds it.
    if (!matched && currentRank != null) {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].rank != currentRank) continue;
        entries[i] = _toEntry(page.rows[i], isCurrentUser: true);
        break;
      }
    }

    // Sort last: the `page.rows[i]` fallback above depends on `entries` still
    // being index-aligned with the payload. Unknown ranks (0) sort to the end
    // rather than ahead of first place.
    entries.sort((a, b) {
      final ra = a.rank >= 1 ? a.rank : 1 << 30;
      final rb = b.rank >= 1 ? b.rank : 1 << 30;
      return ra.compareTo(rb);
    });

    final level = position?.currentLevel;

    return LeaderboardData(
      entries: entries,
      currentRank: currentRank,
      currentLevel: (level != null && level.isNotEmpty)
          ? level
          : (me?.currentLevel.isNotEmpty ?? false)
          ? me!.currentLevel
          : null,
      betterThanPercent: _percentileOf(currentRank, page.totalCount),
    );
  }

  /// Bare lowercase handle, or null when there is nothing to compare.
  static String? _handle(String? username) {
    final handle = username?.replaceFirst('@', '').trim().toLowerCase();
    return (handle == null || handle.isEmpty) ? null : handle;
  }

  /// "Better than N%", derived — the response carries no such field.
  ///
  /// [total] must be the response's `count` (every ranked learner), **not** the
  /// number of rows on the page: ranking 12th of a 50-row page reads as "better
  /// than 78%" when 12th of 5,000 is better than 99%. Null unless both inputs
  /// are usable, since an invented percentage is worse than an absent one.
  static int? _percentileOf(int? rank, int? total) {
    if (rank == null || total == null) return null;
    if (rank < 1 || total < 2 || rank > total) return null;
    return ((total - rank) / (total - 1) * 100).round();
  }

  static LeaderboardEntry _toEntry(
    LeaderboardRow row, {
    required bool isCurrentUser,
  }) => LeaderboardEntry(
    rank: row.rank,
    name: row.displayName,
    username: row.username,
    // Derived, never sent: see `LeaderboardRow.initials`.
    initials: row.initials,
    xp: row.xp,
    avatarUrl: row.avatarUrl,
    isCurrentUser: isCurrentUser,
  );
}
