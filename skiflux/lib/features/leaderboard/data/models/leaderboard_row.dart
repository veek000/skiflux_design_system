import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_row.freezed.dart';
part 'leaderboard_row.g.dart';

/// One ranked learner from `GET /me/leaderboard`.
///
/// Mirrors the spec's `UserLeaderboardEntry`, which the backend attached to
/// this endpoint's 200 (it was description-only before).
/// `LeaderboardRepository.parseRow` still maps a few aliases before this
/// factory runs, and every field keeps a default, so a renamed key costs one
/// blank cell rather than a thrown list.
///
/// `tasks_done` / `coins` are unused on this screen. `id` is modelled so we
/// can match the signed-in learner when `username` is null (the schema marks
/// it nullable) and `is_me` is missing.
@freezed
abstract class LeaderboardRow with _$LeaderboardRow {
  const LeaderboardRow._();

  const factory LeaderboardRow({
    /// Learner UUID from `UserLeaderboardEntry.id`. Empty when omitted.
    @Default('') String id,
    @Default(0) int rank,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String username,
    String? avatarUrl,
    @Default(0) int xp,

    /// The league this learner sits in ("Novice" … "Professional"), from the
    /// entry's `current_level`. Empty when the payload omits it.
    @Default('') String currentLevel,

    /// The entry's own `is_me`. Defaults false so the store can fall back to a
    /// username / id match — see `LeaderboardNotifier.resolve`.
    @Default(false) bool isCurrentUser,
  }) = _LeaderboardRow;

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardRowFromJson(json);

  /// Falls back to the handle so a row with no name still reads as someone.
  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (full.isNotEmpty) return full;
    return username;
  }

  /// Two letters when we have both names, else one — matching the avatar
  /// component's initial style. The API sends names, never initials.
  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    final u = username.replaceFirst('@', '').trim();
    if (u.isNotEmpty) return u[0].toUpperCase();
    return '?';
  }
}

/// A page of the leaderboard plus the signed-in user's own standing, which the
/// endpoint sends separately so it survives their row falling outside the page.
///
/// Plain (not freezed) because it is never deserialised directly — the
/// repository assembles it from a body that may be the documented envelope
/// *or* a bare list of rows.
class LeaderboardPage {
  const LeaderboardPage({
    required this.rows,
    this.myPosition,
    this.totalCount,
  });

  final List<LeaderboardRow> rows;

  /// The signed-in learner's own entry, from the response's `my_position`.
  ///
  /// This is the authoritative standing: the spec marks it nullable and sends
  /// it *beside* `results`, so it is still correct when the learner ranks
  /// below the page. Null when the payload omits it — the screen then says
  /// nothing rather than claiming a rank.
  final LeaderboardRow? myPosition;

  /// Total ranked learners, from the response's `count` — the population the
  /// "better than N%" line is computed against. Null on a bare-array body,
  /// where the page size is all we know and a percentage would be a guess.
  final int? totalCount;
}
