import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_index.dart';

/// A remembered search — enough to render the Recent row
/// (title = query, subtitle = "Episodes · 2 results").
class RecentSearch {
  const RecentSearch({
    required this.query,
    required this.topCategory,
    required this.resultCount,
  });

  final String query;
  final SearchCategory? topCategory;
  final int resultCount;

  /// "Episodes · 2 results" / "Creator · 1 result" / "No results".
  String get subtitle {
    if (resultCount == 0 || topCategory == null) return 'No results';
    final label = resultCount == 1
        ? topCategory!.singularLabel
        : topCategory!.label;
    return '$label · $resultCount ${resultCount == 1 ? 'result' : 'results'}';
  }

  Map<String, Object?> toJson() => {
    'query': query,
    'topCategory': topCategory?.name,
    'resultCount': resultCount,
  };

  static RecentSearch? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final query = raw['query'];
    if (query is! String || query.isEmpty) return null;
    final categoryName = raw['topCategory'];
    return RecentSearch(
      query: query,
      topCategory: categoryName is String
          ? SearchCategory.values.cast<SearchCategory?>().firstWhere(
              (c) => c!.name == categoryName,
              orElse: () => null,
            )
          : null,
      resultCount: (raw['resultCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persists recent searches as a JSON list in shared_preferences.
/// Newest first, de-duplicated by query (case-insensitive), capped.
///
/// Riverpod choice: [AsyncNotifierProvider] — load/add/remove/clear are
/// async (SharedPreferences). Distinct from [searchIndexProvider] (pure
/// index) so UI can watch recents independently of live query results.
class RecentSearchesNotifier extends AsyncNotifier<List<RecentSearch>> {
  static const _prefsKey = 'search.recent';
  static const _maxEntries = 10;

  @override
  Future<List<RecentSearch>> build() => _load();

  Future<List<RecentSearch>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => RecentSearch.fromJson((e as Map).cast<String, Object?>()))
          .whereType<RecentSearch>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> add(RecentSearch entry) async {
    final current = state.value ?? await _load();
    final updated = [
      entry,
      ...current.where(
        (e) => e.query.toLowerCase() != entry.query.toLowerCase(),
      ),
    ].take(_maxEntries).toList();
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> remove(String query) async {
    final current = state.value ?? await _load();
    final updated = current
        .where((e) => e.query.toLowerCase() != query.toLowerCase())
        .toList();
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = const AsyncData([]);
  }

  Future<void> _save(List<RecentSearch> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

final recentSearchesProvider =
    AsyncNotifierProvider<RecentSearchesNotifier, List<RecentSearch>>(
      RecentSearchesNotifier.new,
    );
