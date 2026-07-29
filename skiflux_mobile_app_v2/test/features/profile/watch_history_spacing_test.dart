/// Watch History's row rhythm.
///
/// The screen flattens its date sections and rows into one widget list and
/// feeds that to a plain `ListView.builder`, so every gap is a literal item.
/// That is easy to read and easy to lose — drop one `SizedBox` and two rows
/// share an edge with no error anywhere. These measure the laid-out rects
/// instead of trusting the list.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/library_episode.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/library_repository.dart';
import 'package:skiflux_mobile_app_v2/features/profile/library_episode_row.dart';
import 'package:skiflux_mobile_app_v2/features/profile/watch_history_screen.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

LibraryEpisode _episode(int i) => LibraryEpisode(
  id: 'ep-$i',
  title: 'Designing tokens that survive a rebrand, part $i',
  description: 'A description.',
  creatorName: 'Amara Design',
  creatorUsername: 'amara',
  creatorInitials: 'AD',
  order: i,
  durationSeconds: 600,
  viewCount: 22000,
);

/// Five entries across two days, so both the within-section gap and the
/// between-section gap are exercised.
List<WatchHistoryEntry> _entries() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < 3; i++)
      WatchHistoryEntry(
        episode: _episode(i + 1),
        watchDurationSeconds: 300,
        completed: false,
        viewedAt: now.subtract(Duration(hours: i + 1)),
      ),
    for (var i = 0; i < 2; i++)
      WatchHistoryEntry(
        episode: _episode(i + 4),
        watchDurationSeconds: 600,
        completed: true,
        viewedAt: now.subtract(Duration(days: 1, hours: i + 1)),
      ),
  ];
}

Future<void> _pump(WidgetTester tester, {double width = 393}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
      ],
      child: const MaterialApp(home: WatchHistoryScreen()),
    ),
  );
  // Discrete pumps: the loading state is a skeleton on a repeating ticker,
  // which `pumpAndSettle` would wait on forever.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  testWidgets('rows within a day never touch', (tester) async {
    await _pump(tester);

    final rows = find.byType(LibraryEpisodeRow);
    final count = tester.widgetList(rows).length;
    expect(count, 5);

    for (var i = 1; i < count; i++) {
      final gap =
          tester.getRect(rows.at(i)).top - tester.getRect(rows.at(i - 1)).bottom;
      expect(
        gap,
        greaterThanOrEqualTo(SkifluxSpacing.spaceL - 0.5),
        reason: 'rows ${i - 1} and $i are touching',
      );
    }
  });

  testWidgets('a new date heading is set off from the row above it', (
    tester,
  ) async {
    await _pump(tester);

    // The third row is the last of today; the fourth opens Yesterday. The
    // heading between them must clear both.
    final rows = find.byType(LibraryEpisodeRow);
    final lastToday = tester.getRect(rows.at(2));
    final heading = tester.getRect(find.text('Yesterday'));
    final firstYesterday = tester.getRect(rows.at(3));

    expect(heading.top, greaterThan(lastToday.bottom));
    expect(firstYesterday.top, greaterThan(heading.bottom));
  });

  testWidgets('nothing overflows at the narrowest supported width', (
    tester,
  ) async {
    await _pump(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}

class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository() : super(Dio());

  @override
  Future<List<WatchHistoryEntry>> getWatchHistory({
    bool? completed,
    int? pageSize,
    String? skillworld,
  }) async => _entries();
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore() : super(const FlutterSecureStorage());

  @override
  Future<bool> hasSession() async => true;
}
