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
    this.id = '',
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  /// Learner UUID when the API sent one — used only for identity matching.
  final String id;

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

  LeaderboardEntry copyWith({
    String? id,
    int? rank,
    String? name,
    String? username,
    String? initials,
    int? xp,
    String? avatarUrl,
    bool? isCurrentUser,
  }) => LeaderboardEntry(
    id: id ?? this.id,
    rank: rank ?? this.rank,
    name: name ?? this.name,
    username: username ?? this.username,
    initials: initials ?? this.initials,
    xp: xp ?? this.xp,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isCurrentUser: isCurrentUser ?? this.isCurrentUser,
  );
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

  /// Every entry on the page, sorted by XP descending (then rank) —
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

  /// The podium — the three highest-XP learners on the page.
  ///
  /// Places are XP-driven: a stale or shuffled `rank` field must not put a
  /// lower-XP learner on 1st while someone with more XP sits in the table.
  /// After [LeaderboardNotifier.resolve] renumbers when needed, this is the
  /// same as ranks 1–3, but we still select by XP so a partial page with a
  /// missing rank-1 still fills the steps correctly.
  ///
  /// A filtered league with fewer than three learners simply yields a shorter
  /// podium.
  List<LeaderboardEntry> get podium =>
      entries.take(3).toList(growable: false);

  /// Everyone below the podium (4th and lower by XP).
  List<LeaderboardEntry> get ranked =>
      entries.skip(3).toList(growable: false);

  /// The learner standing on [place] (1, 2 or 3), if the page has one.
  LeaderboardEntry? atPodiumPlace(int place) {
    if (place < 1 || place > podium.length) return null;
    return podium[place - 1];
  }

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
  /// Which row is "you" is decided only on identity evidence:
  ///
  /// 1. the row's own `is_me`;
  /// 2. a UUID match against `my_position.id` or `GET /me/profile`.id;
  /// 3. a username match against `my_position` or the profile
  ///    (`username` is nullable on the schema — id is the safer key);
  /// 4. if still unmatched, **append** `my_position`, else a profile-built
  ///    row, so the learner always appears — never paint another row as "you"
  ///    just because ranks match.
  ///
  /// Display order is **XP descending**. When server ranks are missing or
  /// disagree with XP order, ranks are renumbered 1…n so the podium, table,
  /// standing pill, and "better than N%" line all agree.
  ///
  /// Static so provider tests can exercise the matching without a container.
  static LeaderboardData resolve(LeaderboardPage page, UserProfile? me) {
    final position = page.myPosition;
    // `my_position` is the better identity source than the cached profile: it
    // comes from the same query as the rows.
    final myId = _id(position?.id) ?? _id(me?.id);
    final myUsername = _handle(position?.username) ?? _handle(me?.username);

    var matched = false;
    final entries = <LeaderboardEntry>[];
    for (final row in page.rows) {
      final isMe = _isMe(row, myId: myId, myUsername: myUsername);
      matched |= isMe;
      entries.add(_toEntry(row, isCurrentUser: isMe));
    }

    // `my_position` beside `results` exists precisely so standing survives
    // ranking below the page — and so we never confuse another learner for
    // you when only the rank numbers line up.
    if (!matched && position != null) {
      entries.add(_toEntry(position, isCurrentUser: true));
      matched = true;
    } else if (!matched && me != null) {
      // Last resort: profile has XP/rank even when the board omitted standing.
      entries.add(_entryFromProfile(me));
      matched = true;
    }

    // XP is the source of truth for who stands where. Rank is a display label
    // that should follow XP when the payload is incomplete or inconsistent.
    entries.sort(_byXpThenRank);

    final tracksXp = _ranksTrackXp(entries);
    final ordered = tracksXp
        ? List<LeaderboardEntry>.of(entries)
        : [
            for (var i = 0; i < entries.length; i++)
              entries[i].copyWith(rank: i + 1),
          ];

    // Standing pill + "better than N%" must match the rank number on the
    // learner's own row in [ordered] — never a stale `my_position.rank` that
    // disagrees with the XP-ordered table.
    final matchedEntry = matched
        ? ordered.firstWhere((entry) => entry.isCurrentUser)
        : null;
    final currentRank = _usableRank(matchedEntry?.rank) ??
        _usableRank(position?.rank) ??
        me?.rank;

    final level = position?.currentLevel;

    // Population for the percentile: global `count` when ranks are trusted;
    // when we renumbered locally, prefer `count` only if it still covers the
    // display rank, otherwise the loaded page size.
    final population = tracksXp
        ? page.totalCount
        : (page.totalCount != null &&
                currentRank != null &&
                page.totalCount! >= currentRank
            ? page.totalCount
            : ordered.length);

    return LeaderboardData(
      entries: ordered,
      currentRank: currentRank,
      currentLevel: (level != null && level.isNotEmpty)
          ? level
          : (me?.currentLevel.isNotEmpty ?? false)
          ? me!.currentLevel
          : null,
      betterThanPercent: _percentileOf(currentRank, population),
    );
  }

  /// True when this row is the signed-in learner by flag, id, or username.
  static bool _isMe(
    LeaderboardRow row, {
    required String? myId,
    required String? myUsername,
  }) {
    if (row.isCurrentUser) return true;
    final rowId = _id(row.id);
    if (myId != null && rowId != null && rowId == myId) return true;
    if (myUsername != null && _handle(row.username) == myUsername) return true;
    return false;
  }

  /// Highest XP first; ties break on better (lower) rank, then username.
  static int _byXpThenRank(LeaderboardEntry a, LeaderboardEntry b) {
    final byXp = b.xp.compareTo(a.xp);
    if (byXp != 0) return byXp;
    final ra = a.rank >= 1 ? a.rank : 1 << 30;
    final rb = b.rank >= 1 ? b.rank : 1 << 30;
    final byRank = ra.compareTo(rb);
    if (byRank != 0) return byRank;
    return a.username.toLowerCase().compareTo(b.username.toLowerCase());
  }

  /// Whether every known rank already agrees with XP order (higher XP ⇒
  /// better/equal rank number). Missing ranks force a renumber.
  static bool _ranksTrackXp(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return true;
    if (entries.any((e) => e.rank < 1)) return false;
    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        // After XP sort, [i] has XP ≥ [j]. Their ranks must not invert that.
        if (a.xp > b.xp && a.rank > b.rank) return false;
      }
    }
    return true;
  }

  static int? _usableRank(int? rank) =>
      (rank != null && rank >= 1) ? rank : null;

  /// Bare lowercase handle, or null when there is nothing to compare.
  static String? _handle(String? username) {
    final handle = username?.replaceFirst('@', '').trim().toLowerCase();
    return (handle == null || handle.isEmpty) ? null : handle;
  }

  static String? _id(String? id) {
    final value = id?.trim();
    return (value == null || value.isEmpty) ? null : value;
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
    id: row.id,
    rank: row.rank,
    name: row.displayName,
    username: row.username,
    // Derived, never sent: see `LeaderboardRow.initials`.
    initials: row.initials,
    xp: row.xp,
    avatarUrl: row.avatarUrl,
    isCurrentUser: isCurrentUser,
  );

  /// Build a self row from the profile when the board omitted `my_position`
  /// and the learner is not in `results`.
  static LeaderboardEntry _entryFromProfile(UserProfile me) {
    final first = me.firstName.trim();
    final last = me.lastName.trim();
    final full = '$first $last'.trim();
    final username = me.username.replaceFirst('@', '').trim();
    final initials = () {
      if (first.isNotEmpty && last.isNotEmpty) {
        return '${first[0]}${last[0]}'.toUpperCase();
      }
      if (first.isNotEmpty) return first[0].toUpperCase();
      if (username.isNotEmpty) return username[0].toUpperCase();
      return '?';
    }();
    return LeaderboardEntry(
      id: me.id,
      rank: me.rank ?? 0,
      name: full.isNotEmpty ? full : username,
      username: username,
      initials: initials,
      xp: me.xp,
      avatarUrl: me.avatarUrl,
      isCurrentUser: true,
    );
  }
}
