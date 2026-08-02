/// Season-scoped reads — one provider per season the user actually opened,
/// replacing the single global playlist the whole app used to share.
///
/// Every screen that shows a season (the playlist screen, the feed's EP-chip
/// sheet, a creator's Playlists tab) resolves it through [seasonProvider] with
/// a [SeasonArg]. The fetched season is registered in `playlistsProvider` on
/// the way through, because the unlock sheet only receives an episode id and
/// resolves it against that cache.
///
/// Two backend gaps shape this file:
///  * there is no `GET /seasons/{season_id}`, so a season's title/cover/creator
///    have to be carried in by whoever navigates — that is what [SeasonArg]'s
///    non-id fields are for, and why they are excluded from its equality;
///  * `GET /seasons` filters by skillworld only, so creator-scoped lists are
///    filtered on the device. Both are tracked as TODOs in
///    `seasons_repository.dart`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playlists_store.dart';
import 'seasons_repository.dart';

/// Identifies a season, plus whatever the navigating screen already knew about
/// it so the header can render before the episodes land.
///
/// Equality is on [id] **only**: the same season reached from search and from
/// a creator profile carries different display hints but must share one
/// provider instance, or the episodes are fetched twice and the two copies
/// disagree about lock state after a purchase.
class SeasonArg {
  const SeasonArg({
    required this.id,
    this.title,
    this.creatorName,
    this.creatorId,
    this.coverUrl,
    this.episodeCount,
    this.skillworld,
  });

  /// Everything already known about a season that has been fetched.
  factory SeasonArg.of(Playlist season) => SeasonArg(
    id: season.id,
    title: season.title,
    creatorName: season.creatorName,
    creatorId: season.creatorId,
    coverUrl: season.coverUrl,
    episodeCount: season.episodeCount,
    skillworld: season.skillworld,
  );

  final String id;

  /// Display hints. Null is honest: the header then shows a skeleton line
  /// rather than a guessed title.
  final String? title;
  final String? creatorName;
  final String? creatorId;
  final String? coverUrl;
  final int? episodeCount;
  final String? skillworld;

  @override
  bool operator ==(Object other) => other is SeasonArg && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SeasonArg($id)';
}

/// One season with its episodes and their real lock state.
///
/// `GET /seasons/{season_id}/episodes`. The season shell around them is built
/// from the [SeasonArg]'s hints — the only source available, since the spec
/// has no season-detail endpoint.
final seasonProvider = AsyncNotifierProvider.autoDispose
    .family<SeasonNotifier, Playlist, SeasonArg>(SeasonNotifier.new);

class SeasonNotifier extends AsyncNotifier<Playlist> {
  SeasonNotifier(this.arg);

  final SeasonArg arg;

  @override
  Future<Playlist> build() => _load();

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<Playlist> _load() async {
    final episodes = await ref
        .read(seasonsRepositoryProvider)
        .getSeasonEpisodes(arg.id);
    final season = Playlist(
      id: arg.id,
      // A season whose title was never carried in says "Playlist" rather than
      // borrowing a title from somewhere else.
      title: arg.title ?? 'Playlist',
      creatorName: arg.creatorName ?? '',
      creatorUsername: '',
      creatorId: arg.creatorId,
      skillworld: arg.skillworld,
      episodes: episodes,
      description: '',
      // `SeasonList` carries no view count and the episodes endpoint carries
      // none for the season as a whole, so the detail line omits it.
      viewsLabel: '',
      coverUrl: arg.coverUrl,
      declaredEpisodeCount: arg.episodeCount,
    );
    // Register before returning: the unlock sheet resolves episodes by id
    // against this cache, so an uncached season's rows cannot be purchased.
    ref.read(playlistsProvider.notifier).cacheSeason(season);
    return season;
  }
}

/// Identifies the creator whose seasons to collect.
///
/// Both fields, not just the uuid, because matching on the id alone left the
/// profile's Recent and Playlists tabs empty for creators the catalogue clearly
/// held: `PublicCreatorProfile.id` can arrive empty (it is parsed with a `''`
/// fallback), and there is no guarantee it shares a namespace with
/// `SeasonList.creator.id`. The username is the second, independent handle on
/// the same creator, so a mismatch on one still resolves through the other.
///
/// Equality covers both fields — two different creators must not share a
/// provider instance.
class CreatorRef {
  const CreatorRef({this.id = '', this.username = ''});

  final String id;
  final String username;

  bool get isEmpty => id.isEmpty && username.isEmpty;

  /// Whether [season] belongs to this creator. Case-insensitive on the
  /// username; empty values never match, or every creator would match.
  bool matches(Playlist season) {
    if (id.isNotEmpty && season.creatorId != null && season.creatorId == id) {
      return true;
    }
    if (username.isEmpty || season.creatorUsername.isEmpty) return false;
    return season.creatorUsername.toLowerCase() == username.toLowerCase();
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorRef && other.id == id && other.username == username;

  @override
  int get hashCode => Object.hash(id, username);

  @override
  String toString() => 'CreatorRef(id: $id, username: $username)';
}

/// Every season belonging to a creator — the profile's Playlists tab.
///
/// Client-side filter over `GET /seasons` (see the TODO in
/// `seasons_repository.dart`), on **id or username**: see [CreatorRef] for why
/// the uuid alone was not enough. Pages through the catalogue rather than
/// reading page one, since `getList` returns only the first page and a creator
/// further down it read as having no uploads at all.
final creatorSeasonsProvider = AsyncNotifierProvider.autoDispose
    .family<CreatorSeasonsNotifier, List<Playlist>, CreatorRef>(
      CreatorSeasonsNotifier.new,
    );

class CreatorSeasonsNotifier extends AsyncNotifier<List<Playlist>> {
  CreatorSeasonsNotifier(this.creator);

  final CreatorRef creator;

  @override
  Future<List<Playlist>> build() => _load();

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<Playlist>> _load() async {
    if (creator.isEmpty) return const [];
    final all = await ref
        .read(seasonsRepositoryProvider)
        .getAllSeasons();
    final mine = all.where(creator.matches).toList(growable: false);

    // "This creator has no seasons" and "we fetched a catalogue and could not
    // find them in it" look identical on screen — an empty state either way.
    // They are not the same bug, so the second one says so in the log instead
    // of being silently absorbed.
    if (mine.isEmpty && all.isNotEmpty) {
      final seen = all
          .map((s) => '${s.creatorId ?? '-'}/${s.creatorUsername}')
          .toSet();
      debugPrint(
        'creatorSeasonsProvider: no match for $creator across '
        '${all.length} season(s). Creators seen: ${seen.join(', ')}',
      );
    }
    return mine;
  }
}

/// A creator's episodes, newest first — the profile's Recent section.
///
/// There is no creator-episode endpoint, so this is every season of theirs
/// hydrated in parallel and flattened. Each season is cached on the way
/// through, which is also what makes a locked Recent row purchasable.
///
/// Episodes with no `created_at` sort last rather than being dropped: an
/// unordered upload is still a real upload.
final creatorRecentEpisodesProvider = FutureProvider.autoDispose
    .family<List<PlaylistEpisode>, CreatorRef>((ref, creator) async {
      final seasons = await ref.watch(creatorSeasonsProvider(creator).future);
      if (seasons.isEmpty) return const [];

      final repo = ref.read(seasonsRepositoryProvider);
      final hydrated = await Future.wait(
        seasons.map(repo.getSeasonWithEpisodes),
      );

      final notifier = ref.read(playlistsProvider.notifier);
      final episodes = <PlaylistEpisode>[];
      for (final season in hydrated) {
        notifier.cacheSeason(season);
        for (final ep in season.episodes) {
          // An episode payload may omit `skillworld`; the season it belongs to
          // has one, and that is what the profile pills filter on. Filled in
          // place — the same instance stays in the cache, so a later unlock
          // still flips this row.
          ep.skillworld ??= season.skillworld;
          episodes.add(ep);
        }
      }

      episodes.sort((a, b) {
        final ac = a.createdAt;
        final bc = b.createdAt;
        if (ac == null && bc == null) return 0;
        if (ac == null) return 1;
        if (bc == null) return -1;
        return bc.compareTo(ac);
      });
      return episodes;
    });
