import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/comments_repository.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/comments_store.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/models/user_profile.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/profile_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/network/api_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

void main() {
  group('comment ownership', () {
    // `EpisodeComment` carries no `user_id` and no `is_mine`, so the store
    // infers ownership from the author name and from what this session posted.
    // Getting it wrong in either direction is visible: too narrow hides Edit
    // and Delete from the author, too wide offers them on a stranger's row.
    ProviderContainer withComments(
      _FakeCommentsRepository repo, {
      UserProfile? me,
    }) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          commentsRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(me != null)),
          profileRepositoryProvider.overrideWithValue(
            _FakeProfileRepository(me),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    UserProfile profile({
      String firstName = 'Amara',
      String lastName = 'Diallo',
    }) => UserProfile(
      id: 'me',
      firstName: firstName,
      lastName: lastName,
      username: 'amara',
    );

    Map<String, dynamic> commentJson({
      required int id,
      required String first,
      required String last,
      String text = 'hello',
    }) => {
      'id': id,
      'user_first_name': first,
      'user_last_name': last,
      'text': text,
    };

    /// The notifier loads in a microtask; settle before asserting.
    Future<CommentsState> load(
      ProviderContainer c, {
      String episodeId = 'ep1',
    }) async {
      c.read(commentsProvider.notifier).init(episodeId);
      await Future<void>.delayed(Duration.zero);
      return c.read(commentsProvider);
    }

    test('a name matching the signed-in profile is treated as own', () async {
      final repo = _FakeCommentsRepository([
        commentJson(id: 1, first: 'Amara', last: 'Diallo'),
      ]);
      final c = withComments(repo, me: profile());

      final state = await load(c);
      expect(state.comments.single.author, SkifluxCommentAuthor.own);
    });

    test('the name match ignores case and surrounding space', () async {
      final repo = _FakeCommentsRepository([
        commentJson(id: 1, first: '  amara ', last: 'DIALLO'),
      ]);
      final c = withComments(repo, me: profile());

      final state = await load(c);
      expect(state.comments.single.author, SkifluxCommentAuthor.own);
    });

    test('someone else stays other', () async {
      final repo = _FakeCommentsRepository([
        commentJson(id: 1, first: 'Kofi', last: 'Mensah'),
      ]);
      final c = withComments(repo, me: profile());

      final state = await load(c);
      expect(state.comments.single.author, SkifluxCommentAuthor.other);
    });

    test('signed out claims nothing', () async {
      final repo = _FakeCommentsRepository([
        commentJson(id: 1, first: 'Amara', last: 'Diallo'),
      ]);
      // No profile — an unresolved name must not match every comment.
      final c = withComments(repo);

      final state = await load(c);
      expect(state.comments.single.author, SkifluxCommentAuthor.other);
    });

    test(
      'a comment posted this session is own even when the name cannot prove it',
      () async {
        // The signed-in profile is unavailable, so the name check can decide
        // nothing — the session's own post must still be editable.
        final repo = _FakeCommentsRepository([]);
        final c = withComments(repo);
        await load(c);

        repo.rows = [commentJson(id: 7, first: '', last: '', text: 'mine')];
        await c.read(commentsProvider.notifier).addMessage('mine');
        await Future<void>.delayed(Duration.zero);

        final posted = c
            .read(commentsProvider)
            .comments
            .firstWhere((x) => x.id == 7);
        expect(posted.author, SkifluxCommentAuthor.own);
      },
    );

    test('ownership is re-resolved when the profile arrives late', () async {
      // The sheet can open before `GET /me/profile` answers. Without the
      // re-resolve, the user's own comments would lack Edit/Delete all session.
      final repo = _FakeCommentsRepository([
        commentJson(id: 1, first: 'Amara', last: 'Diallo'),
      ]);
      final slow = _FakeProfileRepository(profile(), delayed: true);
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          commentsRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(true)),
          profileRepositoryProvider.overrideWithValue(slow),
        ],
      );
      addTearDown(c.dispose);
      // Keep the listener in `build()` alive across the profile landing.
      final sub = c.listen(commentsProvider, (_, _) {});
      addTearDown(sub.close);

      final before = await load(c);
      expect(before.comments.single.author, SkifluxCommentAuthor.other);

      slow.release();
      await c.read(profileRepositoryProvider).getProfile();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(commentsProvider).comments.single.author,
        SkifluxCommentAuthor.own,
      );
    });
  });

  group('comment writes', () {
    ProviderContainer withComments(_FakeCommentsRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          commentsRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(false)),
          profileRepositoryProvider.overrideWithValue(
            _FakeProfileRepository(null),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<void> load(ProviderContainer c) async {
      c.read(commentsProvider.notifier).init('ep1');
      await Future<void>.delayed(Duration.zero);
    }

    Map<String, dynamic> row(int id, String text) => {
      'id': id,
      'user_first_name': 'Kofi',
      'user_last_name': 'Mensah',
      'text': text,
    };

    test('a failed edit puts the original text back', () async {
      final repo = _FakeCommentsRepository([row(1, 'original')])
        ..failEdit = true;
      final c = withComments(repo);
      await load(c);

      final target = c.read(commentsProvider).comments.single;
      await expectLater(
        c.read(commentsProvider.notifier).editComment(target, 'changed'),
        throwsA(isA<Object>()),
      );
      // The server rejects a comment the caller does not own; the row must not
      // keep text the backend never accepted.
      expect(c.read(commentsProvider).comments.single.message, 'original');
    });

    test('deleting a parent removes its replies and the count', () async {
      final repo = _FakeCommentsRepository([
        {
          ...row(1, 'parent'),
          'replies': [
            {...row(2, 'child'), 'parent_id': 1},
          ],
        },
      ]);
      final c = withComments(repo);
      await load(c);
      expect(c.read(commentsProvider).comments, hasLength(2));
      final before = c.read(commentsProvider).totalCount;

      final parent = c.read(commentsProvider).comments.first;
      await c.read(commentsProvider.notifier).deleteComment(parent);

      expect(c.read(commentsProvider).comments, isEmpty);
      expect(c.read(commentsProvider).totalCount, before - 2);
      expect(repo.deleted, [1]);
    });

    test('a failed delete restores the row and the count', () async {
      final repo = _FakeCommentsRepository([row(1, 'keep me')])
        ..failDelete = true;
      final c = withComments(repo);
      await load(c);
      final before = c.read(commentsProvider).totalCount;

      final target = c.read(commentsProvider).comments.single;
      await expectLater(
        c.read(commentsProvider.notifier).deleteComment(target),
        throwsA(isA<Object>()),
      );
      expect(c.read(commentsProvider).comments, hasLength(1));
      expect(c.read(commentsProvider).totalCount, before);
    });

    test('reporting sends the picked category verbatim', () async {
      final repo = _FakeCommentsRepository([row(1, 'spam')]);
      final c = withComments(repo);
      await load(c);

      await c
          .read(commentsProvider.notifier)
          .reportComment(
            c.read(commentsProvider).comments.single,
            ReportCommentCategory.harassment,
          );

      // The wire value, not the display label — the enum is a fixed vocabulary.
      expect(repo.reported, [(1, 'harassment')]);
    });
  });
}

class _FakeCommentsRepository extends CommentsRepository {
  _FakeCommentsRepository(this.rows) : super(Dio());

  List<Map<String, dynamic>> rows;
  bool failEdit = false;
  bool failDelete = false;
  final List<int> deleted = [];
  final List<(int, String)> reported = [];

  @override
  Future<Paginated<CommentItem>> getComments(
    String episodeId, {
    int limit = 50,
    int offset = 0,
  }) async => Paginated(
    results: rows.map(CommentItem.fromJson).toList(),
    count: rows.length,
  );

  @override
  Future<void> postComment(String episodeId, String text) async {}

  @override
  Future<void> editComment(int id, String text) async {
    if (failEdit) throw Exception('forbidden');
  }

  @override
  Future<void> deleteComment(int id) async {
    if (failDelete) throw Exception('forbidden');
    deleted.add(id);
    rows = rows.where((r) => r['id'] != id).toList();
  }

  @override
  Future<void> reportComment(int id, String category) async {
    reported.add((id, category));
  }
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile, {bool delayed = false})
    : _gate = delayed ? Completer<void>() : null,
      super(Dio());

  final UserProfile? profile;
  final Completer<void>? _gate;

  void release() => _gate?.complete();

  @override
  Future<UserProfile> getProfile() async {
    if (_gate != null) await _gate.future;
    final value = profile;
    if (value == null) throw Exception('no profile');
    return value;
  }
}
