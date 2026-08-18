import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/home/data/episodes_repository.dart';
import 'package:skiflux/features/home/data/home_feed_store.dart';
import 'package:skiflux/features/profile/data/library_episode.dart';
import 'package:skiflux/features/profile/data/library_repository.dart';
import 'package:skiflux/features/profile/data/library_store.dart';
import 'package:skiflux/shared/network/token_store.dart';

void main() {
  test('the feed is empty until the backend answers', () {
    // There used to be a seven-card sample feed here, playing stock clips
    // under invented creator names. It was indistinguishable from real
    // recommendations, so a signed-out or offline user watched, liked and
    // subscribed against episodes that do not exist.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(homeFeedItemsProvider), isEmpty);
  });

  test('HomeFeedItem only claims a playable video when it has a stream', () {
    const withStream = HomeFeedItem(
      type: FeedContentType.video,
      epTag: 'EP 01',
      title: 'Colour systems',
      description: 'Palettes that survive both themes.',
      coverAsset: '',
      videoUrl: 'https://cdn.skiflux.test/ep01.m3u8',
      creatorName: 'Amara',
      creatorUsername: 'amara',
      creatorInitials: 'A',
    );
    const awaitingStream = HomeFeedItem(
      type: FeedContentType.video,
      epTag: 'EP 02',
      title: 'Motion studies',
      description: 'Easing curves that feel human.',
      coverAsset: '',
      creatorName: 'Lola',
      creatorUsername: 'lola',
      creatorInitials: 'L',
    );

    expect(withStream.hasPlayableVideo, isTrue);
    // A video item whose `video_url` the API omitted must not reach
    // `VideoPlayerController` — that is the crash the seed used to mask.
    expect(awaitingStream.hasPlayableVideo, isFalse);
  });

  group('episodeJsonToFeedItem', () {
    Map<String, dynamic> episodeJson() => {
      'id': 'ep-1',
      'title': 'Colour systems',
      'description': 'Palettes.',
      'order': 3,
      'thumbnail_url': 'https://cdn.skiflux.test/ep1.jpg',
      'video_url': 'https://cdn.skiflux.test/ep1.m3u8',
      'video_duration': 754,
      'view_count': 120,
      'like_count': 45,
      'comment_count': 6,
      'save_count': 2,
      'creator': {'id': 'c-1', 'name': 'Amara Okoye', 'username': 'amara'},
    };

    test('carries the creator UUID and engagement counts', () {
      final item = episodeJsonToFeedItem(episodeJson());
      expect(item.episodeId, 'ep-1');
      // The creator id is what `GET /creators/{id}` and the follow toggle
      // take — the username navigation the app used before always 404'd.
      expect(item.creatorId, 'c-1');
      expect(item.creatorName, 'Amara Okoye');
      expect(item.likeCount, 45);
      expect(item.commentCount, 6);
      expect(item.saveCount, 2);
      expect(item.durationSeconds, 754);
    });

    test('missing counts stay null so the rail shows no number', () {
      final json = episodeJson()
        ..remove('like_count')
        ..remove('comment_count')
        ..remove('save_count');
      final item = episodeJsonToFeedItem(json);
      expect(item.likeCount, isNull);
      expect(item.commentCount, isNull);
      expect(item.saveCount, isNull);
    });
  });

  group('engagedCount', () {
    test('applies this session\'s delta over the payload count', () {
      expect(engagedCount(10, 0), 10);
      expect(engagedCount(10, 1), 11);
      expect(engagedCount(10, -1), 9);
      expect(engagedCount(10, 3), 13);
    });

    test('null payload count stays null — no fabricated numbers', () {
      expect(engagedCount(null, 1), isNull);
    });

    test('never goes negative', () {
      expect(engagedCount(0, -1), 0);
    });
  });

  group('feedEngagementProvider', () {
    ProviderContainer withRepo(_FakeLibraryRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(false)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('toggleLike posts the real toggle and keeps the optimistic flip',
        () async {
      final repo = _FakeLibraryRepository();
      final c = withRepo(repo);
      final notifier = c.read(feedEngagementProvider.notifier);

      final liked = await notifier.toggleLike('ep-1');
      expect(liked, isTrue);
      expect(repo.likeToggles, ['ep-1']);
      expect(c.read(feedEngagementProvider)['ep-1']!.liked, isTrue);
    });

    test('a failed toggle rolls back and rethrows', () async {
      final repo = _FakeLibraryRepository(failToggle: true);
      final c = withRepo(repo);
      final notifier = c.read(feedEngagementProvider.notifier);

      await expectLater(
        notifier.toggleLike('ep-1'),
        throwsA(isA<Exception>()),
      );
      // The card must not claim a like the server never recorded.
      expect(c.read(feedEngagementProvider)['ep-1']!.liked, isFalse);
    });

    test('toggleSave mirrors the like contract', () async {
      final repo = _FakeLibraryRepository();
      final c = withRepo(repo);

      final saved =
          await c.read(feedEngagementProvider.notifier).toggleSave('ep-1');
      expect(saved, isTrue);
      expect(repo.saveToggles, ['ep-1']);
    });

    test(
      'the +1 survives the liked-list refetch that follows the toggle',
      () async {
        // The regression this whole delta rewrite exists for. Liking
        // invalidates `likedEpisodesProvider`; the refetched list now contains
        // the episode, so a count derived from `base != now` collapsed back to
        // the server number and the user watched their like un-count itself.
        final repo = _FakeLibraryRepository(likedAfterToggle: true);
        final c = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            libraryRepositoryProvider.overrideWithValue(repo),
            tokenStoreProvider.overrideWithValue(_FakeTokenStore(true)),
          ],
        );
        addTearDown(c.dispose);

        await c.read(likedEpisodesProvider.future);
        await c.read(feedEngagementProvider.notifier).toggleLike('ep-1');

        // Base state now agrees with the toggle...
        final refetched = await c.read(likedEpisodesProvider.future);
        expect(refetched.map((e) => e.id), contains('ep-1'));

        // ...and the count still shows the like the user earned.
        final delta = c.read(feedEngagementProvider)['ep-1']!.likeDelta;
        expect(delta, 1);
        expect(engagedCount(10, delta), 11);
      },
    );

    test('a failed toggle rolls the count delta back with the flag', () async {
      final repo = _FakeLibraryRepository(failToggle: true);
      final c = withRepo(repo);

      await expectLater(
        c.read(feedEngagementProvider.notifier).toggleLike('ep-1'),
        throwsA(isA<Exception>()),
      );

      // A filled heart next to an unmoved count, or a moved count next to an
      // empty heart, are both lies — they roll back together.
      final engagement = c.read(feedEngagementProvider)['ep-1']!;
      expect(engagement.liked, isFalse);
      expect(engagement.likeDelta, 0);
    });

    test('bumpComments moves the rail count the sheet just changed', () {
      final c = withRepo(_FakeLibraryRepository());
      final notifier = c.read(feedEngagementProvider.notifier);

      notifier.bumpComments('ep-1', 1);
      expect(c.read(feedEngagementProvider)['ep-1']!.commentDelta, 1);

      // Deleting your own comment takes it back down.
      notifier.bumpComments('ep-1', -1);
      expect(c.read(feedEngagementProvider)['ep-1']!.commentDelta, 0);
    });
  });

  group('ViewTracker', () {
    test('posts the view start, then throttles by interval', () async {
      final posts = <(int, bool)>[];
      final tracker = ViewTracker(
        episodeId: 'ep-1',
        totalSeconds: 100,
        interval: const Duration(days: 1), // nothing else fires in this test
        post: (id, {required watchDurationSeconds, required completed}) async {
          posts.add((watchDurationSeconds, completed));
        },
      );

      tracker.onProgress(Duration.zero, const Duration(seconds: 100));
      tracker.onProgress(
        const Duration(seconds: 3),
        const Duration(seconds: 100),
      );
      tracker.onProgress(
        const Duration(seconds: 6),
        const Duration(seconds: 100),
      );
      await Future<void>.delayed(Duration.zero);

      // Only the initial view-start post — the rest fell inside the window.
      expect(posts, [(0, false)]);
    });

    test('flush posts the final position on page change', () async {
      final posts = <(int, bool)>[];
      final tracker = ViewTracker(
        episodeId: 'ep-1',
        totalSeconds: 100,
        interval: const Duration(days: 1),
        post: (id, {required watchDurationSeconds, required completed}) async {
          posts.add((watchDurationSeconds, completed));
        },
      );

      tracker.onProgress(Duration.zero, const Duration(seconds: 100));
      tracker.onProgress(
        const Duration(seconds: 42),
        const Duration(seconds: 100),
      );
      tracker.flush();
      await Future<void>.delayed(Duration.zero);

      expect(posts, [(0, false), (42, false)]);
    });

    test('posts completed immediately at 95% of the duration', () async {
      final posts = <(int, bool)>[];
      final tracker = ViewTracker(
        episodeId: 'ep-1',
        totalSeconds: 100,
        interval: const Duration(days: 1),
        post: (id, {required watchDurationSeconds, required completed}) async {
          posts.add((watchDurationSeconds, completed));
        },
      );

      tracker.onProgress(Duration.zero, const Duration(seconds: 100));
      tracker.onProgress(
        const Duration(seconds: 96),
        const Duration(seconds: 100),
      );
      await Future<void>.delayed(Duration.zero);

      expect(posts, [(0, false), (96, true)]);
    });

    test('a failing post stays silent', () async {
      final tracker = ViewTracker(
        episodeId: 'ep-1',
        interval: const Duration(days: 1),
        post: (id, {required watchDurationSeconds, required completed}) async {
          throw Exception('offline');
        },
      );

      tracker.onProgress(
        const Duration(seconds: 1),
        const Duration(seconds: 100),
      );
      // No throw may escape — telemetry loss is not a user problem.
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('videoProgressFraction', () {
    test('returns 0 for zero duration', () {
      expect(
        videoProgressFraction(const Duration(seconds: 5), Duration.zero),
        0,
      );
    });

    test('returns position/duration clamped to 0–1', () {
      expect(
        videoProgressFraction(
          const Duration(seconds: 5),
          const Duration(seconds: 10),
        ),
        0.5,
      );
      expect(
        videoProgressFraction(
          const Duration(seconds: 12),
          const Duration(seconds: 10),
        ),
        1.0,
      );
      expect(
        videoProgressFraction(Duration.zero, const Duration(seconds: 10)),
        0,
      );
    });
  });
}

/// Records toggles, and can fail on demand.
class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository({
    this.failToggle = false,
    this.likedAfterToggle = false,
  }) : super(Dio());

  final bool failToggle;

  /// When set, `getLiked()` starts empty and returns `ep-1` once the toggle
  /// has been posted — the real server behaviour that used to eat the +1.
  final bool likedAfterToggle;

  final List<String> likeToggles = [];
  final List<String> saveToggles = [];

  @override
  Future<List<LibraryEpisode>> getLiked({
    int? pageSize,
    String? skillworld,
  }) async {
    if (!likedAfterToggle || likeToggles.isEmpty) return const [];
    return const [
      LibraryEpisode(
        id: 'ep-1',
        title: 'Colour systems',
        description: '',
        creatorName: 'Amara',
        creatorUsername: 'amara',
        creatorInitials: 'A',
      ),
    ];
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

