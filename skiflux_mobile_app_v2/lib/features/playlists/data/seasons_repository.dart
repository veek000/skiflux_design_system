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
  // TODO(backend, minor): `GET /seasons` filters by skillworld only, so a
  // creator's Playlists tab still has no source — expects: a `creator` query
  // param on GET /seasons, or GET /creators/{creator_id}/seasons/
  Future<List<Playlist>> getSeasons({String? skillworld}) => getList(
    '/seasons',
    parse: seasonJsonToPlaylist,
    // ignore: use_null_aware_elements
    query: {if (skillworld != null) 'skillworld': skillworld},
  );

  /// `GET /seasons/{season_id}/episodes` — the rows, with their lock state.
  Future<List<PlaylistEpisode>> getSeasonEpisodes(String seasonId) => getList(
    '/seasons/$seasonId/episodes',
    parse: episodeJsonToPlaylistEpisode,
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
  if (creator is Map) {
    final c = Map<String, dynamic>.from(creator);
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
    state: locked
        ? PlaylistEpisodeState.locked
        : PlaylistEpisodeState.unlocked,
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
