import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/home_feed_store.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/library_episode.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/library_repository.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/library_store.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

/// One `Episode` as `/me/liked` returns it.
Map<String, dynamic> episodeJson({
  String id = 'ep-1',
  int? order = 3,
  int duration = 754,
  int views = 1240,
  String? video = 'https://cdn.skiflux.test/ep1.m3u8',
}) => {
  'id': id,
  'title': 'Colour systems that survive dark mode',
  'description': 'Palettes that hold up in both themes.',
  'order': order,
  'thumbnail_url': 'https://cdn.skiflux.test/ep1.jpg',
  'video_url': video,
  'video_duration': duration,
  'view_count': views,
  'skillworld': 'design',
  'creator': {
    'username': 'amara',
    'first_name': 'Amara',
    'last_name': 'Okoye',
    'display_name': '',
  },
};

void main() {
  group('LibraryEpisode.fromJson', () {
    test('maps the Episode schema', () {
      final ep = LibraryEpisode.fromJson(episodeJson());
      expect(ep.id, 'ep-1');
      expect(ep.order, 3);
      expect(ep.durationSeconds, 754);
      expect(ep.viewCount, 1240);
      expect(ep.skillworld, 'design');
      expect(ep.videoUrl, 'https://cdn.skiflux.test/ep1.m3u8');
    });

    test('builds the creator name and initials from first/last name', () {
      final ep = LibraryEpisode.fromJson(episodeJson());
      expect(ep.creatorName, 'Amara Okoye');
      expect(ep.creatorInitials, 'AO');
      expect(ep.creatorUsername, 'amara');
    });

    test('prefers display_name when the API sends one', () {
      final json = episodeJson()
        ..['creator'] = {'username': 'amara', 'display_name': 'Amara Studio'};
      expect(LibraryEpisode.fromJson(json).creatorName, 'Amara Studio');
    });

    test('falls back to preview_url when thumbnail_url is absent', () {
      final json = episodeJson()
        ..remove('thumbnail_url')
        ..['preview_url'] = 'https://cdn.skiflux.test/preview.jpg';
      expect(
        LibraryEpisode.fromJson(json).thumbnailUrl,
        'https://cdn.skiflux.test/preview.jpg',
      );
    });

    test('survives an episode with nothing but an id', () {
      final ep = LibraryEpisode.fromJson({'id': 'ep-x'});
      expect(ep.title, 'Episode');
      expect(ep.creatorName, 'Creator');
      expect(ep.durationLabel, isEmpty);
      expect(ep.epTag, 'EP');
    });
  });

  group('LibraryEpisode labels', () {
    test('durationLabel is m:ss under an hour and h:mm:ss over', () {
      expect(LibraryEpisode.fromJson(episodeJson(duration: 754)).durationLabel,
          '12:34');
      expect(LibraryEpisode.fromJson(episodeJson(duration: 3753)).durationLabel,
          '1:02:33');
    });

    test('durationLabel is empty when the API omitted the duration', () {
      // The row hides the pill rather than printing "0:00".
      expect(
        LibraryEpisode.fromJson(episodeJson(duration: 0)).durationLabel,
        isEmpty,
      );
    });

    test('viewsLabel abbreviates thousands and millions', () {
      expect(LibraryEpisode.fromJson(episodeJson(views: 942)).viewsLabel, '942');
      expect(
        LibraryEpisode.fromJson(episodeJson(views: 1240)).viewsLabel,
        '1.2K',
      );
      expect(
        LibraryEpisode.fromJson(episodeJson(views: 3400000)).viewsLabel,
        '3.4M',
      );
    });

    test('epTag zero-pads the order', () {
      expect(LibraryEpisode.fromJson(episodeJson(order: 3)).epTag, 'EP 03');
      expect(LibraryEpisode.fromJson(episodeJson(order: null)).epTag, 'EP');
    });
  });

  group('LibraryEpisode.toFeedItem', () {
    test('carries the real stream through to the player', () {
      final item = LibraryEpisode.fromJson(episodeJson()).toFeedItem();
      expect(item.type, FeedContentType.video);
      expect(item.hasPlayableVideo, isTrue);
      expect(item.episodeId, 'ep-1');
    });

    test('an episode with no video_url never claims a playable stream', () {
      final item =
          LibraryEpisode.fromJson(episodeJson(video: null)).toFeedItem();
      expect(item.type, FeedContentType.image);
      expect(item.hasPlayableVideo, isFalse);
    });
  });

  group('WatchHistoryEntry', () {
    Map<String, dynamic> historyJson({
      bool completed = false,
      int watched = 377,
      String viewedAt = '2026-07-28T09:20:00Z',
      String id = 'ep-1',
    }) => {
      'episode': episodeJson(id: id),
      'watch_duration_seconds': watched,
      'completed': completed,
      'viewed_at': viewedAt,
    };

    test('progress is watched/duration', () {
      final entry = WatchHistoryEntry.fromJson(historyJson());
      expect(entry.progress, closeTo(0.5, 0.01));
      expect(entry.episode.watchProgress, closeTo(0.5, 0.01));
    });

    test('completed wins over the arithmetic', () {
      // Skipping the outro still counts as done — the server said so.
      final entry =
          WatchHistoryEntry.fromJson(historyJson(completed: true, watched: 12));
      expect(entry.progress, 1);
    });

    test('progress is 0 when the duration is unknown', () {
      final json = historyJson();
      (json['episode'] as Map<String, dynamic>)['video_duration'] = 0;
      expect(WatchHistoryEntry.fromJson(json).progress, 0);
    });

    test('progress never exceeds 1', () {
      expect(WatchHistoryEntry.fromJson(historyJson(watched: 9999)).progress, 1);
    });

    test('an unparseable viewed_at falls back to now rather than throwing', () {
      final entry = WatchHistoryEntry.fromJson(historyJson(viewedAt: ''));
      expect(
        entry.viewedAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });
  });

  group('library providers', () {
    ProviderContainer withRepo(
      _FakeLibraryRepository repo, {
      bool signedIn = true,
    }) {
      final c = ProviderContainer(
        // Riverpod 3 retries a failed build with backoff by default, which
        // would leave `.future` pending for the whole test.
        retry: (_, _) => null,
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('signed out resolves empty without calling the API', () async {
      final repo = _FakeLibraryRepository();
      final c = withRepo(repo, signedIn: false);

      expect(await c.read(likedEpisodesProvider.future), isEmpty);
      expect(repo.likedCalls, 0);
    });

    test('liked exposes what the API returned — nothing is seeded', () async {
      final repo = _FakeLibraryRepository(
        liked: [LibraryEpisode.fromJson(episodeJson())],
      );
      final c = withRepo(repo);

      final liked = await c.read(likedEpisodesProvider.future);
      expect(liked, hasLength(1));
      expect(liked.single.id, 'ep-1');
    });

    test('a failed load stays an error instead of falling back', () async {
      final c = withRepo(_FakeLibraryRepository(fail: true));
      Object? caught;
      try {
        await c.read(likedEpisodesProvider.future);
      } catch (error) {
        caught = error;
      }
      expect(caught, isA<Exception>());
      // The screen needs the error to offer a retry — a silent empty list
      // would read as "you have liked nothing".
      expect(c.read(likedEpisodesProvider).hasError, isTrue);
    });

    test('unlike drops the row and posts the toggle', () async {
      final repo = _FakeLibraryRepository(
        liked: [
          LibraryEpisode.fromJson(episodeJson()),
          LibraryEpisode.fromJson(episodeJson(id: 'ep-2')),
        ],
      );
      final c = withRepo(repo);
      final liked = await c.read(likedEpisodesProvider.future);

      await c.read(likedEpisodesProvider.notifier).unlike(liked.first);

      expect(c.read(likedEpisodesProvider).value!.map((e) => e.id), ['ep-2']);
      expect(repo.likeToggles, ['ep-1']);
    });

    test('a failed unlike puts the row back', () async {
      final repo = _FakeLibraryRepository(
        liked: [LibraryEpisode.fromJson(episodeJson())],
        failToggle: true,
      );
      final c = withRepo(repo);
      final liked = await c.read(likedEpisodesProvider.future);

      await expectLater(
        c.read(likedEpisodesProvider.notifier).unlike(liked.first),
        throwsA(isA<Exception>()),
      );
      // The list must not claim a server state that never happened.
      expect(c.read(likedEpisodesProvider).value, hasLength(1));
    });

    test('unsave drops the row and posts the toggle', () async {
      final repo = _FakeLibraryRepository(
        saved: [LibraryEpisode.fromJson(episodeJson())],
      );
      final c = withRepo(repo);
      final saved = await c.read(savedEpisodesProvider.future);

      await c.read(savedEpisodesProvider.notifier).unsave(saved.single);

      expect(c.read(savedEpisodesProvider).value, isEmpty);
      expect(repo.saveToggles, ['ep-1']);
    });

    test('watch history is sorted newest first', () async {
      final repo = _FakeLibraryRepository(
        history: [
          _entry('ep-old', '2026-07-20T09:00:00Z'),
          _entry('ep-new', '2026-07-28T09:00:00Z'),
          _entry('ep-mid', '2026-07-24T09:00:00Z'),
        ],
      );
      final c = withRepo(repo);

      final history = await c.read(watchHistoryProvider.future);
      expect(
        history.map((e) => e.episode.id),
        ['ep-new', 'ep-mid', 'ep-old'],
      );
    });

    test('hide removes one entry, clear removes all', () async {
      final repo = _FakeLibraryRepository(
        history: [
          _entry('ep-1', '2026-07-28T09:00:00Z'),
          _entry('ep-2', '2026-07-27T09:00:00Z'),
        ],
      );
      final c = withRepo(repo);
      final history = await c.read(watchHistoryProvider.future);

      c.read(watchHistoryProvider.notifier).hide(history.first);
      expect(c.read(watchHistoryProvider).value!.map((e) => e.episode.id),
          ['ep-2']);

      c.read(watchHistoryProvider.notifier).clear();
      expect(c.read(watchHistoryProvider).value, isEmpty);
    });
  });
}

WatchHistoryEntry _entry(String id, String viewedAt) =>
    WatchHistoryEntry.fromJson({
      'episode': episodeJson(id: id),
      'watch_duration_seconds': 100,
      'completed': false,
      'viewed_at': viewedAt,
    });

/// Records what the store asked for, and can fail on demand.
class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository({
    this.liked = const [],
    this.saved = const [],
    this.history = const [],
    this.fail = false,
    this.failToggle = false,
  }) : super(Dio());

  final List<LibraryEpisode> liked;
  final List<LibraryEpisode> saved;
  final List<WatchHistoryEntry> history;
  final bool fail;
  final bool failToggle;

  int likedCalls = 0;
  final List<String> likeToggles = [];
  final List<String> saveToggles = [];

  @override
  Future<List<LibraryEpisode>> getLiked({int? pageSize, String? skillworld}) async {
    likedCalls++;
    if (fail) throw Exception('offline');
    return liked;
  }

  @override
  Future<List<LibraryEpisode>> getSaved({int? pageSize, String? skillworld}) async {
    if (fail) throw Exception('offline');
    return saved;
  }

  @override
  Future<List<WatchHistoryEntry>> getWatchHistory({
    bool? completed,
    int? pageSize,
    String? skillworld,
  }) async {
    if (fail) throw Exception('offline');
    return history;
  }

  @override
  Future<void> toggleLike(String episodeId) async {
    if (failToggle) throw Exception('rejected');
    likeToggles.add(episodeId);
  }

  @override
  Future<void> toggleSave(String episodeId) async {
    if (failToggle) throw Exception('rejected');
    saveToggles.add(episodeId);
  }
}

/// Presence-only session gate, with no platform channel behind it.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}
