/// The learner's own library: what they liked, saved, and watched.
///
/// All three reads return the OpenAPI `Episode` schema (watch history wraps it
/// in `WatchHistoryItem`), so they share [LibraryEpisode]. The two writes are
/// toggles — the same endpoint likes and un-likes — which is why removing a row
/// posts rather than deletes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'library_episode.dart';

class LibraryRepository extends ApiRepository {
  const LibraryRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /me/liked`
  Future<List<LibraryEpisode>> getLiked({
    int? pageSize,
    String? skillworld,
  }) => getList(
    '/me/liked',
    parse: LibraryEpisode.fromJson,
    query: {'page_size': ?pageSize, 'skillworld': ?skillworld},
  );

  /// `GET /me/saved`
  Future<List<LibraryEpisode>> getSaved({
    int? pageSize,
    String? skillworld,
  }) => getList(
    '/me/saved',
    parse: LibraryEpisode.fromJson,
    query: {'page_size': ?pageSize, 'skillworld': ?skillworld},
  );

  /// `GET /me/watch-history` — newest first, per the spec.
  Future<List<WatchHistoryEntry>> getWatchHistory({
    bool? completed,
    int? pageSize,
    String? skillworld,
  }) => getList(
    '/me/watch-history',
    parse: WatchHistoryEntry.fromJson,
    query: {
      'completed': ?completed,
      'page_size': ?pageSize,
      'skillworld': ?skillworld,
    },
  );

  /// `POST /episodes/like` — a toggle, so this is also how a row is un-liked.
  Future<void> toggleLike(String episodeId) => post<void>(
    '/episodes/like',
    body: {'episode_id': episodeId},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `POST /episodes/save` — likewise a toggle.
  Future<void> toggleSave(String episodeId) => post<void>(
    '/episodes/save',
    body: {'episode_id': episodeId},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `DELETE /me/watch-history/{episode_id}` — removes one episode from the
  /// history (204). Same lightweight-row-write kind as the toggles; there is
  /// no dedicated history-delete error kind.
  Future<void> deleteWatchHistoryEntry(String episodeId) => delete(
    '/me/watch-history/$episodeId',
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `DELETE /me/watch-history` — clears the entire history.
  Future<void> clearWatchHistory() => delete(
    '/me/watch-history',
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );
}

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(apiClientProvider)),
);
