import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/search/data/search_index.dart';

/// The spec's `GlobalSearchResponse`: four DRF pages keyed `episodes`,
/// `seasons`, `creators`, `users`.
Map<String, dynamic> responseJson() => {
  'episodes': {
    'count': 1,
    'next': null,
    'previous': null,
    'results': [
      {
        'id': 'ep-1',
        'title': 'Designing Interfaces People Trust',
        'order': 6,
        'video_duration': 1200,
        'view_count': 22000,
        'thumbnail_url': 'https://cdn.skiflux.test/ep1.jpg',
        'creator': {'id': 'c-1', 'name': 'Amara Okoye', 'username': 'amara'},
      },
    ],
  },
  'seasons': {
    'count': 1,
    'next': null,
    'previous': null,
    'results': [
      {
        'id': 's-1',
        'title': 'UI Fundamentals',
        'skillworld': 'design',
        'episode_count': 8,
      },
    ],
  },
  'creators': {
    'count': 1,
    'next': null,
    'previous': null,
    'results': [
      {
        'id': 'c-1',
        'name': 'Amara Okoye',
        'username': 'amara',
        'avatar_url': 'https://cdn.skiflux.test/amara.png',
        'followers_count': 12400,
      },
    ],
  },
  'users': {
    'count': 1,
    'next': null,
    'previous': null,
    'results': [
      {
        'id': 'u-1',
        'name': 'Kojo Mensah',
        'username': 'kojo',
        'avatar_url': null,
      },
    ],
  },
};

void main() {
  group('SearchResults.fromResponse', () {
    test('parses the GlobalSearchResponse groups', () {
      final r = SearchResults.fromResponse('ui', responseJson());

      expect(r.query, 'ui');
      expect(r.episodes.single.id, 'ep-1');
      expect(r.episodes.single.epTag, 'EP 06');
      expect(r.episodes.single.duration, '20:00');
      expect(r.episodes.single.thumbnailUrl, 'https://cdn.skiflux.test/ep1.jpg');

      // Creator rows carry the UUID profile navigation needs, and the REAL
      // follower count — the UI used to hardcode "..." subscribers.
      final creator = r.creators.single;
      expect(creator.id, 'c-1');
      expect(creator.username, 'amara');
      expect(creator.followersCount, 12400);
      expect(creator.subtitle, '@amara · 12.4k subscribers');

      // Learners have no follower figure; the subtitle claims none.
      final user = r.users.single;
      expect(user.id, 'u-1');
      expect(user.followersCount, isNull);
      expect(user.subtitle, '@kojo');

      // The spec's `seasons` group feeds the Playlists tab, and a Season has
      // no creator — the subtitle doesn't invent one.
      final playlist = r.playlists.single;
      expect(playlist.id, 's-1');
      expect(playlist.episodeCount, 8);
      expect(playlist.subtitle, 'design · 8 episodes');
    });

    test('unwraps the {data: …} envelope and the array root the spec declares',
        () {
      final enveloped = SearchResults.fromResponse('ui', {
        'data': responseJson(),
      });
      expect(enveloped.creators, hasLength(1));

      final arrayRoot = SearchResults.fromResponse('ui', [responseJson()]);
      expect(arrayRoot.creators, hasLength(1));
    });

    test('tolerates bare-list groups', () {
      final r = SearchResults.fromResponse('ui', {
        'creators': [
          {'id': 'c-9', 'name': 'Lola', 'username': 'lola'},
        ],
      });
      expect(r.creators.single.id, 'c-9');
      expect(r.episodes, isEmpty);
      expect(r.users, isEmpty);
    });

    test('a garbage body reads as no results, not a crash', () {
      expect(SearchResults.fromResponse('x', 'not json').isEmpty, isTrue);
      expect(SearchResults.fromResponse('x', null).isEmpty, isTrue);
    });

    test('a user without a username keeps an empty one — navigation sites '
        'must disable, not guess', () {
      final r = SearchResults.fromResponse('ui', {
        'users': {
          'results': [
            {'id': 'u-2', 'name': 'Ghost'},
          ],
        },
      });
      expect(r.users.single.username, isEmpty);
      expect(r.users.single.subtitle, isEmpty);
    });
  });

  group('SearchResults aggregation', () {
    test('total / countFor / topCategory', () {
      final r = SearchResults.fromResponse('ui', responseJson());
      expect(r.total, 4);
      expect(r.countFor(SearchCategory.episodes), 1);
      expect(r.isEmpty, isFalse);
      expect(r.topCategory, SearchCategory.episodes);
      expect(SearchResults.empty.topCategory, isNull);
    });
  });
}
