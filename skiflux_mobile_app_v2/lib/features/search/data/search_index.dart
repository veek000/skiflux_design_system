/// Search domain models + the local demo dataset the search flow runs
/// against.
///
/// ⚠️ Demo content only — like the feed/comments/profile, nothing here is
/// backed by a real service. The dataset is intentionally small but varied
/// enough to exercise every flow state (grouped overview, per-category tabs,
/// empty tabs, nothing-found).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
// TODO(backend, blocking): replace local demo search dataset with backend search API — expects: search(query: String) → {episodes: List<{epNumber: int, title: String, duration: String, views: String, creator: String}>, creators: List<{name: String, username: String, subscribers: String}>, users: List<{name: String, username: String, subscribers: String}>, playlists: List<{title: String, creator: String, episodeCount: int, duration: String}>}
class SearchIndex {
  const SearchIndex();

  static const List<EpisodeResult> _episodes = [
    EpisodeResult(
      epNumber: 1,
      title: 'Introduction to UI Design Thinking',
      duration: '20:00',
      views: '550.7k views',
      creator: 'Amara Design',
    ),
    EpisodeResult(
      epNumber: 2,
      title: 'UI Design Systems that Scale',
      duration: '18:24',
      views: '412.3k views',
      creator: 'Amara Design',
    ),
    EpisodeResult(
      epNumber: 3,
      title: 'Mastering Figma Components',
      duration: '24:45',
      views: '389.9k views',
      creator: 'Amara Design',
    ),
    EpisodeResult(
      epNumber: 4,
      title: 'Auto Layout Deep Dive',
      duration: '15:30',
      views: '298.1k views',
      creator: 'Kojo Sketches',
    ),
    EpisodeResult(
      epNumber: 5,
      title: 'Prototyping Motion in Figma',
      duration: '21:12',
      views: '176.4k views',
      creator: 'Kojo Sketches',
    ),
  ];

  static const List<PersonResult> _creators = [
    PersonResult(name: 'Amara Design', username: 'amara', subscribers: '12.4k'),
    PersonResult(
      name: 'Kojo Sketches',
      username: 'kojosketch',
      subscribers: '8.1k',
    ),
  ];

  static const List<PersonResult> _users = [
    PersonResult(name: 'Amara Design', username: 'amara', subscribers: '12.4k'),
    PersonResult(
      name: 'Design Dan',
      username: 'designdan',
      subscribers: '1.2k',
    ),
  ];

  static const List<PlaylistResult> _playlists = [
    PlaylistResult(
      title: 'Introduction to UI Design Thinking',
      creator: 'Amara Design',
      episodeCount: 20,
      duration: '20:00',
    ),
    PlaylistResult(
      title: 'Figma from Zero to Hero',
      creator: 'Kojo Sketches',
      episodeCount: 12,
      duration: '14:00',
    ),
  ];

  bool _matches(String haystack, String query) =>
      haystack.toLowerCase().contains(query.toLowerCase());

  SearchResults search(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      return SearchResults(
        query: q,
        episodes: const [],
        creators: const [],
        users: const [],
        playlists: const [],
      );
    }
    return SearchResults(
      query: q,
      episodes: _episodes
          .where((e) => _matches(e.title, q) || _matches(e.creator, q))
          .toList(),
      creators: _creators
          .where((c) => _matches(c.name, q) || _matches(c.username, q))
          .toList(),
      users: _users
          .where((u) => _matches(u.name, q) || _matches(u.username, q))
          .toList(),
      playlists: _playlists
          .where((p) => _matches(p.title, q) || _matches(p.creator, q))
          .toList(),
    );
  }
}

final searchIndexProvider = Provider<SearchIndex>((ref) {
  return const SearchIndex();
});
