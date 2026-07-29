import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_row.freezed.dart';
part 'leaderboard_row.g.dart';

/// One ranked learner from `GET /me/leaderboard`.
///
/// **The spec documents this endpoint's 200 as "Leaderboard retrieved."** with
/// no schema. The field names here follow the minimum body the backend was
/// asked for in `BACKEND_AI_BUILD_SPEC.md` §0.4; `LeaderboardRepository.parseRow`
/// maps the aliases we consider likely before this factory runs. Every field
/// carries a default so a renamed key costs one blank cell, not a thrown list.
@freezed
abstract class LeaderboardRow with _$LeaderboardRow {
  const LeaderboardRow._();

  const factory LeaderboardRow({
    @Default(0) int rank,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String username,
    String? avatarUrl,
    @Default(0) int xp,
    /// Set only when the backend marks the signed-in learner's own row. It is
    /// not in the asked-for body, so it defaults false and the store falls
    /// back to a username match — see `LeaderboardNotifier.resolve`.
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

/// A page of the leaderboard plus the signed-in user's standing, which the
/// endpoint includes even when their row falls outside the page.
///
/// Plain (not freezed) because it is never deserialised directly — the
/// repository assembles it from a body that may be an envelope *or* a bare
/// list of rows.
class LeaderboardPage {
  const LeaderboardPage({
    required this.rows,
    this.currentRank,
    this.betterThanPercent,
  });

  final List<LeaderboardRow> rows;

  /// Null when the payload omits it — the screen then keeps whatever standing
  /// it was already showing rather than claiming rank 0.
  final int? currentRank;
  final int? betterThanPercent;
}
