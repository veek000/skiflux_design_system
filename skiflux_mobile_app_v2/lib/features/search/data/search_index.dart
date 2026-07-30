/// Search domain models + the local demo dataset the search flow runs
/// against.
///
/// ⚠️ Demo content only — like the feed/comments/profile, nothing here is
/// backed by a real service. The dataset is intentionally small but varied
/// enough to exercise every flow state (grouped overview, per-category tabs,
/// empty tabs, nothing-found).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  factory EpisodeResult.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] ?? {};
    return EpisodeResult(
      epNumber: (json['episode_number'] as int?) ?? 0,
      title: (json['title'] as String?) ?? '',
      duration: (json['duration_formatted'] as String?) ?? '0:00',
      views: '${json['view_count'] ?? 0} views',
      creator: (creator['username'] as String?) ?? '',
    );
  }

  final int epNumber;
  final String title;
  final String duration;
  final String views;
  final String creator;

  String get epTag => 'EP ${epNumber.toString().padLeft(2, '0')}';
}

class PersonResult {
  const PersonResult({
    required this.name,
    required this.username,
    required this.subscribers,
  });

  factory PersonResult.fromJson(Map<String, dynamic> json) {
    final name = (json['display_name'] as String?) ?? (json['username'] as String?) ?? '';
    return PersonResult(
      name: name,
      username: (json['username'] as String?) ?? '',
      subscribers: '...',
    );
  }

  final String name;
  final String username;
  final String subscribers;

  String get subtitle => '@$username · $subscribers subscribers';
}

class PlaylistResult {
  const PlaylistResult({
    required this.title,
    required this.creator,
    required this.episodeCount,
    required this.duration,
  });

  factory PlaylistResult.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] ?? {};
    return PlaylistResult(
      title: (json['title'] as String?) ?? '',
      creator: (creator['username'] as String?) ?? '',
      episodeCount: (json['episode_count'] as int?) ?? 0,
      duration: (json['duration_formatted'] as String?) ?? '0:00',
    );
  }

  final String title;
  final String creator;
  final int episodeCount;
  final String duration;

  String get subtitle => '$creator · $episodeCount episodes';
}

class SearchResults {
  const SearchResults({
    required this.query,
    required this.episodes,
    required this.creators,
    required this.users,
    required this.playlists,
  });

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
}

/// Case-insensitive substring search over the demo dataset.
///
/// Riverpod choice: plain [Provider] — pure read-only index, no session
/// mutations (like leaderboard Pass 1). Live query results stay in the
/// screen; this provider only exposes [search].
class SearchIndex {
  const SearchIndex(this.ref);
  final Ref ref;

  Future<SearchResults> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const SearchResults(
        query: '',
        episodes: [],
        creators: [],
        users: [],
        playlists: [],
      );
    }
    
    final repo = ref.read(searchRepositoryProvider);
    final json = await repo.search(q);
    
    final results = json['results'] as Map<String, dynamic>? ?? {};
    
    final creatorsJson = (results['creators'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final usersJson = (results['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final episodesJson = (results['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final playlistsJson = (results['playlists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    return SearchResults(
      query: q,
      creators: creatorsJson.map((e) => PersonResult.fromJson(e)).toList(),
      users: usersJson.map((e) => PersonResult.fromJson(e)).toList(),
      episodes: episodesJson.map((e) => EpisodeResult.fromJson(e)).toList(),
      playlists: playlistsJson.map((e) => PlaylistResult.fromJson(e)).toList(),
    );
  }
}

final searchIndexProvider = Provider<SearchIndex>((ref) {
  return SearchIndex(ref);
});
