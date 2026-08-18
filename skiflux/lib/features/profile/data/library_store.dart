/// Providers behind Liked Videos, Saved Videos and Watch History.
///
/// No seed sits behind any of these. Signed out there is nothing to fetch, so
/// they resolve empty and the screens show their empty state; a failed request
/// stays an `AsyncError` so the screen can offer a retry instead of quietly
/// showing someone else's sample episodes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
import 'library_episode.dart';
import 'library_repository.dart';

/// `GET /me/liked`
final likedEpisodesProvider =
    AsyncNotifierProvider<LikedEpisodesNotifier, List<LibraryEpisode>>(
      LikedEpisodesNotifier.new,
    );

class LikedEpisodesNotifier extends AsyncNotifier<List<LibraryEpisode>> {
  @override
  Future<List<LibraryEpisode>> build() => _load();

  Future<List<LibraryEpisode>> _load() async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return const [];
    return ref.read(libraryRepositoryProvider).getLiked();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Un-like: drop the row first so the tap feels instant, then post. A failed
  /// toggle puts the row back rather than leaving the list lying about what the
  /// server holds.
  Future<void> unlike(LibraryEpisode episode) async {
    final before = state.value ?? const <LibraryEpisode>[];
    state = AsyncData(before.where((e) => e.id != episode.id).toList());
    try {
      await ref.read(libraryRepositoryProvider).toggleLike(episode.id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

/// `GET /me/saved`
final savedEpisodesProvider =
    AsyncNotifierProvider<SavedEpisodesNotifier, List<LibraryEpisode>>(
      SavedEpisodesNotifier.new,
    );

class SavedEpisodesNotifier extends AsyncNotifier<List<LibraryEpisode>> {
  @override
  Future<List<LibraryEpisode>> build() => _load();

  Future<List<LibraryEpisode>> _load() async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return const [];
    return ref.read(libraryRepositoryProvider).getSaved();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Un-save, with the same optimistic-then-restore contract as [unlike].
  Future<void> unsave(LibraryEpisode episode) async {
    final before = state.value ?? const <LibraryEpisode>[];
    state = AsyncData(before.where((e) => e.id != episode.id).toList());
    try {
      await ref.read(libraryRepositoryProvider).toggleSave(episode.id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

/// `GET /me/watch-history`
final watchHistoryProvider =
    AsyncNotifierProvider<WatchHistoryNotifier, List<WatchHistoryEntry>>(
      WatchHistoryNotifier.new,
    );

class WatchHistoryNotifier extends AsyncNotifier<List<WatchHistoryEntry>> {
  @override
  Future<List<WatchHistoryEntry>> build() => _load();

  Future<List<WatchHistoryEntry>> _load() async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return const [];
    final entries = await ref
        .read(libraryRepositoryProvider)
        .getWatchHistory();
    // The spec promises newest-first, but the screen's Today / Earlier split
    // depends on it, so don't take that on trust.
    final sorted = [...entries]
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return sorted;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Removes one entry — optimistic, backed by
  /// `DELETE /me/watch-history/{episode_id}`. A failed delete puts the row
  /// back and rethrows so the screen can say so (same contract as [unlike]).
  Future<void> remove(WatchHistoryEntry entry) async {
    final before = state.value ?? const <WatchHistoryEntry>[];
    state = AsyncData(
      before.where((e) => e.episode.id != entry.episode.id).toList(),
    );
    try {
      await ref
          .read(libraryRepositoryProvider)
          .deleteWatchHistoryEntry(entry.episode.id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  /// Clears the whole history — optimistic, backed by
  /// `DELETE /me/watch-history`; restores the list and rethrows on failure.
  Future<void> clearAll() async {
    final before = state.value ?? const <WatchHistoryEntry>[];
    if (before.isEmpty) return;
    state = const AsyncData([]);
    try {
      await ref.read(libraryRepositoryProvider).clearWatchHistory();
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
