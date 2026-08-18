import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/network/json_envelope.dart';
import 'models/leaderboard_row.dart';

/// Learner rankings — `GET /me/leaderboard`.
///
/// Reads the body by hand rather than through [getList]: the learner's own
/// standing (`my_position`) sits *beside* the rows, and
/// [ApiRepository.getPage] keeps only DRF's pagination keys.
class LeaderboardRepository extends ApiRepository {
  const LeaderboardRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const leaderboardPath = '/me/leaderboard';

  /// [level] is the spec's league filter (`novice` … `professional`),
  /// [pageSize] caps at 50, [search] matches name or username.
  Future<LeaderboardPage> getLeaderboard({
    String? level,
    int? pageSize,
    String? search,
  }) => guard(() async {
    final response = await dio.get<dynamic>(
      leaderboardPath,
      queryParameters: {
        'level': ?level,
        'page_size': ?pageSize,
        'search': ?search,
      },
    );
    return parseBody(response.data);
  });

  /// Assembles a [LeaderboardPage] from the documented `LeaderboardResponse`
  /// — `{count, next, previous, my_position, results}` — or from a bare row
  /// array, which carries rows but no standing.
  ///
  /// Note there is **no** "better than N%" field anywhere in the response; the
  /// store derives that from the rank and [LeaderboardPage.totalCount]. Asking
  /// for one was dropped when the schema landed.
  ///
  /// Public so provider tests can exercise the shape handling without Dio.
  static LeaderboardPage parseBody(Object? data) {
    final rows = [
      for (final raw in _rowsIn(data))
        if (raw is Map) parseRow(Map<String, dynamic>.from(raw)),
    ];

    // A bare array carries neither standing nor total; only an envelope does.
    final envelope = data is Map ? Map<String, dynamic>.from(data) : null;
    final inner = envelope?['data'];
    final standing = inner is Map
        ? Map<String, dynamic>.from(inner)
        : envelope;

    final position = standing?['my_position'] ?? standing?['me'];

    return LeaderboardPage(
      rows: rows,
      myPosition: position is Map
          ? parseRow(Map<String, dynamic>.from(position))
          : null,
      totalCount: _int(standing, const ['count', 'total', 'total_count']),
    );
  }

  /// The row array, wherever it sits. [unwrapList] covers a bare array plus
  /// DRF's `results`/`data` envelopes; the extra keys below are the names a
  /// hand-rolled leaderboard response is most likely to use instead. Returns
  /// empty rather than throwing when none match — a body whose rows we can't
  /// find still carries a readable standing, and the screen's empty state says
  /// more than a network error would.
  static List<dynamic> _rowsIn(Object? data) {
    try {
      return unwrapList(data);
    } on FormatException {
      if (data is Map) {
        for (final key in const ['leaderboard', 'rankings', 'users', 'entries']) {
          final value = data[key];
          if (value is List) return value;
        }
        final inner = data['data'];
        if (inner is Map) return _rowsIn(inner);
      }
      return const [];
    }
  }

  /// Normalises one row. Accepts a single `name`/`full_name` by splitting on
  /// the first space, since the spec never promised the two-field shape.
  static LeaderboardRow parseRow(Map<String, dynamic> json) {
    final user = json['user'];
    // Some list endpoints nest the person under `user` and keep rank/xp flat.
    final merged = user is Map
        ? {...Map<String, dynamic>.from(user), ...json}
        : json;

    var first = _string(merged, const ['first_name', 'firstname', 'firstName']);
    var last = _string(merged, const ['last_name', 'lastname', 'lastName']);
    if (first.isEmpty && last.isEmpty) {
      final whole = _string(merged, const ['name', 'full_name', 'display_name']);
      if (whole.isNotEmpty) {
        final space = whole.indexOf(' ');
        first = space == -1 ? whole : whole.substring(0, space);
        last = space == -1 ? '' : whole.substring(space + 1).trim();
      }
    }

    return LeaderboardRow(
      id: _string(merged, const ['id', 'user_id', 'uuid']),
      rank: _int(merged, const ['rank', 'position', 'place']) ?? 0,
      firstName: first,
      lastName: last,
      username: _string(
        merged,
        const ['username', 'handle', 'user_name'],
      ).replaceFirst('@', ''),
      avatarUrl: _optionalString(merged, const [
        'avatar_url',
        'avatar',
        'profile_image',
        'image_url',
      ]),
      // XP is what places people on the podium — accept the common aliases a
      // hand-rolled body might use when `xp` is renamed.
      xp: _int(merged, const [
            'xp',
            'total_xp',
            'xp_total',
            'xp_earned',
            'points',
            'score',
            'experience',
          ]) ??
          0,
      currentLevel: _string(merged, const [
        'current_level',
        'level',
        'league',
      ]),
      isCurrentUser: _bool(merged, const [
        'is_me',
        'is_current_user',
        'is_self',
        'is_you',
      ]),
    );
  }

  /// True only on an unambiguous yes. An absent flag is not a "no" about the
  /// user — it means the backend doesn't send one, and the store then matches
  /// on username instead.
  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
    }
    return false;
  }

  static String _string(Map<String, dynamic> json, List<String> keys) =>
      _optionalString(json, keys) ?? '';

  static String? _optionalString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static int? _int(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      // Percentages may arrive as a double or a numeric string.
      if (value is num) return value.round();
      if (value is String) {
        // "4,820" / "4 820" show up in loosely typed payloads.
        final cleaned = value.trim().replaceAll(RegExp(r'[\s,]'), '');
        final parsed = num.tryParse(cleaned);
        if (parsed != null) return parsed.round();
      }
    }
    return null;
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(ref.watch(apiClientProvider)),
);
