import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/leaderboard/data/leaderboard_repository.dart';
import 'package:skiflux/features/leaderboard/data/leaderboard_store.dart';
import 'package:skiflux/features/leaderboard/data/models/leaderboard_row.dart';
import 'package:skiflux/features/profile/data/models/user_profile.dart';
import 'package:skiflux/features/profile/data/profile_repository.dart';
import 'package:skiflux/shared/network/token_store.dart';

void main() {
  group('leaderboardProvider', () {
    ProviderContainer withRepo(
      _FakeLeaderboardRepository repo, {
      bool signedIn = true,
      UserProfile? me,
    }) {
      final c = ProviderContainer(
        // Riverpod 3 retries a failed build with backoff by default, which
        // would leave `.future` pending for the whole test.
        retry: (_, _) => null,
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
          profileRepositoryProvider.overrideWithValue(
            _FakeProfileRepository(me),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    LeaderboardRow row(
      int rank, {
      String? username,
      bool isCurrentUser = false,
    }) => LeaderboardRow(
      rank: rank,
      firstName: 'User',
      lastName: '$rank',
      username: username ?? 'user$rank',
      xp: 1000 - rank,
      isCurrentUser: isCurrentUser,
    );

    test('signed out resolves empty without calling the API', () async {
      final repo = _FakeLeaderboardRepository(const LeaderboardPage(rows: []));
      final c = withRepo(repo, signedIn: false);

      final data = await c.read(leaderboardProvider.future);
      expect(data.isEmpty, isTrue);
      expect(repo.levels, isEmpty);
    });

    test('exposes what the API returned — nothing is seeded', () async {
      final c = withRepo(
        _FakeLeaderboardRepository(
          LeaderboardPage(
            rows: [row(1), row(2)],
            myPosition: row(7, username: 'ghost'),
            totalCount: 100,
          ),
        ),
      );

      final data = await c.read(leaderboardProvider.future);
      // Rows from `results`, plus `my_position` appended so the learner is
      // visible when they rank below the page.
      expect(data.entries, hasLength(3));
      expect(data.entries.first.name, 'User 1');
      expect(data.entries.first.initials, 'U1');
      expect(data.entries.first.handle, '@user1');
      expect(
        data.entries.singleWhere((e) => e.isCurrentUser).username,
        'ghost',
      );
      expect(data.currentRank, 7);
      // Derived from rank 7 of 100, not sent.
      expect(data.betterThanPercent, 94);
    });

    test('a failed request surfaces as an error, not a sample cast', () async {
      final c = withRepo(_FakeLeaderboardRepository(null));

      await expectLater(
        c.read(leaderboardProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('the standing is null when nothing establishes it', () async {
      final c = withRepo(
        _FakeLeaderboardRepository(LeaderboardPage(rows: [row(1)])),
      );

      final data = await c.read(leaderboardProvider.future);
      // Not 0, and not a leftover constant: the payload omitted the standing,
      // no row is the user, and the profile carries no rank.
      expect(data.currentRank, isNull);
      expect(data.betterThanPercent, isNull);
    });

    test('an empty league clears the rankings', () async {
      final c = withRepo(
        _FakeLeaderboardRepository(const LeaderboardPage(rows: [])),
      );
      c.read(leaderboardLeagueProvider.notifier).select(1);

      final data = await c.read(leaderboardProvider.future);
      expect(data.entries, isEmpty);
      expect(data.podium, isEmpty);
      expect(data.ranked, isEmpty);
    });

    test('lowercases the league before sending it as level', () async {
      final repo = _FakeLeaderboardRepository(const LeaderboardPage(rows: []));
      final c = withRepo(repo);
      // Index 5 is "Professional".
      c.read(leaderboardLeagueProvider.notifier).select(5);

      await c.read(leaderboardProvider.future);
      expect(repo.levels, ['professional']);
      expect(repo.pageSizes, [50]);
    });

    test('the All pill sends no level filter', () async {
      final repo = _FakeLeaderboardRepository(const LeaderboardPage(rows: []));
      final c = withRepo(repo);

      await c.read(leaderboardProvider.future);
      expect(repo.levels, [null]);
    });

    test('podium tolerates a league with fewer than three learners', () async {
      final c = withRepo(
        _FakeLeaderboardRepository(LeaderboardPage(rows: [row(1), row(2)])),
      );

      final data = await c.read(leaderboardProvider.future);
      expect(data.podium, hasLength(2));
      expect(data.ranked, isEmpty);
    });
  });

  group('LeaderboardNotifier.resolve', () {
    LeaderboardRow row(
      int rank, {
      String? username,
      bool isCurrentUser = false,
      String currentLevel = '',
    }) => LeaderboardRow(
      rank: rank,
      firstName: 'User',
      lastName: '$rank',
      username: username ?? 'user$rank',
      xp: 1000 - rank,
      currentLevel: currentLevel,
      isCurrentUser: isCurrentUser,
    );

    UserProfile profile({
      String id = 'me',
      String username = 'me',
      int? rank,
      int xp = 0,
      String currentLevel = '',
    }) => UserProfile(
      id: id,
      username: username,
      rank: rank,
      xp: xp,
      currentLevel: currentLevel,
    );

    test('podium and table split by XP order, not by payload order', () {
      // The board arrives shuffled — nothing in the spec promises otherwise.
      // XP (via the test helper: 1000 - rank) decides 1st/2nd/3rd.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(rows: [row(5), row(2), row(4), row(1), row(3)]),
        null,
      );

      expect(data.entries.map((e) => e.rank), [1, 2, 3, 4, 5]);
      expect(data.podium.map((e) => e.rank), [1, 2, 3]);
      expect(data.podium.map((e) => e.username), ['user1', 'user2', 'user3']);
      // The table starts at 4th, which is the whole point of the split.
      expect(data.ranked.map((e) => e.rank), [4, 5]);
    });

    test('a league with fewer than three learners still splits correctly', () {
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(rows: [row(2), row(1)]),
        null,
      );

      expect(data.podium.map((e) => e.rank), [1, 2]);
      expect(data.ranked, isEmpty);
    });

    test('missing ranks are renumbered by XP so the podium fills', () {
      // `parseRow` defaults a missing rank to 0; that used to leave the podium
      // empty. Highest XP must still take 1st.
      final data = LeaderboardNotifier.resolve(
        const LeaderboardPage(
          rows: [
            LeaderboardRow(username: 'low', xp: 100),
            LeaderboardRow(username: 'high', xp: 900),
            LeaderboardRow(username: 'mid', xp: 500),
          ],
        ),
        null,
      );

      expect(data.podium.map((e) => e.username), ['high', 'mid', 'low']);
      expect(data.podium.map((e) => e.rank), [1, 2, 3]);
      expect(data.ranked, isEmpty);
    });

    test('podium follows XP when server ranks disagree with scores', () {
      final data = LeaderboardNotifier.resolve(
        const LeaderboardPage(
          rows: [
            LeaderboardRow(rank: 1, username: 'low', xp: 100),
            LeaderboardRow(rank: 2, username: 'high', xp: 900),
            LeaderboardRow(rank: 3, username: 'mid', xp: 500),
          ],
        ),
        null,
      );

      expect(data.podium.map((e) => e.username), ['high', 'mid', 'low']);
      expect(data.podium.map((e) => e.rank), [1, 2, 3]);
      expect(data.atPodiumPlace(1)?.username, 'high');
      expect(data.atPodiumPlace(2)?.username, 'mid');
      expect(data.atPodiumPlace(3)?.username, 'low');
    });

    test("marks the row the backend flagged as the user's", () {
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(rows: [row(1), row(2, isCurrentUser: true), row(3)]),
        null,
      );

      expect(data.entries[1].isCurrentUser, isTrue);
      expect(data.entries.where((e) => e.isCurrentUser), hasLength(1));
      // The flagged row's rank becomes the standing the pill shows.
      expect(data.currentRank, 2);
    });

    test('falls back to matching the profile username', () {
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [
            row(1),
            row(2, username: 'Me'),
            row(3),
          ],
        ),
        profile(username: '@me'),
      );

      // Case and a leading "@" are normalised off both sides.
      expect(data.entries[1].isCurrentUser, isTrue);
      expect(data.currentRank, 2);
    });

    test('matches the signed-in learner by id when username is empty', () {
      // Schema marks username nullable — id is the reliable key.
      final data = LeaderboardNotifier.resolve(
        const LeaderboardPage(
          rows: [
            LeaderboardRow(id: 'u-1', rank: 1, username: '', xp: 500),
            LeaderboardRow(id: 'u-me', rank: 2, username: '', xp: 400),
          ],
        ),
        profile(id: 'u-me', username: ''),
      );

      expect(data.entries.singleWhere((e) => e.isCurrentUser).id, 'u-me');
      expect(data.currentRank, 2);
    });

    test('prefers my_position over a username match for the standing', () {
      // `my_position` comes from the same query as the rows, so it outranks the
      // cached profile as the identity source.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [
            row(1),
            row(2, username: 'veek'),
            row(3),
          ],
          myPosition: row(2, username: '@Veek', currentLevel: 'Master'),
        ),
        profile(username: 'someone-else'),
      );

      expect(data.entries[1].isCurrentUser, isTrue);
      expect(data.currentRank, 2);
      expect(data.currentLevel, 'Master');
    });

    test('appends my_position when no row matches by identity', () {
      // League-filtered pages may omit the signed-in handle from `results`.
      // Append — never paint rank 3 as "you" just because the numbers match.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [row(1), row(2), row(3)],
          myPosition: row(3, username: 'ghost'),
        ),
        profile(username: 'nobody'),
      );

      expect(data.entries.where((e) => e.isCurrentUser), hasLength(1));
      expect(
        data.entries.singleWhere((e) => e.isCurrentUser).username,
        'ghost',
      );
      expect(data.currentRank, 3);
    });

    test('appends my_position when the rank falls outside the page', () {
      // The whole point of my_position being sent beside `results`.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [row(1), row(2)],
          myPosition: row(88, username: 'ghost'),
        ),
        null,
      );

      expect(data.entries.any((e) => e.isCurrentUser), isTrue);
      expect(data.entries.singleWhere((e) => e.isCurrentUser).rank, 88);
      expect(data.currentRank, 88);
    });

    test('stale profile.rank must not hijack another learner\'s row', () {
      // Regression: profile said #3 while the board's #3 was a 1k+ XP peer;
      // the signed-in user (~700 XP) never appeared as themselves.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [
            row(1, username: 'top'),
            row(2, username: 'second'),
            row(3, username: 'third'),
            row(4, username: 'veek'),
          ],
        ),
        profile(username: 'veek', rank: 3),
      );

      expect(data.entries.where((e) => e.isCurrentUser), hasLength(1));
      expect(data.entries.singleWhere((e) => e.isCurrentUser).username, 'veek');
      expect(data.entries[2].isCurrentUser, isFalse);
      // Username match on the board wins over the stale cached rank.
      expect(data.currentRank, 4);
    });

    test('standing pill matches the table rank, not a stale my_position', () {
      // Server standing said #12 while the XP-ordered board places the learner
      // at #4 — the pill / "better than N%" must follow the table.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [
            row(1, username: 'a'),
            row(2, username: 'b'),
            row(3, username: 'c'),
            row(4, username: 'veek'),
          ],
          myPosition: row(12, username: 'veek', currentLevel: 'Master'),
          totalCount: 100,
        ),
        profile(username: 'veek', rank: 12),
      );

      expect(data.entries.singleWhere((e) => e.isCurrentUser).rank, 4);
      expect(data.currentRank, 4);
      // Rank 4 of 100 → (100-4)/(100-1) ≈ 97%.
      expect(data.betterThanPercent, 97);
      expect(data.currentLevel, 'Master');
    });
    test('when ranks are renumbered by XP, the pill uses the new place', () {
      final data = LeaderboardNotifier.resolve(
        const LeaderboardPage(
          rows: [
            LeaderboardRow(rank: 1, username: 'low', xp: 100),
            LeaderboardRow(rank: 2, username: 'high', xp: 900),
            LeaderboardRow(
              rank: 3,
              username: 'me',
              xp: 500,
              isCurrentUser: true,
            ),
          ],
          myPosition: LeaderboardRow(
            rank: 3,
            username: 'me',
            xp: 500,
            currentLevel: 'Novice',
          ),
          totalCount: 3,
        ),
        null,
      );

      // XP order: high, me, low → places 1, 2, 3 after renumber.
      expect(data.currentRank, 2);
      expect(data.betterThanPercent, 50);
      expect(data.atPodiumPlace(2)?.isCurrentUser, isTrue);
    });

    test(
      'synthesizes a self row from the profile when the board omits you',
      () {
        final data = LeaderboardNotifier.resolve(
          LeaderboardPage(rows: [row(1)]),
          profile(
            id: 'me-id',
            username: 'nobody',
            rank: 31,
            xp: 220,
            currentLevel: 'Novice',
          ),
        );

        // Must appear as yourself — never leave the board without the learner.
        expect(data.entries.where((e) => e.isCurrentUser), hasLength(1));
        expect(
          data.entries.singleWhere((e) => e.isCurrentUser).username,
          'nobody',
        );
        // Pill keeps the profile's global standing.
        expect(data.currentRank, 31);
        expect(data.currentLevel, 'Novice');
        // And must not re-flag the unrelated #1 as you.
        expect(data.entries.first.isCurrentUser, isFalse);
      },
    );

    test('derives better-than-percent from the rank — no field carries it', () {
      // Rank 3 of 5 beats 2 of the other 4 → 50%.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [row(1), row(2), row(3), row(4), row(5)],
          myPosition: row(3, username: 'ghost'),
          totalCount: 5,
        ),
        null,
      );

      expect(data.betterThanPercent, 50);
    });

    test('the percentage is against the population, not the page', () {
      // The regression this fix exists for: 501st of 5,000 is better than 90%,
      // where computing it over the 3 loaded rows would have said otherwise.
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [row(1), row(2), row(3)],
          myPosition: row(501, username: 'ghost'),
          totalCount: 5000,
        ),
        null,
      );

      expect(data.betterThanPercent, 90);
    });

    test('never invents a percentage from an unusable rank', () {
      int? percentOf(LeaderboardPage page) =>
          LeaderboardNotifier.resolve(page, null).betterThanPercent;

      // No total: a bare-array body knows the page size, not the population.
      expect(
        percentOf(
          LeaderboardPage(
            rows: [row(1)],
            myPosition: row(4, username: 'g'),
          ),
        ),
        isNull,
      );
      // Rank past the population.
      expect(
        percentOf(
          LeaderboardPage(
            rows: [row(1)],
            myPosition: row(40, username: 'g'),
            totalCount: 10,
          ),
        ),
        isNull,
      );
      // Nobody to be better than.
      expect(
        percentOf(
          LeaderboardPage(
            rows: [row(1)],
            myPosition: row(1, username: 'g'),
            totalCount: 1,
          ),
        ),
        isNull,
      );
    });

    test('currentIndexInRanked is relative to the rows below the podium', () {
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(
          rows: [row(1), row(2), row(3), row(4), row(5, isCurrentUser: true)],
        ),
        null,
      );

      // Rank 5 is the 2nd row of the rank card, the podium holding 1–3.
      expect(data.currentIndexInRanked, 1);
    });

    test('currentIndexInRanked is -1 when the user is on the podium', () {
      final data = LeaderboardNotifier.resolve(
        LeaderboardPage(rows: [row(1, isCurrentUser: true), row(2), row(3)]),
        null,
      );

      expect(data.currentIndexInRanked, -1);
    });

    test('xpLabel formats thousands', () {
      final data = LeaderboardNotifier.resolve(
        const LeaderboardPage(
          rows: [LeaderboardRow(rank: 1, username: 'lola', xp: 4820)],
        ),
        null,
      );

      expect(data.entries.single.xpLabel, '4,820');
    });
  });

  group('LeaderboardRepository.parseBody', () {
    test('reads the documented LeaderboardResponse', () {
      // Shape per the spec's `LeaderboardResponse` / `UserLeaderboardEntry`.
      final page = LeaderboardRepository.parseBody({
        'count': 128,
        'next': null,
        'previous': null,
        'my_position': {
          'id': 'user-veek',
          'rank': 12,
          'first_name': 'Veek',
          'last_name': 'O',
          'username': 'veek',
          'xp': 2450,
          'current_level': 'Master',
          'tasks_done': 8,
          'coins': '540.00',
          'is_me': true,
        },
        'results': [
          {
            'id': 'user-lola',
            'rank': 1,
            'first_name': 'Lola',
            'last_name': 'Motion',
            'username': 'lolamotion',
            'avatar_url': 'https://cdn/lola.png',
            'current_level': 'Professional',
            'xp': 4820,
            'is_me': false,
          },
        ],
      });

      expect(page.totalCount, 128);
      expect(page.myPosition?.id, 'user-veek');
      expect(page.myPosition?.rank, 12);
      expect(page.myPosition?.currentLevel, 'Master');
      expect(page.myPosition?.isCurrentUser, isTrue);
      expect(page.rows.single.id, 'user-lola');
      expect(page.rows.single.displayName, 'Lola Motion');
      expect(page.rows.single.initials, 'LM');
      expect(page.rows.single.avatarUrl, 'https://cdn/lola.png');
      expect(page.rows.single.currentLevel, 'Professional');
      expect(page.rows.single.xp, 4820);
    });

    test('parses XP aliases and comma-formatted strings', () {
      final page = LeaderboardRepository.parseBody([
        {'rank': 1, 'username': 'a', 'total_xp': '4,820'},
        {'rank': 2, 'username': 'b', 'score': 100},
      ]);

      expect(page.rows.first.xp, 4820);
      expect(page.rows.last.xp, 100);
    });

    test('reads a bare array, with no standing and no total', () {
      final page = LeaderboardRepository.parseBody([
        {'rank': 1, 'username': 'solo', 'xp': 10},
      ]);

      expect(page.rows, hasLength(1));
      expect(page.myPosition, isNull);
      expect(page.totalCount, isNull);
    });

    test('unwraps a data envelope', () {
      final page = LeaderboardRepository.parseBody({
        'data': {
          'count': 9,
          'my_position': {'rank': 4, 'username': 'a'},
          'results': [
            {'rank': 1, 'username': 'a', 'xp': 1},
          ],
        },
      });

      expect(page.rows, hasLength(1));
      expect(page.myPosition?.rank, 4);
      expect(page.totalCount, 9);
    });

    test('finds rows under an alias key', () {
      final page = LeaderboardRepository.parseBody({
        'leaderboard': [
          {'rank': 1, 'username': 'a', 'xp': 1},
        ],
      });

      expect(page.rows, hasLength(1));
    });

    test('an unreadable body yields no rows rather than throwing', () {
      final page = LeaderboardRepository.parseBody({'unexpected': true});
      expect(page.rows, isEmpty);
      expect(page.myPosition, isNull);
    });

    test('a count sent as a numeric string still reads', () {
      final page = LeaderboardRepository.parseBody({
        'count': '128',
        'results': const [],
      });
      expect(page.totalCount, 128);
    });
  });

  group('LeaderboardRepository.parseRow', () {
    test('splits a single name field on the first space', () {
      final row = LeaderboardRepository.parseRow({
        'rank': 2,
        'full_name': 'Kojo Adjei Sketches',
        'username': '@kojosketch',
      });

      expect(row.firstName, 'Kojo');
      expect(row.lastName, 'Adjei Sketches');
      expect(row.displayName, 'Kojo Adjei Sketches');
      // The handle's "@" is added by the entry, not carried in the field.
      expect(row.username, 'kojosketch');
    });

    test('merges a nested user object with flat rank and xp', () {
      final row = LeaderboardRepository.parseRow({
        'rank': 5,
        'total_xp': 3760,
        'user': {
          'first_name': 'Uche',
          'last_name': 'Draws',
          'username': 'uche',
        },
      });

      expect(row.rank, 5);
      expect(row.xp, 3760);
      expect(row.displayName, 'Uche Draws');
    });

    test('falls back to the username for name and initials', () {
      final row = LeaderboardRepository.parseRow({'username': 'solo'});
      expect(row.displayName, 'solo');
      expect(row.initials, 'S');
    });

    test('a row with nothing usable still parses', () {
      final row = LeaderboardRepository.parseRow(const {});
      expect(row.rank, 0);
      expect(row.xp, 0);
      expect(row.initials, '?');
    });

    test('reads current_level, which drives the league label', () {
      expect(
        LeaderboardRepository.parseRow({
          'username': 'a',
          'current_level': 'Master',
        }).currentLevel,
        'Master',
      );
      // Absent rather than guessed when the row omits it.
      expect(
        LeaderboardRepository.parseRow({'username': 'a'}).currentLevel,
        '',
      );
    });

    test('reads the "this is you" flag under any of its likely names', () {
      for (final key in const [
        'is_current_user',
        'is_me',
        'is_self',
        'is_you',
      ]) {
        expect(
          LeaderboardRepository.parseRow({
            'username': 'a',
            key: true,
          }).isCurrentUser,
          isTrue,
          reason: key,
        );
      }
      // A truthy string or number counts; an absent flag does not.
      expect(
        LeaderboardRepository.parseRow({'is_me': 'true'}).isCurrentUser,
        isTrue,
      );
      expect(
        LeaderboardRepository.parseRow({'is_me': 1}).isCurrentUser,
        isTrue,
      );
      expect(
        LeaderboardRepository.parseRow({'username': 'a'}).isCurrentUser,
        isFalse,
      );
    });
  });
}

/// Returns [page], or throws when it is null (the offline path). Records the
/// query values so the league filter can be asserted.
class _FakeLeaderboardRepository extends LeaderboardRepository {
  _FakeLeaderboardRepository(this.page) : super(Dio());

  final LeaderboardPage? page;
  final List<String?> levels = [];
  final List<int?> pageSizes = [];

  @override
  Future<LeaderboardPage> getLeaderboard({
    String? level,
    int? pageSize,
    String? search,
  }) async {
    levels.add(level);
    pageSizes.add(pageSize);
    final value = page;
    if (value == null) throw Exception('offline');
    return value;
  }
}

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}

/// Backs `meProfileProvider`, which the store consults to work out which row is
/// the signed-in learner's.
class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(this.profile) : super(Dio());

  final UserProfile? profile;

  @override
  Future<UserProfile> getProfile() async {
    final value = profile;
    if (value == null) throw Exception('no profile');
    return value;
  }
}
