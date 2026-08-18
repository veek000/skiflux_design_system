import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/subscriptions/data/subscriptions_repository.dart';
import 'package:skiflux/features/subscriptions/data/subscriptions_store.dart';
import 'package:skiflux/shared/error_handling/error_handler.dart';
import 'package:skiflux/shared/network/api_repository.dart';
import 'package:skiflux/shared/network/token_store.dart';

/// One `FollowedCreator` as `/creators/following/` returns it.
Map<String, dynamic> creatorJson({
  String id = 'c-1',
  String username = 'amara',
  String first = 'Amara',
  String last = 'Okoye',
  int followers = 1200,
}) => {
  'id': id,
  'first_name': first,
  'last_name': last,
  'username': username,
  'avatar_public_id': null,
  'bio': 'Designer',
  'skillworld': 'design',
  'followers_count': followers,
};

/// One `Episode` as `/episodes/following/` returns it.
Map<String, dynamic> episodeJson({
  String id = 'ep-1',
  String creatorId = 'c-1',
  String creatorUsername = 'amara',
  int order = 6,
  String? createdAt,
}) => {
  'id': id,
  'title': 'Designing Interfaces People Trust',
  'description': 'Trust patterns.',
  'order': order,
  'thumbnail_url': 'https://cdn.skiflux.test/$id.jpg',
  'video_url': 'https://cdn.skiflux.test/$id.m3u8',
  'video_duration': 1200,
  'view_count': 22000,
  'created_at':
      createdAt ??
      DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
  'creator': {'id': creatorId, 'name': 'Amara Okoye', 'username': creatorUsername},
};

SubscribedCreator creatorOfJson([Map<String, dynamic>? json]) =>
    SubscribedCreator.fromJson(json ?? creatorJson());

void main() {
  group('SubscribedCreator.fromJson', () {
    test('maps the FollowedCreator schema, id included', () {
      final c = creatorOfJson();
      expect(c.id, 'c-1');
      expect(c.name, 'Amara Okoye');
      expect(c.username, 'amara');
      expect(c.initials, 'AO');
      expect(c.followersCount, 1200);
    });

    test('falls back to the username for a nameless account', () {
      final c = SubscribedCreator.fromJson({'id': 'c-2', 'username': 'ghost'});
      expect(c.name, 'ghost');
      expect(c.initials, 'G');
    });
  });

  group('SubscriptionEpisode.fromJson', () {
    test('maps the Episode schema — id, creator id, thumbnail, labels', () {
      final e = SubscriptionEpisode.fromJson(episodeJson());
      expect(e.id, 'ep-1');
      expect(e.creatorId, 'c-1');
      expect(e.creatorUsername, 'amara');
      expect(e.epNumber, 6);
      expect(e.epTag, 'EP 06');
      expect(e.duration, '20:00');
      expect(e.views, '22.0k views');
      expect(e.thumbnailUrl, 'https://cdn.skiflux.test/ep-1.jpg');
      expect(e.hasThumbnail, isTrue);
      expect(e.videoUrl, 'https://cdn.skiflux.test/ep-1.m3u8');
    });

    test('derives postedAgo / isNew / postedToday from created_at', () {
      final fresh = SubscriptionEpisode.fromJson(episodeJson());
      expect(fresh.postedAgo, '5 hrs ago');
      expect(fresh.isNew, isTrue);
      expect(fresh.postedToday, isTrue);

      final old = SubscriptionEpisode.fromJson(
        episodeJson(
          createdAt: DateTime.now()
              .subtract(const Duration(days: 9))
              .toIso8601String(),
        ),
      );
      expect(old.postedAgo, '1 week ago');
      expect(old.isNew, isFalse);
      expect(old.postedToday, isFalse);
    });

    test('a missing created_at reads as "Recently", not a made-up age', () {
      final json = episodeJson()..remove('created_at');
      expect(SubscriptionEpisode.fromJson(json).postedAgo, 'Recently');
    });
  });

  group('relativeAgeLabel', () {
    final now = DateTime(2026, 7, 31, 12);
    test('formats each bracket', () {
      expect(relativeAgeLabel(null), 'Recently');
      expect(
        relativeAgeLabel(now.subtract(const Duration(seconds: 30)), now: now),
        'Just now',
      );
      expect(
        relativeAgeLabel(now.subtract(const Duration(minutes: 5)), now: now),
        '5 mins ago',
      );
      expect(
        relativeAgeLabel(now.subtract(const Duration(hours: 1)), now: now),
        '1 hr ago',
      );
      expect(
        relativeAgeLabel(now.subtract(const Duration(days: 2)), now: now),
        '2 days ago',
      );
      expect(
        relativeAgeLabel(now.subtract(const Duration(days: 21)), now: now),
        '3 weeks ago',
      );
    });
  });

  group('SubscriptionsState logic', () {
    SubscriptionsState state() => SubscriptionsState(
      creators: [
        creatorOfJson(),
        creatorOfJson(creatorJson(id: 'c-2', username: 'kojo', first: 'Kojo', last: 'Sketches')),
      ],
      episodes: [
        SubscriptionEpisode.fromJson(episodeJson()),
        SubscriptionEpisode.fromJson(
          episodeJson(
            id: 'ep-2',
            creatorId: 'c-2',
            creatorUsername: 'kojo',
            order: 2,
            createdAt: DateTime.now()
                .subtract(const Duration(days: 9))
                .toIso8601String(),
          ),
        ),
      ],
      hasLoaded: true,
    );

    test('feed sorts new episodes first', () {
      final feed = state().feed();
      expect(feed.first.id, 'ep-1');
      expect(feed.first.isNew, isTrue);
      expect(feed.last.isNew, isFalse);
    });

    test('today filter keeps only episodes from the last 24h', () {
      final feed = state().feed(filter: SubscriptionFeedFilter.today);
      expect(feed.map((e) => e.id), ['ep-1']);
    });

    test('feed filtered by creator matches by username or id', () {
      final byUsername = state().feed(creatorUsername: 'kojo');
      expect(byUsername.map((e) => e.id), ['ep-2']);
      final byId = state().feed(creatorUsername: 'c-2');
      expect(byId.map((e) => e.id), ['ep-2']);
    });

    test('creatorOf resolves the followed creator, and falls back to the '
        'episode payload rather than "Unknown"', () {
      final s = state();
      expect(s.creatorOf(s.episodes.first).id, 'c-1');

      final stranger = SubscriptionEpisode.fromJson(
        episodeJson(id: 'ep-3', creatorId: 'c-9', creatorUsername: 'lola'),
      );
      final resolved = s.creatorOf(stranger);
      expect(resolved.name, 'Amara Okoye'); // name comes from the payload
      expect(resolved.id, 'c-9');
    });

    test('isSubscribed matches id and username', () {
      final s = state();
      expect(s.isSubscribed('c-1'), isTrue);
      expect(s.isSubscribed('amara'), isTrue);
      expect(s.isSubscribed('nobody'), isFalse);
      expect(s.isSubscribed(''), isFalse);
    });

    test('sortedCreators A–Z', () {
      final sorted = state().sortedCreators(SubscriptionListSort.aToZ);
      expect(sorted.map((c) => c.name), ['Amara Okoye', 'Kojo Sketches']);
    });
  });

  group('subscriptionsProvider', () {
    ProviderContainer withRepo(
      _FakeSubscriptionsRepository repo, {
      bool signedIn = true,
    }) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          subscriptionsRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('signed out resolves empty — the demo creators are gone', () async {
      final repo = _FakeSubscriptionsRepository();
      final c = withRepo(repo, signedIn: false);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      final state = c.read(subscriptionsProvider);
      expect(state.creators, isEmpty);
      expect(state.episodes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasLoaded, isTrue);
      expect(repo.followingCalls, 0);
    });

    test('loads real creators and episodes from the follow endpoints',
        () async {
      final repo = _FakeSubscriptionsRepository(
        creators: [creatorOfJson()],
        episodes: [SubscriptionEpisode.fromJson(episodeJson())],
      );
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      final state = c.read(subscriptionsProvider);
      expect(state.creators.map((x) => x.id), ['c-1']);
      expect(state.episodes.map((x) => x.id), ['ep-1']);
      expect(state.hasLoaded, isTrue);
      expect(state.error, isNull);
    });

    test('a failed load keeps an error for retry — no seed substitution',
        () async {
      final repo = _FakeSubscriptionsRepository(failLoad: true);
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      var state = c.read(subscriptionsProvider);
      expect(state.creators, isEmpty);
      expect(state.error, isNotNull);
      expect(state.hasLoaded, isFalse);

      repo.failLoad = false;
      repo.creators = [creatorOfJson()];
      await c.read(subscriptionsProvider.notifier).refresh();

      state = c.read(subscriptionsProvider);
      expect(state.error, isNull);
      expect(state.creators, hasLength(1));
    });

    test('subscribe posts the follow toggle and keeps the row on success',
        () async {
      final repo = _FakeSubscriptionsRepository();
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      await c.read(subscriptionsProvider.notifier).subscribe(creatorOfJson());
      expect(repo.toggles, ['c-1']);
      expect(c.read(subscriptionsProvider).isSubscribed('c-1'), isTrue);
      expect(
        c.read(subscriptionsProvider.notifier).isSubscribed('amara'),
        isTrue,
      );
    });

    test('a failed subscribe rolls the row back and rethrows', () async {
      final repo = _FakeSubscriptionsRepository(failToggle: true);
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      await expectLater(
        c.read(subscriptionsProvider.notifier).subscribe(creatorOfJson()),
        throwsA(isA<Exception>()),
      );
      // The list must not claim a follow the server never recorded.
      expect(c.read(subscriptionsProvider).isSubscribed('c-1'), isFalse);
    });

    test('subscribe without a creator UUID fails honestly', () async {
      final repo = _FakeSubscriptionsRepository();
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      await expectLater(
        c.read(subscriptionsProvider.notifier).subscribe(
              SubscribedCreator(name: 'No Id', username: 'noid', initials: 'N'),
            ),
        throwsA(isA<SkifluxFailure>()),
      );
      expect(repo.toggles, isEmpty);
    });

    test('unsubscribe removes creator + episodes; failure restores both',
        () async {
      final repo = _FakeSubscriptionsRepository(
        creators: [creatorOfJson()],
        episodes: [SubscriptionEpisode.fromJson(episodeJson())],
      );
      // The server confirms the toggle landed as an unfollow — otherwise the
      // store's reconcile step correctly puts the row back.
      repo.toggleResult = const FollowToggleResult(isFollowing: false);
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      final row = c.read(subscriptionsProvider).creators.single;
      await c.read(subscriptionsProvider.notifier).unsubscribe(row);
      expect(c.read(subscriptionsProvider).creators, isEmpty);
      expect(c.read(subscriptionsProvider).episodes, isEmpty);
      expect(repo.toggles, ['c-1']);

      // Now the failing path.
      final repo2 = _FakeSubscriptionsRepository(
        creators: [creatorOfJson()],
        episodes: [SubscriptionEpisode.fromJson(episodeJson())],
        failToggle: true,
      );
      final c2 = withRepo(repo2);
      c2.read(subscriptionsProvider);
      await pumpEventQueue();

      await expectLater(
        c2
            .read(subscriptionsProvider.notifier)
            .unsubscribe(c2.read(subscriptionsProvider).creators.single),
        throwsA(isA<Exception>()),
      );
      expect(c2.read(subscriptionsProvider).creators, hasLength(1));
      expect(c2.read(subscriptionsProvider).episodes, hasLength(1));
    });

    test('setNotificationMode stays local', () async {
      final repo = _FakeSubscriptionsRepository(creators: [creatorOfJson()]);
      final c = withRepo(repo);
      c.read(subscriptionsProvider);
      await pumpEventQueue();

      final creator = c.read(subscriptionsProvider).creators.single;
      c
          .read(subscriptionsProvider.notifier)
          .setNotificationMode(creator, CreatorNotificationMode.none);
      expect(creator.notificationMode, CreatorNotificationMode.none);
      expect(repo.toggles, isEmpty);
    });
  });
}

/// Records what the store asked for, and can fail on demand.
class _FakeSubscriptionsRepository extends SubscriptionsRepository {
  _FakeSubscriptionsRepository({
    this.creators = const [],
    this.episodes = const [],
    this.failLoad = false,
    this.failToggle = false,
  }) : super(Dio());

  List<SubscribedCreator> creators;
  List<SubscriptionEpisode> episodes;
  bool failLoad;
  bool failToggle;
  FollowToggleResult? toggleResult;

  int followingCalls = 0;
  final List<String> toggles = [];

  @override
  Future<Paginated<SubscribedCreator>> getFollowingCreators({
    int limit = 50,
    int offset = 0,
  }) async {
    followingCalls++;
    if (failLoad) throw Exception('offline');
    return Paginated(results: creators, count: creators.length);
  }

  @override
  Future<Paginated<SubscriptionEpisode>> getFollowingEpisodes({
    int limit = 50,
    int offset = 0,
  }) async {
    if (failLoad) throw Exception('offline');
    return Paginated(results: episodes, count: episodes.length);
  }

  @override
  Future<FollowToggleResult> toggleFollow(String creatorId) async {
    if (failToggle) throw Exception('rejected');
    toggles.add(creatorId);
    return toggleResult ?? const FollowToggleResult(isFollowing: true);
  }
}

/// Presence-only session gate, with no platform channel behind it.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}

