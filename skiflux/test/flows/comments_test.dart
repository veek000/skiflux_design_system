import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux/features/home/data/comments_repository.dart';
import 'package:skiflux/features/home/data/comments_store.dart';
import 'package:skiflux/shared/network/api_repository.dart';

/// One `EpisodeComment` as `GET /episodes/{id}/comments` returns it — the
/// flat spec shape (`user_first_name`, `text`, `is_liked`…), not the invented
/// nested `author` object an earlier pass parsed.
Map<String, dynamic> commentJson({
  int id = 11,
  String first = 'Amara',
  String last = 'Okoye',
  String? text = 'Loved the pacing on this one.',
  String? audioUrl,
  int likeCount = 3,
  bool isLiked = false,
  List<Map<String, dynamic>> replies = const [],
}) => {
  'id': id,
  'parent_id': null,
  'user_first_name': first,
  'user_last_name': last,
  'user_avatar': 'https://cdn.skiflux.test/u$id.png',
  'text': text,
  'audio_public_id': null,
  'audio_url': audioUrl,
  'like_count': likeCount,
  'is_liked': isLiked,
  'replies': replies,
  'created_at': '2026-07-31T09:00:00Z',
  'updated_at': '2026-07-31T09:00:00Z',
};

/// A simple test widget that wraps the comments sheet body for isolated
/// testing without the sheet modal shell.
class _CommentsTestHarness extends ConsumerStatefulWidget {
  const _CommentsTestHarness();

  @override
  ConsumerState<_CommentsTestHarness> createState() =>
      _CommentsTestHarnessState();
}

class _CommentsTestHarnessState extends ConsumerState<_CommentsTestHarness> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider.notifier).init('ep-1');
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(commentsProvider);
    final notifier = ref.read(commentsProvider.notifier);
    return Column(
      children: [
        Text('count:${session.totalCount}'),
        Expanded(
          child: ListView(
            children: [
              if (session.comments.isEmpty) const Text('No comments yet'),
              for (int i = 0; i < session.comments.length; i++)
                if (session.comments[i].message != null)
                  Text(
                    '[${session.comments[i].message}]',
                    key: Key('comment_$i'),
                  ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: TextField(controller: _textController)),
            ElevatedButton(
              onPressed: () async {
                try {
                  await notifier.addMessage(_textController.text);
                  _textController.clear();
                } catch (_) {
                  // The sheet surfaces this via ErrorDisplay; the harness
                  // only cares that the list rolled back.
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester,
  _FakeCommentsRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [commentsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: _CommentsTestHarness())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CommentItem.fromJson', () {
    test('maps the flat EpisodeComment schema', () {
      final item = CommentItem.fromJson(commentJson());
      expect(item.id, 11);
      expect(item.authorName, 'Amara Okoye');
      expect(item.message, 'Loved the pacing on this one.');
      expect(item.likeCount, 3);
      expect(item.isLiked, isFalse);
      expect(item.body, SkifluxCommentBody.message);
      expect(item.avatarUrl, 'https://cdn.skiflux.test/u11.png');
      // No username exists on the payload — nothing is invented.
      expect(item.handle, isEmpty);
    });

    test('a comment with audio_url renders as a voicenote', () {
      final item = CommentItem.fromJson(
        commentJson(text: null, audioUrl: 'https://cdn.skiflux.test/v.mp3'),
      );
      expect(item.body, SkifluxCommentBody.voicenote);
      expect(item.audioUrl, isNotNull);
      // Remote audio has no local file, so it is not claimed playable.
      expect(item.audioPath, isNull);
    });

    test('nested replies are parsed', () {
      final item = CommentItem.fromJson(
        commentJson(
          replies: [
            commentJson(id: 12, text: 'Same here!')
              ..['parent_id'] = 11,
          ],
        ),
      );
      expect(item.replies, hasLength(1));
      expect(item.replies.single.parentId, 11);
    });
  });

  group('Comments flow', () {
    testWidgets('renders the backend comments — no demo seeds', (
      tester,
    ) async {
      final repo = _FakeCommentsRepository(
        comments: [
          CommentItem.fromJson(commentJson()),
          CommentItem.fromJson(
            commentJson(id: 12, first: 'Kojo', text: 'Great breakdown'),
          ),
        ],
      );
      await _pumpHarness(tester, repo);

      expect(find.textContaining('[Loved the pacing'), findsOneWidget);
      expect(find.textContaining('[Great breakdown'), findsOneWidget);
      expect(find.text('count:2'), findsOneWidget);
      expect(repo.loads, ['ep-1']);
    });

    testWidgets('an empty episode shows the empty state, not sample chatter', (
      tester,
    ) async {
      await _pumpHarness(tester, _FakeCommentsRepository());
      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('replies are flattened into the list after their parent', (
      tester,
    ) async {
      final repo = _FakeCommentsRepository(
        comments: [
          CommentItem.fromJson(
            commentJson(
              replies: [
                commentJson(id: 12, text: 'A reply')..['parent_id'] = 11,
              ],
            ),
          ),
        ],
      );
      await _pumpHarness(tester, repo);
      expect(find.textContaining('[A reply'), findsOneWidget);
      expect(find.text('count:2'), findsOneWidget);
    });

    testWidgets('sending a text comment posts `text` and appends it', (
      tester,
    ) async {
      final repo = _FakeCommentsRepository();
      await _pumpHarness(tester, repo);

      await tester.enterText(find.byType(TextField), 'My unique comment 42');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('My unique comment 42'), findsOneWidget);
      expect(repo.posted, [('ep-1', 'My unique comment 42')]);
    });

    testWidgets('a failed post rolls the optimistic comment back', (
      tester,
    ) async {
      final repo = _FakeCommentsRepository(failPost: true);
      await _pumpHarness(tester, repo);

      await tester.enterText(find.byType(TextField), 'Will not stick');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // The list must not show a comment the server never accepted — the
      // count stays 0. The compose field keeps the draft so the user can
      // retry, so the one allowed match is the TextField itself.
      expect(find.text('count:0'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Will not stick'), findsOneWidget);
      expect(find.textContaining('Will not stick'), findsOneWidget);
    });

    testWidgets('empty message is not added', (tester) async {
      final repo = _FakeCommentsRepository();
      await _pumpHarness(tester, repo);

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
      expect(repo.posted, isEmpty);
    });
  });

  group('Comment interactions (store)', () {
    ProviderContainer withRepo(_FakeCommentsRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [commentsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('toggleCommentLike is optimistic and posts the toggle', () async {
      final repo = _FakeCommentsRepository(
        comments: [CommentItem.fromJson(commentJson())],
      );
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      final comment = c.read(commentsProvider).comments.single;
      await c.read(commentsProvider.notifier).toggleCommentLike(comment);

      final updated = c.read(commentsProvider).comments.single;
      expect(updated.isLiked, isTrue);
      expect(updated.likeCount, 4);
      expect(repo.likeToggles, [11]);
    });

    test('a failed like flips the state back and rethrows', () async {
      final repo = _FakeCommentsRepository(
        comments: [CommentItem.fromJson(commentJson())],
        failLike: true,
      );
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      await expectLater(
        c
            .read(commentsProvider.notifier)
            .toggleCommentLike(c.read(commentsProvider).comments.single),
        throwsA(isA<Exception>()),
      );
      final restored = c.read(commentsProvider).comments.single;
      expect(restored.isLiked, isFalse);
      expect(restored.likeCount, 3);
    });

    test('a send while replying posts to the reply endpoint', () async {
      final repo = _FakeCommentsRepository(
        comments: [CommentItem.fromJson(commentJson())],
      );
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      final parent = c.read(commentsProvider).comments.single;
      c.read(commentsProvider.notifier).startReply(parent);
      await c.read(commentsProvider.notifier).addMessage('Agreed!');

      expect(repo.replies, [(11, 'Agreed!')]);
      expect(repo.posted, isEmpty);
      expect(c.read(commentsProvider).replyingTo, isNull);
    });

    test('a failed voice note upload removes the optimistic row', () async {
      final repo = _FakeCommentsRepository(failVoice: true);
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      await expectLater(
        c.read(commentsProvider.notifier).addVoiceNote('/tmp/note.m4a'),
        throwsA(isA<Exception>()),
      );
      expect(c.read(commentsProvider).comments, isEmpty);
    });

    test('a successful voice note upload keeps the playable row', () async {
      final repo = _FakeCommentsRepository();
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      await c.read(commentsProvider.notifier).addVoiceNote('/tmp/note.m4a');
      final row = c.read(commentsProvider).comments.single;
      expect(row.body, SkifluxCommentBody.voicenote);
      expect(row.audioPath, '/tmp/note.m4a');
      expect(repo.voicePosts, [('ep-1', '/tmp/note.m4a')]);
    });

    test('local audioPath survives the post-upload reload', () async {
      final repo = _FakeCommentsRepository();
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      await c.read(commentsProvider.notifier).addVoiceNote('/tmp/keep.m4a');
      // Let the unawaited `_loadAndClaimNew` finish — previously this wiped
      // the recorder path and left only a remote URL (or nothing).
      await pumpEventQueue();

      final row = c.read(commentsProvider).comments.single;
      expect(row.body, SkifluxCommentBody.voicenote);
      expect(row.id, isNotNull);
      expect(row.audioPath, '/tmp/keep.m4a');
      expect(row.audioUrl, isNotNull);
    });

    test('reload without audio_url keeps a playable voicenote, not a blank',
        () async {
      // Regression: server echoed the comment as empty text (no audio_url) →
      // UI showed "0:10" then a blank bubble.
      final repo = _FakeCommentsRepository(voiceOmitsAudioUrl: true);
      final c = withRepo(repo);
      c.read(commentsProvider.notifier).init('ep-1');
      await pumpEventQueue();

      await c.read(commentsProvider.notifier).addVoiceNote('/tmp/blank-bug.m4a');
      await pumpEventQueue();

      final row = c.read(commentsProvider).comments.single;
      expect(row.body, SkifluxCommentBody.voicenote);
      expect(row.audioPath, '/tmp/blank-bug.m4a');
      expect(row.message, anyOf(isNull, isEmpty));
    });
  });
}

/// Records what the store asked for, and can fail on demand.
class _FakeCommentsRepository extends CommentsRepository {
  _FakeCommentsRepository({
    this.comments = const [],
    this.failPost = false,
    this.failLike = false,
    this.failVoice = false,
    this.voiceOmitsAudioUrl = false,
  }) : super(Dio());

  List<CommentItem> comments;
  bool failPost;
  bool failLike;
  bool failVoice;

  /// When true, the echoed voice comment has no `audio_url` — the blank-bubble
  /// regression the store must still keep playable via the local path.
  bool voiceOmitsAudioUrl;

  final List<String> loads = [];
  final List<(String, String)> posted = [];
  final List<(String, String)> voicePosts = [];
  final List<int> likeToggles = [];
  final List<(int, String)> replies = [];

  @override
  Future<Paginated<CommentItem>> getComments(
    String episodeId, {
    int limit = 50,
    int offset = 0,
  }) async {
    loads.add(episodeId);
    return Paginated(results: comments, count: comments.length);
  }

  @override
  Future<void> postComment(String episodeId, String text) async {
    if (failPost) throw Exception('rejected');
    posted.add((episodeId, text));
    // Echo like the real backend: the store refetches after a successful
    // post and expects the server to hold the new row.
    comments = [
      ...comments,
      CommentItem.fromJson(
        commentJson(id: 1000 + posted.length, first: 'You', last: '', text: text),
      ),
    ];
  }

  @override
  Future<CommentItem?> postVoiceComment(
    String episodeId,
    String audioFilePath,
  ) async {
    if (failVoice) throw Exception('rejected');
    voicePosts.add((episodeId, audioFilePath));
    // Echo like the real backend so reload + local-path merge can be tested.
    final created = CommentItem.fromJson(
      commentJson(
        id: 2000 + voicePosts.length,
        first: 'You',
        last: '',
        text: voiceOmitsAudioUrl ? null : null,
        audioUrl: voiceOmitsAudioUrl
            ? null
            : 'https://cdn.skiflux.test/note.m4a',
      ),
    );
    comments = [...comments, created];
    return created.copyWith(audioPath: audioFilePath);
  }

  @override
  Future<void> toggleCommentLike(int commentId) async {
    if (failLike) throw Exception('rejected');
    likeToggles.add(commentId);
  }

  @override
  Future<void> replyToComment(int commentId, String text) async {
    if (failPost) throw Exception('rejected');
    replies.add((commentId, text));
  }
}

