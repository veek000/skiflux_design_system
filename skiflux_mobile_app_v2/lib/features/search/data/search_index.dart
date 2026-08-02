/// Search domain models + the thin façade the search screens call.
///
/// Backed by `GET /search` (spec `GlobalSearchResponse`). Results carry the
/// backend ids the rest of the app navigates with: creator rows keep the
/// creator UUID for `GET /creators/{id}`, user rows keep the username for
/// `GET /users/by-username/{u}`. Creator rows also carry the real
/// `followers_count`; nothing renders a placeholder subscriber figure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/formatting.dart';
import 'search_repository.dart';

enum SearchCategory { episodes, creators, users, playlists }

extension SearchCategoryLabel on SearchCategory {
  /// Tab / section-header label ("Episodes", "Creators", …).
  String get label => switch (this) {
    SearchCategory.episodes => 'Episodes',
    SearchCategory.creators => 'Creators',
    SearchCategory.users => 'Users',
    SearchCategory.playlists => 'Playlists',
  };

  /// Singular form for recent-search subtitles ("Creator · 1 result").
  String get singularLabel => switch (this) {
    SearchCategory.episodes => 'Episode',
    SearchCategory.creators => 'Creator',
    SearchCategory.users => 'User',
    SearchCategory.playlists => 'Playlist',
  };
}

class EpisodeResult {
  const EpisodeResult({
    required this.epNumber,
    required this.title,
    required this.duration,
    required this.views,
    required this.creator,
    this.id = '',
    this.thumbnailUrl,
  });

  /// Spec `Episode` — the same schema the feeds parse.
  factory EpisodeResult.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    final order = json['order'];
    final durationSeconds = json['video_duration'] is int
        ? json['video_duration'] as int
        : 0;
    return EpisodeResult(
      id: json['id']?.toString() ?? '',
      epNumber: order is num ? order.toInt() : 0,
      title: (json['title'] as String?) ?? '',
      duration: _durationLabel(durationSeconds),
      views: '${countLabel(json['view_count'] is int ? json['view_count'] as int : 0)} views',
      creator: creator is Map ? _string(creator['username']) ?? '' : '',
      thumbnailUrl: _string(json['thumbnail_url']),
    );
  }

  final String id;
  final int epNumber;
  final String title;
  final String duration;
  final String views;
  final String creator;
  final String? thumbnailUrl;

  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  String get epTag => 'EP ${epNumber.toString().padLeft(2, '0')}';
}

class PersonResult {
  const PersonResult({
    required this.name,
    required this.username,
    this.id = '',
    this.avatarUrl,
    this.followersCount,
  });

  /// Spec `Creator` (`{id, name, username, avatar_url, followers_count}`).
  factory PersonResult.fromCreatorJson(Map<String, dynamic> json) {
    final username = _string(json['username']) ?? '';
    final name = _string(json['name']) ?? username;
    return PersonResult(
      id: json['id']?.toString() ?? '',
      name: name,
      username: username,
      avatarUrl: _string(json['avatar_url']),
      followersCount: json['followers_count'] is int
          ? json['followers_count'] as int
          : null,
    );
  }

  /// Spec `BasicUser` (`{id, name, username, avatar_url}`) — no follower
  /// figure exists for learners, so none is shown.
  factory PersonResult.fromUserJson(Map<String, dynamic> json) {
    final username = _string(json['username']) ?? '';
    final name = _string(json['name']) ?? username;
    return PersonResult(
      id: json['id']?.toString() ?? '',
      name: name,
      username: username,
      avatarUrl: _string(json['avatar_url']),
    );
  }

  /// Backend UUID — creator rows navigate with it (`GET /creators/{id}`).
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  /// Real `followers_count` when the payload carries one (creators only).
  final int? followersCount;

  /// "@handle · 1.2k subscribers", trimmed to whatever is actually known.
  String get subtitle {
    final parts = <String>[
      if (username.isNotEmpty) '@$username',
      if (followersCount != null)
        '${countLabel(followersCount!)} subscribers',
    ];
    return parts.join(' · ');
  }
}

class PlaylistResult {
  const PlaylistResult({
    required this.title,
    required this.episodeCount,
    this.id = '',
    this.skillworld,
  });

  /// Spec `Season` — search's "playlists" group is the seasons page. There is
  /// no creator or duration on a Season, so the row doesn't claim one.
  factory PlaylistResult.fromJson(Map<String, dynamic> json) => PlaylistResult(
    id: json['id']?.toString() ?? '',
    title: (json['title'] as String?) ?? '',
    episodeCount: json['episode_count'] is int
        ? json['episode_count'] as int
        : 0,
    skillworld: _string(json['skillworld']),
  );

  final String id;
  final String title;
  final int episodeCount;
  final String? skillworld;

  String get subtitle {
    final count = '$episodeCount episode${episodeCount == 1 ? '' : 's'}';
    return skillworld == null ? count : '$skillworld · $count';
  }
}

class SearchResults {
  const SearchResults({
    required this.query,
    required this.episodes,
    required this.creators,
    required this.users,
    required this.playlists,
  });

  /// Parses a `GET /search` body: `GlobalSearchResponse`, optionally wrapped
  /// in `{data: …}` and/or a single-element array, each group either a DRF
  /// page (`{results: []}`) or a bare list.
  factory SearchResults.fromResponse(String query, Object? body) {
    var root = body;
    if (root is Map && root['data'] is Object) root = root['data'];
    if (root is List) root = root.isEmpty ? const <String, dynamic>{} : root.first;
    final map = root is Map
        ? Map<String, dynamic>.from(root)
        : const <String, dynamic>{};

    return SearchResults(
      query: query,
      episodes: _group(map['episodes'], EpisodeResult.fromJson),
      creators: _group(map['creators'], PersonResult.fromCreatorJson),
      users: _group(map['users'], PersonResult.fromUserJson),
      // The spec calls this group `seasons`; older builds said `playlists`.
      playlists: _group(
        map['seasons'] ?? map['playlists'],
        PlaylistResult.fromJson,
      ),
    );
  }

  static List<T> _group<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    Object? list = raw;
    if (list is Map) list = list['results'];
    if (list is! List) return const [];
    return [
      for (final entry in list)
        if (entry is Map) parse(Map<String, dynamic>.from(entry)),
    ];
  }

  final String query;
  final List<EpisodeResult> episodes;
  final List<PersonResult> creators;
  final List<PersonResult> users;
  final List<PlaylistResult> playlists;

  int get total =>
      episodes.length + creators.length + users.length + playlists.length;

  bool get isEmpty => total == 0;

  int countFor(SearchCategory category) => switch (category) {
    SearchCategory.episodes => episodes.length,
    SearchCategory.creators => creators.length,
    SearchCategory.users => users.length,
    SearchCategory.playlists => playlists.length,
  };

  /// Category with the most hits — recorded on recent-search entries
  /// ("Episodes · 2 results").
  SearchCategory? get topCategory {
    if (isEmpty) return null;
    var best = SearchCategory.episodes;
    for (final c in SearchCategory.values) {
      if (countFor(c) > countFor(best)) best = c;
    }
    return best;
  }

  static const empty = SearchResults(
    query: '',
    episodes: [],
    creators: [],
    users: [],
    playlists: [],
  );
}

/// Thin façade the search screens call; delegates to `GET /search`.
///
/// Riverpod choice: plain [Provider] — pure read-only lookup, no session
/// mutations. Live query results stay in the screen; this provider only
/// exposes [search].
class SearchIndex {
  const SearchIndex(this.ref);
  final Ref ref;

  Future<SearchResults> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return SearchResults.empty;
    return ref.read(searchRepositoryProvider).search(q);
  }
}

final searchIndexProvider = Provider<SearchIndex>((ref) {
  return SearchIndex(ref);
});

// ── Formatting helpers ───────────────────────────────────────────────

String _durationLabel(int seconds) {
  if (seconds <= 0) return '0:00';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
