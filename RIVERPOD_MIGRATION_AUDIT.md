# Riverpod migration audit (verification only — no fixes)

**Date:** 2026-07-19  
**Scope:** `c:\Users\timmy\skiflux\skiflux_mobile_app_v2`  
**Method:** Verified against actual code, not Session Log claims.  
**Mode:** Report findings only — no fixes applied.

---

## PART 1 — Dependency and setup

| Check | Result |
|--------|--------|
| `flutter_riverpod` in `pubspec.yaml` | **YES** — line 30: `flutter_riverpod: ^3.3.2` |
| `pubspec.lock` resolves | **YES** — `flutter_riverpod` direct main, version **3.3.2** |
| `ProviderScope` at app root | **YES** — `lib/main.dart` lines 8–11 |

```dart
// lib/main.dart:8-11
runApp(
  const ProviderScope(
    child: SkifluxMobileAppV2(),
  ),
);
```

Also: `test/widget_test.dart` wraps `SkifluxMobileAppV2` in `ProviderScope`.

---

## PART 2 — Pass 1: notifications, leaderboard, streaks

### Store files (still present — not dead)

| File | Status |
|------|--------|
| `lib/features/notifications/data/notifications_store.dart` | **Active** Riverpod: `NotifierProvider` → `notificationsProvider` (≈L195–197) |
| `lib/features/leaderboard/data/leaderboard_store.dart` | **Active** Riverpod: `Provider` → `leaderboardProvider` (≈L185) |
| `lib/features/streaks/data/streaks_store.dart` | **Active** Riverpod: `NotifierProvider` → `streaksProvider` (≈L195) |

No remaining `ChangeNotifier` / `instance` singletons in these files (only comments referring to the old pattern).

### Screen consumption (quoted)

**notifications_screen.dart**

```dart
// L35-51
class NotificationsScreen extends ConsumerStatefulWidget { ... }
final all = ref.watch(notificationsProvider);
final notifier = ref.read(notificationsProvider.notifier);
// L221 (_NotificationCard)
ref.read(notificationsProvider.notifier).markRead(notification),
```

**leaderboard_screen.dart**

```dart
// L16-32
class LeaderboardScreen extends ConsumerStatefulWidget { ... }
final board = ref.watch(leaderboardProvider);
```

**streak_screen.dart**

```dart
// L17-50
class StreakScreen extends ConsumerStatefulWidget { ... }
ref.read(streaksProvider.notifier).consumeCelebration()  // L36
final streaks = ref.watch(streaksProvider);               // L50
```

**week_picker_sheet.dart**

```dart
// L30-55
class _WeekPickerSheet extends ConsumerStatefulWidget { ... }
final streaks = ref.watch(streaksProvider);
```

**milestone_sheet.dart**

```dart
// L23-28
class _MilestoneSheet extends ConsumerWidget { ... }
final streaks = ref.watch(streaksProvider);
```

### setState in Pass 1 files

| Location | Classification |
|----------|----------------|
| `notifications_screen.dart:85` `_tabIndex` | **Local UI** (tab selection) |
| `leaderboard_screen.dart:111` `_leagueIndex` | **Local UI** (demo league pill only) |
| `streak_screen.dart:45` `_week` | **Local UI** (selected week in session; catalog is provider) |
| `week_picker_sheet.dart:106,153` `_month` / `_selected` | **Local UI** (picker draft until Apply) |

No Pass 1 `setState` holding shared catalog / mark-read / celebration flag.

**Pass 1 verdict:** Migrated cleanly.

---

## PART 3 — Pass 2: playlists, search, subscriptions

### Store files (active Riverpod)

| File | Provider |
|------|----------|
| `playlists/data/playlists_store.dart` | `playlistsProvider` (≈L214), `playerPrefsProvider` (≈L266) |
| `search/data/search_index.dart` | `searchIndexProvider` (≈L238) |
| `search/data/recent_searches_store.dart` | `recentSearchesProvider` AsyncNotifier (≈L118) |
| `subscriptions/data/subscriptions_store.dart` | `subscriptionsProvider` (≈L310) |

### Screens that do consume Riverpod (quoted)

**playlist_screen.dart**

```dart
// L14-27
class PlaylistScreen extends ConsumerStatefulWidget { ... }
final pl = ref.watch(playlistsProvider).defaultPlaylist;
```

**playlist_menu_sheet.dart**

```dart
// L20-25
class _PlaylistMenuSheet extends ConsumerWidget { ... }
final pl = ref.watch(playlistsProvider).defaultPlaylist;
```

**search_screen.dart**

```dart
// L23-49, 56, 103
class SearchScreen extends ConsumerStatefulWidget { ... }
final index = ref.read(searchIndexProvider);
await ref.read(recentSearchesProvider.notifier).add(...);
final recentsAsync = ref.watch(recentSearchesProvider);
```

**subscriptions_screen.dart**

```dart
// L23-35, 88, 376, 538-541
class SubscriptionsBody extends ConsumerStatefulWidget { ... }
final creators = ref.watch(subscriptionsProvider).creators;
ref.watch(subscriptionsProvider).feed(filter: _filter);
// EpisodePlayerSheet:
final prefs = ref.watch(playerPrefsProvider);
ref.watch(subscriptionsProvider).creatorOf(episode).name;
```

**subscription_widgets.dart**

```dart
// L87-101, 181-193
final newCount = ref.watch(subscriptionsProvider).newCountFor(creator);
final creator = ref.watch(subscriptionsProvider).creatorOf(episode);
```

**all_subscriptions_screen.dart**

```dart
// L16-46
final notifier = ref.read(subscriptionsProvider.notifier);
ref.watch(subscriptionsProvider).sortedCreators(_sort)...
```

### Pass 2 files that do not consume Riverpod

| File | Notes |
|------|--------|
| **playlist_description_sheet.dart** | `StatelessWidget`; takes `Playlist playlist` prop. Imports `playlists_store` for **types only**. No `ref` — OK if parent already watched provider. |
| **search_results_screen.dart** | Plain `StatefulWidget`. Results passed in constructor; no provider. Only `setState` for tab index. |
| **search_result_widgets.dart** | Presentational only; models from data files. No Riverpod. |
| **filter_sheet.dart** | Presentational sheets; enums from store file. No `ref`. |

### Home sheets + profile (Pass 2 log claims) — verified

**episode_unlock_sheet.dart**

```dart
// L21-39, 211
class _EpisodeUnlockSheet extends ConsumerStatefulWidget { ... }
final store = ref.watch(playlistsProvider);
ref.read(playlistsProvider.notifier).tryUnlock(ep.id);
```

**more_menu_sheet.dart**

```dart
// L22-28, 157
class _MoreMenuSheet extends ConsumerWidget { ... }
final prefs = ref.watch(playerPrefsProvider);
final tasks = ref.read(tasksProvider).learning;  // also tasks (Pass 3)
```

**playback_speed_sheet.dart**

```dart
// L19-30
class _PlaybackSpeedSheet extends ConsumerWidget { ... }
final prefs = ref.watch(playerPrefsProvider);
final notifier = ref.read(playerPrefsProvider.notifier);
```

**profile_screen.dart**

```dart
// L17, 110-111, 161
class ProfileScreen extends ConsumerStatefulWidget { ... }
ref.watch(playlistsProvider).defaultPlaylist.episodes.take(4);
ref.watch(playlistsProvider).defaultPlaylist;
```

**my_profile_screen.dart**

```dart
// L29-35, 92-97
class MyProfileBody extends ConsumerWidget { ... }
final subs = ref.watch(subscriptionsProvider);
final streak = ref.watch(streaksProvider).streak;  // also Pass 1
```

### setState Pass 2 — classification

| Location | Classification |
|----------|----------------|
| `search_screen.dart:49` `_results = index.search(query)` | **Local UI / ephemeral query** (index is provider; live results intentionally not stored) |
| `search_results_screen.dart:85` `_tab` | **Local UI** |
| `playlist_screen.dart:181,193` `_liked` / `_saved` | **Local UI** |
| `subscriptions_screen.dart:114` `_filter` | **Local UI** (filter choice for feed) |
| `subscriptions_screen.dart:94,404` `setState(() {})` onRefresh | **Smell** — empty rebuild; with `ref.watch` often unnecessary. Not unmigrated store state. |
| `subscriptions_screen.dart:603` scrubber `_progress` | **Local UI** |
| `all_subscriptions_screen.dart:68,135` `_query` / `_sort` | **Local UI** |
| `episode_unlock_sheet.dart:206+` phase / busy | **Local UI** (sheet flow) |
| `profile_screen.dart:59,78,93,135,305` subscribe/notify/tabs/pills | **Local UI** (demo toggles not in any store) |

---

## PART 4 — Pass 3: tasks

### Store

`lib/features/tasks/data/tasks_store.dart` → **active** `tasksProvider` (`NotifierProvider`, ≈L515). Not dead.

### Consumption (quoted)

| File | Evidence |
|------|----------|
| `tasks_screen.dart` | `ConsumerStatefulWidget`; `ref.watch(tasksProvider)` ≈L32; `ref.read(...notifier)` ≈L33 |
| `submission_task_screen.dart` | `ConsumerStatefulWidget`; `ref.read(tasksProvider).byId` ≈L29; `markInReview` ≈L95 |
| `quiz_intro_screen.dart` | `ConsumerWidget`; `ref.watch(tasksProvider).byId(taskId)` ≈L18 |
| `quiz_assessment_screen.dart` | `ConsumerStatefulWidget`; `ref.read(tasksProvider)` ≈L42; `recordQuizResult` ≈L103 |
| `quiz_result_screen.dart` | `ConsumerWidget`; `ref.watch(tasksProvider).byId(taskId)` ≈L30 |

### task_shared_widgets.dart — GAP

Still uses the Pass 2 workaround, **not** standard `Consumer`/`ref` for subscriptions:

```dart
// task_shared_widgets.dart:135-140
void openTaskEpisode(BuildContext context, LearningTask task) {
  ...
  final subs = ProviderScope.containerOf(context).read(subscriptionsProvider);
```

- Does **not** use `tasksProvider` (task is passed in).
- Still a non-idiomatic provider read vs Consumer/ref.
- File imports Riverpod only for this workaround.

### tasks setState

| Location | Classification |
|----------|----------------|
| `tasks_screen.dart:49,57,64` segment/filter | **Local UI** |
| `quiz_assessment_screen.dart:57,76,83` timer/answers/index | **Local attempt state** (correct to stay local per Pass 3 design) |
| `submission_task_screen.dart:83,176,184,192` file/method/link | **Local form state** |

### Minor incompleteness

`submission_task_screen.dart` uses `ref.read` for task in getter (≈L29), not `ref.watch` — UI won’t auto-rebuild if task mutates while screen is open (usually OK after submit+pop).

---

## PART 5 — Cross-check

### All `*_store.dart` under `lib/features/`

| File | Dead? |
|------|--------|
| `notifications_store.dart` | **No** — `notificationsProvider` |
| `leaderboard_store.dart` | **No** — `leaderboardProvider` |
| `streaks_store.dart` | **No** — `streaksProvider` |
| `playlists_store.dart` | **No** — playlists + playerPrefs |
| `recent_searches_store.dart` | **No** — `recentSearchesProvider` |
| `subscriptions_store.dart` | **No** — `subscriptionsProvider` |
| `tasks_store.dart` | **No** — `tasksProvider` |

Note: `search_index.dart` is not named `*_store` but holds `searchIndexProvider`.

**No orphan old-pattern store files.** Stores were converted in place, not deleted.

### Other setState (outside migrated features)

| Location | Classification |
|----------|----------------|
| `home_screen.dart:94` bottom tab index | **Local UI** |
| `comments_sheet.dart` compose/playback | **Out of Riverpod pass scope** (still ad hoc) |
| `notify_settings_sheet.dart` radio selection | **Local UI** |

### Half-migrated (old store + Riverpod in same file)

- **No** file still uses `ChangeNotifier` / `TasksStore.instance` / `PlaylistsStore.instance` alongside Riverpod.
- Store files import Riverpod and **are** the providers.
- `task_shared_widgets.dart`: Riverpod only via `ProviderScope.containerOf` — not dual old/new store, but incomplete style.

---

## PART 6 — Full verification

| Step | Result |
|------|--------|
| `flutter clean` | OK |
| `flutter pub get` | Got dependencies! |
| `flutter analyze` | **No issues found! (ran in 6.8s)** |
| `flutter build apk --debug` | **√ Built build\app\outputs\flutter-apk\app-debug.apk** |

---

## PART 7 — Pass/fail table

TRUE only if verified by reading code.

| Feature | Old store removed/dead | Screens consume Riverpod (quoted) | No leftover setState for feature state | No half-migrated files |
|---------|------------------------|-----------------------------------|----------------------------------------|-------------------------|
| **notifications** | **TRUE*** | **TRUE** | **TRUE** | **TRUE** |
| **leaderboard** | **TRUE*** | **TRUE** | **TRUE** | **TRUE** |
| **streaks** | **TRUE*** | **TRUE** | **TRUE** | **TRUE** |
| **playlists** | **TRUE*** | **TRUE** (screen + menu + unlock; description sheet props-only) | **TRUE** | **TRUE** |
| **search** | **TRUE*** | **PARTIAL** — `search_screen` YES; `search_results_screen` NO provider | **TRUE** (live results local by design) | **TRUE** |
| **subscriptions** | **TRUE*** | **TRUE** (body, widgets, all-subs, player) | **TRUE** (filter/sort local) | **TRUE** |
| **tasks** | **TRUE*** | **TRUE** for screens; **task_shared_widgets** workaround only | **TRUE** | **FALSE** — `ProviderScope.containerOf` still present |

\*Store **files still exist** but are the Riverpod implementations (not dead old code). “Old pattern removed” = TRUE for singleton/ChangeNotifier pattern.

---

## Gaps (report only — not fixed)

1. **`task_shared_widgets.dart:140`** — still  
   `ProviderScope.containerOf(context).read(subscriptionsProvider)`  
   instead of Consumer/ref. **Highest-priority incomplete item** vs Pass 3 wording.

2. **`search_results_screen.dart`** — no Riverpod; pure route args. Acceptable if intentional; not a store leak. Optional: convert to Consumer only if results should re-query from provider.

3. **`playlist_description_sheet.dart` / `filter_sheet.dart` / `search_result_widgets.dart`** — no providers; presentational. **Not gaps** if parent provides data (current design).

4. **`submission_task_screen.dart:29`** — `ref.read` not `ref.watch` for task lookup (weak rebuild coupling).

5. **`subscriptions_screen.dart:94,404`** — empty `setState(() {})` “onRefresh” after pop; redundant with `ref.watch` if list already updates.

6. **Out of scope but still non-Riverpod:** `comments_sheet.dart`, home feed local state — never in Pass 1–3 scope.

7. **Naming:** `*_store.dart` files remain; they are providers + models. Not wrong, but name still says “store.”

---

## Bottom line

| Area | Status |
|------|--------|
| Dependency + `ProviderScope` | Pass |
| All 7 feature domains on Riverpod providers | Pass (stores converted in place) |
| Main screens wired with Consumer + `ref.watch`/`read` | Pass |
| Feature catalog no longer on ChangeNotifier singletons | Pass |
| Analyze + debug APK | Pass |
| **Real gaps** | **1 hard:** `task_shared_widgets` containerOf; **soft:** search results not on Riverpod; read vs watch on submission |

No fixes applied (verification-only). Follow-up fix prompt can target gap #1 (and optionally #2–5).

---

## Provider inventory (quick reference)

| Provider | Type | File |
|----------|------|------|
| `notificationsProvider` | `NotifierProvider` | `notifications/data/notifications_store.dart` |
| `leaderboardProvider` | `Provider` | `leaderboard/data/leaderboard_store.dart` |
| `streaksProvider` | `NotifierProvider` | `streaks/data/streaks_store.dart` |
| `playlistsProvider` | `NotifierProvider` | `playlists/data/playlists_store.dart` |
| `playerPrefsProvider` | `NotifierProvider` | `playlists/data/playlists_store.dart` |
| `searchIndexProvider` | `Provider` | `search/data/search_index.dart` |
| `recentSearchesProvider` | `AsyncNotifierProvider` | `search/data/recent_searches_store.dart` |
| `subscriptionsProvider` | `NotifierProvider` | `subscriptions/data/subscriptions_store.dart` |
| `tasksProvider` | `NotifierProvider` | `tasks/data/tasks_store.dart` |
