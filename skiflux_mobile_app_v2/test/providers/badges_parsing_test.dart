/// `GET /me/badges` wire tolerance.
///
/// The parser must survive a backend that strays from the spec's UUID-string
/// `id` / date-time `earned_at` — an int id or a missing timestamp degrades to
/// a badge that still renders, never a `TypeError` that takes the whole
/// Badges screen down. The join rule itself is covered in `badges_test.dart`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/profile/data/badges_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> received = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    received.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

({BadgesRepository repo, _StubAdapter adapter}) _build(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _StubAdapter(handler);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.test/api/v1',
      contentType: Headers.jsonContentType,
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ),
  )..httpClientAdapter = adapter;
  return (repo: BadgesRepository(dio), adapter: adapter);
}

void main() {
  group('UserBadge.fromJson', () {
    test('parses the spec shape', () {
      final badge = UserBadge.fromJson({
        'id': 'ub-1',
        'badge': {
          'id': 'b-1',
          'name': 'First Task Completed',
          'description': 'Finish your first task',
          'icon_url': null,
          'is_active': true,
        },
        'earned_at': '2026-07-01T12:00:00Z',
      });

      expect(badge.id, 'ub-1');
      expect(badge.badge.name, 'First Task Completed');
      expect(badge.earnedAt, DateTime.utc(2026, 7, 1, 12));
    });

    test('tolerates an integer id on both records', () {
      final badge = UserBadge.fromJson({
        'id': 7,
        'badge': {'id': 12, 'name': 'Big Earner'},
        'earned_at': '2026-07-01T12:00:00Z',
      });

      expect(badge.id, '7');
      expect(badge.badge.id, '12');
    });

    test('tolerates a null or malformed earned_at without unearning', () {
      // Presence in the response is what "earned" means — see
      // badge_catalogue.dart; a dropped timestamp must not drop the award.
      final missing = UserBadge.fromJson({
        'id': 'ub-2',
        'badge': {'id': 'b-2', 'name': 'Super Fan'},
      });
      final malformed = UserBadge.fromJson({
        'id': 'ub-3',
        'badge': {'id': 'b-3', 'name': 'Top Learner'},
        'earned_at': 'yesterday-ish',
      });

      expect(missing.earnedAt, isNull);
      expect(missing.badge.name, 'Super Fan');
      expect(malformed.earnedAt, isNull);
      expect(malformed.badge.name, 'Top Learner');
    });

    test('survives a missing badge object', () {
      final badge = UserBadge.fromJson({'id': 'ub-4'});
      expect(badge.badge.name, isEmpty);
    });
  });

  group('BadgesRepository.getMyBadges', () {
    test('GETs /me/badges, not the legacy /profile/me/badges', () async {
      final env = _build(
        (_) async => _json(200, '''
          [{"id": "ub-1",
            "badge": {"id": "b-1", "name": "3 Days Streak",
                      "description": "", "icon_url": null},
            "earned_at": "2026-07-01T12:00:00Z"}]'''),
      );

      final badges = await env.repo.getMyBadges();

      final request = env.adapter.received.single;
      expect(request.path, '/me/badges');
      expect(request.method, 'GET');
      expect(badges.single.badge.name, '3 Days Streak');
    });
  });
}
