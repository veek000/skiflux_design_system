import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/comments_store.dart';

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
        Expanded(
          child: ListView(
            children: [
              if (session.comments.isEmpty)
                const Text('No comments yet'),
              for (int i = 0; i < session.comments.length; i++)
                if (session.comments[i].message != null)
                  Text('[${session.comments[i].message}]',
                      key: Key('comment_$i')),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _textController),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.addMessage(_textController.text);
                _textController.clear();
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  group('Comments flow', () {
    testWidgets('sending a text comment appends it to the list',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _CommentsTestHarness()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial seeded comments: 2 message comments with the same text.
      // Own message [comment_0], other message [comment_1].
      expect(find.textContaining('[Hello, I need help tracking'),
          findsNWidgets(2));

      // Type a unique new comment.
      await tester.enterText(find.byType(TextField), 'My unique comment 42');
      await tester.pumpAndSettle();

      // Tap send.
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // New comment should appear in the list (now 3 message texts).
      expect(find.textContaining('My unique comment 42'), findsOneWidget);
    });

    testWidgets('empty message is not added', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _CommentsTestHarness()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Count initial comment texts (2 message comments).
      final initialCount =
          find.textContaining('[').evaluate().length;
      expect(initialCount, 2);

      // Tap send with empty text.
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // No new comment added — same count.
      expect(
        find.textContaining('[').evaluate().length,
        initialCount,
      );
    });
  });
}
