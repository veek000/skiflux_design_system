/// The top-three podium columns.
///
/// Two things have gone wrong here in turn, so both are pinned. The XP line
/// once overlapped the podium steps; moving the labels *above* the avatar fixed
/// that but read as wrong — the name belongs under the face it names. The
/// column is now bottom-anchored to its step and stacks avatar → name → XP
/// downward, which satisfies both at once: the labels are under the avatar, and
/// because the anchor is the step's own surface they cannot grow down onto it
/// whatever the text metrics do at a given width.
///
/// The third failure is height rather than width: on a short screen the podium
/// and the rank card were each sized independently, so the card was asked for a
/// negative height and the columns ran up into the standing pill above them.
/// The short-viewport cases below are that one.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux_mobile_app_v2/features/leaderboard/data/leaderboard_repository.dart';
import 'package:skiflux_mobile_app_v2/features/leaderboard/data/models/leaderboard_row.dart';
import 'package:skiflux_mobile_app_v2/features/leaderboard/leaderboard_screen.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/models/user_profile.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/profile_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

/// The cast the screen is laid out against. Nothing is seeded in the app any
/// more, so the layout's fixtures live here — with the longest name the design
/// allows, since the column's width is what makes a label wrap.
LeaderboardRow _row(int rank, {String first = 'Lola', String last = 'Motion'}) =>
    LeaderboardRow(
      rank: rank,
      firstName: first,
      lastName: last,
      username: 'learner$rank',
      xp: 5000 - rank * 100,
    );

final _page = LeaderboardPage(
  rows: [
    _row(1, first: 'Oluwaseun', last: 'Adebayo-Fashola'),
    _row(2, first: 'Kojo', last: 'Sketches'),
    _row(3, first: 'Amara', last: 'Design'),
    for (var rank = 4; rank <= 12; rank++) _row(rank),
  ],
  myPosition: _row(12),
  // 12 rows loaded out of a 128-learner board — the gap is deliberate, so the
  // standing pill's percentage is computed against the population rather than
  // the page.
  totalCount: 128,
);

/// The podium entries, in place order, as the screen derives them.
List<LeaderboardRow> get _podiumRows => _page.rows.take(3).toList();

/// "4,900" — the label the screen prints, formatted the same way.
String _xpLabel(int xp) {
  final digits = '$xp';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '$buffer';
}

/// Mounts the screen at [width] × [height] logical pixels.
///
/// Both axes matter and for different reasons: the podium's geometry scales
/// with the width while the type inside a column does not, and the height is
/// what decides whether the podium and the rank card can both have the room
/// they want.
Future<void> _pumpAt(
  WidgetTester tester,
  double width, {
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        leaderboardRepositoryProvider.overrideWithValue(
          _FakeLeaderboardRepository(_page),
        ),
        tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      ],
      child: const MaterialApp(home: LeaderboardScreen()),
    ),
  );

  // Discrete pumps rather than `pumpAndSettle`: the loading state shimmers on a
  // repeating ticker, which never settles. Each pump flushes one round of the
  // provider's awaits.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

/// The laid-out rect of whatever [finder] matches.
///
/// Named only to keep the assertions below readable — they are all comparisons
/// between two rects, and the wrapping made them hard to scan.
Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The surface each podium column stands on, as a y in the 216-tall viewBox of
/// `assets/badges/podium.svg`: the top of 1st's block, and the back edge of the
/// top face on 2nd's and 3rd's. Podium-order, so index == place - 1.
const _stepTops = <double>[22.2031, 48.7402, 73.6758];

void main() {
  // 320 is the narrowest supported phone; 568 and 480 are the short viewports
  // that used to drive the rank card to a negative height.
  const viewports = <({double width, double height})>[
    (width: 320, height: 800),
    (width: 393, height: 852),
    (width: 430, height: 932),
    (width: 320, height: 568),
    (width: 393, height: 480),
  ];

  for (final view in viewports) {
    final label = '${view.width.toInt()}×${view.height.toInt()}';

    group('podium at $label', () {
      testWidgets('name and XP sit under the avatar', (tester) async {
        await _pumpAt(tester, view.width, height: view.height);

        for (final row in _podiumRows) {
          final avatar = find.ancestor(
            of: find.text(row.initials),
            matching: find.byType(SkifluxAvatar),
          );
          expect(avatar, findsOneWidget, reason: '${row.displayName}: 1 avatar');

          // The top three appear again in the rank table below, which is built
          // in order — so the first match for each string is the podium's.
          final avatarRect = _rectOf(tester, avatar);
          final nameRect = _rectOf(tester, find.text(row.displayName).first);
          final xpRect = _rectOf(
            tester,
            find.text('${_xpLabel(row.xp)} XP').first,
          );

          expect(
            nameRect.top,
            greaterThanOrEqualTo(avatarRect.bottom),
            reason: '${row.displayName}: the name must be below the avatar',
          );
          expect(
            xpRect.top,
            greaterThanOrEqualTo(nameRect.bottom),
            reason: '${row.displayName}: the XP must be below the name',
          );
        }
      });

      testWidgets('the labels clear the step they stand on', (tester) async {
        await _pumpAt(tester, view.width, height: view.height);

        // The check the other two miss. Overlapping the step is not an
        // overflow and does not move a label out from under its avatar, so
        // both of those passed while the XP line was printed across the step
        // it was standing on. This measures the step itself: the SVG's own
        // rect, mapped through its viewBox.
        final svg = _rectOf(tester, find.byType(SvgPicture));
        final unit = svg.height / 216;

        for (var i = 0; i < _podiumRows.length; i++) {
          final row = _podiumRows[i];
          final stepTop = svg.top + _stepTops[i] * unit;
          final xpRect = _rectOf(
            tester,
            find.text('${_xpLabel(row.xp)} XP').first,
          );

          expect(
            xpRect.bottom,
            lessThanOrEqualTo(stepTop),
            reason: '${row.displayName}: the XP line is printed on the step',
          );
        }
      });

      testWidgets('the crown clears the top of the podium', (tester) async {
        await _pumpAt(tester, view.width, height: view.height);

        // The podium is a Stack that clips, so a column with too little
        // headroom is not an overflow error — it is a silently shaved crown.
        // `getRect` reports layout, not what survived the clip, so this
        // compares the two directly. The crowned column is the tallest and
        // the crown overhangs its avatar, so it is the binding case.
        final stack = find
            .ancestor(of: find.byType(SvgPicture), matching: find.byType(Stack))
            .first;
        final crown = find.byIcon(RemixIcons.vip_crown_fill);
        expect(crown, findsOneWidget);

        expect(
          _rectOf(tester, crown).top,
          greaterThanOrEqualTo(_rectOf(tester, stack).top),
          reason: 'the column rises further than _Podium.columnRiseFor allows',
        );
      });

      testWidgets('the podium clears the standing pill above it', (
        tester,
      ) async {
        await _pumpAt(tester, view.width, height: view.height);

        // The pill is laid out above the podium in a Column, so an
        // over-tall podium does not overlap it — it pushes the whole group
        // down and off the bottom instead. Either way the pill's own text
        // must still be fully on screen and unclipped.
        final pill = _rectOf(
          tester,
          find.textContaining('better than', findRichText: true),
        );
        final crown = _rectOf(tester, find.byIcon(RemixIcons.vip_crown_fill));

        expect(
          crown.top,
          greaterThanOrEqualTo(pill.bottom),
          reason: 'the 1st-place column overlaps the standing pill',
        );
      });

      testWidgets('the rank card keeps a usable height', (tester) async {
        await _pumpAt(tester, view.width, height: view.height);

        // The regression this pins: the card's top was computed from the
        // podium's natural height, so on a short screen it was positioned
        // below its own bottom edge.
        //
        // The card yields before the podium does, so on a short viewport it
        // shows fewer rows rather than the podium collapsing. Past the card's
        // floor the whole board scrolls, which puts the header below the fold —
        // legitimately, so scroll to it first and then hold it to the same bar.
        // Measured as laid-out height, not as position within the viewport.
        // Once the board is allowed to scroll on a very short window, "how far
        // is the header from the bottom of the screen" stops describing
        // anything — the card can be perfectly tall and still start below the
        // fold. Its own rect is the thing that has to stay usable.
        final header = _rectOf(tester, find.text('RANK'));
        final list = _rectOf(tester, find.byType(ListView));

        expect(
          list.bottom - header.top,
          greaterThanOrEqualTo(LeaderboardScreen.minRankCardFloor),
          reason: 'the rank card was squeezed past its floor',
        );
        expect(
          list.height,
          greaterThan(0),
          reason: 'the rank card has no room for a single row',
        );
      });

      testWidgets('the podium is not collapsed to fit the card', (
        tester,
      ) async {
        await _pumpAt(tester, view.width, height: view.height);

        // The failure this pins is the one that put the 1st-place XP line on
        // top of the podium art. The podium used to scale by whatever was left
        // after reserving 200px for the rank card — unclamped that resolved to
        // roughly a *tenth* of full size on a 480-tall window, and even once
        // clamped to 0.72 the labels closed the gap onto the step.
        //
        // The podium now never scales at all: the rank table shrinks, and past
        // its floor the whole board scrolls. So this is an equality, not a
        // tolerance. Measured against the art's own width, because the SVG
        // fills the width it is given — a scaled podium is a narrow one.
        final svg = _rectOf(tester, find.byType(SvgPicture));
        final available = view.width - SkifluxSpacing.spaceL * 2;

        expect(
          svg.width,
          moreOrLessEquals(available, epsilon: 0.5),
          reason: 'the podium was scaled down to make room for the rank card',
        );
      });

      testWidgets('nothing overflows', (tester) async {
        // A RenderFlex overflow would surface as a test failure here; the
        // explicit pump keeps the assertion honest if that ever changes.
        await _pumpAt(tester, view.width, height: view.height);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the standing pill shows the rank the API returned', (
    tester,
  ) async {
    await _pumpAt(tester, 393);

    // The "#12" used to be a constant in a seeded cast; it now comes from the
    // payload's `my_position`.
    expect(find.text('#12'), findsOneWidget);
    // Derived — no field carries it. 12th of 128 beats 116 of the other 127.
    expect(
      find.text('You are doing better than 91% of other participants'),
      findsOneWidget,
    );
  });

  testWidgets("highlights the signed-in learner's own row", (tester) async {
    await _pumpAt(tester, 393);

    // `_FakeProfileRepository` is learner12, which the payload also ranks 12.
    final row = find.ancestor(
      of: find.text('@learner12'),
      matching: find.byType(Container),
    );
    final highlighted = tester
        .widgetList<Container>(row)
        .where(
          (c) =>
              (c.decoration as BoxDecoration?)?.color ==
              SkifluxColors.backgroundSelected,
        );

    // The XP chip carries the same tint but is a sibling of the handle, not an
    // ancestor of it — so this can only be the row's own highlight.
    expect(highlighted, isNotEmpty);
  });
}

class _FakeLeaderboardRepository extends LeaderboardRepository {
  _FakeLeaderboardRepository(this.page) : super(Dio());

  final LeaderboardPage page;

  @override
  Future<LeaderboardPage> getLeaderboard({
    String? level,
    int? pageSize,
    String? search,
  }) async => page;
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore() : super(const FlutterSecureStorage());

  @override
  Future<bool> hasSession() async => true;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(Dio());

  @override
  Future<UserProfile> getProfile() async =>
      const UserProfile(id: 'me', username: 'learner12', rank: 12);
}
