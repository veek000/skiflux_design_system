/// The playlist page's episode list.
///
/// The rows used to touch. The list's header was spread across a fourteen-slot
/// index ladder inside `itemBuilder`, with every gap written by hand as its own
/// item — and the gaps *between the episodes* were simply never written, so
/// consecutive rows shared an edge. The header is one item now and the spacing
/// is set in one place; this pins that it stays there.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux/features/playlists/data/playlists_store.dart';
import 'package:skiflux/features/playlists/data/season_providers.dart';
import 'package:skiflux/features/playlists/data/seasons_repository.dart';
import 'package:skiflux/features/playlists/playlist_episode_row.dart';
import 'package:skiflux/features/playlists/playlist_screen.dart';

/// Three rows, so both gaps between them are measurable.
List<PlaylistEpisode> _episodes() => [
  for (var i = 1; i <= 3; i++)
    PlaylistEpisode(
      id: 'ep-$i',
      number: i,
      title: 'Designing tokens that survive a rebrand, part $i',
      duration: '12:40',
      coinCost: 0,
      state: PlaylistEpisodeState.unlocked,
      viewCount: 22000,
      createdAt: DateTime(2026, 7, i + 1),
    ),
];

Future<void> _pump(WidgetTester tester, {double width = 393}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        seasonsRepositoryProvider.overrideWithValue(_FakeSeasonsRepository()),
      ],
      // The screen is season-scoped now; the arg's display hints stand in for
      // the season detail endpoint the spec doesn't have.
      child: const MaterialApp(
        home: PlaylistScreen(
          season: SeasonArg(
            id: 'season-1',
            title: 'Design systems, end to end',
            creatorName: 'Amara Design',
          ),
        ),
      ),
    ),
  );
  // Discrete pumps: the loading state is a skeleton on a repeating ticker,
  // which `pumpAndSettle` would wait on forever.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  testWidgets('consecutive episode rows are a spaceL apart', (tester) async {
    await _pump(tester);

    final rows = find.byType(PlaylistEpisodeRow);
    expect(
      tester.widgetList(rows).length,
      greaterThan(1),
      reason: 'the gap can only be measured between two rows',
    );

    final rects = [
      for (var i = 0; i < tester.widgetList(rows).length; i++)
        tester.getRect(rows.at(i)),
    ];

    for (var i = 1; i < rects.length; i++) {
      expect(
        rects[i].top - rects[i - 1].bottom,
        closeTo(SkifluxSpacing.spaceL, 0.5),
        reason: 'rows $i and ${i - 1} are touching',
      );
    }
  });

  testWidgets('the first row clears the actions above it', (tester) async {
    await _pump(tester);

    // The header owns its own bottom gap through the first row's padding, so
    // an off-by-one in the item index would show up as the "Play all" button
    // sitting on the first episode.
    final actions = tester.getRect(find.text('Play all'));
    final first = tester.getRect(find.byType(PlaylistEpisodeRow).first);

    expect(first.top, greaterThanOrEqualTo(actions.bottom));
  });

  testWidgets('nothing overflows at the narrowest supported width', (
    tester,
  ) async {
    await _pump(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSeasonsRepository extends SeasonsRepository {
  _FakeSeasonsRepository() : super(Dio());

  @override
  Future<List<PlaylistEpisode>> getSeasonEpisodes(String seasonId) async =>
      _episodes();
}

