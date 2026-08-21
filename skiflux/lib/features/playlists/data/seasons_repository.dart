/// The learner-facing season catalogue — what the app calls "playlists".
///
/// `GET /seasons` and `GET /seasons/{season_id}/episodes`. Both landed in the
/// spec on 2026-07-31; before that the app had no way to list seasons at all
/// and the playlist screens ran entirely on a seeded catalogue.
///
/// The lock state on each row comes from the episode's own `is_purchased` /
/// `is_locked` / `skillcoin_price` — the fields tracker 61c was waiting for.
/// Nothing here decides who may watch what; it reports what the server said.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'playlists_store.dart';

class SeasonsRepository extends ApiRepository {
  const SeasonsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /seasons` — the browse list. [skillworld] is the spec's only filter.
  ///
  /// Returns season shells with **no episodes**; the list endpoint carries a
  /// count, not the rows. Call [getSeasonEpisodes] to fill one in.
  //
  // TODO(backend, minor): `GET /seasons` takes only `skillworld`, so a
  // creator's Playlists tab and Recent section have to walk the whole catalogue
  // and filter on the device — matching on `creator.id` *or* `creator.username`
  // because `PublicCreatorProfile.id` and `SeasonList.creator.id` are not
  // guaranteed to agree, and paging because page one alone made creators
  // further down read as "no uploads yet". Both go away with a server-side
  // filter. Expects: `GET /seasons?creator={creator_id}`, or
  // `GET /creators/{creator_id}/seasons/`.
  //
  // TODO(backend, minor): there is no `GET /seasons/{season_id}` detail
  // endpoint, only the episodes sub-resource, so a season's title and cover
  // must be carried in by whoever navigates to it. A deep link into a season
  // cannot render its own header.
  Future<List<Playlist>> getSeasons({String? skillworld}) => getList(
    '/seasons',
    parse: seasonJsonToPlaylist,
    // ignore: use_null_aware_elements
    query: {if (skillworld != null) 'skillworld': skillworld},
  );

  /// The catalogue across pages, for the creator-scoped filters that have no
  /// server-side filter to use.
  ///
  /// [getSeasons] returns page one only, so a creator whose seasons sit further
  /// down read as having no uploads — one of the causes of the empty Recent and
  /// Playlists tabs. Paging is capped at [maxPages] because this walks the whole
  /// catalogue to find one creator's rows; when the cap is hit the result is
  /// knowingly partial, and the caller's diagnostic says as much.
  ///
  /// The spec declares `GET /seasons` as a bare array, so a response with no
  /// `next` simply yields a single page and stops.
  Future<List<Playlist>> getAllSeasons({
    String? skillworld,
    int maxPages = 5,
    int limit = 100,
  }) async {
    final all = <Playlist>[];
    for (var offset = 0, page = 0; page < maxPages; page++) {
      final result = await getPage(
        '/seasons',
        parse: seasonJsonToPlaylist,
        query: {
          // ignore: use_null_aware_elements
          if (skillworld != null) 'skillworld': skillworld,
          'limit': limit,
          'offset': offset,
        },
      );
      all.addAll(result.results);
      // No `next` (or an unpaginated bare array) means this was everything.
      if (!result.hasMore || result.results.isEmpty) break;
      offset += result.results.length;
    }
    return List.unmodifiable(all);
  }

  /// `GET /seasons/{season_id}/episodes` — the rows, with their lock state.
  Future<List<PlaylistEpisode>> getSeasonEpisodes(String seasonId) => getList(
    '/seasons/$seasonId/episodes',
    parse: episodeJsonToPlaylistEpisode,
  );

  /// `GET /creators/{creator_id}/seasons` — published seasons for one creator.
  Future<List<Playlist>> getCreatorSeasons(
    String creatorId, {
    String? skillworld,
  }) => getList(
    '/creators/$creatorId/seasons',
    parse: seasonJsonToPlaylist,
    // ignore: use_null_aware_elements
    query: {if (skillworld != null) 'skillworld': skillworld},
  );

  /// `GET /creators/{creator_id}/episodes` — published episodes for one creator with lock state.
  Future<List<PlaylistEpisode>> getCreatorEpisodes(
    String creatorId, {
    String? skillworld,
  }) => getList(
    '/creators/$creatorId/episodes',
    parse: episodeJsonToPlaylistEpisode,
    // ignore: use_null_aware_elements
    query: {if (skillworld != null) 'skillworld': skillworld},
  );

  /// A season plus its episodes, which is what every playlist screen needs.
  Future<Playlist> getSeasonWithEpisodes(Playlist season) async {
    final episodes = await getSeasonEpisodes(season.id);
    return season.copyWith(episodes: episodes);
  }
}

/// Maps the spec's `SeasonList` onto [Playlist].
Playlist seasonJsonToPlaylist(Map<String, dynamic> json) {
  final creator = json['creator'];
  var creatorName = '';
  var creatorUsername = '';
  String? creatorId;
  if (creator is Map) {
    final c = Map<String, dynamic>.from(creator);
    creatorId = _string(c['id']);
    creatorUsername = _string(c['username']) ?? '';
    creatorName =
        _string(c['display_name']) ??
        (creatorUsername.isNotEmpty ? creatorUsername : 'Creator');
  }

  return Playlist(
    id: _string(json['id']) ?? '',
    title: _string(json['title']) ?? 'Playlist',
    creatorName: creatorName.isEmpty ? 'Creator' : creatorName,
    creatorUsername: creatorUsername,
    episodes: const [],
    description: _string(json['description']) ?? '',
    // `cover_url` is the real image; the local asset stays only as the
    // placeholder for a season that has none.
    coverUrl: _string(json['cover_url']),
    // The list endpoint sends a count without the rows, so a season shell can
    // still say "8 Episodes" before its episodes are fetched.
    declaredEpisodeCount: _int(json['episode_count']),
    // No view count on `SeasonList`; an invented one would be worse than none.
    viewsLabel: '',
    // The creator UUID is what the profile filters seasons by, and what the
    // playlist header navigates to. Dropping it is why the playlist screen
    // used to hand a username to a route that wanted an id.
    creatorId: creatorId,
    skillworld: _string(json['skillworld']),
  );
}

/// Maps the spec's `Episode` onto [PlaylistEpisode], lock state included.
PlaylistEpisode episodeJsonToPlaylistEpisode(Map<String, dynamic> json) {
  final price = _decimal(json['skillcoin_price']);
  final purchased = json['is_purchased'] == true;
  // `is_locked` is the server's own verdict. Absent is treated as unlocked:
  // hiding content the backend never said was paid is the worse error.
  final locked = json['is_locked'] == true && !purchased;

  return PlaylistEpisode(
    id: _string(json['id']) ?? '',
    number: _int(json['order']) ?? 0,
    title: _string(json['title']) ?? 'Episode',
    duration: formatDuration(_int(json['video_duration'])),
    coinCost: coinCostOf(price),
    state: locked ? PlaylistEpisodeState.locked : PlaylistEpisodeState.unlocked,
    skillworld: _string(json['skillworld']),
    viewCount: _int(json['view_count']),
    createdAt: DateTime.tryParse(_string(json['created_at']) ?? '')?.toLocal(),
    thumbnailUrl:
        _string(json['thumbnail_url']) ?? _string(json['preview_url']),
    // Both are required on `Episode`; a locked row may still carry only the
    // preview, which is the right thing to play in that case.
    videoUrl: _string(json['video_url']) ?? _string(json['preview_url']),
  );
}

/// The price as whole coins for the pill on the row.
///
/// Rounded **up**: the charge is computed server-side by
/// `POST /episodes/purchase`, and a price shown lower than what is taken is a
/// worse failure than one shown a fraction high. Free (null) is 0.
int coinCostOf(Decimal? price) {
  if (price == null || price <= Decimal.zero) return 0;
  return price.ceil().toBigInt().toInt();
}

/// Seconds → "12:40", or "1:02:30" past the hour. Empty when unknown, so the
/// row renders no duration chip rather than "0:00".
String formatDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Money is a decimal string on the wire — never `double.parse`.
Decimal? _decimal(Object? value) {
  if (value is String) return Decimal.tryParse(value.trim());
  if (value is num) return Decimal.tryParse(value.toString());
  return null;
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

final seasonsRepositoryProvider = Provider<SeasonsRepository>(
  (ref) => SeasonsRepository(ref.watch(apiClientProvider)),
);
