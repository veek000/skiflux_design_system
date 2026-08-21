import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

void main() {
  group('SkifluxComment message body', () {
    testWidgets('renders author name and handle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              message: 'Hello world',
            ),
          ),
        ),
      );
      expect(find.text('Amara Design'), findsOneWidget);
      expect(find.text('@amara'), findsOneWidget);
    });

    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              message: 'Hello world',
            ),
          ),
        ),
      );
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('onReply callback fires', (tester) async {
      var replied = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              message: 'Hello',
              onReply: () => replied = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reply'));
      expect(replied, isTrue);
    });

    testWidgets('onAuthorTap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              message: 'Hello',
              onAuthorTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Amara Design'));
      expect(tapped, isTrue);
    });
  });

  group('SkifluxComment voicenote body (decorative)', () {
    testWidgets('shows play button when voicenote without audioPath',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              body: SkifluxCommentBody.voicenote,
              timeLabel: '15min',
            ),
          ),
        ),
      );
      // Voicenote shows a play button.
      expect(find.byIcon(RemixIcons.play_mini_fill), findsOneWidget);
      // Duration label from fallback — unknown length is 0:00, never a fake 0:10.
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('play toggle callback fires', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              authorName: 'Amara Design',
              handle: '@amara',
              body: SkifluxCommentBody.voicenote,
              onPlayToggle: () => toggled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(RemixIcons.play_mini_fill));
      expect(toggled, isTrue);
    });
  });

  group('SkifluxComment own messages', () {
    testWidgets('shows Edit and Delete for own messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              author: SkifluxCommentAuthor.own,
              authorName: 'Me',
              handle: '@me',
              message: 'My message',
            ),
          ),
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('onEdit callback fires', (tester) async {
      var edited = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              author: SkifluxCommentAuthor.own,
              authorName: 'Me',
              handle: '@me',
              message: 'My message',
              onEdit: () => edited = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      expect(edited, isTrue);
    });

    testWidgets('onDelete callback fires', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              author: SkifluxCommentAuthor.own,
              authorName: 'Me',
              handle: '@me',
              message: 'My message',
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Delete'));
      expect(deleted, isTrue);
    });
  });

  group('SkifluxComment other messages', () {
    testWidgets('shows thumb up/down for others messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              author: SkifluxCommentAuthor.other,
              authorName: 'Other',
              handle: '@other',
              message: 'Their message',
            ),
          ),
        ),
      );
      expect(find.byIcon(RemixIcons.thumb_up_line), findsOneWidget);
      expect(find.byIcon(RemixIcons.thumb_down_line), findsOneWidget);
    });

    testWidgets('onThumbUp and onThumbDown fire', (tester) async {
      var liked = false;
      var disliked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComment(
              author: SkifluxCommentAuthor.other,
              authorName: 'Other',
              handle: '@other',
              message: 'Their message',
              onThumbUp: () => liked = true,
              onThumbDown: () => disliked = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(RemixIcons.thumb_up_line));
      expect(liked, isTrue);
      await tester.tap(find.byIcon(RemixIcons.thumb_down_line));
      expect(disliked, isTrue);
    });
  });
}
