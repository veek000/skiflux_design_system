import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/playlists/data/playlists_store.dart';
import 'package:skiflux_mobile_app_v2/features/playlists/data/season_providers.dart';
import 'package:skiflux_mobile_app_v2/features/playlists/data/seasons_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/api_repository.dart';

void main() {
  // The creator profile's Recent and Playlists tabs came back empty for
  // creators the catalogue plainly held. `GET /seasons` has no creator filter,
  // so the match happens on the device — and matching on the uuid alone, over
  // page one alone, was not enough.
  group('CreatorRef.matches', () {
    Playlist season({String? creatorId, String creatorUsername = ''}) =>
        Playlist(
          id: 's1',
          title: 'Season',
          creatorName: 'Creator',
          creatorUsername: creatorUsername,
          creatorId: creatorId,
          episodes: const [],
          description: '',
          viewsLabel: '',
        );

    test('matches on the creator uuid', () {
      const ref = CreatorRef(id: 'abc', username: 'amara');
      expect(ref.matches(season(creatorId: 'abc')), isTrue);
    });

    test('falls back to the username when the id does not line up', () {
      // `PublicCreatorProfile.id` parses with a `''` fallback and is not
      // guaranteed to share a namespace with `SeasonList.creator.id`.
      const ref = CreatorRef(id: '', username: 'amara');
      expect(
        ref.matches(season(creatorId: 'abc', creatorUsername: 'Amara')),
        isTrue,
      );
    });

    test('a different creator matches on neither', () {
      const ref = CreatorRef(id: 'abc', username: 'amara');
      expect(
        ref.matches(season(creatorId: 'xyz', creatorUsername: 'kofi')),
        isFalse,
      );
    });

    test('empty values never match — that would claim the whole catalogue', () {
      const ref = CreatorRef();
      expect(ref.matches(season(creatorId: null)), isFalse);
      expect(ref.matches(season(creatorId: '')), isFalse);
      // And a season with no creator identity is not matched by a real ref.
      const real = CreatorRef(id: 'abc', username: 'amara');
      expect(real.matches(season()), isFalse);
    });
  });

  group('creatorSeasonsProvider', () {
    ProviderContainer withRepo(_FakeSeasonsRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [seasonsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    Playlist season(
      String id, {
      String? creatorId,
      String creatorUsername = '',
    }) => Playlist(
      id: id,
      title: 'Season $id',
      creatorName: 'Creator',
      creatorUsername: creatorUsername,
      creatorId: creatorId,
      episodes: const [],
      description: '',
      viewsLabel: '',
    );

    test('returns only this creator\'s seasons', () async {
      final repo = _FakeSeasonsRepository([
        season('1', creatorId: 'abc'),
        season('2', creatorId: 'xyz'),
        season('3', creatorId: 'abc'),
      ]);
      final c = withRepo(repo);

      final seasons = await c.read(
        creatorSeasonsProvider(const CreatorRef(id: 'abc')).future,
      );
      expect(seasons.map((s) => s.id), ['1', '3']);
    });

    test('finds a creator whose id is empty, via the username', () async {
      final repo = _FakeSeasonsRepository([
        season('1', creatorId: 'abc', creatorUsername: 'amara'),
      ]);
      final c = withRepo(repo);

      final seasons = await c.read(
        creatorSeasonsProvider(const CreatorRef(username: 'amara')).future,
      );
      expect(seasons, hasLength(1));
    });

    test('an empty ref resolves empty without calling the API', () async {
      final repo = _FakeSeasonsRepository([season('1', creatorId: 'abc')]);
      final c = withRepo(repo);

      final seasons = await c.read(
        creatorSeasonsProvider(const CreatorRef()).future,
      );
      expect(seasons, isEmpty);
      expect(repo.calls, 0);
    });
  });

  group('getAllSeasons', () {
    test('pages until the catalogue runs out', () async {
      // Page one alone made a creator further down the catalogue read as
      // having no uploads at all.
      final repo = _PagingSeasonsRepository(pages: 3, perPage: 2);

      final all = await repo.getAllSeasons(limit: 2);
      expect(all, hasLength(6));
      expect(repo.offsets, [0, 2, 4]);
    });

    test('stops at maxPages rather than walking forever', () async {
      final repo = _PagingSeasonsRepository(pages: 99, perPage: 2);

      final all = await repo.getAllSeasons(limit: 2, maxPages: 3);
      expect(all, hasLength(6));
      expect(repo.offsets, hasLength(3));
    });

    test('a bare array (no next) yields a single page', () async {
      final repo = _PagingSeasonsRepository(pages: 1, perPage: 4);

      final all = await repo.getAllSeasons(limit: 100);
      expect(all, hasLength(4));
      expect(repo.offsets, [0]);
    });
  });
}

class _FakeSeasonsRepository extends SeasonsRepository {
  _FakeSeasonsRepository(this.seasons) : super(Dio());

  final List<Playlist> seasons;
  int calls = 0;

  @override
  Future<List<Playlist>> getAllSeasons({
    String? skillworld,
    int maxPages = 5,
    int limit = 100,
  }) async {
    calls++;
    return seasons;
  }
}

/// Serves [pages] pages of [perPage] seasons through the real [getAllSeasons]
/// paging loop, by faking the single-page fetch underneath it.
class _PagingSeasonsRepository extends SeasonsRepository {
  _PagingSeasonsRepository({required this.pages, required this.perPage})
    : super(Dio());

  final int pages;
  final int perPage;
  final List<int> offsets = [];

  @override
  Future<Paginated<T>> getPage<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parse,
    Map<String, dynamic>? query,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) async {
    final offset = (query?['offset'] as int?) ?? 0;
    offsets.add(offset);
    final page = offset ~/ perPage;
    final isLast = page >= pages - 1;
    return Paginated<T>(
      results: [
        for (var i = 0; i < perPage; i++)
          parse({'id': 's${offset + i}', 'title': 'Season'}),
      ],
      count: pages * perPage,
      next: isLast ? null : 'more',
    );
  }
}
