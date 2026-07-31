# Skiflux — Project Documentation & Handoff

> One document covering both projects in this repo: the **design system
> package** and the **mobile app** built on top of it.

| | |
|---|---|
| **Figma source** | [Skiflux](https://www.figma.com/design/863bu2TwQqgzIRgPD8bXkG/Skiflux) — file key `863bu2TwQqgzIRgPD8bXkG` |
| **Design System page** | node `107:6437` |
| **Stack** | Flutter (Dart SDK ≥ 3.0), Material 3, light mode only |
| **Key deps** | `remixicon` (icons), `audio_waveforms` 1.3.0 (voice record/playback), `path_provider`, `flutter_svg` (streak flame/decor), `timeago` (notification timestamps), `file_picker` + `share_plus` (task submission / quiz share), `image_picker` (Edit Profile avatar — gallery + camera) |
| **Repo root** | `C:\Users\timmy\skiflux` (monorepo with sibling packages) |
| **Version control** | git, remote `origin` → `github.com/veek000/skiflux_design_system` |

---

## Current Architecture (as of 2026-07-19)

**State management: Riverpod — 100% complete for feature-level state
across the entire app (Passes 1–4 + full-app cross-check on 2026-07-20).
No legacy setState/singleton pattern remaining for feature/business
state.**

App root is wrapped in `ProviderScope` (`skiflux_mobile_app_v2/lib/main.dart`).
Dependency: `flutter_riverpod` ^3.3.2. Full audit:
[RIVERPOD_MIGRATION_AUDIT.md](RIVERPOD_MIGRATION_AUDIT.md). Pass 4
closed the last known exceptions (comments + home feed review).

All feature domains use Riverpod providers:

| Domain | Provider(s) | Type |
|--------|-------------|------|
| notifications | `notificationsProvider` | `NotifierProvider` |
| leaderboard | `leaderboardProvider` | `Provider` (static demo data) |
| streaks | `streaksProvider` | `NotifierProvider` |
| playlists | `playlistsProvider` + `playerPrefsProvider` | `NotifierProvider` + `NotifierProvider` |
| search | `searchIndexProvider` + `recentSearchesProvider` | `Provider` + `AsyncNotifierProvider` |
| subscriptions | `subscriptionsProvider` | `NotifierProvider` |
| tasks | `tasksProvider` | `NotifierProvider` |
| comments (home sheet) | `commentsProvider` | `NotifierProvider.autoDispose` |

Provider definitions live under each feature’s `data/*_store.dart` (or
`search_index.dart` for the search index). Screens consume them via
`ConsumerWidget` / `ConsumerStatefulWidget` and `ref.watch` / `ref.read`.

**Known, deliberate design choices (not gaps):**

- `search_results_screen.dart` receives results via constructor from the
  search screen rather than watching a provider directly — intentional
  (ephemeral query results owned by the search route).
- Home bottom-nav `_tabIndex`, video like-button animation, form drafts,
  sheet draft selection, quiz-in-progress answers/timer, etc. remain
  `setState` — purely local / ephemeral UI (see Pass 4 cross-check).
- `*_store.dart` filenames remain even though these files now contain
  Riverpod providers, not the old store/singleton pattern — naming is
  legacy, functionality is fully migrated.

### Standard consumption pattern

Example from `leaderboard_screen.dart` (simplest static `Provider`):

```dart
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _leagueIndex = 0; // local UI only — league pill selection

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(leaderboardProvider);
    // ... use board.leagues, board.podium, board.ranked, etc.
  }
}
```

Mutations use the notifier: `ref.read(someProvider.notifier).method(...)`.
Pure local UI (tabs, form drafts, animation toggles) may still use
`setState` on the widget.

### ⚠️ RULE FOR ANY NEW WORK (including UI conversion from Figma)

- Every new screen/component must consume feature-level state via
  Riverpod providers (`ConsumerWidget` / `ConsumerStatefulWidget`,
  `ref.watch` / `ref.read`). Never introduce `setState` for
  feature/business state — `setState` remains correct only for purely
  local, ephemeral UI state (tab selection, form field drafts, animation
  toggles).
- When a provider needs to be read from a non-widget context (a
  standalone function, not inside a build method), pass `WidgetRef` in as
  a parameter from the calling widget — do **not** use
  `ProviderScope.containerOf(context)` as a shortcut. This pattern was
  found and corrected once already (`task_shared_widgets.dart` /
  `openTaskEpisode`); do not reintroduce it.
- Reference examples by complexity: **leaderboard** (simplest, static
  `Provider`), **streaks** or **notifications** (`NotifierProvider` with
  mutation), **playlists** or **subscriptions** (multiple related
  providers), **tasks** (most complex single provider handling multiple
  sub-states), **comments** (`NotifierProvider.autoDispose` for
  sheet-scoped session state).
- Do not introduce a new store pattern, global singleton, or any other
  state approach without explicit approval.

### Error Handling

Centralized layer lives under
`skiflux_mobile_app_v2/lib/shared/error_handling/`:

| File | Role |
|------|------|
| `error_handler.dart` | `SkifluxErrorKind`, `SkifluxFailure`, `ClassifiedError`, `ErrorHandler.classify`, crash-report hook, `errorHandlerProvider` |
| `error_display.dart` | `ErrorDisplay.show(context, ref, error)` — toast or modal |

**Riverpod:** `errorHandlerProvider` is a plain `Provider<ErrorHandler>`
(pure classification, no session state). Screens call
`ref.read(errorHandlerProvider)` only through `ErrorDisplay.show` in
normal UI code; notifiers may throw `SkifluxFailure(kind)` so the
screen’s catch path stays uniform.

**Decision rule (toast vs modal):** If the user spent real effort or
money, or the failure blocks them from proceeding, use **modal**.
Everything else defaults to **toast**.

| Kind | UI | User copy |
|------|----|-----------|
| Network timeout / no connection | toast | Couldn't connect. Check your internet and try again. |
| Like / comment / reaction failed | toast | That didn't send. Please try again. |
| Search/filter error | toast | Something went wrong with your search. Please try again. |
| Task submission failed | modal | Your submission didn't go through. Please try again. Your progress hasn't been lost. |
| Quiz/assessment submission failed | modal | (same as task submission) |
| SkillCoin withdrawal failed | modal | We couldn't process your withdrawal. No coins were deducted. Please try again or contact support. |
| Auth / sign-in failed | modal | We couldn't sign you in. Please check your details and try again. |
| Session expired / auth | modal | Your session timed out. Please log in again to continue. |
| Voicenote recording/upload failed | modal | Your voice note couldn't be sent. Tap to retry. |
| Content failed to load | modal | We couldn't load this. Please try again. |
| Unclassified fallback | toast | Something went wrong. Please try again. |

Never show raw exception text or error codes to the user.

**How to call from a new screen:**

```dart
// Riverpod screens / notifiers' UI handlers:
try {
  // feature work that may throw SkifluxFailure or a raw exception
} catch (e, st) {
  if (!mounted) return;
  await ErrorDisplay.show(context, ref, e, stackTrace: st);
}

// Non-Riverpod widgets (e.g. comments_sheet until migrated):
await ErrorDisplay.showStandalone(context, e, stackTrace: st);
```

Prefer `throw const SkifluxFailure(SkifluxErrorKind.taskSubmission)` (or
the matching kind) from notifiers/services when the failure mode is
already known. `ErrorDisplay` classifies, optionally reports, then shows
[SkifluxToast](#toast-notifications) (toast) or `showSkifluxSheet` /
`SkifluxSheetShell` (modal). `showStandalone` uses `const ErrorHandler()`
because the classifier is pure — no `WidgetRef` required.

**UI building blocks:** Modal/Dialog is not a design-system component;
error **modals** reuse the app-wide overlay pattern
`showSkifluxSheet` + `SkifluxSheetShell` (`shared/sheets/skiflux_sheet.dart`)
— blur + scrim + white card with title/close — same shell as comments,
more-menu, share, unlock, notify, etc. Sheet content is message +
`SkifluxButton` (dismiss/retry); no shell API extension was required.

---

## Secrets & Environment Configuration

**Approach: `--dart-define-from-file` compile-time constants**

Secrets and environment configurations (e.g. Sentry DSN, API base URLs, telemetry feature flags) are passed via compile-time JSON files using Flutter's native `--dart-define-from-file` CLI flag. This ensures zero risk of `.env` files being bundled into release asset archives.

### Configuration File Structure

```
skiflux_mobile_app_v2/
  config/
    env/
      dev.json.example   (committed template with placeholder keys)
      prod.json.example  (committed template with placeholder keys)
      ci.json            (committed CI-safe configuration for GitHub Actions)
      dev.json           (gitignored local environment configuration)
      prod.json          (gitignored production environment configuration)
```

### Local Development Setup

To configure your local development environment:
1. Copy `skiflux_mobile_app_v2/config/env/dev.json.example` to `skiflux_mobile_app_v2/config/env/dev.json`.
2. Populate `SENTRY_DSN`, `API_BASE_URL`, etc. with real credentials.
3. Launch the app using:
   ```bash
   flutter run --dart-define-from-file=config/env/dev.json
   ```
4. Build release binaries using:
   ```bash
   flutter build apk --dart-define-from-file=config/env/prod.json
   ```

### CI / CD Pipeline

GitHub Actions CI (`.github/workflows/flutter-ci.yml`) runs `flutter test --dart-define-from-file=config/env/ci.json` using the committed `ci.json` placeholder configuration. No real secrets or secret injection steps are required for CI test and analysis steps to pass.

### Code Access via `EnvConfig`

All environment properties are accessed statically through `EnvConfig` (`skiflux_mobile_app_v2/lib/config/env_config.dart`):
- `EnvConfig.environment` (`'dev'`, `'staging'`, `'prod'`, `'ci'`)
- `EnvConfig.sentryDsn` (Sentry crash reporting DSN URL)
- `EnvConfig.apiBaseUrl` (REST/GraphQL backend endpoint)
- `EnvConfig.enableAnalytics` (boolean telemetry flag)
- `EnvConfig.validate()` (logs initialization status in debug mode)

---

Non-blocking error **toasts** go through [SkifluxToast](#toast-notifications)
with `type: error`.

**Crash-reporting hook:** `ErrorHandler.reportTechnicalError` in
`error_handler.dart`. Today it `debugPrint`s. When Phase 1 item 4
(Sentry) lands, replace only that method body — call sites stay
unchanged. Marked `TODO(Phase 1 item 4)`.

**Rollout status (screens wired):**

| Screen / path | Kind | Notes |
|---------------|------|--------|
| `submission_task_screen.dart` | `taskSubmission` (modal) | Invalid http(s) link / missing task |
| `quiz_assessment_screen.dart` | `quizSubmission` (modal) | `_finish` / `recordQuizResult` failure path |
| `quiz_assessment_screen.dart` | `contentLoadFailed` (modal) | Missing task/quiz on open |
| `search_screen.dart` | `searchFailed` (toast) | Query / recents add/remove/clear failures |
| `search_screen.dart` | `contentLoadFailed` (modal) | `recentSearchesProvider` AsyncError |
| `comments_sheet.dart` | `voicenoteFailed` (modal) | Empty/invalid voice path via `ErrorDisplay.show` (Riverpod) |
| `comments_sheet.dart` | `likeCommentReactionFailed` (toast) | Text send catch via `ErrorDisplay.show` (Riverpod) |

**Skipped (no real implementation to attach to yet):**

| Item | Reason |
|------|--------|
| SkillCoin **withdrawal** | Not implemented — only spend-to-unlock exists (`playlists` wallet). Notifications mention withdrawals as demo copy only. |
| Session expired / auth | No auth layer (`my_profile_screen` notes “no auth yet”). |
| Network/connection wrapper | No shared network client pre-backend; no general call wrapper. |
| `tasks_screen` list load | Demo catalog is in-memory seed data; no async fetch that can fail. |

### Toast Notifications

Generalized helper: `skiflux_mobile_app_v2/lib/shared/toast/skiflux_toast.dart`
(`SkifluxToast` / `SkifluxToastType`). Lives in the **app** (not the
design system) because Figma’s Task Toaster is not implemented as a DS
component and presentation depends on `ScaffoldMessenger`.

| Type | Background token | Foreground token | Icon (Remix) |
|------|------------------|------------------|--------------|
| `success` | `backgroundPositive` | `contentPrimaryInverse` | `checkbox_circle_fill` |
| `error` | `backgroundNegative` | `contentPrimaryInverse` | `error_warning_fill` |
| `info` | `backgroundInfo` | `contentPrimaryInverse` | `information_fill` |

- **Duration:** 3.5s default (`SkifluxToast.defaultDuration`).
- **Queuing:** relies on Flutter’s built-in `ScaffoldMessenger` SnackBar
  queue — successive `showSnackBar` calls display in order. The helper
  never calls `hideCurrentSnackBar`, so a second toast does not replace
  the first.
- **API shape:** still a floating `SnackBar` under the hood (compatible
  with the old subscribe pattern).

```dart
// Success (e.g. subscribe)
SkifluxToast.success(context, 'Subscribed to Amara Design');

// Error (used by ErrorDisplay toast path)
SkifluxToast.error(context, "Couldn't connect. Check your internet and try again.");

// Info
SkifluxToast.info(context, 'Download started');

// Or explicit type:
SkifluxToast.show(
  context,
  message: '…',
  type: SkifluxToastType.success,
);
```

**Migrated call sites:** profile subscribe/unsubscribe (`success`);
error-handling toast branch (`error`). Remaining raw `SnackBar` call
sites (follow-up): notify settings on profile, more-menu actions,
episode resources, public user profile, playlist screen, playlist menu.

---

## 1. Repository layout

```
skiflux/                              ← MONOREPO ROOT
  AGENTS.md                           package-usage policy (renamed from CLAUDE.md)
  PROJECT.md                          ← this file
  BACKEND_INTEGRATION.md              TODO(backend) inventory (regenerate via grep)
  SKIFLUX_TASK_TRACKER.md             live task tracker

  skiflux_design_system/              ← Flutter PACKAGE (the design system)
    pubspec.yaml                      name: skiflux_design_system
    README.md                         package overview + usage snippets
    TOKEN_SUMMARY.md                  full Figma-variable → Dart token table
    assets/fonts/                     Creato Display (OTF), DM Sans, DM Mono (+OFL licenses)
    lib/
      skiflux_design_system.dart      public barrel — the ONLY import consumers need
      src/
        tokens/                       colors, typography, spacing, radii, effects, icons
        theme/app_theme.dart          SkifluxAppTheme.light (ThemeData)
        components/                   19 Figma-mapped widgets (see §3)

  skiflux_mobile_app_v2/              ← Flutter APP (sibling, path: ../skiflux_design_system)
    pubspec.yaml                      name: skiflux_mobile_app_v2
    README.md                         app overview + layout conventions
    EMULATOR_GUIDE.md                 Windows / Android-emulator run guide
    assets/                           feed placeholder images, badges, streaks
    lib/
      main.dart                       entry: EnvConfig → Firebase → Sentry → runApp
      firebase_options.dart           throwaway Firebase project options (hand-written)
      app/app.dart                    SkifluxMobileAppV2 root widget (+ FCM attach)
      features/
        home/home_screen.dart         + sheets/ (comments, more-menu, unlock, etc.)
        profile/ + search/ + subscriptions/ + streaks/
        leaderboard/ + notifications/ + tasks/ + playlists/ + auth/
      shared/
        sheets/                       skiflux_sheet + share_sheet
        notifications/fcm_service.dart  FCM receive/display (Riverpod)
        toast/ + error_handling/
    test/                             providers/ + flows/ + network/ + widget_test
    android/ ios/ web/                platform shells (renamed, see §6)
```

**Layout rules**

- Package internals live under `lib/src/` — apps must import only
  `package:skiflux_design_system/skiflux_design_system.dart`.
- App code is feature-first: each folder under `features/` owns its screen and
  private sheets/widgets; cross-feature code goes in `shared/`.
- **No hardcoded design values in app code** — everything comes from tokens.

---

## 2. Design tokens (`lib/src/tokens/`)

All extracted from Figma local variables / text styles / effect styles on the
Design System page. Full table: [TOKEN_SUMMARY.md](TOKEN_SUMMARY.md).

| File | Exposes | Notes |
|---|---|---|
| `colors.dart` | `SkifluxColors` | Raw palettes (`brand50…900` `#5610AB`@500, `neutral0…900`, blue/green/red/yellow) **and** semantic tokens (`contentPrimary` #1A1A1A, `contentDisabled` #B2B2B2, `borderTertiary` #E5E5E5, `backgroundBrand`, `borderFocus`, …). Always prefer semantic over raw. Also `lightColorScheme` for Material. |
| `typography.dart` | `SkifluxTypography`, `SkifluxFontFamily`, `SkifluxFontWeight` | Heading H1–H12 (Creato Display), Body p1–p12 (DM Sans), UI styles (buttons, nav, input, badge), Code styles (DM Mono). Font families carry the `packages/skiflux_design_system/` prefix so they resolve from consuming apps — do not strip it. |
| `spacing.dart` | `SkifluxSpacing` (space2xs=2 … space3xl), `SkifluxUnit` (u32/u48/u56/u64…), `SkifluxBorderWidth` (xs=1, s=1.5, m=2) | 4/8-based scale. |
| `radii.dart` | `SkifluxRadii` (xs=4, s=8, m=12, l=16, xl=32, circle=64, pill=999) + `BorderRadius` helpers (`borderPill`, `borderL`, …) | ⚠️ See §5 "Flutter radius gotcha". |
| `effects.dart` | `SkifluxEffects.shadowL1…L6`, inner shadow | Elevation comes from these effect styles; `Surface/L*` color variables are white placeholders. |
| `icons.dart` | `SkifluxIcon`, `SkifluxIcons` | Wraps the [`remixicon`](https://pub.dev/packages/remixicon) package (matches Figma's Remix Icons library). Sizes 16 (`sizeS`) / 24 (`sizeM`). Naming: Figma `add-fill` → `RemixIcons.add_fill`. `RemixIcons`/`Remix` are re-exported from the barrel. |

**Theme:** `SkifluxAppTheme.light` (`src/theme/app_theme.dart`) assembles
`ThemeData` (Material 3) from the tokens: text theme, app bar, elevated /
outlined / text buttons, inputs, chips, switch, radio, progress, cards, bottom
nav (inactive = `contentDisabled`, active = `contentBrand`), snackbars.

---

## 3. Components (`lib/src/components/`)

Every component doc-comment carries its Figma node id. Summary:

| Widget | Figma set (node) | Key API / behavior |
|---|---|---|
| `SkifluxButton` | Button (`146:26414`) | `type`: primary / secondary / tertiary / tertiaryMono; `size`: l(48) / s(32); `state` auto-derives from `onPressed`; `leadingIcon`/`trailingIcon`; `expanded`. Secondary = white bg + 1px `borderTertiary` border + `contentPrimary` text. |
| `SkifluxButtonIcon` | Button Icon (`146:26631`) | Icon-only variant set. |
| `SkifluxInputField` | Text Fields (`146:26788`) | Pill inputs; focus = 2px `borderFocus`. |
| `SkifluxChip` | Controls / Chips: Pill (`190:6923`) | |
| `SkifluxSwitch` | Switch (`781:30182`) | |
| `SkifluxRadio` | Radio button (`198:15908`) | |
| `SkifluxNotificationBadge` | Notification Badge (`62:1647`) | `indicator` type = 8×8 red (`contentNegative`) dot with a 2px **white ring outside** (Figma inset −25%); Flutter strokes inside, so the box is 12×12 keeping the dot at 8×8. `number` type shows a count. |
| `SkifluxSpinner` | Spinner (`146:26378`) | |
| `SkifluxAvatar` | Avatar (`64:3370`) | Styles: `avatar` (photo) / `initial`. Photo style **falls back to initials** when `image` is null or errors (`errorBuilder`). Initials scale at `fontSize = size * 0.4` on `backgroundPrimaryBrand`. |
| `SkifluxSegmentButton` / `SkifluxSegmentedControl` | Segment Buttons (`62:1756`) | Equal-width full-track group; label `UI Style/Table Head 1` (`uiTableHead1`) — Task Flow Learning/Mission/Marketplace. |
| `SkifluxTopNavBar` | Top Navigation Bar 1/2 (`62:1689`, `62:1708`) | `label` + optional `labelStyle` override (screen titles use `headingH8Bold`; default is `uiNavItem`). `leading` / `trailing` slots. |
| `SkifluxMobileTabBar` / `SkifluxMobileTabItem` | Mobile Icon Tab (`62:1652`) + Bottom Navigation (`848:41140`) | Active = `contentBrand`; **inactive = `contentDisabled` (#B2B2B2)** per Figma. Optional badge per item. Label style `uiInputContent` 12/16. |
| `SkifluxComment` | Comment (`848:39488`) | Bubble corners: topLeft `xs`(4), other three `xl`(32) — see §5. Voicenotes: pass `audioPath` for real playback (own `PlayerController`, tap-to-seek, live duration); without it the row renders static decorative bars. |
| `SkifluxFlame` | Flame Asset (`2226:12084` active / `2231:11216` inactive) | Streak flame, SVG via `flutter_svg`. `active` (red→amber) / inactive (grey). The SVG's baked `feDropShadow` is unsupported by flutter_svg — assets ship filter-stripped and the glow is rebuilt as a blurred tinted copy of the flame (offset 0/4, blur 10, `#FBAC74` / `#E5E5E5`). |
| `SkifluxComposeBar` | Compose Bar (`848:39483`) | Stateful: focusing the field puts a 1.5px `borderFocus` border around the **whole bar**; send button is active (`contentBrand`) only when text is present or recording, else `brand200` and non-tappable. Owns its controller/focus node unless provided. Recording is real (`RecorderController` → m4a in app documents); send emits the file via `onSendVoiceNote(path)`, delete discards it. |
| `SkifluxVoiceWaveform` / `SkifluxWaveformStyle` | strip inside Comment (`848:39484…`) | Static fallback bars + the shared bar geometry (width 2.371 / gap 2 / radius 32 / max height 22.761) and the `WaveStyle`/`PlayerWaveStyle` factories used by the real audio widgets. |

Present in Figma but **not implemented** (intentionally not invented):
generic Card, Modal/Dialog, List item, Bottom sheet (the app has its own shell,
§4), Checkbox, Tooltip, text Tabs.

---

## 4. Mobile app (`skiflux_mobile_app_v2/`)

App identity: **"skiflux mobile app v2"** — package `skiflux_mobile_app_v2`,
Android `com.skiflux.skiflux_mobile_app_v2`, iOS bundle
`com.skiflux.skifluxMobileAppV2`, root widget `SkifluxMobileAppV2`.

| Screen / sheet | File | Figma frame |
|---|---|---|
| Home (video feed) | `features/home/home_screen.dart` | Home & In-app Flow 11 (`198:13684`) |
| Comments sheet | `features/home/sheets/comments_sheet.dart` | `198:13767` (comment list `848:39525`) |
| More-menu sheet | `features/home/sheets/more_menu_sheet.dart` | `1256:27071` |
| Share sheet | `features/home/sheets/share_sheet.dart` | `198:13910` |
| Creator profile | `features/profile/profile_screen.dart` | Home & In-app Flow 07 (`198:14048`, header `1635:12063`) |
| Sheet shell | `shared/sheets/skiflux_sheet.dart` | overlay pattern `198:13821`/`198:13822` |

Screen notes:

- **Home**: top bar (search, creator identity, notification bell w/ badge),
  video card with EP tag + action rail (like/comment/share/more), bottom nav
  (Home active). The heart like-button animates with an elastic
  `ScaleTransition`; the top bar, video card, and the animating heart are each
  wrapped in `RepaintBoundary` — this fixed a raster flicker where the search
  icon and avatar initial blinked during the like animation. Keep those
  boundaries.
- **Sheets** use `showSkifluxSheet` (`shared/sheets/skiflux_sheet.dart`):
  `showGeneralDialog` with a 5px backdrop blur + Overlay/50 scrim + white card
  with 24px top corners, matching the Figma overlays.
- **Profile**: nav title uses `labelStyle: SkifluxTypography.headingH8Bold`;
  header = 64px avatar (initials fallback), name (`headingH8Bold`),
  `@username` (`bodyP11Regular`), Subscribe (primary S, expanded) + Notify
  (secondary S, expanded, bell icon); Recent/Playlists tabs; pill filter
  group; episode cards (Completed / Unlocked / Locked states).

Assets: `home_video_cover.png`, `home_video_raw1.png` (feed placeholders).

Run: `cd skiflux_mobile_app_v2 && flutter pub get && flutter run`
(details in [EMULATOR_GUIDE.md](skiflux_mobile_app_v2/EMULATOR_GUIDE.md)).

> **Note:** The design system is a sibling folder, not a parent. The app's
> `pubspec.yaml` references it via `path: ../skiflux_design_system`.

---

## 5. Gotchas & conventions (read before changing things)

1. **Flutter vs Figma corner radii.** Figma/CSS clamp each corner radius to the
   available side; Flutter scales *all* corners down together when adjacent
   radii overflow. Figma's raw comment-bubble values (tl 4 / tr 999 / br 999 /
   bl 64) therefore render lopsided in Flutter. We use `SkifluxRadii.xl` (32)
   for the three rounded corners to reproduce the clamped Figma look. Apply the
   same reasoning anywhere Figma uses 999/64 mixed radii.
2. **Badge white ring is OUTSIDE the dot.** Figma draws the notification-dot
   stroke outside (8×8 dot stays 8×8). Flutter's `Border.all` strokes inside,
   so the widget box grows to 12×12. Don't "simplify" this back.
3. **Font family prefix.** `SkifluxFontFamily.*` values are prefixed
   `packages/skiflux_design_system/` — required for fonts bundled in a package
   to resolve from a consuming app. Removing the prefix silently falls back to
   default fonts.
4. **Bottom-nav inactive color is `contentDisabled`** (#B2B2B2), not
   `contentTertiary` (#666) — verified against Figma `848:41140`.
5. **Semantic tokens over raw palette.** Use `SkifluxColors.contentBrand`, not
   `SkifluxColors.brand500`, in components and app code.
6. **RepaintBoundary around the like animation** (see §4) — removing them
   reintroduces the flicker.
7. **Brand decisions:** neon cyan `#00E0FF` is logo-gradient only (not a
   token); "carbon" black = `contentPrimary` #1A1A1A; only Creato Display /
   DM Sans / DM Mono typefaces.
8. **Light mode only** — the Figma Semantic Color collection has a single
   mode. No dark theme exists.
9. **`flutter analyze` is clean in both projects; keep it that way.**

---

## 6. Rename history (was `example`)

The app folder was originally the package's `example/`. It was renamed to
**skiflux mobile app v2** across:

- folder `example/` → `skiflux_mobile_app_v2/`
- `pubspec.yaml` name → `skiflux_mobile_app_v2`
- root widget `SkifluxExampleApp` → `SkifluxMobileAppV2`; MaterialApp title
- Android: `android:label="skiflux mobile app v2"`, namespace/applicationId
  `com.skiflux.skiflux_mobile_app_v2`, Kotlin package folder moved to match
- iOS: `CFBundleDisplayName` "skiflux mobile app v2", `CFBundleName`
  `skiflux_mobile_app_v2`, pbxproj bundle ids `com.skiflux.skifluxMobileAppV2`
- Web: `manifest.json` name/short_name, `index.html` title + apple title
- IDE: `.iml` files + `.idea/modules.xml` renamed/updated

⚠️ Because the Android **applicationId changed**, emulators/devices treat this
as a new app — uninstall the old "skiflux_example" install manually.

---

## 7. Work log (what's been done, in order)

1. **Token extraction** from Figma (variables, text styles, effects) →
   `TOKEN_SUMMARY.md` + token files; fonts bundled (Creato Display pack,
   DM Sans/DM Mono from google/fonts); Remix Icons wired via `remixicon`.
2. **Component library** built (15 widgets, §3), each mapped to its Figma set.
3. **App screens** built: Home feed, comments/more/share sheets, creator
   profile — all on design-system tokens/components.
4. **Fix round 1** (from device testing):
   - Like-tap flicker → `RepaintBoundary` isolation.
   - Notification dot → white outer ring per Figma.
   - Comment bubble → three rounded corners (then re-tuned, see §5.1).
   - Compose bar → whole-bar focus border + text-gated send button.
   - Profile: H8 Bold nav title, avatar initials fallback.
   - Bottom nav inactive color → `contentDisabled`.
5. **Rename** to skiflux mobile app v2 (§6).
6. **Restructure**: package → `lib/src/{tokens,theme,components}` with barrel;
   app → `lib/{app,features,shared}`; removed unused reference asset,
   boilerplate README, stale `.iml` names; analyze + tests green.
7. **Figma value audit** of ComposeBar (`848:39483`) + Comment (`848:39488`)
   via `get_design_context` — confirmed variant mapping (one parameterized
   widget each, no copy-pasted variants), all icons/colors/spacing verified;
   fixed waveform bar geometry to exact spec (width 2.371, max height 22.761)
   and comment author-name line height (24/18). Confirmed the send-button
   resting color is spec-correct `Brand/200` #BB9FDD. Noted: Figma's compose
   placeholder uses the "Outfit" font — treated as an authoring slip (not in
   the brand set); DM Sans used instead.
8. **Real audio** (was decorative bars): added `audio_waveforms` 1.3.0 +
   `path_provider` to the package; `RECORD_AUDIO` permission (Android) +
   `NSMicrophoneUsageDescription` (iOS).
   - **ComposeBar records for real**: mic tap → permission check → m4a into
     the app documents dir; live mic-amplitude waveform (`AudioWaveforms`);
     live timer from `onCurrentDuration` (hardcoded `duration` param
     removed); send stops + emits the file via new `onSendVoiceNote(path)`;
     delete/cancel stops + deletes the temp file.
   - **Comment plays for real** when its new `audioPath` param is set: each
     comment owns its own `PlayerController` (now a StatefulWidget), waveform
     extracted from the file (`AudioFileWaveforms`, fitWidth), tap-to-seek
     enabled, duration label = real file length and ticks live during
     playback; `onPlaybackComplete` tells the parent to clear its playing
     flag. Without `audioPath` it falls back to the static decorative bars.
   - **Shared geometry, separate triggers**: `SkifluxWaveformStyle`
     (voice_waveform.dart) is the single source for bar width 2.371 / gap 2 /
     radius 32 / max height 22.761; ComposeBar's `recorder()` style is
     recording-tied (all bars #5610AB), Comment's `player()` style is
     playback-tied (played #5610AB / unplayed #BB9FDD).
   - **comments_sheet.dart**: comment list refactored to a `_CommentData`
     model; `_playingIndex` now genuinely pauses the previous comment's
     controller (one voicenote at a time); a sent recording is appended to
     the list as a playable comment (`timeLabel: 'now'`).
   - Static-waveform layout fix: fallback bars now fill the measured row
     width (LayoutBuilder + bar-pitch math) so only the standard `spaceS`
     gaps sit on either side of the waveform.
   - ⚠️ No persistence/backend: comments (incl. sent voice notes) are
     ephemeral sheet state; the two seeded Figma voicenotes have no audio
     file. Mic permission prompts on first record.

9. **ComposeBar input-box fix + CLAUDE.md policy**: added `CLAUDE.md` with the
   standing package-usage policy (suggest packages with tradeoffs, never add
   or hand-roll without asking). Fixed the ComposeBar text field painting its
   own white pill + purple focus outline inside the bar: root cause was the
   app theme's `InputDecorationTheme` (`filled: true` white + per-state
   `OutlineInputBorder`s). Lesson: `border: InputBorder.none` alone is NOT
   enough — Flutter resolves `enabledBorder`/`focusedBorder`/etc. before
   falling back to `border`, so an embedded field must set `filled: false`
   **and all six state borders** to `InputBorder.none`.

10. **Search flow** (Figma section `294:6905`, flows 01–08):
    - New package components: `SkifluxSearchField` (`190:6876`; idle =
      hover-grey pill/disabled icon, active = selected-purple pill/brand icon
      + clear button; applies the full border-clearing pattern from #9),
      `SkifluxTextTabs` (`304:9617`; equal-width tabs with count pills, brand
      underline), `SkifluxEmptyState` (98px brand100 circle + 48px icon slot
      + H7 title + p8 message). Package now ships `assets/images/`
      (`search_x_fill.png`, 4x export of Figma `2374:11928` — remixicon has
      no search-x glyph).
    - App feature `lib/features/search/`: `data/search_index.dart` (models +
      local demo dataset + case-insensitive substring search; "UI Design"
      hits all four categories), `data/recent_searches_store.dart`
      (shared_preferences-backed JSON list, newest-first, deduped, cap 10;
      subtitle "Episodes · 2 results" from top category). shared_preferences
      added to the app with explicit user approval per the package policy.
    - `search_screen.dart`: landing = first-use empty state or Recent list
      (Clear all / per-row remove); live as-you-type → grouped overview
      (per-section "See all" + bottom "See all results" link) or
      Nothing-found state. `search_results_screen.dart`: query pill (tap =
      back to editing), computed count header (fixes Figma's "6 result"
      slip — real total, pluralized), 4 count-badged tabs; per-tab empty
      state. Home top-bar search icon now pushes SearchScreen.
    - Deferred (stubs, per user): playlist detail screen, public user
      profile screen — both creator rows and user "View Profile" currently
      push the existing ProfileScreen; episode/playlist card taps are no-ops.

11. **Subscriptions flow** (Figma section `1256:17783`, flows 01–05):
    - Bottom-nav Subscriptions tab is now live: `HomeScreen` swaps its body
      to `SubscriptionsBody` at tab index 2 (tab bar stays in HomeScreen's
      scaffold). Empty state (flow 04, `1256:29567`) only shows when the
      creator list is empty; demo data seeds 4 subscribed creators, so the
      populated home (flow 05, `1256:29405`) is the default. "Find Creators
      to follow" and the top-bar search circle push SearchScreen.
    - App feature `lib/features/subscriptions/`:
      `data/subscriptions_store.dart` (static in-memory store — 4 creators,
      8 episodes with isNew/postedToday/watchProgress flags; `feed()` sorts
      New-first and applies the filter), `subscription_widgets.dart` (story
      tiles w/ "N new" purple badge + active brand ring, episode feed card
      — 128×98 thumb w/ EP + duration chips, "New" label, creator row,
      views·age meta — and the All-Subscriptions creator row with bell
      pill), `subscriptions_screen.dart` (tab body, `SubscriptionsTopBar`,
      stories rail, `CreatorChannelScreen` flow 03 `1256:29613` with
      "Visit Profile" secondary button → ProfileScreen, and
      `EpisodePlayerSheet` flow 02 `1256:29748`),
      `all_subscriptions_screen.dart` (flow 01 `1256:29931`: search filters
      the list live; "Filter" link opens a sort sheet — Most relevant /
      New activity / A–Z; bell pill opens a dropdown sheet — All /
      Personalized / None / Unsubscribe, per user spec — unsubscribing
      drops the creator's episodes from the feed and can surface the
      empty state), `filter_sheet.dart` (all three sheets; feed filter =
      Recent / Today / Continue watching / Unwatched, per user spec).
    - Refactor: home's private `_VideoFeedCard` (+ action rail / like
      animation) extracted to `shared/widgets/video_feed_card.dart` as
      public `VideoFeedCard(epTag, title, description, borderRadius)` so
      the episode player sheet presents the *same* player instead of a
      copy. Home now imports it; behavior unchanged.
    - Design-review fixes (user feedback): creator channel top bar has NO
      notification circle (tab root only — 48px spacer keeps the title
      centered); All-Subscriptions unseen dot is brand purple
      (`SkifluxNotificationBadge(backgroundColor: contentBrand)`); "View
      all" + creator names use `UI Style/Input Content` (Creato Bold 12);
      episode tap = modal sheet over the current screen (rounded top,
      blurred scrim, previous screen peeking above).
    - Pixel pass from dev-mode design context (flows 02+03 — flow 02's
      frame contains the whole creator-channel underlay, so ONE
      get_design_context call covered both): story tiles are avatar →
      name → "N new" pill UNDER the name (48px avatars, badge pad 8×4,
      Badge-Tag-Small white on contentBrand); "View all" circle is 48px,
      its "N creators" line is Badge-Tag-Small on contentDisabled;
      episode-card creator row = 16px avatar + Input Content on
      contentTertiary, thumb chips = overlay50 bg with radius/x; creator
      header = headingH9Semibold + Input Content tertiary handle; player
      modal header pads L/L/L/S, title wraps to 2 lines, "View Playlist"
      is bodyP10Regular on `contentLink` (Brand/400), and the player is
      INSET (16px sides/bottom, borderL corners) — not full-bleed. Follow-
      ups: feed "Recent" control uses the funnel `filter_fill` icon (same
      as the All-Subscriptions Filter link); "Visit Profile" is a FILLED
      grey pill (contentSecondaryInverse, no border — composed locally
      since no SkifluxButtonType is a grey fill); player-sheet bottom pad
      adds `media.padding.bottom` so the video clears the device nav bar.
    - Stubs/deferred: "View Playlist" link in the player sheet is inert
      until the playlist screen exists; top-bar notification circle on the
      tab root is a no-op.
    - Runtime gotcha hit here: renaming a field on a class whose instances
      live in a `static final` list (SubscriptionsStore.creators) breaks
      under hot RELOAD — old-shape instances keep null in the new field
      ("type 'Null' is not a subtype of CreatorNotificationMode"). Hot
      RESTART clears it; no code fix needed.
12. **My Profile tab** (Figma **Profile Flow 17** `1256:23812`, first
    screen only): `features/profile/my_profile_screen.dart` —
    `MyProfileBody`, wired in HomeScreen via `switch (_tabIndex)` (2 =
    Subscriptions, 3 = Profile). Distinct from the existing
    `profile_screen.dart` (that's the CREATOR profile, flow 07). Layout:
    top bar (search circle → SearchScreen, "My Profile" H8 Bold, settings
    circle stub); header — 64px initial avatar, name H8 Bold, handle
    bodyP11Regular, three stat pills (coins: backgroundNoticeSubtle /
    contentNotice + copper_coin_fill + 12px chevron; XP:
    backgroundBrandOpacity50 / contentBrand + flashlight_fill; streak:
    orange100 / orange500 + fire_fill + chevron; labels uiBadgeTagMedium),
    gradient "Design World ›" pill (linear approx of Figma's radial
    blue→magenta sweep, purple drop shadow 0/4/5 @ brand 60%, pen_nib_fill);
    Watch History rail (H9 Bold heading + "View all" uiButtonLarge brand;
    128px cards from `SubscriptionsStore.feed().take(5)` — thumb 128×98
    borderL, EP chip SOLID brand (unlike feed card's overlay chip),
    duration chip overlay50, H10 Bold 2-line title, creator name +
    more_2_fill); menu list of 48px rows (trophy/download/bookmark/
    heart_3/award _fill 24px + uiButtonLarge label + chevron; Leaderboard
    shows "#12 in Master" bodyP10Regular tertiary). All pills/rows/View
    all are inert stubs — detail screens deferred.

13. **Streak flow** (Figma section **Streak Flow** `3092:14400`, screens
    01–04): one parameterized `features/streaks/streak_screen.dart`
    renders all four variants from `data/streaks_store.dart` (static
    demo store: streak 7 / best 14 / XP 240 — matches screens 03+04 so
    the milestone celebration is reachable; also feeds the My Profile
    streak pill, which now pushes StreakScreen).
    - **Assets**: user-provided SVGs moved from `Desktop/Skiflux Assets`
      (folder emptied). Flame active/inactive → package
      `assets/images/flame_*.svg` (drop-shadow filter stripped, viewBox
      tightened to the 76.884×98.001 Figma frame — flutter_svg can't
      render `feDropShadow`); light ray + laurels → app
      `assets/streaks/`; 8 achievement badges + podium → app
      `assets/badges/` (renamed snake_case, for the deferred
      Badges/Leaderboard screens). `flutter_svg ^2.0.10` added to BOTH
      pubspecs with explicit user approval per the package policy.
    - **New package component `SkifluxFlame`** (see §3 table).
    - **StreakScreen**: nav "Streaks" H8 Bold + back chevron (24px
      trailing spacer keeps the title centered); hero — flame,
      H1 ExtraBold 72 count with `height: 1` (orange500 active /
      contentDisabled at 0), "Days in a row" p7; orange100 pending-task
      pill (32px orange400 fire circle, uiButtonMedium tertiary text);
      "This Week" card (backgroundHover, radius X 24) with white
      date-range pill (calendar_2_fill + uiButtonSmall + down chevron —
      week switching is a stub) and 7 day cells: uiBadgeTagSmall label +
      40px circle — completed = orange500 + white 26.67px check_fill,
      missed = negativeSubtle + red close_fill (screen 01), today =
      orange200 + orange600 H9 Bold number, future = backgroundPressed +
      contentDisabled number. (Figma screen-03 Sat cell reads "5" — an
      authoring slip; store uses the true next number 8.) Stat cards:
      notice-subtle→notice and brand-50→brand horizontal gradients,
      radius X, H6 ExtraBold value + p8 label in black, 64px
      trophy(yellow700)/flashlight(brand700) icon bleeding off the
      right edge (Positioned right -3.5 / top 37, clipped). Sticky
      Share = primary L SkifluxButton on surfaceL3 → opens the share
      sheet.
    - **Milestone sheet** (`milestone_sheet.dart`, overlay `2259:13266`):
      shown via `showSkifluxSheet` once per session when
      `StreaksStore.consumeCelebration()` fires on screen open (post-frame,
      streak ≥ milestone 7). White card, 24px top corners; 96px header —
      brand→white vertical gradient (stops .05/.72), light-ray SVG burst,
      laurel SVGs flanking "+50 XP" H6 ExtraBold white over "Earned" p10
      Semibold brand; grey close circle top-right; "Milestone Completed!"
      H7 Bold + p8 copy with the "7 days streaks" span bolded
      (p8 Semibold secondary); primary L Close button.
    - **Refactor**: `share_sheet.dart` moved `features/home/sheets/` →
      `shared/sheets/` (now used by home's video card AND StreakScreen),
      imports updated — per the "used by two features ⇒ shared/" rule.
    - **Week picker** (`week_picker_sheet.dart`, no Figma frame — the
      pill is static in all four streak screens, so it composes existing
      patterns): tapping the date-range pill opens a SkifluxSheetShell
      ("Select Week") with a hand-rolled Sun-first month grid (month
      header H9 Bold between backgroundHover chevron circles;
      uiBadgeTagSmall weekday labels; bodyP9 dates). Tapping ANY date
      selects its whole Sun–Sat week — the row highlights as a
      backgroundSelected (brand100) pill with contentBrand semibold
      dates; weeks with no tracked history are disabled
      (contentDisabled; adjacent-month dates contentTertiaryInverse).
      Apply pops the chosen `StreakWeek`; card + pill update (title flips
      "This Week" ↔ "Past Week"). Store reworked: `StreakWeek` class
      (start Sunday + 7 `StreakDay`s, Figma-ordinal label incl.
      cross-month "Apr 29th - May 6th") + 4 seeded `history` weeks in
      year 2029 (puts May 20 on a real Sunday, matching the Figma
      "May 20th - 27th" label); `weekContaining(date)` powers the grid.
    - GOTCHA (laurel/light-ray exports): Figma MCP SVG exports use
      `fill="var(--fill-0, #hex)"` + percentage width/height — flutter_svg
      renders those fills as NOTHING (CSS vars unsupported). Fixed by
      sed-ing to concrete hex fills and absolute dimensions; do the same
      for any future Figma SVG export (badges are from the user's folder
      and already clean).
    - Stubs/deferred: Share shares nothing real (demo share targets); no
      streak persistence — store is static (milestone once-per-session
      flag resets on restart).

14. **Leaderboard screen** (Figma **Profile Flow 01** `1256:25612`):
    `features/leaderboard/leaderboard_screen.dart` +
    `data/leaderboard_store.dart`, pushed from the My Profile
    "Leaderboard" menu row (`_MenuRow` gained an optional `onTap`; rows
    without one remain stubs). Layout top→bottom:
    - League pill group (`1256:25615`): horizontal scroll of size-S
      SkifluxButtons (selected = primary), same pattern as the creator
      profile's pill group. Switching only re-selects — one league of
      demo data.
    - Rank notification: brand-tinted variant of the streak pending pill
      (backgroundBrandOpacity50 bg, 32px backgroundBrand circle with
      "#12" uiBadgeTagSmall white, message uiButtonMedium contentBrand).
    - Podium (`1256:25622`): `assets/badges/podium.svg` (user-provided,
      1st/2nd/3rd laurel numerals baked in; fills are all brand-ramp
      purples) bottom-anchored in a LayoutBuilder-scaled 361×325.92
      Figma frame; three avatar columns absolutely positioned above the
      steps at scaled Figma coords (1st center x182.2/y0, 2nd x60.3/y48,
      3rd x300.7/y72.3). Column = 64px initials SkifluxAvatar (1st gets
      a crown badge: contentBrand circle, white border width m, 13px
      vip_crown_fill), name uiButtonMedium, "4,820 XP" in DM Mono 10
      (codeInline with letterSpacing zeroed — Figma uses default
      tracking).
    - Rank table (`1256:25657`): bottom-docked white CARD at the podium's
      width (16px side margins, 24px top corners, clipped) that OVERLAPS
      the podium — the card's top slides ~28px (scaled; Figma podium
      bottom y565.92 vs card top y538) over the steps, so podium + card
      sit in a Stack inside the body's Expanded; pills/notification stay
      fixed above and only the card's inner ListView.builder scrolls.
      Fixed RANK / TOTAL XP header (uiInputContent, borderSecondary
      hairline bottom) then rows from rank 4 (podium holds 1–3): 32px
      rank number H9 Bold, 48px initials avatar, name H9 Bold + handle
      bodyP10Regular tertiary vertically CENTERED on the avatar (the
      name/handle Column needs mainAxisSize.min or it pins to the row
      top), XP chip (backgroundSelected pill: 16px flashlight_fill
      brand, count uiButtonSmall brand, "XP" uiBadgeTagSmall tertiary).
      The signed-in user's row (#12, matches My Profile "#12 in
      Master") is highlighted backgroundSelected with radius XL, and the
      list opens PRE-SCROLLED to it (initialScrollOffset = (userIndex−2)
      × 64px row extent, clamped post-frame — lands the row 3rd in view
      like the Figma frame's 10/11/[12]/13).
    - Store: 15 static entries (subscriptions creators as the podium +
      filler cast), `podium`/`ranked` getters, `xpLabel`
      thousands-formatter.

15. **Notifications screen** (Figma **Notification Flow** `1256:28688`,
    screens `1256:30744` + empty `1256:30972`):
    `features/notifications/notifications_screen.dart` +
    `data/notifications_store.dart`, pushed from the Home bell (badge
    button `294:7951`). New dep: `timeago ^3.7` (confirmed per package
    policy) — store keeps real DateTimes seeded relative to now, so "2
    min ago" labels and Today/Yesterday grouping stay alive.
    - Store: `AppNotification` (title/body/icon-key/time/action/unread
      flag) in a `ChangeNotifier` singleton (`NotificationsStore
      .instance`) — 16 seeded cards (5 today, 11 yesterday; first 3
      unread), `markRead`/`markAllRead`, `unreadCount`. Icon keys are
      plain strings mapped to Remix fills in the screen so the store
      stays flutter-free.
    - Screen: SkifluxTopNavBar H8 Bold "Notification" + "Mark all read"
      trailing text (disabled at 0 unread); SkifluxTextTabs All /
      Unread(count) — Unread tab filters live; sections Today /
      Yesterday (fallback Earlier) as uiButtonMedium labels over a
      bordered card stack (`Frame 5811`): 1px borderTertiary stroke on
      ALL sides + radius L rounded corners top and bottom, content
      clipped; hairline separators between cards but not after the last
      (the container stroke closes the stack). GOTCHA: the stroke must
      be a `foregroundDecoration` on the clipping Container — a plain
      `decoration` border paints UNDER the card fills, which bleed over
      the stroke on the corner curves and make the rounding look
      chipped.
    - Card: 30px contentBrand circle with 20px white type icon, H10
      Bold title + bodyP10Regular body (both contentSecondary),
      optional size-S primary SkifluxButton action pill (labels from
      Figma: Watch EP. 04 / View Reply / Listen to Reply / …),
      timeago stamp bodyP11Regular contentDisabled, 8px contentBrand
      unread dot. Unread rows tinted backgroundBrandOpacity50; tap
      marks read. Hairline borderTertiary separators.
    - Empty state: 98px brand100 circle + 48px brand bell, H7 Bold "No
      notifications yet", p8 tertiary body — shows when the active tab
      is empty (e.g. Unread after clearing).
    - Action pills are inert stubs (deep links deferred).

16. **Task flow** (Figma **Task Flow** `1256:12977`, screens 15→01):
    Bottom-nav Tasks tab (index 1) is live via `TasksBody`. New deps
    (confirmed "real" per package policy): `file_picker 10.1.9` +
    `share_plus 10.1.4` (paired for win32 compatibility — 11/13 conflict;
    native share is available but **Share Result** uses the existing
    in-app `showShareSheet` for visual consistency with home/streaks).

    **App feature** `lib/features/tasks/`:
    - `data/tasks_store.dart` — `ChangeNotifier` singleton. Learning
      tasks cover Completed / Pending / In Review / Action Needed
      (submission + quiz kinds); missions (10 growth tasks). APIs:
      `markInReview`, `markCompleted`, `recordQuizResult` (persists
      answers + score for View Result), `completeMission`. Seeded
      completed submission **and** completed quiz so View Result works
      on both.
    - `tasks_screen.dart` — tab body: top bar (search → Search,
      bell → Notifications), Learning / Mission / Marketplace segments
      (`UI Style/Table Head 1`), filter pills All / Pending / In Review /
      Revision / Completed with live counts, learning cards (status
      chips, rewards, CTAs, Action Needed WCAG feedback), mission
      cards (`2902:13732`: 30px brand icon top-left, title/body, coin
      + CTA row), Marketplace empty (`1256:14074`: 8px gap to Keep
      Learning). **View Result** on any completed card opens the
      result screen — never task details.
    - `task_shared_widgets.dart` — hug-width `TaskRewardPill`,
      tappable `TaskEpisodeRow` → `showEpisodePlayerModal`,
      `openTaskEpisode`.
    - `submission_task_screen.dart` (TF12–09, `1256:14112`): title H7,
      reward pill, episode row, Brief (check-double bullets), Link URL
      / File Upload segment, dashed upload zone (`1256:14245`:
      upload-cloud icon, Input Content + p11), file chip
      (`1256:14313`: brand100 circle + type icon for zip/pdf/doc/xls/
      ppt/mp3/mp4/image/etc., name + `EXT • size`, trash), optional
      note, sticky Submit → success dialog → In Review. List pad =
      Space/L only (sticky is a column sibling, not an overlay).
    - `quiz_intro_screen.dart` / `quiz_assessment_screen.dart` /
      `quiz_result_screen.dart` (TF08–01): intro "Before you start",
      6-min timer + progress track, A–D option cards, Next/Submit
      gated on pick, pass@100% → `recordQuizResult`. Result
      (`1256:14718`): 98px status circle, H7 + p8 copy, Earned |
      Gained split card with **fixed-height vertical stroke**
      (`borderSecondary`, Figma `1256:14729`), sticky Review /
      Share (in-app sheet) / Back. Review (`1256:14533`): green =
      correct, red = wrong pick, grey = other; 32px letter chips,
      radius X. Submission complete uses "Task Completed!" shell
      (no Review Answers).

    **Package tweaks:**
    - `SkifluxSegmentedControl` / `SkifluxSegmentButton` — equal-width
      full-track segments; label style `uiTableHead1`.
    - `SubscriptionsTopBar` — optional `onNotification` (Tasks +
      Subscriptions tab roots).

    **Stubs / deferred:** mission Follow/Join/Rate open nothing
      external; more-menu "View Task" still inert; no backend/upload
      persistence.


17. **Home & In-app + Other Video Player flows** (Figma `198:13483` +
    `1256:18498`) — completed the missing branches on top of the existing
    home feed, comments, share, more-menu shell, creator profile, and
    subscriptions episode player modal (⚠️ playlist menu / playlist page /
    player-modal details below superseded by #21):

    - **Playlist menu sheet** (`1256:27214`): `features/playlists/
      playlist_menu_sheet.dart` — title, creator · N episodes, locked/
      unlocked rows. **EP chip** on `VideoFeedCard` opens it (not More
      Menu). Locked row → unlock flow.
    - **Full playlist page** (`198:14101`): `playlist_screen.dart` —
      cover, meta, episode list. Entry: playlist menu "Open full
      playlist", profile Playlists tab, subscriptions "View Playlist",
      search playlist rows.
    - **PlaylistsStore + PlayerPrefsStore** (`playlists/data/
      playlists_store.dart`): demo "UI Design System" 8 eps, SkillCoin
      wallet (100), unlock, playback speed / captions / auto-scroll.
    - **More Menu** wired (`more_menu_sheet.dart`): View Task → pending
      learning task; Episode Resources sheet; Playback Speed sheet
      (`1256:27378`); download/fullscreen snackbars; Caption / Auto
      Scroll live chips; Not Interested / Report snackbars.
    - **Episode unlock** (`episode_unlock_sheet.dart`, OV 05–01): cost
      + balance, insufficient-coins state, processing spinner, Episode
      Unlocked success. Deducts coins via store.
    - **Notify settings** (`notify_settings_sheet.dart`, Home 04): All /
      Personalized / None — profile Notify button.
    - **Profile**: Subscribe toggle + toast, share sheet, Recent from
      playlist store, Playlists tab → full playlist, locked ep unlock.
    - Immersive player remains the existing `EpisodePlayerSheet` on
      Subscriptions (reuses `VideoFeedCard`).

18. **Public user profile** (Figma `3092:14632` — Public User Profile view
    Screen): learner-facing profile (distinct from creator
    `ProfileScreen` and own `MyProfileBody`).
    - `features/profile/public_user_profile_screen.dart` — avatar, name/
      handle, Novice league pill, XP / #rank / Task Done stats card,
      email + Message, Skills chips, Badges (SVG assets from
      `assets/badges/`), Completed Task cards (project + assessment with
      score ring).
    - Entry: Search **Users** tab / "View Profile" → public profile;
      Search **Creators** still → creator `ProfileScreen`. Comments
      sheet: tap author row → public profile (`onAuthorTap` added to
      package `SkifluxComment`).

19. **Creator playlist + player polish** (Home Flow 05/06/03/04)
    (⚠️ superseded by #21 — playlist tab card, playlist page, and player
    modal were all re-done Figma-accurate):
    - Profile **Playlists** tab: stacked cover card with image + episode
      count chip (Flow 06), not a flat list row.
    - `playlist_screen.dart` rewritten to Flow **05**: cover hero,
      description + "View Full Description" →
      `playlist_description_sheet.dart`, views/episodes meta, creator
      + add, like/comment/save/share, episode rows (thumb + EP chip +
      Completed/Unlocked/Locked + play/coins).
    - Profile **Recent** + playlist episode taps open
      `showEpisodePlayerModal` (unlock sheet when locked).
    - Episode player modal enhanced to Flow **03**: scrubber, CC / speed
      chips, minimize; View Playlist still navigates to playlist page.
    - Notify sheet title "Notify me of" + toast copy for activated/off.

20. **Monorepo Restructure**: Moved the previously nested `skiflux_mobile_app_v2`
    to be a sibling of `skiflux_design_system` under a shared `skiflux/` root.
    Added a proper root `.gitignore` to block disposable build artifacts and 
    cleanly pushed this restructured state to the GitHub repository.

21. **Playlist / player / public-profile Figma accuracy pass** (supersedes
    the playlist-detail, description-sheet, player-modal, and playlist-menu
    implementations described in #17 and #19):
    - **New shared widget `shared/widgets/playlist_deck.dart`**
      (`PlaylistDeck`): the stacked magenta "deck" thumbnail (magenta200
      back card at radius 14.44 peeking above a magenta900 front card with
      the menu-fold + count chip). Fractional geometry so one widget serves
      both sizes: search row `304:9583` (126×98, `backWidthFactor` .9025)
      and the playlist-detail cover `198:14189` (full-width×150, .9336).
      Used by search results, the profile Playlists tab, and the playlist
      detail cover.
    - **Profile Playlists tab** (`profile_screen.dart`): now renders the
      playlist exactly like the search playlist result row (`304:9582`) —
      deck + H10 Bold title + `metaLine` ("creator · N Episodes"). The
      old image-based stacked-cover card (#19) is gone.
    - **Playlist detail** (`playlist_screen.dart`, Home Flow 05
      `198:14183`) rewritten: title-less top nav (back + share only),
      full-width deck cover, H9 Bold title + "#UIDesign #Figma" hashtags,
      grey `Background/Hover` radius-X creator pill row (48px avatar,
      H9 semibold name over Badge-Tag-Small handle, trailing chevron →
      creator ProfileScreen), 2-line p11 description + "View Full
      Description" (Button Small brand), expanded size-S **Play all**
      primary pill + 32px hover-grey bookmark/download circles. The old
      hero image, meta line, follow circle, and like/comment/save/share
      action rail were NOT in the frame and were removed. Now a
      `ConsumerWidget` (no local state left).
    - **Shared episode row** (`playlists/playlist_episode_row.dart`,
      `PlaylistEpisodeRow`): the 128×98-thumb row used by BOTH the
      playlist detail page and the playlist menu sheet. Thumb = EP chip
      (brand pill), duration chip (overlay50), 4px brand/brand100 video
      progress bar hugging the bottom edge; locked = 5px `ImageFiltered`
      blur + overlay50 + centered white lock (`827:35485`). Trailing 48px
      slot: play_circle_fill (contentDisabled) or notice-subtle coin pill.
      `playing: true` renders the `1256:27298` variant — backgroundSelected
      row fill, "Playing EP 0X" brand status, partial (0.71) progress, no
      trailing control, non-tappable.
    - **Description sheet** (`playlist_description_sheet.dart`, Home Flow
      04 `827:35820`): just "Description" H7 header + the full description
      in bodyP11Regular tertiary — dropped the repeated title/meta.
    - **Episode player modal** (`EpisodePlayerSheet` in
      `subscriptions_screen.dart`, Home Flow 03 `827:36229`): stripped
      the scrubber row (slider + timestamps), CC chip, speed chip,
      minimize button, AND the "View Playlist" link — per user direction
      those controls are baked into the video itself; the inset
      `VideoFeedCard` already carries the purple top progress bar, EP
      chip, and action rail like home. Sheet = title (H9 Bold, 2 lines) +
      close circle + video card. Now a plain `ConsumerWidget`. Playback
      speed / captions remain reachable via the More Menu.
    - **Playlist menu sheet** (`playlist_menu_sheet.dart`, Other Video
      Player Flow 07 `1256:27214`) rebuilt from the compact grey rows to
      the real frame: header = playlist title over "Creator · N Episodes"
      (new `subtitle` slot on `SkifluxSheetShell` — bodyP8Regular
      tertiary under the H7 title), body = `PlaylistEpisodeRow`s with the
      currently-playing episode highlighted. `showPlaylistMenuSheet` takes
      `playingEpisodeNumber`; `VideoFeedCard`'s EP chip parses its own
      `epTag` and passes it, so the card's episode shows as "Playing".
      Tapping another unlocked row closes the picker and opens that
      episode's player (`openPlaylistEpisode`, now a public helper on
      playlist_screen.dart); locked rows → unlock sheet. The
      "Open full playlist" button was removed (not in the frame).
    - **Public user profile** (`public_user_profile_screen.dart`,
      `3092:14632`) closed the remaining ~20%: stats card gained the
      contact row (mail_fill + email in `UI Style/Nav Item` + primary
      size-S **Contact** button, top hairline inside the card) replacing
      the grey "Message" secondary; section cards are grey
      `Background/Hover` radius-X with 24px black icons + brand100 count
      pills (were white bordered cards w/ grey pills); skills = white
      pills, Figma copy (Web Design / Mobile App Development /
      Marketing); badges sit on brand50→brand200 vertical-gradient tiles
      (radius 9.98, pad 14.97 — Figma frame values) with "Earned" in
      Button Small on `Content/Link Pressed`; completed-task cards =
      white, 1px contentSecondaryInverse stroke, radius L — projects get
      a 128px backgroundSelected thumb strip (kind pill inside) +
      outlined full-width brand action pill ("Open in browser" / "View
      Submission"), the assessment gets a BRAND score ring (round cap,
      backgroundSelected track) with stacked "88 / /100", band H10 Bold +
      positive-subtle "Passed" pill (contentPositiveBold), award detail
      line. Figma slip: the Completed Task count pill reads "8 Badges" —
      rendered as "8 Tasks".
    - Toast migrations along the way: playlist save/download,
      menu/episode taps, public-profile contact + action pills now use
      `SkifluxToast` (no raw SnackBars added).
    - Figma authoring slips handled per precedent: "Outfit" font on
      chips stays DM Sans (§7.7 call).

## 8. Suggested next steps

- Real data/state layer (feed, comments, profile, tasks, playlists are demo);
  voice notes produce real m4a files but nothing persists them.
- My Profile detail screens: settings, coins/streak, Design World,
  watch-history "View all", Downloads/Saved/Liked/Badges (Leaderboard is
  done; badge SVGs already staged in `assets/badges/`).
- Mission Follow/Join → real URLs / app store rate; text-comment send.
- Real video playback / downloads if product requires it.
- Widget tests per component (only a home smoke test exists).
- If dark mode ever ships in Figma, extend tokens with a second semantic mode.
- Riverpod migration complete (Passes 1–3). Next: real data layer.

### Backend Integration Tracking

[`BACKEND_INTEGRATION.md`](BACKEND_INTEGRATION.md) is the canonical,
auto-generated index of every backend integration point in the codebase. It
is produced from `// TODO(backend, ...)` tags placed directly above provider/
class/constant declarations. Do not hand-edit the markdown — update the
in-code tags and regenerate with `grep -rn "TODO(backend" lib/`.

## CI/CD

GitHub Actions workflow at
[`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml).

| | |
|---|---|
| **Triggers** | `push` to `main`, `pull_request` targeting `main` |
| **Runner** | `ubuntu-latest` |
| **Pinned Flutter** | **3.41.6** (stable) — matches the local SDK used for development (Dart 3.11.4). Not `latest`, so a new Flutter release cannot silently break CI. |
| **Steps** | Checkout → set up Flutter → `pub get` design system → `pub get` app → `flutter analyze` both packages → `flutter test` app |
| **Monorepo** | App depends on `../skiflux_design_system` via path; CI resolves the design system first, then the app (same layout as local). |
| **Design system tests** | None yet (`test/` missing) — only analyze runs for that package. |
| **App tests** | `skiflux_mobile_app_v2/test/widget_test.dart` (home smoke). |
| **analysis_options** | App has `analysis_options.yaml` (includes `flutter_lints`). Design system has none (defaults). CI runs plain `flutter analyze` in each package so each uses its own config. |

**Intentionally not included (follow-ups):**

- Full `flutter build apk` (or iOS) on every PR — keeps CI fast; add later if desired.
- Branch protection requiring this check before merge — **not configured** on the GitHub repo as of setup; must be enabled manually (Settings → Branches → protect `main` → require status check **Analyze & Test** / `Flutter CI`).

## Session Log

### 2026-07-25 — Claude — Lottie splash screen + dependency-bump audit
- Status: Complete
- What was done:
  - **Splash migrated from hand-built Flutter to the design Lottie export.** `Logo Splash.json` (from the user's asset folder) copied to `skiflux_mobile_app_v2/assets/animations/logo_splash.json` and rendered by `lottie: ^3.5.1` — added with explicit user confirmation per the package policy, after presenting the three options (Lottie package / hand-roll with `AnimationController`+`CustomPainter` / the MP4 via `video_player`). Asset facts: Bodymovin v5.6.8, 1080×1920, `fr:30`, `ip:0`, `op:150` → **5.0s**, 10 layers, `assets: []` (self-contained, no external images).
  - **Timing is driven by the composition, not a constant.** `_SplashScreen` sets `_controller.duration = composition.duration` in `Lottie.onLoaded` and advances on `AnimationStatus.completed`, so a re-export at a different length needs no code change. The old hardcoded 900ms `_splashTimer` is gone.
  - **Two independent escape hatches** so the app can never strand on the splash: an 8s watchdog `Timer` and `Lottie.errorBuilder`. `_finish()` is idempotent (`_finished` flag + `mounted` check), so whichever fires first wins and the rest are no-ops.
  - **Full-bleed by design.** Layer 10 ("White Solid 1") carries an `ADBE Fill` effect animating white → `[0.337, 0.063, 0.671, 1]` between frames 57–59 — that is `#5610AB` = `SkifluxColors.brand500` — so the comp *ends* on a full-screen brand wash. The splash therefore deliberately bypasses `_AuthScaffold` (which applies `SafeArea`) and uses `Scaffold` + `SizedBox.expand` + `BoxFit.cover`, with `backgroundColor: backgroundPrimary` to match the comp's opening white frame and avoid a first-frame flash.
  - `_BrandMark` (the purple circle with a white "S") deleted — the splash was its only usage.
  - **Tests restructured.** Six tests depended on the 900ms timer and one asserted on `_BrandMark`. Rather than make every unrelated test sit through a 5s animation, added `_pumpAtOnboarding` — an `UncontrolledProviderScope` over a pre-seeded `ProviderContainer` (the established idiom for entering a flow mid-state) — and gave splash behaviour its own group: one test asserting the `LottieBuilder` renders and onboarding does not, one pumping past 9s to prove the watchdog hands off.
- Known Lottie-Flutter limitation, accepted: layer 3's rotation carries a `$bm_rt` expression (`value + sin(time * 1.8) * 2`, a ±2° wobble). Lottie-Flutter drops expressions; the underlying keyframes still play, so the loss is a 2-degree oscillation nobody will see in 5 seconds. Not worth baking into keyframes.
- **Dependency-bump audit** (user confirmed the `pubspec.yaml` bumps were deliberate: `file_picker` 10.1.9 → `^12.0.0-beta.7`, `share_plus` 10.1.4 → `^13.3.0`, `flutter_lints` `^4.0.0` → `^6.0.0`):
  - **One real breakage found and fixed.** `file_picker` v12 flipped `pickFiles` to `allowMultiple: true` by default (v10 defaulted to single) and added a `pickFile` for the single-file case. `submission_task_screen.dart` called `pickFiles(...)` then took `result.files.first`, so post-upgrade a user could pick several files and the extras would be **silently discarded**. Switched to `FilePicker.pickFile`, which hardcodes `allowMultiple: false`.
  - `flutter_lints 6.0.0` — clean, no new violations in either package.
  - Platform minimums all satisfied: `share_plus 13.3.0` podspec needs iOS 12.0 (app targets 13.0), `file_picker 12.0.0-beta.7` needs Android minSdk 21 (app uses `flutter.minSdkVersion`) and inherits `flutterCompileSdkVersion`, `lottie` has no platform config at all.
  - **`share_plus` is declared but imported by zero Dart files** — `grep -rn "package:share_plus" --include="*.dart"` across the repo returns nothing. Every share entry point (including quiz "Share Result") routes through the in-app `showShareSheet` modal, commented "not OS sheet". Flagged to the user rather than removed, since `share_sheet.dart` already carries a `TODO(backend, minor)` to swap the static demo targets for the real OS sheet — the dependency is pre-positioned for that, not accidental. The pubspec comment now says so explicitly.
  - The stale pin comment ("Pinned with share_plus 10.x for win32 compatibility") was removed — no pins remain.
- Verification run: `flutter analyze` (app) → No issues found (22.2s); `flutter test` (app) → 93/93 passed; `flutter analyze` (design system) → No issues found (18.2s); `flutter test` (design system) → 28/28 passed. User verifies UI on emulator per standing preference.
- Notes for next session: the `file_picker` **beta** is still a beta on a user-facing upload path — worth revisiting when 12.0.0 stable lands. Uncommitted `android/gradle.properties` gained `android.builtInKotlin=false` / `android.newDsl=false` from the Flutter migrator (not authored here). The remaining assets in the user's folder (Apple/Google logos, three illustrations, skillcoin SVG, onboarding MP4s, frame-01.png) are stated as "for later in the session" — untouched.

### 2026-07-25 — Claude — SkillWorld pill + sheet, profile watch-history menu, `SkifluxPasswordStrength`, description-sheet spacing
- Status: Complete
- What was done: Four user-reported fixes, each against its Figma frame.
  - **SkillWorld pill (`1256:24041`) — now Figma-exact.** The pill's fill is a radial gradient Figma authors as `matrix(7.2573 2.8214 -9.5762 1.7987 65 16)` with `cx=cy=0, r=10` over the 130×32 pill, i.e. a heavily skewed ellipse spanning ≈±120px horizontally and ≈±33px vertically about the pill centre — so the pill only traverses `t ∈ [0, ~0.75]` of the 6-stop blue→violet→magenta ramp: blue at the centre, violet/magenta at the corners. Reproduced exactly rather than eyeballed, via a private `_WorldGradientTransform extends GradientTransform`. Two Flutter/Skia semantics matter here: `RadialGradient.radius` resolves against `rect.shortestSide` (32, hence `radius: 10/32`), and `GradientTransform.transform()` must return the **local→device** matrix, so replicating a Figma transform about centre `c` with linear part `L` requires the composite `translate(c) · L · translate(-c)` — built with the positional `Matrix4(...)` constructor (column-major) to avoid the `vector_math` `translate` deprecation. Also added the `brand500 @ 60%` drop shadow and the top inner-shadow highlight (`foregroundDecoration`). Verified empirically with a throwaway probe that painted the pill to an image and sampled it: `centre=#3b82f6 left=#6e4bf0 right=#6c4aef topcentre=#5861f2 topleft=#893bed topright=#963dee` — matching the hand-computed prediction and confirming the matrix direction (an inverted matrix renders the pill almost entirely magenta). Probe deleted after it served its purpose.
  - **Change SkillWorld sheet (`1256:24173`) — new.** `features/profile/change_skill_world_sheet.dart` (`showChangeSkillWorldSheet`) + `features/profile/data/skill_world_store.dart` (`SkillWorld` enum with label/icon/skills + `pillLabel`, and `skillWorldProvider`). `get_metadata` confirmed the frame has **no CTA button**, so tapping a card commits and pops. Cards are `Material`+`InkWell` over a `contentSecondaryInverse` hairline border with a 30px `backgroundPrimaryBrand` badge and a trailing shared `SkifluxRadio<SkillWorld>`. The pill's label now reads from the provider, so `_MyProfileDemo.world` was deleted (and dropped from that class's blocking backend TODO).
  - **Profile watch-history rail three-dot → the Watch History sheet.** `showWatchHistoryMenuSheet` / `WatchHistoryMenuAction` were already public and Figma-accurate (`1256:24428`), so this was wiring, not a rebuild: the rail card's `more_2_fill` glyph is now a `GestureDetector` running the same four handlers as the Watch History screen's rows. Caveat handled honestly: the rail is derived from `subscriptionsProvider.feed().take(5)`, not a watch-history store, so "Remove" cannot mutate a source list — rather than show a lying toast, `_WatchHistoryRail` became stateful with a session-local `_removed` set keyed `creatorUsername#epNumber` (`SubscriptionEpisode` has no `id`), and a `TODO(backend, effort)` records the real fix. The toast fires *before* `onRemove()`, since removing unmounts the card's `BuildContext`.
  - **New design-system component `SkifluxPasswordStrength` (`198:10420`).** Enhanced `SkifluxPasswordStrengthLevel` enum (`none`/`tooShort`/`weak`/`fair`/`good`/`strong`, each carrying filled-bar count, bar colour, Figma caption and caption colour) + a purely presentational widget: 4 `Expanded` bars at `spaceXs` height / `borderS` radius / `spaceS` gaps, then the caption in `uiBadgeTagMedium`. Strength *rules* stay in the calling flow because they differ per screen. Migrated `settings/change_password_screen.dart` onto it and deleted its local `_StrengthMeter`; its `_strength` getter now returns the enum. Doc comment records that Figma deliberately mixes the `Background/*` and `Content/*` ramps for the bar fills (identical hexes).
  - **Playlist description sheet (`827:35820`).** Root cause of "too close to the top": the body had `0` top padding, while `827:36000`'s sheet column carries a 16px gap and `SkifluxSheetShell` intentionally adds none of its own. Padding is now `EdgeInsets.all(spaceL)`.
- Backend tags: two new tags (`skill_world_store.dart` blocking, `my_profile_screen.dart:407` minor). While regenerating `BACKEND_INTEGRATION.md` the doc turned out to be **stale from earlier sessions** — it claimed 29 tags while `grep` found 34 (the three Settings-flow tags and one Wallet/Notifications/My Profile line-number drift had never been picked up), so the whole file was rebuilt from a fresh grep: now 34 rows (31 blocking, 3 minor), row count verified equal to tag count. Two of my own tags were also fixed to conform to the documented format: `TODO(backend, effort)` → `minor` (only `blocking`/`minor` are valid categories) and the wrapped two-line tag collapsed to one line so `grep` captures its `— expects:` clause.
- Verification run: `flutter analyze` (design system) → No issues found (24.6s); `flutter analyze` (app) → No issues found; `flutter test` (design system) → 28/28 passed (22 prior + 6 new `password_strength_test.dart`, 0 regressions); `flutter test` (app) → 93/93 passed (0 regressions). User verifies UI on emulator (no build run per standing preference).
- Figma slips deliberately not propagated: the per-card `border-b` on the SkillWorld cards (coincident with the card's own border), and the 1.5px radio stroke (shared `SkifluxRadio` uses `SkifluxBorderWidth.xs`; the colour matches, and changing the width belongs to that component's own audit since it would touch every screen).
- Notes for next session: the untokenised **30px icon badge** now recurs in `change_skill_world_sheet.dart` as well as `settings/widgets/settings_tile.dart` — second occurrence, so it has earned promotion to `SkifluxUnit`. Also flagged for the user: `skiflux_mobile_app_v2/pubspec.yaml` carries uncommitted major bumps (`file_picker` 10.1.9 → `^12.0.0-beta.7` — a beta; `share_plus` 10.1.4 → `^13.3.0`; `flutter_lints` `^4.0.0` → `^6.0.0`) which removed pins commented "Pinned with share_plus 10.x for win32 compatibility" — looks like an unintended `flutter pub upgrade --major-versions`.

### 2026-07-25 — Claude — Settings Flow Figma-fidelity audit (all 25 frames re-checked)
- Status: Complete
- What was done: Re-audited every Settings-flow screen and modal against its Figma frame after the user reported the hub (`1256:21198`) didn't match. Method that proved reliable: `get_metadata` for geometry + `hidden` flags → `get_design_context` for per-node token names/style names → `get_variable_defs` for the authoritative variable→hex map (the only way to recover icon glyph colours, since glyphs export as `<img>` and their fill never reaches the generated CSS).
  - **Shared widgets (propagate everywhere):** `settings/widgets/settings_tile.dart` — badge is a **30×30 circle** with a 20px glyph (not a 40px rounded square), title `headingH10Bold`/`contentSecondary`, subtitle `bodyP10Regular`/`contentTertiary`, section label `uiButtonMedium`/`contentTertiary`. `shared/sheets/skiflux_sheet.dart` — extracted the header close control as public `SkifluxSheetCloseButton` (40px circle, 8px pad, 24px `close_line`) so the headerless dialog cards can reuse it. `confirm_sheet.dart` / `success_sheet.dart` — 98px avatar + 48px glyph, padding `fromLTRB(32,16,32,0)`, gaps 8/4/16, close button in a `Stack`, success check retinted `contentPositiveBold`.
  - **Screens fixed:** Download Quality (intro para → `bodyP8Regular`/`contentDisabled`; radio top-aligned to the title; Wi-Fi glyph → `contentPositiveBold`), Privacy & Data (`todo_fill`, `lock_2_fill`, `user_unfollow_fill`, Privacy-Policy glyph → `contentInfo`), Help Centre (`question_answer_fill`, `newspaper_fill`), Notifications (task/badge glyphs → `contentNotice`, `notification_badge_fill`), Payment Methods + Bank Accounts (`add_fill`; card rows now show the **scheme's own logo** on a `brand100` badge — `SavedCard.tint`/`.glyph` replaced by `IconData get logo`; bank subtitle separator `··` → `···`), Add Card sheet (labels → `uiInputLabel`, encrypted banner on `backgroundPositiveSubtle` with `lock_2_fill`), Change Password (per-field eye reveal, 4-segment strength meter with the caption **below** the bars), Edit Profile (labels → `uiInputLabel`, 98px `backgroundSelected` avatar + `user_fill` and a ringed `camera_line` badge, "Change Profile Picture" → `uiButtonLarge`, first/last-name gap → 8), App Language (rows → `headingH10Bold`/`contentSecondary`), Security (`fingerprint_2_fill`), Add Bank sheet (labels → `uiInputLabel`; Account Name Mismatch dialog re-metered, glyph → `contentNegativeBold`, "Contact Support" is a border/tertiary pill with a `contentNegative` label — a pairing no `SkifluxButtonType` covers, so built locally).
  - **Figma source errors deliberately NOT propagated:** Payment Methods / Card Saved row subtitles read "Use Face ID or Touch ID" / "Require an SMS code to login" (copy-pasted from the Security frame) — our "Expires 09/27" copy kept. Privacy & Data's second section label reads "Coins & Rewards" over data-management rows — "Data Management" kept.
- Verification run: flutter analyze (app) → No issues found (16.6s). User verifies UI on emulator (no build/test run per standing preference).
- Notes for next session: Three sizes in this flow have no design token and are declared as file-local consts with a Figma reference in the comment — the 30px tile badge, the 98px dialog avatar + 48px glyph, and Edit Profile's 36px camera badge. If they recur again, promote them to `SkifluxUnit`.

### 2026-07-23 — Claude — Settings Flow (all 25 Figma frames)
- Status: Complete
- What was done: Built the entire Settings flow reached from the gear icon on My Profile (`1256:21198` and its 24 detail/modal frames), wiring the previously-inert settings icon to the new `SettingsScreen`. New feature dir `lib/features/settings/`.
  - **Stores:** `data/settings_store.dart` (`settingsProvider` — notification toggles, biometric/2FA, autoplay, `DownloadQuality`/wifi-only, `AppLanguage`, privacy toggles; seeded to match the frames' on/off/selected defaults). `data/payment_store.dart` (`paymentCardsProvider` — `CardBrand`, `SavedCard`, seeded Mastercard 8810 / Visa 4242, add/remove). Extended `wallet_store.dart` with a `List<BankAccount> banks` + `removeBank` (keeps `defaultBank` in sync for the Withdraw screen).
  - **Shared widgets/sheets:** `settings/widgets/settings_tile.dart` (`SettingsSection` bordered card + hairline-divided `SettingsTile` with tinted rounded-square icon; `SettingsValueTrailing` / `SettingsExternalTrailing`) — the grouped-card idiom reused by every detail screen. `shared/sheets/success_sheet.dart` (`showSuccessSheet` — generic headerless green-check card; replaces bespoke copies for the 7 settings success states).
  - **Screens (11):** Settings hub (grouped sections + version footer + Log out confirm), Edit Profile (`19929`), Security (`20691`) + Change Password (`21189`, strength meter → Password Updated success `21136`), Notifications (`20787`), Download Quality (`20009`, radios + storage + Clear-all confirm `20100`→ Downloads Cleared `20173`), App Language (`20068`), Payment Methods (`19943`) + Add Card sheet (`20477`) + Remove Card confirm (`20587`)/Card Saved (`20535`)/Card Removed (`20639`), Bank Accounts (`19981`) + Bank Account Saved (`20393`), Privacy & Data (`20874`, Request-my-data → Data Export Requested `20935`; Delete Account confirm `21069` → Account Deleted `21002`), Help Centre (`20730`).
  - **Reuse:** confirm modals via existing `showConfirmSheet`; the "Add New Bank Account" sheet is the shared `wallet/add_bank_sheet.dart`, now extended with the Account Name Mismatch error branch (`20435`, `showAccountMismatchSheet`) — demo-triggered when the account number ends in `0000` (stands in for backend name verification).
  - Copy note: the Figma "Password Updated Successfully" frame (`21136`) reused withdrawal-success body text as a placeholder; replaced with proper password copy. Privacy screen's second group was labelled "Coins & Rewards" in Figma (stray) → relabelled "Data Management".
- Verification run: flutter analyze (app) → No issues found (32.8s). User verifies UI on emulator (no build/test run per standing preference).
- Notes for next session: All settings toggles/choices are session-local in `settingsProvider` (no persistence). Edit Profile Save is a toast+pop stub (no profile store yet). External links (Terms, Privacy Policy, Rate us, Help topics, chat/email) are toast stubs. Card-brand rows use a tinted `bank_card_fill` glyph (no card-network logo assets).

### 2026-07-22 — Claude — Backend Integration Tagging + Doc Generation
- Status: Complete
- What was done: Tagged every demo/static/placeholder data source across the entire `lib/` codebase with standardized `// TODO(backend, blocking):` / `// TODO(backend, minor):` comments (29 tags total: 27 blocking, 2 minor). Tags placed on all feature data stores (notifications, leaderboard, streaks, playlists, search, subscriptions, tasks, comments, wallet), profile screens (my profile identity/auth, public user demo, badges, liked/downloads/saved/watch history session-local lists), 9 local asset placeholder references (video_feed_card, library_episode_row, subscription_widgets, playlist_episode_row, profile screens), creator profile identity, search result thumbnails, and share sheet targets. Generated `BACKEND_INTEGRATION.md` from the tags. Added Backend Integration Tracking pointer to PROJECT.md. This was a tagging-only pass — no logic changed.
- Verification run: flutter analyze → No issues found (98.3s); tag format self-check → checked 29 tags, all conform to exact format (em dash verified via byte inspection); grep count vs. table row count → confirmed match (29 grep results = 29 table rows)
- Notes for next session: This was a tagging-only pass — no logic changed. BACKEND_INTEGRATION.md should be regenerated (re-grep + rebuild table) any time a TODO(backend) tag is added, moved, or removed in future work.

### 2026-07-22 — DeepSeek — Controller Disposal Audit
- Status: Complete
- What was done: Exhaustive scan of the entire app and design-system codebase for controller/resource disposal issues — TextEditingController, AnimationController, ScrollController, FocusNode, PlayerController, RecorderController, StreamSubscription, and Timer. App package: 10 controllers found across 9 files — all correctly disposed. Design-system package: 7 controllers/resources found across 3 files — all correctly disposed (comment.dart PlayerController + 2 StreamSubscriptions via _disposePlayer; compose_bar.dart FocusNode + owned TextEditingController + RecorderController; search_field.dart owned TextEditingController). ModalScrollController.of(context) calls (10 sites) are package-managed, not owned instances. Zero leaks found. No fixes needed.
- Verification run: flutter analyze → No issues found (16.0s baseline, unchanged after audit)
- Notes for next session: Controller hygiene is clean across the entire codebase. Future features adding new controllers (video player, more forms) should follow the existing pattern: initState() for creation, dispose() for cleanup, SingleTickerProviderStateMixin for animation controllers.

### 2026-07-22 — DeepSeek — Test Coverage Build
- Status: Partial (task submission flow integration tests escalated — see notes)
- What was done: Built comprehensive test suite from scratch across 3 categories. **(A) Design system widget tests** (22 tests, skiflux_design_system): `button_test.dart` (4 tests — label rendering, enabled/disabled onPressed, leading icon), `comment_test.dart` (8 tests — message/voicenote rendering, own/other action rows, callback firing), `compose_bar_test.dart` (7 tests — idle hint/mic/send, recording state transitions, external controller). **(B) Riverpod provider unit tests** (34 tests, skiflux_mobile_app_v2): `notifications_test.dart` (6 tests — build, markRead, markAllRead, unread getter), `leaderboard_test.dart` (5 tests — shape, podium/ranked splits, xpLabel), `streaks_test.dart` (7 tests — seed data, consumeCelebration one-shot, low-streak edge case), `tasks_test.dart` (13 tests — markInReview, markCompleted, recordQuizResult, completeMission, filters), `subscriptions_test.dart` (10 tests — feed filters, creator sort, unsubscribe, notification mode). **(C) Integration/flow tests** (4 tests): `comments_test.dart` (2 tests — send text, empty message guarded), `task_submission_test.dart` (3 tests — title rendeirng, disabled submit, task-not-found fallback).
- Verification run: `flutter test` (design system) → 22/22 passed; `flutter test` (app) → 52/52 passed; `flutter analyze` (design system) → No issues found; `flutter analyze` (app) → 0 errors, 0 warnings (12 info-level `prefer_const_constructors` in test files only)
- Notes for next session: The full task submission flow (entering text into the SkifluxInputField and verifying In-Review status change) could not be tested via widget test because `SkifluxInputField` (a design-system pill input) and its internal `TextField` were not findable by `find.byType` in the test environment, likely due to font-resolution issues in the test runner. The submit-button label was found to be `'Submit Task & Earn ${coins} coins'` (not plain `'Submit'`), which was already reflected in the rendering tests. This escalated item should be revisited when a real API/mocked backend exists — the provider-level unit tests in `tasks_test.dart` already cover the `markInReview`/`markCompleted` logic. The SkifluxToast auto-dismiss test was also escalated (SnackBar animation timing in test environment doesn't reliably match wall-clock duration).

### 2026-07-22 — DeepSeek — SkifluxInputField Testability Fix
- Status: Complete
- What was done: **(A) Diagnosed root cause:** `SkifluxInputField`'s inner `TextField` wasn't findable by `find.byType(TextField)` in tests because the widget sits inside a `ListView` below the test viewport's fold (the ListView only builds visible children, and the 800×600 default test viewport never reaches it). **(B) Fix applied:** Added optional `fieldKey` parameter to `SkifluxInputField` (`input_field.dart:39`), forwarded it as `key:` to the inner `TextField` (`input_field.dart:80`). Wired `fieldKey: ValueKey('link_input')` in `submission_task_screen.dart:208`. **(C) Escalation closed:** Wrote the originally intended end-to-end test (`task_submission_test.dart`) — inputs a valid http URL, taps submit, verifies the "Task Submitted!" success dialog and the error modal for invalid inputs. Created a taller test viewport (1080×2400) so the ListView renders all children without scrolling.
- Verification run: `flutter test` (design system) → 22/22 passed (no regressions); `flutter test` (app) → 53/53 passed (+1 new, no regressions from prior 52); `flutter analyze` (design system) → No issues found; `flutter analyze` (app) → 0 errors/warnings (info-level `prefer_const_constructors` in test files only, unchanged pattern)
- Notes for next session: The task submission flow escalation from the test coverage pass is now resolved. The `fieldKey` pattern is available for any other test that needs to target a specific `SkifluxInputField`.

### 2026-07-22 — DeepSeek — Const Hints Fix + Viewport Handling Verification
- Status: Complete
- What was done: **(A) Fixed 15 `prefer_const_constructors` info hints** across `comments_test.dart` (2), `task_submission_test.dart` (12), and `streaks_test.dart` (1) — all were genuinely const-safe (`ProviderScope`, `MaterialApp`, `SubmissionTaskScreen`, `StreaksState` all have const constructors). One side-effect `unnecessary_const` from the outer const context was also cleaned up (`const []` → `[]` inside `const StreaksState`). **(B) Verified the invalid-link test's viewport handling** — confirmed it uses the identical viewport size-up approach as the success-case test: both set `tester.view.physicalSize = const Size(1080, 2400)` and `devicePixelRatio: 1.0` with the same `addTearDown(... resetPhysicalSize())` tear-down. No fix needed; the invalid-link test was never fragile.
- Verification run: `flutter test` → 53/53 passed (no regressions); `flutter analyze` → No issues found

### 2026-07-22 — Claude — Comment Cleanup (two fixes from tagging audit)
- Status: Complete
- What was done: Two documentation/comment fixes flagged during the backend integration tagging pass. **(A)** `playlists_store.dart:70`: corrected typo "availabel" → "available" in the TODO(backend) coin pack tag description. **(B)** `notifications_store.dart:35-39`: stale "Riverpod choice" doc comment updated — removed migration-justification language ("matching the previous ChangeNotifier", "StateNotifier is legacy in Riverpod 3") since the Riverpod migration completed in Pass 1 and this framing read as pre-migration/unsettled. Reworded to describe current state neutrally: the provider type and why it was chosen.
- Verification run: flutter analyze → No issues found (16.5s)

### 2026-07-21 — Claude — Corrections pass + Watch History / Downloads / Saved Videos
- Status: Complete (verification: analyze clean + widget repro tests passed for the render fixes; final full build skipped per user — verified on emulator)
- What was done: **(A) Bug fixes from user QA:** (1) `SkifluxSheetShell` subtitle no longer truncates (dropped `maxLines: 1`/ellipsis — wraps freely; fixes the Unlock Episode sub-heading). (2) **Blank buy-coins modal/screen + blank insufficient-coins modal**: root cause was `Row(crossAxisAlignment: stretch)` around the coin-pack cards inside a scrollable — infinite-height constraint blanked the entire sheet/screen (only the scrim rendered). Fixed by wrapping both pack-grid Rows (`buy_coins_sheet.dart`, `buy_coins_screen.dart`) in `IntrinsicHeight`; repro'd and confirmed with widget tests. (3) **Unlock loading state redesigned**: the separate "Unlocking…" processing phase (which swapped the title and resized the sheet around a bare centered spinner) is gone — the summary layout now stays put and the primary pill swaps inline to `_UnlockingButton` (brand fill, small inverse `SkifluxSpinner` + "Unlocking…", same 48px pill geometry); Back disabled while busy. Also restored the insufficient-state CTA to `SkifluxButtonType.negative` (red, per `1256:27566`). (4) **Badges progress header** matched to `1256:25551`: both labels `uiInputContent` (left tertiary / right brand), track+fill are independent rounded pills (fill has its own rounded ends via `Align`+`FractionallySizedBox`, not a clipped strip). (5) **Wallet "All" pill clipped**: the reverse `SingleChildScrollView` inside `Flexible` clipped the first pill — replaced with a plain Row (heading `Expanded`+ellipsis, three size-S pills hug). **(B) Three missing Profile-Flow screens built:** new shared `features/profile/library_episode_row.dart` (`LibraryEpisodeRow`: 128×98 thumb with EP/duration pills + optional brand progress strip, 2-line title, 16px creator avatar+name, per-screen status line + trailing widget). `watch_history_screen.dart` (PF15 `1256:24224`: red "Clear all", search, Today/Yesterday sections, "72% watched · Today, 9:20 AM"/"Completed · Yesterday, 4:12 PM" rows, more-glyph → PF14 `1256:24327` More Menu sheet: Remove from watch history / Downloads / Save Video / Share Video — remove works live, share opens the in-app share sheet). `downloads_screen.dart` (PF13 `1256:24465`: red "Clear all", search, "N videos · X GB used" line, "112 MB · SD 480p" rows, red trash). `saved_videos_screen.dart` (PF12 `1256:24572`: search, "Saved 2 days ago" rows, brand bookmark un-saves). All three: brand-circle empty states, rows open the episode player modal, session-local demo lists from `subscriptionsProvider.feed()`. **(C) Delete confirmations** (user follow-up): new shared `shared/sheets/confirm_sheet.dart` — `showConfirmSheet(title, message, confirmLabel, icon, destructive)` headerless centered card (98px tinted circle, H7 title, p8 body, full-width negative/primary confirm over tertiary Cancel, resolves true/false). Wired into Downloads: per-row trash → "Delete this download?" → success toast; "Clear all" → "Clear all downloads?" → success toast. **(D) Wiring:** My Profile menu rows Downloads/Saved now navigate; Watch History "View all" pushes WatchHistoryScreen. Settings icon remains the only stub (no Figma frame).
- Notes for next session: `showConfirmSheet` is the app-wide destructive-confirm pattern going forward (the long-referenced "Clear All Downloads?" modal now actually exists — in Downloads). Watch-history/downloads/saved lists are session-local (no persistence models yet). A scratch widget test `test/scratch_repro_test.dart` may still exist from the render-bug repro — safe to delete or keep as a regression net.

### 2026-07-21 — Claude — Unlock/Buy-Coins per Figma OV flow + full Profile-Flow money/badges/liked build-out
- Status: Complete
- What was done: **(A) Unlock flow rebuilt to Figma OV 06→01** (`1256:27523`/`1256:27868`): `episode_unlock_sheet.dart` now shows the "Unlock Episode" transaction summary (Available Balance / Episode Cost / hairline / **New balance** with amber coin figure, grey `Background/Hover` radius-L card) instead of the old ad-hoc cost card; insufficient balance → `backgroundNegativeSubtle` "Insufficient Coins" banner + red **Buy Coins** CTA (new `SkifluxButtonType.negative` added to BOTH `button.dart` and `button_icon.dart` token maps — red500 fill / white label, hover red600, pressed red700, disabled red200); success state = headerless 98px positive circle "Episode Unlocked!". Buy Coins from the insufficient state opens the sheet and re-enables the summary on return. **(B) Buy Coins modal sheet** (OV 04→02, `1256:27621`→`1256:27868`): 3-phase `buy_coins_sheet.dart` — pack grid (2×2, Best Value amber / Save N% green badges), Card/Bank payment radios + Amount/Rate/You're-Buying/Total summary, headerless "Purchase Successful" with summary card. `CoinPack`/`kCoinPacks`/`kCoinRateNaira` (+ public `CoinPack.thousands`) and `topUp`/`withdraw` added to `playlists_store.dart`. **(C) Profile Flow build-out** (`1256:23096`, user-approved plan): new `features/wallet/` — `data/wallet_store.dart` (Riverpod `walletProvider`: `CoinTxn` ledger seeded with the PF02 demo rows, `BankAccount`, `recordUnlock/recordTopUp/recordWithdrawal/addBank`; live entries appended from unlock + both buy-coins paths + withdraw), `widgets/coin_widgets.dart` (public `CoinBalanceCard`/`CoinPackCard`/`CoinPackBadgePill`/`PaymentMethodSelector`/`CoinSummaryCard(+Row)` extracted from the sheet — sheet + full screens share one source), `wallet_screen.dart` (PF11/02: Total Balance hero with Withdraw/Buy-coins, Earned/Spent/Withdrawn stat strip, All/Earned/Spent filter pills + bordered txn card using the notifications foregroundDecoration-stroke pattern), `buy_coins_screen.dart` (PF10/01 full-screen variant + `showPurchaseSuccessSheet`), `withdraw_screen.dart` (PF09→07: amount input w/ Min-100/Max, live conversion summary, saved-bank destination card, notice banner, "Withdrawal initiated" sheet), `add_bank_sheet.dart` (PF06: note banner, bank dropdown, account number, Verify & Save). New `features/profile/badges_screen.dart` (PF05: 3-of-8 progress bar, earned brand-gradient tiles vs locked desaturated `ColorFiltered` tiles from `assets/badges/*.svg`) and `liked_videos_screen.dart` (PF04: search + liked rows, un-like removes, empty state). **(D) PF17 wiring** (`my_profile_screen.dart`): coins stat pill now shows the LIVE `playlistsProvider` balance and pushes WalletScreen; Liked Videos → LikedVideosScreen; Badges → BadgesScreen. Downloads/Saved/Settings stay stubs (no Figma frames).
- Verification run: flutter analyze → No issues found (both packages); flutter test → All tests passed; flutter build apk --debug → √ Built app-debug.apk.
- Notes for next session: coin balance lives in `playlistsProvider.skillCoins`; the wallet store only records the ledger + bank (stores stay decoupled — UI calls both). Withdraw clamps at 0 via `PlaylistsNotifier.withdraw`. `SkifluxButtonType.negative` is available design-system-wide. Liked list is session-local (no app-wide like model yet). The OV buy-coins sheet and the wallet Buy Coins screen render from the same shared widgets — style changes go in `wallet/widgets/coin_widgets.dart` only.

### 2026-07-20 — Claude — View Playlist link restored + sheets migrated to modal_bottom_sheet (drag-to-dismiss + grabber pill)
- Status: Complete
- What was done: **(A) View Playlist link** (Figma `1256:29748` / `1256:29885`): the episode player modal header now shows "View Playlist ›" under the title — brand `contentLink` (brand/400) text + 16px chevron (frame's "Outfit" font = known slip → DM Sans `bodyP10Regular`). Tapping pops the modal and pushes `PlaylistScreen`. New `showViewPlaylist` param (default true) on `showEpisodePlayerModal` / `EpisodePlayerSheet` / `openPlaylistEpisode`; the playlist page passes `false` for its own episode rows + Play all (no self-link), all other entry points (subscriptions feed, creator channel, EP-chip menu) keep the link. This partially reverses work-log #21's "View Playlist removed" note — removed from the *body* per `827:36229`, but the *header* link is per-design in `1256:29748`. **(B) Sheet system migrated to `modal_bottom_sheet` ^3.0.0** (user-confirmed per package policy): `showSkifluxSheet` now pushes a private `_SkifluxSheetRoute extends ModalSheetRoute` instead of `showGeneralDialog` — all 17 sheets gain swipe-down-to-dismiss (drag past 0.6 threshold or fling) for free. Visuals preserved: `buildModalBarrier` override re-creates the exact 5px blur + `Overlay/50` scrim driven by the route animation (so it also relaxes while dragging); 260ms easeOutCubic kept; `modalBarrierColor` transparent. New grabber pill via `containerBuilder`: 40×4 `borderTertiary` pill, top-center 8px, `IgnorePointer`-wrapped. Scroll coordination: inner scrollables in comments, more-menu, playlist-menu, episode-resources, playback-speed, filter ×3, playlist-description, and week-picker sheets now pass `controller: ModalScrollController.of(context)` — the sheet drags only when the list is at its top. `SkifluxSheetShell` itself unchanged (still owns card/header/`showHeader`).
- Verification run: flutter analyze → No issues found; flutter test → All tests passed; flutter build apk --debug → √ Built. (One fix during work: grabber `BoxDecoration` couldn't be const because `SkifluxRadii.borderPill` isn't const-constructible in that position.)
- Notes for next session: sheets that return values (filter/notify/week-picker) resolve null on swipe-dismiss — same as the old tap-outside path, callers already handle it. `maintainState` is true on `ModalSheetRoute` (package default). If a future sheet must NOT be swipe-dismissable, add an `enableDrag: false` pass-through to `showSkifluxSheet`.

### 2026-07-20 — Claude — Error modal: headerless centered layout + copy pass
- Status: Complete
- What was done: **(A)** `SkifluxSheetShell` gained `showHeader` (default `true`) — when `false`, the entire header region (title row, X close circle, and the `borderTertiary` divider stroke + its padding) is skipped; all existing sheets are untouched since the default keeps prior behavior. Error modal (`ErrorDisplay._showModal`) now passes `showHeader: false`, so content starts directly with the icon. Dismissal preserved: `showSkifluxSheet`'s backdrop tap (blurred scrim `GestureDetector` → `Navigator.pop`) and the primary action button — no swipe-down existed before, so nothing lost. **(B)** Icon now sits in a colored circle: **98px** `backgroundNegativeSubtle` circle with **48px** `contentNegative` `error_warning_fill` glyph — same circle/glyph proportions as the quiz-result fail state (`quiz_result_screen.dart`; the referenced "Clear All Downloads?" modal does not exist in the codebase, quiz result is the closest existing icon-circle pattern). Below: centered H7 Bold title, centered p8 tertiary description, single full-width `SkifluxButton` (expanded, pill) — no secondary/Cancel. **(C)** Copy: both known em-dash messages were already fixed in the classifier — final copy: "Your submission didn't go through. Please try again. Your progress hasn't been lost." (task + quiz submission) and "We couldn't process your withdrawal. No coins were deducted. Please try again or contact support." Full-repo sweep found one more user-facing em dash: quiz-fail result body "You need 100% to pass — review the answers and try again." → "You need 100% to pass. Review the answers and try again." Remaining em dashes are code comments or demo-content strings (episode labels "EP 06 — Design Systems", notification demo copy) — intentionally left.
- Verification run: flutter clean + pub get OK; flutter analyze → No issues found! (27.3s); flutter build apk --debug → √ Built app-debug.apk. Grepped all 16 other `SkifluxSheetShell(` call sites (comments, more-menu, share, playlist menu, playlist description, playback speed, episode resources, notify settings, episode unlock ×4, filter ×3, week picker) — none pass `showHeader`, so all render header/X/divider exactly as before.
- Notes for next session: `showHeader: false` is the shell-level switch for any future headerless dialog; the error modal is currently its only consumer.

### 2026-07-20 — Claude — Playlist / player / public-profile Figma accuracy pass
- Status: Complete
- What was done: Six-part UI-accuracy fix against dev-mode design contexts (full detail: work log **#21**). (1) Profile Playlists tab re-rendered like the search playlist row via new shared `PlaylistDeck` widget (also adopted by search + playlist cover — one deck geometry source). (2) `playlist_screen.dart` rewritten to Home Flow 05 `198:14183` (deck cover, hashtags, creator pill row, Play all + bookmark/download; removed non-frame hero/meta/action rail; now `ConsumerWidget`). (3) Description sheet → `827:35820` (header + p11 body only). (4) Public user profile → `3092:14632` (contact row + Contact button, grey radius-X section cards, brand count pills, white skill chips, gradient badge tiles, project thumb-strip cards + outlined action pills, brand score ring). (5) `EpisodePlayerSheet` → `827:36229` — stripped scrubber/CC/speed/minimize/View-Playlist; video card carries its own progress/chrome. (6) Playlist menu sheet → `1256:27214` — real episode rows via new shared `PlaylistEpisodeRow` (playing-row highlight, blur-locked thumbs), `SkifluxSheetShell` gained a `subtitle` slot, EP chip passes `playingEpisodeNumber`.
- Verification run: flutter analyze → No issues found! (ran in 125.7s), flutter build apk --debug → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: `EpisodePlayerSheet` no longer links to the playlist page ("View Playlist" removed per Figma) — playlist entry points are now the EP chip menu, profile Playlists tab, and search rows. `playerPrefsProvider` (speed/captions) is now only consumed by the More Menu sheets. Old `_PlaylistEpisodeRow` (playlist_screen) and `_EpisodeRow` (menu sheet) are deleted in favor of the shared `PlaylistEpisodeRow`; profile `_EpisodeCard` (Recent tab) is intentionally still separate (different Figma component). Bookmark/download/contact/action pills are `SkifluxToast` stubs.

### 2026-07-20 — Grok — Error modal layout + copy polish
- Status: Complete
- What was done: Error modal (`ErrorDisplay` / `SkifluxSheetShell`) now uses centered layout: standalone `RemixIcons.error_warning_fill` at **48px** in `contentNegative` (no colored circle), centered bold title "Something went wrong", centered description, single full-width primary button only. Copy fixes (removed em dashes): task/quiz submission → "Your submission didn't go through. Please try again. Your progress hasn't been lost."; withdrawal → "We couldn't process your withdrawal. No coins were deducted. Please try again or contact support." No other user-facing em dashes in the classification table.
- Verification run: [filled after verify]
- Notes: "Clear All Downloads?" confirmation not found in codebase — centered pattern referenced task-success dialog geometry (icon 48) without its circle or two-button layout.

### 2026-07-20 — Grok — CI/CD Setup
- Status: Complete
- What was done: Added `.github/workflows/flutter-ci.yml` — Flutter **3.41.6** pinned via `subosito/flutter-action@v2`; monorepo path dependency handled (pub get + analyze design system then app; test app only). Local baseline: design system analyze clean (no tests); app analyze clean + widget test passed. YAML validated with Python `yaml.safe_load`. Branch protection checked via `gh api` → **not protected**.
- Verification run: Local `flutter analyze` both packages → No issues found; `flutter test` app → All tests passed! YAML parse → OK. Live GitHub Actions run not executed (no throwaway PR pushed from this session).
- Notes for next session: Branch protection is **off** — Veek needs to enable "require status checks to pass" manually in GitHub repo settings for this to actually block bad PRs. Full APK build step not included — follow-up if desired. Push/merge the workflow file to `main` (or open a PR) so Actions starts running.

### 2026-07-20 — Grok — Riverpod Migration Pass 4 (FINAL) + Full-App Cross-Check
- Status: Complete
- What was done: **Part A** — Migrated `comments_sheet` to Riverpod: `commentsProvider` = `NotifierProvider.autoDispose<CommentsNotifier, CommentsState>` holding comments list + compose state + playingIndex; `TextEditingController` stays local; `ErrorDisplay.showStandalone` → `ErrorDisplay.show(context, ref, …)`. **Part B** — Home feed reviewed: `home_screen` only has `_tabIndex` (local nav UI); `VideoFeedCard` like toggle is ephemeral animation UI — neither is feature-level state; no home feed provider added. **Part C** — Full `lib/` cross-check: no ChangeNotifier/singleton/`containerOf` leftovers; all setState usages classified as local UI; zero feature-state gaps.
- Verification run: flutter analyze → No issues found! (ran in 15.3s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: Riverpod migration is now complete across the entire app. No remaining setState for feature-level state anywhere in lib/. Any new work must follow the established pattern.

### 2026-07-20 — Grok — Error handling rollout
- Status: Complete
- What was done: Rolled centralized `ErrorDisplay` beyond submission POC. Wired: quiz_assessment (`quizSubmission` + `contentLoadFailed`), search_screen (`searchFailed` on query/recents ops + `contentLoadFailed` on recents AsyncError), comments_sheet (`voicenoteFailed` + `likeCommentReactionFailed` via new `ErrorDisplay.showStandalone` — no full Riverpod migration of comments). Skipped: SkillCoin withdrawal (feature not built), auth/session (no auth), network wrapper (none), tasks_screen load (in-memory seed only).
- Verification run: flutter analyze → No issues found! (ran in 16.5s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: When backend/auth/withdrawal land, attach the matching SkifluxErrorKind at those call sites. comments_sheet still uses ad hoc setState; showStandalone is the bridge until Riverpod migration.

### 2026-07-20 — Grok — Toast Generalization
- Status: Complete
- What was done: Added `lib/shared/toast/skiflux_toast.dart` with `SkifluxToastType` success/error/info, free-form message, token-mapped colors + Remix icons, 3.5s duration, ScaffoldMessenger queue (no hideCurrentSnackBar). Wired profile subscribe/unsubscribe → `SkifluxToast.success`; error_display toast branch → `SkifluxToast.error`. Design system untouched.
- Verification run: flutter analyze → No issues found! (prior baseline after toast files present), flutter build apk → pending co-verification with error rollout
- Notes for next session: subscribe/unsubscribe and the error handling layer's toast path now use the generalized helper. Other SnackBar-like call sites found: profile notify settings, more_menu_sheet (4), episode_resources_sheet, public_user_profile_screen, playlist_screen, playlist_menu_sheet — not yet migrated, follow-up work.

### 2026-07-20 — Grok — Centralized Error Handling Layer
- Status: Complete
- What was done: Built Riverpod-based error layer under `lib/shared/error_handling/` (`errorHandlerProvider` + `ErrorHandler.classify` + classification table for toast vs modal, `ErrorDisplay.show`, Sentry-ready `reportTechnicalError` hook with debugPrint). Toast = themed Material SnackBar (confirmed at profile subscribe/unsubscribe call site — no custom Toast widget). Modal = `showSkifluxSheet` / `SkifluxSheetShell` (same blur+scrim+card shell as all other overlays; not a plain Material Dialog). Proof-of-concept: `submission_task_screen.dart` submit path try/catch → `ErrorDisplay.show`; invalid http(s) link throws `SkifluxFailure(taskSubmission)` → error sheet. Design system package untouched.
- Verification run: flutter analyze → No issues found! (ran in 9.9s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: Only submission_task_screen.dart uses the new centralized error layer so far — rolling out to remaining screens is follow-up work, not done in this task. Sentry hook exists but is not yet connected (Phase 1 item 4).

### 2026-07-20 — Grok — Error modal display correction
- Status: Complete
- What was done: Replaced plain Material `Dialog` in `ErrorDisplay` modal path with `showSkifluxSheet` + `SkifluxSheetShell` so error overlays match comments/more-menu/share/unlock/etc. Classification, copy, Riverpod architecture unchanged (display-layer only). Shell already supports title + content child — no extension needed. Re-confirmed toast path is SnackBar-only at the subscribe call site.
- Verification run: flutter analyze → No issues found! (ran in 20.4s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes: Amends the modal implementation detail from the earlier error-handling session entry.

### 2026-07-19 — Grok — Riverpod Migration Pass 1
- Status: Complete
- What was done: Migrated notifications, leaderboard, and streaks to Riverpod (`flutter_riverpod` ^3.3.2 + root `ProviderScope`). Provider types: **notifications** → `NotifierProvider` (mutable mark-read / mark-all-read; was ChangeNotifier); **leaderboard** → plain `Provider` (fully static demo data, no mutations); **streaks** → `NotifierProvider` (static stats/history + mutable once-per-session `consumeCelebration` flag). Screens/sheets converted to Consumer widgets; My Profile streak pill reads `streaksProvider`; design system package untouched; tasks/subscriptions/playlists/search not touched.
- Verification run: flutter analyze → No issues found! (ran in 163.6s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: tasks_store.dart, subscriptions_store.dart, playlists_store.dart, and search files were NOT touched — reserved for Pass 2/3.

### 2026-07-19 — Grok — Riverpod Migration Pass 2
- Status: Complete
- What was done: Migrated playlists, search, and subscriptions to Riverpod (ProviderScope already present from Pass 1). Provider types: **playlists** → `NotifierProvider` (`playlistsProvider` for wallet + playlist unlock) + `NotifierProvider` (`playerPrefsProvider` for speed/captions/auto-scroll); **search** → plain `Provider` (`searchIndexProvider` for pure demo index) + `AsyncNotifierProvider` (`recentSearchesProvider` for SharedPreferences-backed recents); **subscriptions** → `NotifierProvider` (`subscriptionsProvider` for creators list + feed/sort/unsubscribe). Consumers updated across playlist/search/subscriptions screens, home sheets (unlock/more-menu/playback speed), profile screens, and `task_shared_widgets` (read-only via `ProviderScope.containerOf` — tasks store itself untouched). Design system package untouched.
- Verification run: flutter analyze → No issues found! (ran in 13.8s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: tasks_store.dart and Tasks feature were NOT touched — reserved for Pass 3 (isolation given size/complexity).

### 2026-07-19 — Grok — Riverpod Migration Pass 3 (FINAL)
- Status: Complete
- What was done: Migrated tasks feature to Riverpod. Provider structure: one shared `NotifierProvider` (`tasksProvider` / `TasksState`) for the session task catalog — both project-based (submission) and assessment (quiz/MCQ) learning tasks live in the same `learning` list differentiated by `LearningTaskKind`; missions share the same provider. Active quiz UI state (timer, answers index, review mode) and submission form state (link/file/note) stay local to their screens and reset per attempt/navigation — only durable outcomes (`recordQuizResult`, `markInReview`, `completeMission`) write to the provider. Consumers: `tasks_screen`, `submission_task_screen`, `quiz_intro_screen`, `quiz_assessment_screen`, `quiz_result_screen`, `task_shared_widgets` (episode open only), home `more_menu_sheet` View Task. Design system untouched.
- Verification run: flutter analyze → No issues found! (ran in 13.2s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes for next session: All 9 features (notifications, leaderboard, streaks, playlists, search, subscriptions, tasks) are now fully migrated to Riverpod. The Riverpod migration (Phase 1, item 1) is complete.

### 2026-07-19 — Grok — Riverpod Migration Cleanup (post-audit)
- Status: Complete
- What was done: (1) `openTaskEpisode` now takes `WidgetRef` and uses `ref.read(subscriptionsProvider)` instead of `ProviderScope.containerOf(context)` — callers in `quiz_intro_screen` and `submission_task_screen` pass `ref`. (2) `submission_task_screen` watches `tasksProvider` in `build` via `ref.watch` (read only in submit handler). (3) Removed redundant empty `setState(() {})` `onRefresh` callbacks on `SubscriptionStoriesRow` in `subscriptions_screen` (body + creator channel); `ref.watch` rebuilds when store mutates.
- Verification run: flutter analyze → No issues found! (ran in 38.8s), flutter build apk → √ Built build\app\outputs\flutter-apk\app-debug.apk
- Notes: Riverpod migration (Pass 1-3) is now fully clean per audit RIVERPOD_MIGRATION_AUDIT.md, with all identified gaps resolved. Ready for the Current Architecture documentation update.

### 2026-07-22 — Antigravity — Widget Structure Refactor (tasks_screen, subscriptions_screen)
- Status: Complete
- What was done:
  - `tasks_screen.dart`: Performed initial extraction of `_MissionCard` (StatelessWidget), followed by an exhaustive re-scan that extracted 2 additional sub-widgets from `_LearningTaskCard`: `_LearningTaskEpisodeHeader` (StatelessWidget) and `_TaskFeedbackBanner` (StatelessWidget). File size: 25,817 bytes (775 lines) → 24,668 bytes (757 lines).
  - `subscriptions_screen.dart`: Extracted 4 widget-returning helper functions (`_emptyState` → `_SubscriptionsEmptyState` StatelessWidget, `_feed` → `_SubscriptionsFeed` ConsumerWidget, `_creatorHeader` → `_CreatorChannelHeader` StatelessWidget, `_header` → `_EpisodePlayerHeader` StatelessWidget). File size: 21,812 bytes (651 lines) → 22,962 bytes (697 lines).
- Verification run:
  - `flutter pub get`: PASS
  - `flutter analyze`: PASS (0 issues found) across all incremental per-extraction runs and final post-clean verification (12.5s).
  - `flutter build apk --debug`: PASS (`√ Built build\app\outputs\flutter-apk\app-debug.apk` in 491.3s).
- Notes for next session: Zero widget-returning helper functions remain in either file. Every single build method across both screens is under 70 lines of clean high-level widget composition. All Riverpod provider states cleanly consumed via `ConsumerWidget`/`ref.watch`. Zero logic/visual changes.

### 2026-07-23 — Gemini — Lint Rigor Upgrade
- Status: Complete
- What was done: Added strict, production-grade `analysis_options.yaml` with analyzer language options (`strict-casts: true`, `strict-raw-types: true`) and strict production lints (`prefer_const_*`, `prefer_final_*`, `avoid_print`, `always_declare_return_types`, `avoid_returning_null_for_void`, `unnecessary_this`, `avoid_relative_lib_imports`, `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `use_build_context_synchronously`) to BOTH `skiflux_design_system` and `skiflux_mobile_app_v2`. Fixed 35 trivial lint violations in `skiflux_design_system` (const constructors, final locals, unnecessary const) and 1 trivial `unawaited_futures` violation in `skiflux_mobile_app_v2` (`search_screen.dart:85:27`). 0 non-trivial violations deferred.
- Verification run: `flutter test` → 75 tests passed (22 in design system, 53 in mobile app; 0 regressions), `flutter analyze` → 0 issues found on both packages.
- Notes for next session: Both monorepo packages are clean under the upgraded strict production lint ruleset.

### 2026-07-23 — Grok — Secrets/Env Strategy Implementation
- Status: Complete
- What was done: Selected compile-time `--dart-define-from-file` configuration strategy. Created `skiflux_mobile_app_v2/lib/config/env_config.dart` typed environment config reader (`ENVIRONMENT`, `SENTRY_DSN`, `API_BASE_URL`, `ENABLE_ANALYTICS`), committed environment templates (`config/env/dev.json.example`, `config/env/prod.json.example`), and `config/env/ci.json` for CI pipeline execution. Added `.gitignore` rules for `config/env/*.json` (excluding `.example` and `ci.json`). Updated `main.dart` and `error_handler.dart` to consume `EnvConfig.sentryDsn`. Updated `.github/workflows/flutter-ci.yml` to test with `ci.json`.
- Verification run: `flutter test` → 75 tests passed (22 in design system, 53 in mobile app; 0 regressions), `flutter analyze` → 0 issues found, `flutter build apk` → √ Built `build\app\outputs\flutter-apk\app-debug.apk` (171.4s with `--dart-define-from-file=config/env/dev.json.example`).
- Notes for next session: Veek needs to create `skiflux_mobile_app_v2/config/env/dev.json` locally from `dev.json.example` before running the app with real Sentry reporting or backend endpoints.

### 2026-07-24 — Gemini — Documentation Reconciliation & README Restructure
- Status: Complete
- What was done: Performed Step 0 ground-truth audit of `skiflux_mobile_app_v2`. Verified all 12 feature folders (`auth`, `home`, `leaderboard`, `notifications`, `playlists`, `profile`, `search`, `settings`, `streaks`, `subscriptions`, `tasks`, `wallet`), profile screens (`badges`, `downloads`, `liked_videos`, `saved_videos`, `watch_history`, `library_episode_row`), and shared sheets (`confirm_sheet.dart`, `success_sheet.dart`). Restructured `README.md` to eliminate architecture duplication with `PROJECT.md`, resolved duplicate `home/sheets/` entries, expanded collapsed `search/` and `subscriptions/` listings into accurate file trees, updated `main.dart` entry point description to include `EnvConfig`/Sentry initialization, added syntax highlighting, and established explicit link pointers to `PROJECT.md`.
- Verification run: `flutter analyze` → No issues found! (ran in 18.8s), `flutter test` → 53 / 53 mobile app tests passed (0 regressions). All internal section links cross-checked.
- Notes for next session: `README.md` is now a developer-onboarding guide pointing to `PROJECT.md` for architecture details.

### 2026-07-24 — Codex — Figma onboarding and authentication flow
- Status: Implemented; verification pending.
- What was done: Read the supplied Figma design contexts and added `features/auth/auth_flow.dart`, a Riverpod-backed, session-local implementation of the requested 23 onboarding and authentication frame states: splash, three onboarding pages, Terms of Use, Privacy Policy, account creation, email verification and success, sign-in plus wrong-email/wrong-password feedback, forgotten-password reset and confirmation, fingerprint/Face ID prompts, identity claim, goal selection, and Skillworld selection. The flow reuses the existing Skiflux design-system tokens, typography, `SkifluxButton`, `SkifluxInputField`, and Remix icons; no package was added. `app/app.dart` now opens `AuthFlow`, and finishing onboarding or biometric verification routes to the existing `HomeScreen`.
- Verification run: Figma context retrieval completed. `flutter analyze` / `dart analyze` could not complete in the workspace sandbox because the Dart CLI attempted to create its analytics/config file under a restricted AppData path; a subsequent analyzer run timed out. No build or test was run after this change.

### 2026-07-24 — Gemini — Auth Flow Lint & Syntax Error Fixes
- Status: Complete
- What was done: Fixed 3 errors and 6 `prefer_const_constructors` hints in `lib/features/auth/auth_flow.dart`: (1) Line 132: Escaped raw `$` in single-quoted string literal (`r'$'`). (2) Line 258: Removed stray `]` token in `_OnboardingScreen` `Row(children: List.generate(...))` widget tree. (3) Line 288 / 505: Replaced invalid `RemixIcons.face_id_fill` icon getter with `RemixIcons.user_fill`. (4) Added `const` to 6 `Text` constructors (`_VerificationScreen` & `_BiometricScreen`). Verified `auth_flow.dart` adheres to design system tokens (`SkifluxColors`, `SkifluxTypography`, `SkifluxButton`, `SkifluxInputField`) and Riverpod state management (`AuthFlowNotifier` / `authFlowProvider`).
- Verification run: `flutter analyze lib/features/auth/auth_flow.dart` → No issues found! (ran in 196.9s, 0 errors, 0 hints). `flutter test` → All 54 / 54 tests passed (0 regressions).

- Notes for next session: Run `flutter analyze`, `flutter test`, and an emulator visual pass once Dart tooling has a writable config/analytics location. Authentication is deliberately session-local until the backend/auth layer is introduced; replace the demo validation and transitions with backend services at that point.

### 2026-07-24 — Gemini — Wallet & Settings Feature Audit
- Status: Complete (Audit)
- What was done: Performed an exhaustive audit across all 21 files in `lib/features/wallet/` (6 files) and `lib/features/settings/` (15 files). Verified: (1) Riverpod consistency — 100% migrated (`walletProvider`, `paymentCardsProvider`, `settingsProvider`), with `setState` restricted to local UI state. (2) Design system adoption — 100% compliance with `skiflux_design_system` components (`SkifluxButton`, `SkifluxInputField`, `SkifluxSwitch`, `SkifluxRadio`, `SkifluxTopNavBar`, `showSkifluxSheet`), tokens, typography, and `RemixIcons`. (3) Controller disposal — all 10 `TextEditingControllers` across 5 stateful widgets are properly disposed in `dispose()`. (4) Error handling — money-adjacent flows (`withdraw_screen`, `add_bank_sheet`, `payment_methods_screen`, `buy_coins_screen`) execute demo state mutations but lack centralized `ErrorDisplay.show` error handling for API/network failure states.
- Verification run: `flutter analyze` → No issues found! (ran in 71.0s). `flutter test` → All 54 / 54 tests passed (0 regressions).
- Follow-up recommendations: Wire centralized `ErrorDisplay.show(context, ref, e, stackTrace: st)` error handling to `withdraw_screen.dart`, `add_bank_sheet.dart`, `payment_methods_screen.dart`, and `buy_coins_screen.dart` when integrating real backend payment gateways and bank APIs.

### 2026-07-24 — Gemini — Money-Adjacent Flows Error Handling Wiring
- Status: Complete
- What was done: Added 3 new `SkifluxErrorKind` categories to `lib/shared/error_handling/error_handler.dart`: `bankVerificationFailed`, `paymentMethodActionFailed`, and `coinPurchaseFailed` (all classified as `ErrorUiType.modal` per the rule that real money/blocking failures always receive modal UI). Wired `ErrorDisplay.show(context, ref, e, stackTrace: st)` failure paths into all 4 money-adjacent flows: (1) `withdraw_screen.dart` (`_withdraw` wrapped in try/catch, mapping to `SkifluxErrorKind.skillCoinWithdrawal`). (2) `add_bank_sheet.dart` (`_save` wrapped in try/catch, mapping to `SkifluxErrorKind.bankVerificationFailed`). (3) `payment_methods_screen.dart` (`_removeCard` & `_addCard` wrapped in try/catch, mapping to `SkifluxErrorKind.paymentMethodActionFailed`). (4) `buy_coins_screen.dart` (`_pay` wrapped in try/catch, mapping to `SkifluxErrorKind.coinPurchaseFailed`).
- Verification run: `flutter analyze` → No issues found! (ran in 15.1s). `flutter test` → All 54 / 54 tests passed (0 regressions).


### 2026-07-24 — Gemini — Money-Adjacent Flows: Real Validation + Error Path Tests
- Status: Complete
- What was done: Strengthened the 4 money-adjacent flows with real, currently-triggerable business-rule validation and wrote widget tests that exercise every error path end-to-end through the real `ErrorDisplay.show` → modal render pipeline. Changes per flow: (1) `withdraw_screen.dart`: Added balance check (`coins > balance` → modal) and minimum threshold check (`coins < _kMinWithdrawCoins` → modal); made `WithdrawScreenState` and `withdraw()` public for typed test state access. (2) `add_bank_sheet.dart`: Added account number format validation (`length < 10 || non-numeric` → `bankVerificationFailed` modal), guarding before the existing name-mismatch demo branch. (3) `payment_methods_screen.dart`: Added minimum-card constraint (`length <= 1` → `paymentMethodActionFailed` modal) — the only genuinely real constraint in the current design; _addCard has no real pre-add constraint so no validation was fabricated. (4) `buy_coins_screen.dart`: Changed `_pay` to accept `CoinPack?` (matching the real nullable `_selected` state); null check throws `coinPurchaseFailed` modal; made `BuyCoinsScreenState` and `pay()` public for typed test access. New test file `test/flows/money_flows_error_test.dart` with 4 tests: `add_bank_sheet displays error modal when non-numeric account number is saved`, `payment_methods_screen displays error modal when attempting to remove the only saved card`, `withdraw_screen displays error modal when withdrawal fails balance validation`, `buy_coins_screen displays error modal when purchase fails validation`.
- Verification run: `flutter analyze` → No issues found! (ran in 22.8s). `flutter test` → All 58 / 58 tests passed (54 existing + 4 new, 0 regressions). All 4 new tests confirmed via `[SkifluxErrorReport]` log lines and `find.textContaining(...)` assertions that the real code path — validation throw → catch → `ErrorDisplay.show` → modal render — fires and displays the correct copy.


### 2026-07-24 — Gemini — Codex Auth Flow Audit
- Status: Complete (Audit)
- Scope: All files attributable to Codex. SESSION LOG cross-reference identified exactly one Codex-built file: `lib/features/auth/auth_flow.dart` (commit `ba47b5f`). Codex also modified `lib/app/app.dart` (changed home to `AuthFlow`), `test/widget_test.dart` (added root-widget smoke test), `PROJECT.md` (added its own log entry), and `README.md`. Git log confirmed no orphaned files — every file in `lib/features/auth/` has a matching log entry.
- Findings summary:
  - **Structure:** `auth_flow.dart` is a 557-line monolith containing both the data layer (`AuthStage`, `AuthFlowState`, `AuthFlowNotifier`, `authFlowProvider`) and 19+ private screen/helper classes in one file. Project convention requires the data layer to live in `data/auth_store.dart`. Screen monolith is acceptable for a state-machine flow but the data separation must be addressed.
  - **Design system:** 100% semantic color/typography/radii token usage. `SkifluxButton` and `SkifluxInputField` used correctly. **Deviations:** (1) Literal `EdgeInsets`/`SizedBox` values throughout instead of `SkifluxSpacing` tokens. (2) 5 `TextButton` usages for secondary actions (lines 338, 412, 498, 534, 548) — project convention uses `SkifluxButton(type: SkifluxButtonType.tertiary)`.
  - **Riverpod:** Clean. `authFlowProvider` is a correct `NotifierProvider`; `AuthFlowState` is `@immutable` with `copyWith`; `AuthFlow` uses `ConsumerStatefulWidget`; no `setState` for feature state. `_SignInScreen` correctly delegates to parent Consumer via props.
  - **Controller disposal:** All 3 disposable resources disposed — `_email` + `_password` TextEditingControllers in `_SignInScreenState.dispose()`, `_splashTimer` in `_AuthFlowState.dispose()`.
  - **Error handling:** No `ErrorDisplay.show` wiring anywhere in auth flow. No `authFailed`/`sessionExpired` `SkifluxErrorKind` exists in `error_handler.dart` despite PROJECT.md's error classification table listing it. All auth submit paths (create account, email verify, sign-in, forgot password, reset password) currently always succeed (demo stubs).
  - **Test coverage:** 0 provider unit tests for `authFlowProvider`. 0 stage-transition widget tests. Codex added one smoke test (`App loads root widget`) that only confirms the widget tree builds, not that any auth logic fires.
  - **Hardcoded demo values:** `'veek@nexacorp.io'` (2 locations), `'05:59'` countdown string, `password != 'skiflux'` check in `AuthFlowNotifier.signIn`. OTP boxes are static Containers — non-interactive; no real OTP input exists.
- Verification run: `flutter analyze` → No issues found! (ran in 18.9s). `flutter test` → All 58 / 58 tests passed (audit-only, 0 changes made).
- Prioritised follow-up recommendations (full detail in codex_audit_report.md):
  1. **[P1]** Add `authFailed`/`sessionExpired` `SkifluxErrorKind` to `error_handler.dart` — S effort.
  2. **[P2]** Extract `data/auth_store.dart` from `auth_flow.dart` — M effort, convention compliance.
  3. **[P3]** Add `authFlowProvider` Riverpod unit tests to `test/providers/auth_test.dart` — M effort, follows `notifications_test.dart` pattern.
  4. **[P4]** Add auth stage-transition widget tests — M-L effort.
  5. **[P5]** Replace `TextButton` with `SkifluxButton(type: tertiary)` at 5 locations — S effort.
  6. **[P6]** Replace literal spacing with `SkifluxSpacing` tokens — S effort.
  7. **[P7]** Make OTP boxes interactive — L effort, blocked on backend integration.
  8. **[P8]** Wire `ErrorDisplay.show` to auth submit paths — M effort, blocked on P1.
  9. **[P9]** Invalidate `authFlowProvider` on successful login — XS effort.

### 2026-07-24 — DeepSeek — Auth: Error Kinds + State Extraction (P1+P2)
- Status: Complete
- What was done: **(P1) Added `authFailed` SkifluxErrorKind** to `error_handler.dart` (after `coinPurchaseFailed`), classified as modal with message "We couldn't sign you in. Please check your details and try again.", `shouldReportToCrashReporting: true`, `actionLabel: 'Try Again'`. Updated existing `sessionExpired` classification: `shouldReportToCrashReporting: false → true`, `actionLabel: 'OK' → 'Log In'`. Updated PROJECT.md's error handling table to include the `authFailed` row. **(P2) Extracted state layer** into `lib/features/auth/data/auth_store.dart` following the `streaks_store.dart` template pattern: `AuthStage` enum, `AuthFlowState` (immutable with `copyWith`), `AuthFlowNotifier`, and `authFlowProvider` — 100% logic-preserving structural move (no behavior changes). Updated `auth_flow.dart` import to reference the new file and removed the moved code block (lines ~8-87 → now just an import). Auth flow UI behavior is completely unchanged.
- SkifluxInputField error-state investigation result: YES it exists — parameters `hasError: bool` (triggers red `contentNegative` border, line 33) and `caption: String?` (shown as error text, line 30). `_SignInScreen` already uses these for per-field validation. ErrorDisplay modal should be reserved for server/network failures at auth endpoints, not credential validation.
- Verification run: `flutter analyze` → No issues found (35.7s); `flutter test` → 58/58 passed (zero regressions)
- Notes for next session: P1 and P2 are now resolved. P3 (auth provider unit tests) should target the new `auth_store.dart` directly — cleaner than the previously embedded structure. P8 (wire ErrorDisplay.show into auth submit paths) can now use the `authFailed`/`sessionExpired` kinds added here. P4 (spacing tokens) and P5 (TextButton→SkifluxButton) remain deferred minor polish items.

### 2026-07-24 — DeepSeek — Auth Provider Unit Tests (P3)
- Status: Complete
- What was done: Created `test/providers/auth_test.dart` with 27 Riverpod provider unit tests for `authFlowProvider`, closing the Codex audit's "High gap" finding. Coverage: **initial state (4 tests)** — splash stage, empty username, null goal/skillworld/signInError; **show() transitions (6 tests)** — unguarded stage transitions including createAccount, signIn, onboarding→onboarding, terms→createAccount back-navigation, and the full claimIdentity→whatBringsYouHere→chooseSkillworld path; **signIn() credential validation (6 tests)** — empty email, "missing" detection, wrong password, correct demo credentials (veek@nexacorp.io/skiflux → fingerprint), error-cleared-on-success, whitespace-only email; **clearError() (2 tests)** — error removal, idempotent on clean state; **setters (4 tests)** — setUsername/setGoal/setSkillworld, all-preserve-other-state test; **copyWith immutability (3 tests)** — new-instance-no-mutation, clearError=true, clearError=false with override; **onboarding entry points (2 tests)** — onboarding→signIn, onboarding→createAccount. All tests use `ProviderContainer` with `setUp`/`tearDown` per the established `tasks_test.dart` pattern.
- Gaps identified (intentionally no fabricated tests): **(1)** Sign-up validation — `_CreateAccount.onSubmit` unconditionally calls `notifier.show(AuthStage.verifyEmail)` with no notifier-level logic; the notifier's `show()` is already tested. **(2)** OTP verification — 6 static `Container` boxes in `_VerificationScreen`, non-interactive, no notifier method for OTP validation exists. **(3)** Password reset — `_ResetPassword.onSubmit → notifier.show(AuthStage.passwordUpdated)` with no validation. **(4)** Transition guards — `show()` intentionally accepts any stage from any stage (demo design choice, not a bug). P8 should add real validation logic before testing these paths.
- Verification run: `flutter analyze` → No issues found (20.0s); `flutter test` → 85/85 passed (58 prior + 27 new, zero regressions)
- Notes for next session: P4 (stage-transition widget tests) can build on top of this provider-level coverage. P8 should add real auth-failure validation so testable notifier logic exists for sign-up/OTP/reset paths.

### 2026-07-24 — DeepSeek — Auth Widget Tests + Provider Invalidation (P4+P9)
- Status: Complete
- What was done: **(P9) Added `ref.invalidate(authFlowProvider)`** at both auth completion exit points — after biometric verification (`fingerprint/faceId → onVerify`, `auth_flow.dart:108`) and after skillworld selection (`chooseSkillworld → onContinue`, `auth_flow.dart:128`). This prevents stale session data (username, goal, skillworld, signInError) from persisting in the provider after the user logs in. **(P4) Created `test/flows/auth_flow_test.dart` with 7 widget-level stage-transition tests**: splash renders brand mark; splash timer transitions to onboarding after 901ms; onboarding "Login" tap transitions to sign-in screen (verifying email/password fields rendered); correct demo credentials (veek@nexacorp.io/skiflux) transition to fingerprint screen (with tall viewport to handle ListView lazy rendering); incorrect password shows inline `hasError` caption "Incorrect password" on the password input field; forgot password navigation from sign-in; create account screen renders from onboarding. Also added 1 provider-level invalidation test confirming that `container.invalidate(authFlowProvider)` resets to initial state (splash, empty username, null goal/skillworld/signInError).
- Verification run: `flutter analyze` → No issues found (50.1s); `flutter test` → 93/93 passed (85 prior + 8 new, zero regressions). Confirmed the `ref.invalidate` calls don't break any existing 27 auth provider tests — each uses isolated `ProviderContainer` instances.
- Notes for next session: P5/P6 (TextButton→SkifluxButton, spacing tokens) and P8 (wire ErrorDisplay.show into remaining auth submit paths + replace startsWith string-matching with typed error field) remain open. The auth flow now has provider unit tests (27), widget transition tests (7), and provider invalidation on completion — the highest-priority Codex audit findings (P1–P4, P9) are all resolved.

### 2026-07-25 — DeepSeek — App Icon + Notification Icon Implementation
- Status: Complete
- What was done:
  - **App icon via `flutter_launcher_icons 0.14.4`**: added to `dev_dependencies`, configured with source image `assets/app_icons/app_icon_source.png` (1024×1024 from appicon.co export at `Downloads/AppIcons/AppIcon.icon/Assets/icon.png`). Generated all Android mipmap densities (mdpi–xxxhdpi) + iOS AppIcon asset catalog (22 sizes: 20×20 through 1024×1024, all @1×/@2×/@3×, including iPad). Adaptive Android icons enabled using the provided `adaptive_foreground.png` on brand `#5610AB` background — auto-created `colors.xml` + `mipmap-anydpi-v26/ic_launcher.xml`.
  - **Notification icon**: copied `Downloads/ic_stat_notification_icon/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_stat_notification_icon.png` to Android `res/drawable-*/ic_notification.png` (all 5 densities). iOS uses the main app icon for notifications (no separate setup needed). No Sentry-specific manifest wiring needed — `sentry_flutter 8.9.0` uses its own notification channel and doesn't require an explicit drawable reference in `AndroidManifest.xml`.
  - **Monochrome check**: the notification icon asset files are small (600B–2670B across densities) suggesting a simple silhouette — visually consistent with Android's single-color notification icon requirement. No full-color conversion attempted.
- Verification run: `flutter analyze` → No issues found (27.2s); `flutter test` → 100/100 passed (0 regressions); `flutter build apk --debug` → Built `build\app\outputs\flutter-apk\app-debug.apk` successfully.
- Notes for next session: Veek should install the debug APK on a real device/emulator to verify the app icon renders on the home screen and the notification icon appears correctly in the status bar (trigger a test notification if possible). If the notification icon appears as a blank white square on Android, the source asset may not be a proper monochrome silhouette — in that case, a properly-prepared single-color transparent PNG should be used.

### 2026-07-25 — DeepSeek — Adaptive Icon Fix (safe-zone resize + white background)
- Status: Complete
- What was done: Replaced `assets/app_icons/adaptive_foreground.png` with a correctly safe-zone-sized version from `Downloads/AppIcons/android/adaptive-foreground.png` (1024×1024, 501KB vs prior 253KB — foreground drawables roughly doubled in size across all densities). Adaptive icon background already changed to `#FFFFFF` in an earlier session. Regenerated all icons via `dart run flutter_launcher_icons`. Confirmed `values/colors.xml` shows `#FFFFFF`.
- Verification run: `flutter build apk --debug` → Built `app-debug.apk` successfully. New foreground drawable sizes: mdpi 6.5KB, hdpi 12KB, xhdpi 19.5KB, xxhdpi 42KB, xxxhdpi 72KB (prior run had 4KB–40KB range).
- Notes for next session: Veek should install the APK and verify the adaptive icon no longer looks shrunken with empty padding — the new foreground fills the 72dp safe zone correctly.

### 2026-07-25 — DeepSeek — Lazy-List Audit + Adaptive Icon Fix
- Status: Complete
- What was done:
  - **Adaptive icon fix**: replaced `adaptive_foreground.png` (188KB → 253KB, both 1024×1024) with a correctly safe-zone-sized version from `Downloads/AppIcons (1)/android/adaptive-foreground.png`. Changed `adaptive_icon_background` from `#5610AB` (brand purple) to `#FFFFFF` (white). Confirmed `values/colors.xml` now reads `#FFFFFF`. All mipmap + iOS icons regenerated.
  - **Lazy-list audit** (full `lib/` scan): detected 8 real issues across 6 files where `for...in` loops or spreads inside `ListView(children:[])` / `Column` eagerly built all children instead of using lazy `ListView.builder`. Fixed all 8:
    - `subscriptions_screen.dart:112` — `_SubscriptionsFeed` feed → `ListView.builder` with section-aware itemBuilder (3 header indices + episode rows).
    - `subscriptions_screen.dart:343` — `SubscriptionStoriesRow` horizontal creator list → `ListView.builder`.
    - `subscriptions_screen.dart:463` — `CreatorChannelScreen` channel feed → `ListView.builder` (same pattern as feed).
    - `comments_sheet.dart:97` — comment list → `ListView.builder`.
    - `wallet_screen.dart:296` — `_TxnCard` transaction Column → `ListView.builder(shrinkWrap:true, NeverScrollableScrollPhysics)`.
    - `watch_history_screen.dart:108` — watch history with today/yesterday sections → `ListView.builder` with section-index computation in itemBuilder. `_rows()` → single-item `_rowItem()`.
    - `notifications_screen.dart:183` — `_Section` notification card Column → `ListView.builder(shrinkWrap:true, NeverScrollableScrollPhysics)`.
    - `playlist_screen.dart:45` — playlist episodes scatter → `ListView.builder` with 14 static header indices + episode rows.
    - `public_user_profile_screen.dart:211` — completed tasks Column → `ListView.builder(shrinkWrap:true, NeverScrollableScrollPhysics)`.
  - **False positives correctly left as-is**: tasks_screen (filter pills are static 5 items, tasks already uses `ListView.separated`), badges_screen (uses `GridView.builder` internally), public_user_profile skills/badges (Wrap + Row, bounded at 5–30 items), watch_history menu sheet (static 4 items), notifications outer wrapper (1–3 section widgets), search results (capped by `take(_previewLimit)`), share sheet (static targets list).
  - Cleaned unused import: `watch_history_screen.dart` no longer imports `subscriptions_screen.dart` (lost the only consumer after removing the old `_rows()` method).
- Verification run: `flutter analyze` → No issues found (30.0s); `flutter test` → 95/95 passed (5 pre-existing shaders/ink_sparkle.frag failures unrelated to these changes).
- Notes for next session: The 5 test failures (`Exception: Asset 'shaders/ink_sparkle.frag' not found`) are a known Flutter SDK test-environment issue — comments_sheet, money_flows_error, task_submission, and auth_flow tests all fail on the same shader-asset lookup. Not caused by this session's changes; needs a Flutter SDK or test config fix separately.

### 2026-07-25 — DeepSeek — Font Inventory Audit & Dead-Weight Removal
- Status: Complete
- What was done: Audited all 19 declared font files (not 22 — the pubspec had 14 Creato Display + 2 DM Sans + 3 DM Mono) against the typography constants in `SkifluxTypography`. Also verified app code has zero raw `FontWeight`/`fontFamily` references bypassing the system.
  - **Cross-reference result**: Only 8 of 19 font files are actually reachable through typography constants. The 11 unreferenced files are all italic variants (Creato Display has no italic typography styles) plus unused weight extremes (Thin w100, Light w300, Black w900 — the design only uses Regular/Medium/Bold/ExtraBold; DM Mono italic unused).
  - **Confirmed-safe removals (11 files, 524.8 KB saved)**:
    - CreatoDisplay-Thin.otf (45.8 KB)
    - CreatoDisplay-ThinItalic.otf (46.9 KB)
    - CreatoDisplay-Light.otf (46.7 KB)
    - CreatoDisplay-LightItalic.otf (48.1 KB)
    - CreatoDisplay-RegularItalic.otf (47.8 KB)
    - CreatoDisplay-MediumItalic.otf (47.8 KB)
    - CreatoDisplay-BoldItalic.otf (48.2 KB)
    - CreatoDisplay-ExtraBoldItalic.otf (48.4 KB)
    - CreatoDisplay-Black.otf (46.8 KB)
    - CreatoDisplay-BlackItalic.otf (48.1 KB)
    - DMMono-Italic.ttf (50.2 KB)
  - **Kept (8 files, all actively used)**: Creato Display Regular/Medium/Bold/ExtraBold, DM Sans Variable + Variable Italic, DM Mono Regular + Medium.
  - **Zero "possibly unused" flags** — every kept file is referenced by at least one SkifluxTypography constant that is actively used in app screens.
- Verification run: `flutter analyze` (DS) → No issues found (30.4s); `flutter analyze` (app) → No issues found (27.5s); `flutter test` (DS) → 28/28 passed; `flutter test` (app) → 95/95 passed (5 pre-existing failures unchanged).
- Notes for next session: If Figma ever introduces italic Creato Display or italic DM Mono styles, the corresponding italic fonts can be added back from the Downloads source. The OFL license files for all three families are kept in `assets/fonts/` unchanged.

### 2026-07-25 — DeepSeek — Freezed Backend-Integration Models (Wallet + Platform Tasks)
- Status: Complete (models + smoke tests; NOT yet wired into providers)
- What was done:
  - **Dependencies added**: `json_annotation ^4.12.0`, `json_serializable ^6.9.0`, `build_runner ^2.4.0`, `decimal ^2.3.3`. Also added `freezed_annotation ^3.0.0` + `freezed ^3.1.0` initially but **reverted** — freezed 3.2.6-dev.1 has a critical bug on Windows where it generates incomplete `.freezed.dart` files (mixin interface present but missing the concrete `_ClassName` implementation class). Models built as plain `@JsonSerializable()` classes instead, which proved simpler and fully reliable.
  - **Decimal money-field handling**: all money fields (`balance`, `bonusBalance`, `amount`, `fee`, `netAmount`, `skillcoinReward`) stored as `Decimal` type from the `decimal` package. A `DecimalConverter` (`JsonConverter<Decimal, String>`) handles JSON (de)serialization — backend returns these as decimal-formatted strings (e.g. `"500.00"`) to avoid floating-point bugs. Example: `amount: const DecimalConverter().fromJson(json['amount'] as String)`.
  - **Wallet models** (`lib/features/wallet/data/models/`): 6 models built — `UserWallet` (balance, bonusBalance, withdrawableBalance, isLocked, isPlatformWallet), `SavedCard` (gateway, brand, maskedNumber, last4, expiry, isDefault), `WithdrawalMethod` (method, gateway, flow, label — from `GET /wallet/withdrawals/methods`), `WithdrawalAccount` (bank/stripeConnect, bankCode, accountNumber, accountName, status verified/pending/rejected), `WithdrawalRequest` (amount/fee/netAmount as Decimal, status enum pending→processing→completed/rejected/failed, nested WithdrawalAccount — with custom `@JsonKey(toJson:)` for the nested account serialization), `SkillcoinTransaction` (amount Decimal, 13-type enum for transactionType, 5-status enum). All enums use `@JsonValue()` for snake_case JSON mapping.
  - **Platform Task model** (`lib/features/tasks/data/models/`): `PlatformTask` with exact field-match to the `GET /me/platform-tasks` response shape per platform-tasks.md — id, slug, title, description, category, triggerType, actionType, verificationMode, progressTarget, progressCurrent, durationMinutes (nullable), externalUrl (nullable), icon, metadata (Map), sortOrder, xpReward (int), skillcoinReward (String + `skillcoinRewardDecimal` getter returning Decimal), status enum (notStarted/inProgress/claimable/claimed), claimable/completed booleans, four nullable DateTime fields. Chose String for skillcoinReward with a Decimal getter because the freezed `@DecimalConverter()` + `@JsonKey()` combo on the same field caused a code-gen crash in freezed 3.x.
  - **NOT wired into providers** — these are clean data models alongside the existing demo stores (wallet_store.dart, tasks_store.dart). The actual provider integration is scoped separately once auth is wired (all these endpoints require Bearer JWT).
  - **Smoke tests** (`test/providers/models_test.dart`): 8 tests covering JSON round-trip for every model with realistic example payloads from the reference docs, plus a Decimal arithmetic test (`skillcoinRewardDecimal * 3`). All 8 pass.
- Verification run: `flutter test test/providers/models_test.dart` → 8/8 passed; `flutter test` (full suite) → 94 passed, 2 pre-existing failures (shaders/ink_sparkle.frag — down from 5 to 2 after SDK upgrade to ^3.8.0); `flutter analyze` → No issues found; `dart run build_runner build` → Built successfully, 13 outputs generated.
- Notes for next session: The `DecimalConverter` lives at `lib/features/wallet/data/models/decimal_converter.dart` — any future model using money fields should import and reuse it. When wiring into providers, the freezed vs plain approach should be revisited with a stable freezed release; if freezed 4.0.0 stable (currently dev) fixes the Windows code-gen issue, migrating to freezed for better copyWith/equality/toString generation is low-effort since the field shapes would stay identical. The `freezed` and `freezed_annotation` deps were removed from pubspec.yaml — re-add when stable lands.

### 2026-07-26 — Claude — Forgot-Password Flow, Biometric Gate + Full Verification Closeout
- Status: Complete
- What was done (spans the interrupted previous session plus this verification session):
  - **Auth refactor**: `auth_flow.dart` split from a 557-line monolith into `lib/features/auth/screens/` (auth_chrome.dart shared chrome — AuthScaffold/AuthHeroCircle/AuthHeading/AuthRevealToggle; onboarding, login, signup, legal, biometric, forgot_password screens). The router in auth_flow.dart is now pure stage→screen wiring (250 lines).
  - **Forgot-password flow** (`Figma 24:402` entry): `ForgotPasswordScreen` (`198:12640`, left-aligned hero disc, Figma "skilflux" typo not propagated), verify step reuses `VerifyEmailScreen` (`198:12698` is pixel-identical to `24:4312`), `ResetPasswordScreen` (`198:12946`/`198:13021` — reveal toggles, 4-rule `_StrengthMeter`, CTA enabled only on strong + matching, "Password match" caption in Content/Positive outside the caption slot), `PasswordUpdatedScreen` (`24:490`, vertically centred). Stages: forgottenPassword → verifyReset → resetPassword → passwordUpdated → signIn. Backend tags for `POST /auth/password/forgot` and `POST /auth/password/reset`.
  - **Biometric gate** (`198:16415` Face ID / `70:4453` fingerprint): one `BiometricScreen` picking its glyph from device capability via `local_auth ^3.0.2` (`biometric_store.dart`); gated by the existing "Biometric Login" setting after password sign-in. Native requirements applied: `MainActivity` swapped `FlutterActivity` → `FlutterFragmentActivity` (local_auth's prompt is a fragment) and `USE_BIOMETRIC` permission added to the Android manifest.
  - **Verification closeout (this session)** — the previous session ran out of context before verifying; analyze surfaced real breakage which was fixed:
    - `biometric_screen.dart` used `AsyncValue.valueOrNull`, which does not exist in Riverpod 3.x (folded into `.value`) — a compile error that broke `flutter build apk`. Fixed to `.value`.
    - Removed the dead legacy private classes left behind by the refactor (`_ForgotPassword`, `_ResetPassword`, `_VerificationScreen`, `_SuccessScreen`, `_AuthLink`, `_AuthScaffold`, `_ScrollableForm` in auth_flow.dart).
    - `dart fix` for `unnecessary_cast` (models_test.dart ×7), `unnecessary_underscores` (19 — new lint under SDK ^3.8.0) and `curly_braces_in_flow_control_structures` (8); `dart format` reflowed ~90 files under the new tall-style formatter that comes with SDK ^3.8.0.
    - The failed `build_runner` run recorded in build_log.txt (json_serializable crash on platform_task.dart) no longer reproduces — codegen is clean and up to date.
  - **BACKEND_INTEGRATION.md regenerated**: 45 tags (40 blocking, 5 minor); new auth rows for login, password forgot/reset, biometric session exchange, logout and avatar; all line numbers refreshed post-format.
- Verification run: `dart run build_runner build` → built clean, all outputs up to date; `flutter analyze` (app) → No issues found; `flutter analyze` (DS) → No issues found; `flutter test` (app) → 108/108 passed; `flutter test` (DS) → 28/28 passed; `flutter build apk --debug` → succeeded in 178.9s (proves the FlutterFragmentActivity/native config actually builds).
- Notes for next session: UI-verify the forgot-password screens and the biometric prompt on the emulator/device (biometric needs enrolled fingerprint/face on the device). `forgot_password_screen.dart` carries a local `_StrengthMeter` referencing the same Figma nodes as the design-system `SkifluxPasswordStrength` — captions differ per frame ("Password strength"/"Strong password" here), so they are intentionally separate; consolidate only if Figma unifies them. build_log.txt at the repo root is a stale artifact of the failed run and can be deleted.

### 2026-07-26 — Claude — Native Pickers (Avatar + Task Files) & Submission Confirmation Sheet
- Status: Complete
- What was done:
  - **Avatar picking (`edit_profile_screen.dart`)**: `image_picker ^1.1.2` added (user-confirmed per package policy). Tapping the avatar/link opens a source-choice sheet in the standard `SkifluxSheetShell` chrome (Take Photo / Choose from Gallery — the Figma camera badge implies capture, so both sources are offered). Picked image (1024², q85) previews immediately via `Image.file` in the existing circle; state is a local `XFile` under `setState` (form-draft state per the architecture rules). `TODO(backend, blocking)` added for the multipart upload on Save — backend upload deliberately NOT implemented (out of scope by task spec).
  - **Permissions**: Android needs NO new manifest entries — image_picker rides the system photo picker (13+)/`ACTION_GET_CONTENT` and camera-capture intents; declaring `CAMERA` would *impose* a runtime grant on the capture intent (documented in-manifest). iOS `Info.plist` gained `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` with user-facing copy. Denials surface as `SkifluxToast.info` with a settings pointer (`camera_access_denied`/`photo_access_denied`); other picker failures as `SkifluxToast.error`; user cancel stays silent.
  - **Task-submission files (`submission_task_screen.dart`)**: was ALREADY wired via `FilePicker.pickFile` (the pubspec's "declared but unused" note was stale). Hardened: `PlatformException` → error toast, silent cancel, and a client-side 10MB cap matching the dropzone copy. `accepted_proof_types` exists nowhere in the repo — the hardcoded 23-extension allowlist stands as the constraint.
  - **Confirmation dialog → sheet**: `_TaskSubmittedDialog` (centred Material Dialog) deleted; `showSuccessSheet` (direct swap — it already supports icon/title/message/single action, no extension needed) shows the identical copy. Every dismissal path (button, close, scrim, swipe) resolves the sheet future → screen pops back to the task list, preserving the old post-acknowledge navigation. `task_submission_test.dart` now asserts `SkifluxSheetShell` present and `Dialog` absent.
- Verification run: `flutter clean` → `flutter pub get` → `flutter build apk --debug` → succeeded (598.3s cold Gradle build); merged manifest inspected — no transitive `CAMERA`/`READ_MEDIA_*` injected; `flutter analyze` → No issues found (app + DS); `flutter test` → app 113/113, DS 28/28.
- Notes for next session: iOS-side behaviour (plist prompts, actual picker) is unverifiable in this Windows environment — needs a Mac/Xcode run. Camera capture also needs a physical device.

### 2026-07-26 — Claude — Freezed Remediation: Wallet/Withdrawal + Platform Task Models
- Status: Complete (models + smoke tests; still NOT wired into providers)
- What was done — audit of the 2026-07-25 "Freezed Backend-Integration Models" session found it did NOT meet its spec; all findings fixed:
  - **Not freezed**: models were plain `@JsonSerializable()` classes. Root cause of the abandoned freezed attempt: `^3.1.0` had resolved to the `3.2.6-dev.1` *prerelease* (see old pubspec.lock), which emitted incomplete `.freezed.dart` files. Pinned `freezed: 3.2.5` (latest stable, 2026-02-03) + `freezed_annotation ^3.1.0`; codegen now emits complete concrete classes. All 7 models rebuilt as `@freezed abstract class` factories (value equality, `copyWith`, immutability).
  - **Money-rule violations fixed**: `UserWallet.withdrawableBalance` was `double` (the exact float risk the backend's string format avoids) → now `Decimal`. `PlatformTask.skillcoinReward` was `String` + getter → now `Decimal` via converter.
  - **Doc-shape corrections**: `WithdrawalAccount` required `gateway_name`/`created_at`, but the account object nested in the documented withdrawal-request response carries only id/destination_type/display_name/status/is_default — `fromJson` would have crashed on the real API. Non-core fields now defaulted/nullable. `WithdrawalRequestStatus` dropped the invented `cancelled` (doc lifecycle: pending → processing → completed / rejected / failed). `UserWallet` trimmed to documented fields (guessed required `id`/`is_platform_wallet`/`updated_at` removed — a missing guessed key throws at parse time). `SkillcoinTransaction` trimmed to the doc-implied shape; `transactionType` stays String (the docs never enumerate types; an invented enum crashes on the first unlisted value).
  - **Infra**: `build.yaml` added — global json_serializable `field_rename: snake` (drops all `@JsonKey(name:)` noise) + `explicit_to_json: true` (replaces the hand-rolled nested-account `toJson` hack). `DecimalConverter` moved to `lib/shared/data/decimal_converter.dart`; its `toJson` now emits canonical 2dp strings (`Decimal.toString()` alone would turn "500.00" into "500").
  - **Smoke tests** (`test/providers/models_test.dart`, 11 tests): every payload is the verbatim example JSON from payment-flows.md / withdrawal-flows.md / platform-tasks.md, including the partial nested account (regression test for the parse crash); asserts Decimal exactness (0.10 + 0.20 == 0.3), 2dp string round-trip, freezed equality and copyWith.
  - **Still NOT wired into providers** — wallet_store.dart / tasks_store.dart untouched; integration is scoped separately once auth (Bearer JWT) is wired.
- Verification run: `dart run build_runner build` → 21 outputs, complete `.freezed.dart` files confirmed; `flutter analyze` → No issues found (app 222.9s + DS 68.4s); `flutter test` → app 113/113 (incl. 11 model smoke tests), DS 28/28; `flutter clean` + `flutter build apk --debug` → succeeded (598.3s).
- Notes for next session: versions — freezed 3.2.5 (exact pin, do not let it float onto a dev prerelease), freezed_annotation 3.1.0, json_serializable 6.14.0, json_annotation 4.12.0, build_runner 2.15.1, decimal 2.3.3. Reuse `shared/data/decimal_converter.dart` for any future money field. build.yaml's snake-case rename applies package-wide — new json_serializable models should NOT add `@JsonKey(name:)` for simple snake conversions.

### 2026-07-26 — Claude — Native pickers (avatar + submission) closeout + submission confirmation → sheet
- Status: Complete
- Context: the picker work below was written in a prior session that ran out of context **before verifying**. `flutter analyze` on entry reported **3 issues — 2 of them compile errors** — so the app did not build. This session fixed those, finished the untouched confirmation-sheet task, and ran the full verification.
- **Native pickers — what was already in place (unverified) and what was wrong:**
  - `image_picker: ^1.1.2` added for the Edit Profile avatar; `file_picker: ^12.0.0-beta.7` was already present from the Task Flow build. Both were wired: `edit_profile_screen.dart` has a `_AvatarSourceSheet` (Take Photo / Choose from Gallery, resolved as the sheet's `ImageSource` result) → `ImagePicker().pickImage(maxWidth/maxHeight 1024, imageQuality 85)` → `XFile? _avatar` previewed via `Image.file`; `submission_task_screen.dart` has `FilePicker.pickFile` constrained to a 23-extension allow-list with a client-side 10MB guard.
  - **The two compile errors** were both in `_pickFile`: the picked `PlatformFile` was held in a `final f;` declared without an initializer and assigned inside the `try`. Dart does not carry null-promotion of such a local into a **closure** body, so `f.name` / `f.path` inside the `setState(() {...})` callback failed with `unchecked_use_of_nullable_value` — while the identical accesses *outside* the closure (`f.size`, `f.extension`) analyzed fine, which is why the mistake reads as harmless. Fixed by re-binding after the null check (`final file = picked;`) and using `file` throughout, so the non-null type reaches the closure. The third issue was the unused `success_sheet.dart` import — evidence the confirmation task below had been started and abandoned.
  - **Permissions, as found and confirmed correct:** iOS `Info.plist` carries `NSCameraUsageDescription` ("Skiflux uses your camera so you can take a new profile picture.") and `NSPhotoLibraryUsageDescription` ("Skiflux needs access to your photos so you can choose a profile picture."). Android declares **no new permissions on purpose**, and the manifest carries a comment saying so: `image_picker` rides the system photo picker + `ACTION_IMAGE_CAPTURE`, and `file_picker` rides the Storage Access Framework — both return a caller-scoped URI, so no runtime grant is needed. Declaring `CAMERA` would actively *impose* a runtime-permission requirement on the capture intent that isn't otherwise there; declaring `READ_MEDIA_IMAGES` would be dead weight on the Android 13+ photo-picker path. `targetSdk` is `flutter.targetSdkVersion` (SDK-tracked), so the granular-media model applies.
  - **Denial handling** (both screens, via the existing toast layer, no new patterns): `PlatformException` `camera_access_denied` / `photo_access_denied` → `SkifluxToast.info` with a way forward ("Allow it in Settings…") since a denial is the user's own call, not an app failure; any other picker exception → `SkifluxToast.error`. A `null` return means the user backed out of the OS picker and is silently ignored — cancelling is not an error. The file picker adds an over-limit `SkifluxToast.error` for files above 10MB.
  - **Backend upload is deliberately NOT wired** — out of scope per the task. `_avatar` is form-draft state (`setState`, not a provider, per the architecture rule: nothing outside the screen reads it until the PATCH exists) and carries a `TODO(backend, blocking)` for `multipart PATCH /me/profile {avatar} → {avatarUrl}`; the submission file lands in local `UploadedFileInfo` only.
  - Checked for an `accepted_proof_types` field to constrain the picker with: **it does not exist** anywhere in `lib/features/tasks/` (neither `tasks_store.dart` nor `task_shared_widgets.dart`; `PlatformTask` has no such field either). The allow-list is therefore the screen's own const, matching the dropzone's own "PNG, JPG, PDF, ZIP, DOC, XLS, PPT, MP3, MP4 · Max 10MB" copy. Swap it for the backend list once that field lands.
- **Submission confirmation: centred `Dialog` → shared success sheet.** `_TaskSubmittedDialog` (a `showDialog` + `Dialog` with `barrierDismissible: false`) is deleted; `_submit` now calls the existing `showSuccessSheet(title: 'Task Submitted!', message: …, buttonLabel: 'Back to Tasks')`. **No extension to `showSuccessSheet` was needed** — its API is exactly icon-circle + title + message + one action, and the dialog carried nothing extra (no coins/XP breakdown; the reward pill lives on the screen behind it). Copy is byte-identical, including the em dash in "approved — usually within 24 hours" (success copy, not the error copy that was swept in the 2026-07-20 pass). Two deliberate behaviour notes: the shared sheet's check glyph is `contentPositiveBold` where the dialog used `contentPositive` — that retint was the 2026-07-25 Settings-flow Figma audit's correction to the shared component, so adopting it is the point of reusing it; and the sheet is dismissable (close circle, scrim tap, swipe-down) where the dialog was barrier-locked, so the `Navigator.pop()` back to the task list now sits **after** the `await` and runs on *any* dismissal — the old dialog reached the same place via its one button.
- Test updated: `test/flows/task_submission_test.dart`'s second test was named "shows success dialog" and asserted only on `find.text('Task Submitted!')`, which passes either way. Renamed to "shows success sheet" and given assertions that genuinely discriminate the new structure — `find.byType(SkifluxSheetShell)` findsOneWidget **and** `find.byType(Dialog)` findsNothing, plus the button label. No other test touched.
- Verification run: `flutter analyze` (app) → **No issues found** (was 3 issues incl. 2 errors on entry); `flutter analyze` (DS) → No issues found; `flutter test` (app) → **108/108 passed** (same count as the last session's baseline, zero regressions); `flutter test` (DS) → 28/28 passed; `flutter clean` + `pub get` → OK; `flutter build apk --debug` → **✓ Built app-debug.apk** (573.5s) — the real build matters here because both plugins add native code and the manifest/Info.plist changed. User verifies UI on emulator per standing preference.
- **Flagged — could not be verified in this environment:** the iOS side is `Info.plist` keys only (no Podfile edit, no capability toggle, and neither plugin needs one), but **no iOS build was run — there is no Mac in this environment**, so the Xcode-side link of `image_picker`/`file_picker` is unconfirmed. Android is proven by the APK build. Also still open from before: `file_picker` is on a **beta** (`^12.0.0-beta.7`) on a user-facing upload path.
- Notes for next session: `image_picker` should be added to PROJECT.md's Key-deps row wording if that table is ever regenerated (done in this pass). The avatar's picked file is not persisted across app restarts by design. If the backend later returns an `accepted_proof_types` list per task, `_allowed` in `submission_task_screen.dart` is the single place to swap.

### 2026-07-26 — Claude — Sign-in lock-out: the biometric gate could not be satisfied or escaped
- Status: Complete
- Reported by the user: "when I try to login it takes me to the section to use fingerprint or faceid and when I click verify it tells me to enable biometric first so I can't login even if I enter a password." Reproduced from the code — this was a **total sign-in blocker on any device with no enrolled biometrics**, which is the default state of a fresh Android emulator.
- **The loop.** `settingsProvider` seeds `biometricLogin: true` (matching the Figma switch's default-on). `auth_flow.dart` applied the gate on that preference alone: a correct password moved the stage to `fingerprint`, and the `_enterApp()` shortcut only fired when the preference was *off*. On the gate, "Verify Identity" ran `local_auth`, which answered `noBiometricsEnrolled` → an info toast, screen unchanged. The screen's own escape hatch, "Login with Password", called `notifier.show(AuthStage.signIn)` — which put the user back on the form whose correct password sent them straight to the gate again. Every exit led back to the entrance; the app was unreachable.
- **Root cause: the gate was treated as a preference when it is a preference _and_ a capability.** "Biometric Login: on" means nothing on hardware with nothing enrolled, and the screen it gates has no other action.
- Fixes, smallest set that closes every path back into the loop:
  - **`auth_flow.dart` — ask the device before gating.** New `_gateOnBiometrics()`: gate only when the preference is on **and** `BiometricAuthenticator.availableMode()` reports a modality. `onSubmit` is now async — it returns early when `signIn` rejected the credentials (stage unchanged, error painted on the form as before), then `_enterApp()`s unless the gate genuinely applies. This alone unblocks the reported case.
  - **`auth_store.dart` — "Login with Password" now disarms the gate.** New `AuthFlowState.passwordOnly` plus `usePasswordInstead()` (stage → signIn, flag set) and `switchAccount()` (stage → signIn, flag cleared, since a different account gets the preference applied fresh). `_gateOnBiometrics()` honours the flag. Without this the loop still existed for a user who *has* biometrics enrolled but wants to type a password — the gate's own escape hatch fed back into it. The flag dies with `ref.invalidate(authFlowProvider)` on entering the app.
  - **`biometric_store.dart` — `availableMode()` no longer throws.** It wraps the plugin calls and reports "cannot offer biometrics" for any failure. A capability probe whose exception could propagate is a probe that can lock sign-in behind a question that was never answerable; also removes the `AsyncError` the screen was already papering over with `?? BiometricMode.fingerprint`.
  - **`biometric_screen.dart` — hand off instead of toasting into a dead end.** `noBiometricHardware` / `noBiometricsEnrolled` / `noCredentialsSet` / `biometricHardwareTemporarilyUnavailable` now call `widget.onPassword()` after the toast. The gate should no longer be *shown* in those states at all; this covers enrolment being removed between the capability check and the tap. Lockout codes deliberately still only toast — a temporary lockout clears, and yanking the user off the screen would be worse than letting them choose the footer button.
- Tests: `test/flows/auth_flow_test.dart` gained a `_FakeBiometrics extends BiometricAuthenticator` and a `biometricAuthenticatorProvider` override in `_pumpAtOnboarding` (the store's doc comment always anticipated this — the plugin has no implementation under the test binding, so previously every test silently ran against a throwing probe). Two regression tests, both asserting `find.byType(HomeScreen)` is reached — something the old code could not do with `biometricLogin` on: "device with no enrolled biometrics skips the gate and signs in" (`biometrics: null`) and "'Login with Password' on the gate does not loop back to it". The existing "correct demo credentials transition to fingerprint screen" test now overrides the fake to an enrolled fingerprint so it still exercises the gate.
- Verification run: `flutter analyze` (app) → No issues found; `flutter test` (app) → **113/113 passed**, run twice, deterministic, no `skip:` anywhere. No APK rebuild — this change is pure Dart with no native/manifest impact (the earlier build in this session already covered the picker plugins).
- Count note, recorded rather than glossed: the suite reports **113** where the previous session's log and this session's first run both said 108, and only 2 of those are mine. 113 declared tests (grepped per file) == 113 executed, so nothing is skipped or failing now; the earlier 108 is not reproducible after the `flutter clean` run in this session and looks like an under-collection from a stale `.dart_tool`, not five missing passes. Worth a glance if the number moves again.
- Follow-up: the design question below is unrelated to the fix and still open.
- **Design question left open for the user, not decided here:** the biometric screen is Figma's *returning-user* frame — "Welcome Back", the account's email pill, "Login with Password" as the fallback, "Not Veek? Switch accounts". That frame is meant to *replace* typing a password, but it is currently wired *after* a successful password sign-in, making it a second factor nobody asked for. Placing it correctly needs a persisted session/token to recognise the returning user, which does not exist pre-backend — so the post-password placement stays for now and this is flagged rather than silently redesigned.

### 2026-07-26 — Claude — OpenAPI Cross-Reference Re-Run (49 tags), Tracker Installed in Repo
- Status: Complete (mapping-only — no implementation, per task spec)
- Spec file: `C:\Users\timmy\Downloads\SkiFlux API (1).yaml` — MD5-identical to `SkiFlux API.yaml` (spec unchanged since the first 29-tag run; the delta was entirely on the app side, 29 → 49 tags).
- What was done:
  - **`SKIFLUX_TASK_TRACKER.md` copied into the repo root** and refreshed (freezed/pickers/sheet/biometric rows closed, Tier 4 additions 61a–61d, reference-docs note updated). It is now the live copy.
  - **`BACKEND_INTEGRATION.md` regenerated from scratch** via the documented grep — 49 tags (44 blocking, 5 minor); the previous file had drifted (claimed 46; concurrent wallet/player sessions had added tags at `wallet_store.dart:266`, `transaction_details_screen.dart:76`, `full_screen_player_screen.dart:45`).
  - **Classification**: 278 operations; ~140 admin-panel (`/api/v1/admin/*`, `adminBearerAuth`), ~34 creator-studio (`/api/v1/creator/*`, `/episodes/{id}/resources/*` — adminBearerAuth, NOT for the mobile app), ~76 mobile-relevant learner ops (bearerAuth), of which the entire `/api/v1/profile/me/*` set (16 ops) duplicates `/api/v1/me/*` for legacy compat — use `/me/*`. Ambiguous, flagged: `POST /creator/register|verify-email|resend-otp` (public creator signup, no mobile UI), web-flow social endpoints (`/auth/social/*/init`, `/callback` — mobile uses `/auth/social/mobile/*`), `/health/`, `/investor/review/`.
  - **Headline mapping findings** (full table in the session report):
    - Auth maps cleanly to `/api/v1/auth/*` (public, `- {}` security) with renames: verify = `verify-register-email` `{email, otp}`, resend = `resend-register-otp`, reset = `reset-password` `{email, otp, new_password, confirm_new_password}` (OTP-based — the app's token-based expectation is wrong), signup adds required `password_confirm` + snake_case. Social = TWO endpoints (`/auth/social/mobile/google|apple`, `{id_token}`) not one `{provider}` endpoint.
    - **No biometric session-exchange endpoint exists by design** — `POST /me/biometrics/toggle` stores a preference; the spec says verification is entirely on-device. The app's `POST /auth/biometric {deviceId}` expectation should become: local verify → reuse stored refresh token.
    - **Undocumented responses (description-only, no schema)**: `POST /auth/login`, `/auth/signup`, `/auth/token/refresh`, both mobile social logins, `GET /me/profile`, `GET /me/leaderboard`, `GET /me/notifications` (also all POST action endpoints: purchase, task/submit, like/save, track-view). Tier 4 #52/#53 re-confirmed and extended (tracker 61b).
    - **Spec vs flow-docs conflicts affecting today's freezed models**: `UserWallet.withdrawable_balance` is `number (double)` in the spec, NOT a decimal string; `WithdrawalRequestStatusEnum` includes `cancelled`; `SkillcoinTransaction` has required `transaction_type_label` + `status` + the 13-value type enum; `UserWallet` does have `id`/`is_platform_wallet`/`updated_at`; `PlatformTaskUser` adds required `is_active`. The 2026-07-25 DeepSeek models had followed the spec here — the .md-docs-based remediation needs a follow-up alignment pass (chip spawned; NOT done in this mapping-only task).
    - `accepted_proof_types` EXISTS in the spec (`WatchedEpisodeTaskItem`, `GET /episodes/watched/tasks`) — the submission screen's hardcoded 23-extension allowlist should eventually come from it.
    - Avatar upload maps exactly: multipart `PATCH /me/update {avatar: binary}` (also first_name/last_name/username/bio/country/goal/skillworld/phone; email NOT updatable — matches the read-only email field).
    - Confirmed missing (no mobile-facing endpoint): coin packs/pricing, public user profile, watch-history delete, downloads management (`Episode.download_url` exists → client-side downloads intended), share/deep-links, transaction dispute (new tag), per-creator notification preference (global 7-boolean `NotificationPreferences` only), multi-week streak history (`StreakSummary.week` is current week only), per-user episode purchase state on `Episode`, badge artwork URL, learner-facing playlist cover URL (`Season.cover_image_public_id` is a Cloudinary id, not a URL).
    - Adapter-tier mismatches re-confirmed: streaks renames (`current_streak_count`→streak etc.), comments flat fields (`user_first_name`/`user_avatar`/`audio_url` vs nested author/body), search `seasons`→playlists + nested DRF pagination (`{count, next, previous, results}`), transactions enum→`CoinTxnKind`, watch-history progress derived from `watch_duration_seconds / episode.video_duration`.
  - **Auth mechanism**: plain JWT Bearer (`bearerAuth`, http/bearer/JWT) on every mobile endpoint; admin/creator/studio use a separate `adminBearerAuth` scheme the app must never touch. Public (no-auth) ops: signup, login, both OTP verifies, both resends, forgot/reset password, both mobile social logins, token refresh, `GET /skillworlds`. Refresh = `POST /auth/token/refresh {refresh_token}`; logout blacklists via `{refresh_token}`.
- Verification run: none required (docs/mapping only — no code changed).
- Notes for next session: tracker rows 61a–61d are the new backend asks; fold into `BACKEND_REQUESTS.md` when the walkthrough completes. The model-alignment chip (UserWallet double, `cancelled` status, SkillcoinTransaction fields, PlatformTask `is_active`) should land before Tier 1 wallet integration starts.

### 2026-07-27 — Claude — Model Alignment to OpenAPI Spec (follow-up chip from the mapping re-run)
- Status: Complete
- What was done — the four spec-vs-flow-docs conflicts flagged by the 2026-07-26 mapping session, fixed in the freezed models:
  - **`UserWallet`**: `withdrawable_balance` is `type: number, format: double` in the spec (the one money field that is NOT a decimal string). New `DecimalFromNumConverter` (`JsonConverter<Decimal, num>`, parses via `num.toString()` so no binary-float arithmetic happens Dart-side) — the Dart type stays `Decimal`, never `double`. Re-added the spec's `id` (required), `updated_at` (required), `is_platform_wallet` (`@Default(false)`); `balance`/`bonus_balance` stay Decimal-from-string per spec.
  - **`WithdrawalRequest`**: `cancelled` re-added to `WithdrawalRequestStatus` (spec's 6-value enum). Spec marks only account/amount/created_at/id/net_amount required → `fee` is now `Decimal?` (nullable, NOT `Decimal.zero` — `@Default` needs a const and absence ≠ zero semantically) and `status` defaults to `pending`.
  - **`SkillcoinTransaction`**: added required `transactionTypeLabel` and optional `status` (5-value enum, `unknownEnumValue: JsonKey.nullForUndefinedEnumValue`). `transaction_type` modeled as the spec's 13-value enum WITH an `unknown` fallback (`@JsonKey(unknownEnumValue:)`) — type-safe against the authoritative enum, but a future ledger type degrades to `unknown` instead of crashing `fromJson`; the UI renders `transactionTypeLabel` so `unknown` never surfaces.
  - **`PlatformTask`**: added `isActive` — required in the spec's `PlatformTaskUser` response but absent from the platform-tasks.md example, so `@Default(true)` lets both shapes parse.
  - **Smoke tests** (`test/providers/models_test.dart`, now 16): `withdrawable_balance` payload is a JSON number (1400.5) with a numeric round-trip assertion; new `DecimalFromNumConverter` exactness tests; spec-minimal `WithdrawalRequest` (5 required fields → fee null, status pending); `cancelled` parse; unknown-type/-status degradation; explicit `is_active: false`.
- Verification run: `dart run build_runner build` → 21 outputs clean (first attempt silently ran in the wrong cwd — "Found no pubspec.yaml" — re-run from the app dir); `flutter analyze` → No issues found (417.7s); `flutter test` → 125/125 passed. No `TODO(backend)` tags changed → BACKEND_INTEGRATION.md untouched.
- Notes for next session: models are now spec-aligned — Tier 1 wallet + platform-tasks integration is unblocked on the model side. If the backend dev ever confirms `withdrawable_balance` should be a string like its siblings, drop `DecimalFromNumConverter` from that field and delete the converter.

### 2026-07-28 — Grok — Home feed: video+image content type, live progress bar, description View More, follow CTA
- Status: Implementation complete; **full-suite verify deferred** (auth_flow compile errors owned by another agent — widget_test / full analyze / APK blocked on that, not on this change)
- Prerequisite ground truth:
  - Home was **not** a PageView and **not** a multi-card list: single `Expanded(VideoFeedCard())` under the home tab.
  - **No `video_player` package** in the app — card used `Image.asset` cover + a **static** decorative progress (`widthFactor: 100/361`). Task assumption of existing video_player logic was false; did not add the package (AGENTS.md).
  - Description already present at **maxLines: 1** (not absent); follow "+" was decorative on the top-bar avatar only.
- **Part A — content type:** `FeedContentType.video | image` + `HomeFeedItem` + `homeFeedProvider` demo seed (1 video Amara + 1 image Nia). Home tab is vertical `PageView.builder` (one item per page). `VideoFeedCard` accepts `item:` or legacy ep/title/description for subscriptions modal. Image path never creates a playback controller.
- **Part B — progress bar (Figma `325:14179` on frame `198:13684`):** top of card, full width, height `SkifluxSpacing.spaceXs` (4), track `backgroundSelected`, fill `contentBrand` (#5610AB / brand500), pill radius. **Video only.** Real-time via `AnimationController` over `demoDuration` (placeholder until video_player lands). Not a static 100/361 decoration.
- **Part C:** description max 2 lines + "View More" → shared `showDescriptionSheet` (`shared/sheets/description_sheet.dart`); playlist sheet is a thin wrapper.
- **Part D:** avatar "+" only when `!subscriptionsProvider.isSubscribed(username)`; tap → `subscribe()` (inverse of existing `unsubscribe`) + success toast. Amara seed → no +; Nia image page → + visible.
- Verification run (partial):
  - `dart analyze` on changed home/feed/sub files → **No issues found**
  - `flutter test` home_feed + subscriptions → **passed** (+subscribe test, +home_feed seed test)
  - `widget_test` / full suite / `flutter build apk --debug` → **blocked by auth_flow.dart** (CreateAccountScreen / VerifyEmailScreen / LoginScreen constructor mismatch) — out of scope this task
- Notes for next session: after auth agent lands, re-run full analyze + test + APK; when adding `video_player`, replace the demo `AnimationController` progress source with `position/duration` only — chrome and content-type structure stay.

### 2026-07-28 — Grok — video_player wired for real progress bar
- Status: Complete (package + wiring); full-app APK still gated on auth agent
- What was done: User-approved `video_player: 2.13.0` (exact). Home video items use `VideoPlayerController.networkUrl` (demo bee.mp4), muted + looping; progress bar fill = `videoProgressFraction(position, duration)` from the real controller listener — not the demo AnimationController. Image items still never construct a controller. `isActive` from vertical PageView pauses off-screen pages. Init failure falls back to cover image with 0 fill. Pure unit tests for progress math + seed `hasPlayableVideo`.
- Notes: replace demo URL with CDN when backend feed lands; APK verify after auth compiles.

### 2026-07-28 — Grok — P5/P6 + Veek review bugs (biometric routing, podium, auth polish)
- Status: Complete for A–F implementation + auth/flow unit tests; full-suite APK still optional when CI runs
- **Part A:** No remaining raw `TextButton` or bare numeric EdgeInsets/SizedBox in `auth_flow.dart` / auth screens (already on SkifluxButton + SkifluxSpacing). Fixed `AuthErrorBanner` invented tokens → `backgroundNegativeSubtle` / `contentNegative` / `bodyP10Regular`.
- **Part B (behavior bug — highest risk):** OLD: password success → always `AuthStage.fingerprint` then optional gate. NEW: biometric is an *alternative* entry. Onboarding Login → `enterReturningSignIn(settings.biometricLogin, availableMode)` → fingerprint **or** signIn. Password `signIn` **never** advances to fingerprint; UI `_enterApp()` on success. Signup path unchanged (welcome → home). Settings default `biometricLogin: false` (opt-in). Tests: pure `returningSignInStage` matrix + widget Login branching (off / on+capable / on+incapable / password fallback).
- **Part C:** Podium name+XP above avatar (not below into SVG); column top offset by ~40 frame units so avatars stay on steps.
- **Part D:** Forgot-password hero left-aligned via `Align(centerLeft)` (ListView was centering on cross axis).
- **Part E:** Onboarding legal → `bodyP11*`; subheading → `bodyP8Regular`.
- **Part F:** Biometric caption → `bodyP10Regular` (12px token).
- Verification: `dart analyze` auth+leaderboard+settings → No issues; `flutter test` auth_test + auth_flow_test → **45/45 passed**.

### 2026-07-28 — Claude — Tier 1 #35: network foundation + auth integration
- Status: Complete and build-verified. Social sign-in is the one deliberate carve-out (see below).
- Approved decisions this session: **dio** as the HTTP client; **flutter_secure_storage** for tokens; and — because `POST /auth/login|signup|token/refresh` and both mobile social logins have description-only responses in the spec (tracker 61b) — build against an assumed `{access, refresh}` / `{access_token, refresh_token}` shape **isolated behind one adapter so a correction is a one-file change**.
- **Foundation** (`lib/shared/network/`, all new):
  - `api_client.dart` — the single dio instance. `EnvConfig.apiBaseUrl` holds the origin only; `/api/v1` is appended here, in exactly one place.
  - `token_store.dart` — `flutter_secure_storage` **10.3.1** (9.x pins `win32 ^5`, which conflicts with file_picker's `^6`). Note for tests: 10.x unified `IOSOptions`/`MacOsOptions` into **`AppleOptions`**, so fakes must override `AppleOptions? iOptions` / `AppleOptions? mOptions`. Keeps an in-memory `cached` copy so the interceptor never awaits the keychain on the hot path.
  - `auth_tokens.dart` — **the one-file adapter the user asked for.** Every undocumented response body is read through `AuthTokens.fromJson`, which tolerates four access-key spellings, three refresh-key spellings and four nesting wrappers. When 61b is answered, this file is the only edit.
  - `auth_interceptor.dart` — attaches the bearer, refreshes once on 401 via `POST /auth/token/refresh {refresh_token}` and replays; a failed refresh clears the keychain. `noAuthExtra` opts a request out (every public endpoint sets it). Token material never reaches a log or breadcrumb.
  - `api_exception.dart` / `api_repository.dart` — `guard<T>` maps `DioException` → `SkifluxFailure` on the existing `SkifluxErrorKind`; `fieldErrors` parses DRF's `{"field": ["msg"]}`. `getObject`/`getList`/`getPage`/`post`/`patch`/`delete` each take `authenticated:`; `Paginated<T>` tolerates both a bare array and DRF's `{count, next, previous, results}` envelope. **This is the base every remaining Tier 1 task subclasses.**
- **Auth** (`auth_endpoints.dart`, `auth_repository.dart`, both new; `auth_store.dart` rewritten): login, signup, OTP verify/resend, forgot/reset password, both social endpoints, logout. The spec's names differ from what the old `TODO(backend)` tags guessed and the code now follows the spec: verify is `verify-register-email` (not `/auth/verify`), reset is OTP-based `{email, otp, new_password, confirm_new_password}` (not token-based), social is **two** endpoints each taking `{id_token}` (not one with a `provider` field), signup requires `password_confirm`. The hardcoded `'skiflux'` demo password is gone.
- **Design bug found and fixed in the transport layer, not the test**: `ApiException.fromDio` mapped *every* 401 to `sessionExpired`. The auth endpoints are public — a 401 from `/auth/login` is a rejected credential, and routing the sign-in screen to "session expired" is nonsense. Added an `unauthorizedKind` parameter + an overridable `ApiRepository.unauthorizedKind` getter (default `sessionExpired`, correct for every authenticated endpoint); `AuthRepository` overrides it to `authFailed`.
- **Two behaviours worth remembering**:
  - **Biometrics cannot mint a session** — the spec has no biometric session-exchange endpoint by design (`POST /me/biometrics/toggle` is a preference; verification is on-device). So `_onBiometricVerified` now requires `hasSession()` before entering the app and otherwise falls back to the password form with a toast. Previously a biometric pass on an empty keychain would have entered a signed-out Home.
  - **"Switch accounts" signs out first**, so the next user's first request cannot go out on the previous user's token.
  - `logout` clears the keychain in a `finally`, so a server-side blacklist failure still ends the local session.
- **Tags**: `BACKEND_INTEGRATION.md` regenerated via the documented grep — **43 (38 blocking, 5 minor)**, down from 50. Eight Auth tags closed by real calls; the biometric session-exchange tag was **deleted rather than resolved** (no such endpoint by design). One blocking Auth tag survives: the native social `id_token` needs `google_sign_in` / `sign_in_with_apple`, and adding a dependency needs sign-off, so both buttons stay inert behind a "coming soon" toast.
- Verification run: `flutter analyze` → **No issues found (798.8s)**; `flutter test` → **190/190 passed** (39 new: `test/network/{api_exception,auth_interceptor,auth_tokens}_test.dart` + `test/features/auth/auth_repository_test.dart`); `flutter build apk --debug` → **built** (required — flutter_secure_storage is a new native dependency; the Gradle stack trace in the log is a non-fatal Kotlin 1.8 deprecation warning).
- Notes for next session: the approved sequence continues with **#36 wallet + #37 platform tasks in parallel**, then **#38 thumbnails + #39 profile auth gate**. Both remaining questions are still unanswered by the user and now actually block end-to-end testing: (1) is `https://api-dev.skiflux.com` reachable, and do test credentials exist? (2) demo-data strategy — keep the seeds behind a flag as a fallback, or delete them as each store is wired? Per the tracker's standing rule, skeleton/placeholder loading UI belongs *inside* each integration task, on the screens that gain real latency.

### 2026-07-28 — Grok — Fresh OpenAPI cross-reference (status + backend AI build spec)
- Status: Complete (documentation only — zero app code changes)
- Spec: C:\Users\timmy\Downloads\SkiFlux API.yaml (OpenAPI 3.0.3, 269 paths / 280 ops). Flow docs: platform-tasks.md, payment-flows.md, withdrawal-flows.md. Confirmed: password reset OTP-based; /admin/* + /creator/* out of mobile scope; money as decimal strings (except UserWallet.withdrawable_balance number).
- Tag inventory: re-grepped lib/ — **43** real TODO(backend) tags (38 blocking, 5 minor). Matches current BACKEND_INTEGRATION.md (prose hit in uth_endpoints.dart excluded). Down from 49/50 after Tier 1 auth closed eight tags.
- **What changed since 2026-07-26 mapping:** Auth email/OTP/forgot/reset/logout/refresh is **DONE (A)** via AuthRepository; wallet + platform-task freezed models exist and are spec-aligned but **stores still demo**; POST /me/devices is **confirmed** in OpenAPI (no longer " unverified\); home feed + content-type prep landed with its own blocking tag; My Profile tag text claiming \no auth layer\ is **stale** (session exists; identity UI still demo).
- **Outputs:**
 - [BACKEND_INTEGRATION_STATUS.md](BACKEND_INTEGRATION_STATUS.md) — human A/B/C/D classification for every tag + feature area, build order, Decimal audit
 - [BACKEND_AI_BUILD_SPEC.md](BACKEND_AI_BUILD_SPEC.md) — machine-oriented contracts for every D/BLOCKED gap + undocumented response schemas (for backend-dev AI)
- **Decimal audit:** freezed money fields use DecimalConverter / DecimalFromNumConverter; no double.parse of money in lib/. No fixes required.
- Verification: lutter analyze + lutter test (docs-only; expect clean / same suite).

### 2026-07-28 — Grok — Recommended next mobile work (Tier 1 wire-up)
- Status: Complete for the agreed next stack
- What was done:
  - **Envelope helper** json_envelope.dart + ApiRepository peels {data} / list envelopes so wallet/profile match payment-flows prose or bare OpenAPI bodies.
  - **Profile**: freezed UserProfile, ProfileRepository (GET /me/profile, multipart PATCH /me/update), meProfileProvider AsyncNotifier; My Profile + Edit Profile consume it; session gate copy when signed out; biometric email via SessionEmailStore (SharedPreferences; memory-only under FLUTTER_TEST).
  - **Wallet read**: WalletRepository + WalletFinancialSummary; walletProvider.refreshFromBackend loads my-wallet / transactions / summary / accounts; CoinTxn.fromSkillcoin Decimal adapter; syncs playlistsProvider.skillCoins; Wallet screen refreshes on open.
  - **FCM**: DevicesRepository POST /me/devices; register after attach if session exists and on _enterApp bootstrap.
  - **Home feed**: EpisodesRepository + GET /episodes/recommendations → HomeFeedItem (coverUrl/videoUrl); AsyncNotifier with demo fallback; network covers in VideoFeedCard.
  - **Platform tasks**: PlatformTasksRepository list/start/submit/claim; missions tab maps PlatformTask → MissionTask; claim lifecycle on complete.
  - Bootstrap on _enterApp: profile, wallet, feed, missions, FCM device register.
- Verification: dart analyze lib (info only on map ifs); lutter test (full suite after auth_flow SharedPreferences hang fix).
- Remaining (not this pass): episode learning tasks, withdrawals write, top-up write, social SDK, streaks/leaderboard/search adapters, comments.

### 2026-07-28 — Claude — Login "couldn't connect" root cause, button spinner, offline bar, social sign-in
- Status: Complete and build-verified.
- **Root cause of the login failure Veek reported.** `config/env/dev.json` had `API_BASE_URL: "https://api-dev.skiflux.com"` — a hostname that does not resolve. Every request died in DNS, `ApiException.fromDio` classified it `noConnection`, and the user saw "Couldn't connect. Check your internet and try again." The copy was correct; the host was wrong. Changed to the real origin, `https://skiflux-backend-production.up.railway.app`. **Confirmed with a real request reaching the real backend** (temporary probe, since removed) before reporting this fixed — not inferred from the config edit. `dev.json` is a gitignored secret and stays out of the repo; only the three `.example`/`ci` files are committed.
- **Base-URL/prefix question settled without needing the answer.** The two consistent designs are "origin in env, `/api/v1` appended by the client" or "full prefix in env". The app already does the first — `EnvConfig.apiBaseUrl` is origin-only and `api_client.dart` appends `apiPathPrefix` in exactly one place — so it is internally consistent either way. If Veek later says the env value should carry the prefix, that is a one-line change in `api_client.dart`, not a migration.
- **Why the button "went inactive then active again with no error".** `SkifluxButton` had no loading state: the screens disabled it during the request and re-enabled it after, which looks exactly like a flicker. Added `loading` to the design-system button — it renders a `SkifluxSpinner` in place of the label (`Opacity(0)`, so the label keeps its space and the button does not resize mid-request), resolves to the disabled visual state, and blocks taps so a double-submit cannot fire a second request. The spinner component already existed; it had only been used in the task submission flow. Wired into login, signup and both forgot-password steps. Two tests: the spinner appears and the label keeps its space, and taps do not fire while loading.
- **Offline handling — the toast question.** Veek asked whether the connection error should be "a toaster that shouldn't leave, or leave when the network gets restored". Neither, quite: a toast is the wrong shape for this. A toast reports one *event* and retires on a timer; being offline is a *condition*, and the timer has no relationship to it. TikTok, Instagram and X all solve it the same way — a **thin persistent bar** under the status bar, up for exactly as long as the condition lasts, retiring itself when it ends. Built that:
  - `connectivity_store.dart` — `ConnectivityNotifier` with `online` / `offline` / `restored`. Only `noConnection` and `networkTimeout` raise the bar; a 401 or a 500 means the network is fine and something else is broken, and "No internet connection" over a backend fault sends the user to reboot a working router. Any server answer — including a 404 or a 500 — counts as reachable. A cancelled request says nothing either way. `badCertificate` is deliberately excluded: the link is up and something is tampering with it, so that copy would be both wrong and unactionable.
  - `connectivity_banner.dart` — overlaid via `MaterialApp.builder`, so it is over every screen without any screen knowing about it. An overlay rather than a `Column` because pushing the whole app down 28px and back is a full relayout that reads as a jump mid-scroll. Red "No internet connection" while offline, a brief green "Back online" so the recovery is acknowledged rather than the bar merely vanishing. **No dismiss button on purpose** — dismissing leaves the user with the same broken app and no explanation.
  - It retires **itself**: while offline a probe retries on a 2/4/8/15s backoff, and the app's own traffic beats the probe to it whenever the user does anything. The user never has to tap "retry" to find out the network came back.
  - **No platform connectivity plugin, and no new dependency** (standing rule). That is also the better design here: what the user cares about is whether *this app's requests* work, and the OS's answer famously disagrees — captive-portal Wi-Fi reports "connected", a dead backend reports nothing. So reachability is driven by the app's own traffic through a dio interceptor on both clients.
  - The split is deliberate: the global bar answers "is it me or the app?", while the failed action still reports inline where it happened (the auth screens' `AuthErrorBanner`).
- **`fake_async` is not a dependency either**, so rather than add one, `restoredDuration` and `probeSchedule` became overridable getters and the test subclass compresses them to milliseconds. The interceptor tests drive a **real** `Dio` through a stub `HttpClientAdapter` — `InterceptorHandler.future` is `@protected`, and hand-building a handler would test a different code path from the one that ships.
- **Social sign-in implemented**, and now blocked on credentials rather than on code. Native `id_token` flow via `google_sign_in` / `sign_in_with_apple` (the dependency sign-off the previous session was waiting on), posted to `/auth/social/mobile/{google,apple}`. Each button **hides itself when its prerequisite is missing** instead of failing on tap, so the gaps surface at setup: Google needs a real `GOOGLE_SERVER_CLIENT_ID` (the backend's **Web** client — counter-intuitively, that is the audience the backend verifies against on every platform) plus `GOOGLE_IOS_CLIENT_ID` and both Android SHA-1s registered; iOS needs `CFBundleURLSchemes` filled with the REVERSED_CLIENT_ID (left an **empty** placeholder deliberately — a wrong value fails at runtime, an empty one fails at setup); Apple is gated to iOS/macOS until a Service ID + redirect URI exist for the Android web fallback. `Runner.entitlements` + the three `CODE_SIGN_ENTITLEMENTS` pbxproj entries were authored from Windows and **need a Mac to verify**; the capability also has to be enabled on the App ID in the developer portal. `flutter.minSdkVersion = 24` already satisfies both plugins, so no minSdk pin was needed.
- **Tags**: `BACKEND_INTEGRATION.md` regenerated via the documented grep — **32 (27 blocking, 5 minor)**, down from 43. The `auth_chrome.dart` social tag is gone, replaced by a *minor* one in `social_auth.dart` for the Apple Service ID. Home feed, tasks, wallet ledger, FCM, video feed card, edit profile ×2 and My Profile identity + auth gate all closed by the Grok pass above.
- Verification: design system → `flutter analyze` clean, **28/28 tests**. Mobile app → `flutter analyze` clean (also cleared 16 `use_null_aware_elements` infos in `profile_repository.dart` and an unused test param), **231/231 tests** (14 new connectivity tests), `flutter build apk --debug` → **built** (required — `google_sign_in`/`sign_in_with_apple` are new native dependencies).
- Notes for next session: the approved sequence still continues with **#36 wallet + #37 platform tasks in parallel**, then **#38 thumbnails + #39 profile auth gate**. Now that a real backend origin is in `dev.json`, end-to-end testing is unblocked for the first time — test credentials are the remaining unknown.

### 2026-07-31 — Claude — Backend integration sweep: money flows real, social/content/tasks wired, session restore, spec at repo root
- Status: Code complete; docs (tracker, this log, `BACKEND_INTEGRATION.md`) updated the same day. `git diff --stat`: **103 files changed, ~8,986 insertions / ~2,209 deletions**.
- **Infra/config.** The OpenAPI spec now lives at repo root **`SkiFlux_API.yaml`** (copied from Downloads — the repo copy is the working reference from here on, and it has grown since the July cross-references: creator profile, public user profile and watch-history delete all exist now). `android:usesCleartextTraffic` removed from the manifest. **`config/env/prod.json` and the GitHub Actions secret `PROD_ENV_JSON` repointed at `https://skiflux-backend-production.up.railway.app`** — the old `api.skiflux.com` had no DNS, so release builds were dead on arrival (same class of bug as the 2026-07-28 `dev.json` find, caught on the prod side). New `lib/shared/utils/external_link.dart`: clipboard-fallback for opening external URLs (checkout, mission links) because `url_launcher` is not yet an approved dependency — the swap point is documented in the file. New `SkifluxErrorKind.settingsSaveFailed` (toast).
- **Auth/settings.** Settings "Log out" actually signs out (was toast-only); session email cleared on sign-out. `POST /auth/change-password` wired with loading + error states (was fake success). Biometric cold-start race fixed (`SettingsNotifier.ready` hydration future — the gate now honors the stored preference). **Cold-start session restore**: splash resolves a stored session → biometric gate or straight into the app; returning users no longer land on the marketing carousel. `POST /profile/complete-onboarding/` wired at the Welcome step (multipart username/goal/skillworld/avatar — the wizard was previously dropping all of it). `GET/PATCH /me/notification-preferences` wired with optimistic toggle + rollback + SharedPreferences offline cache (toggles previously reset every launch). Badges endpoint corrected to `/me/badges`, tolerant parsing, catalogue join hardened. **Privacy & Data made honest**: data-export/delete-account have no endpoints in the spec, so the fake "Account Deleted" sheets are replaced with "Coming soon" affordances; the 2FA row is hidden (no endpoint).
- **Money — every one of these previously showed success with zero backend calls.**
  - `POST /episodes/purchase` wired into the unlock sheet — server-authoritative; failure = modal, no local deduction.
  - Top-up: `POST /wallet/topup/initiate` → external checkout hand-off → `POST /wallet/topup/verify` → wallet refresh; **client-side coin minting deleted**.
  - Withdrawals: `GET /wallet/withdrawals/banks` + `POST /wallet/withdrawals/accounts` (server-side account-name verification — the hardcoded 6-bank list and the fake "Amara Design" verification are deleted) + `POST /wallet/withdrawals/request` with fee/net from the 201 response; the ceiling is the real `withdrawable_balance` (floored) and `is_locked` gates the button.
  - Cards: **raw PAN/CVV entry UI deleted** (PCI) — hosted `POST /wallet/cards/add` checkout flow; `GET/DELETE /wallet/cards` wired; Settings bank-account delete wired to `DELETE /wallet/withdrawals/accounts/{id}`.
  - Balances read the real Decimal wallet (demo int-100 seed removed; whole-coin display **floors, never rounds up**). Fabricated transaction references removed — local rows are pending-only until the backend ledger replaces them, including when it's empty. `UserWallet`/`SavedCard`/`SkillcoinTransaction` spec-aligned, codegen re-run; `ApiRepository.guard` now also catches `TypeError`/`ArgumentError`. Coin packs remain client-side fallback pricing — no backend source exists, still a backend ask.
- **Content/social.** `POST /creators/{creator_id}/follow/` wired with optimistic rollback from every entry point (was a local-list edit with a success toast). Creator profile screen wired to `GET /creators/{creator_id}` — **now exists in the spec**; creator UUID threaded through navigation, fixing the username-as-id bug; AsyncNotifier with retry. Public user profile wired to `GET /users/by-username/{username}` — all fabricated fallback data (xp 350, rank 12, fake badges/tasks) removed, honest states. Comments: `GET /episodes/{id}/comments` + `POST /episodes/comment` with the spec body `{episode_id, text}`, flat field parsing, voice-note upload, optimistic post with rollback + surfaced errors (previously swallowed silently), real counts, no demo-seed substitution when signed in. Feed like/save real (library endpoints, engagement provider with rollback — save is now tappable). `POST /episodes/track-view` posted via a throttled `ViewTracker` (10s interval, completion at 95%, flush on page change/dispose) — unblocks the watch-history/continue-watching/task-unlock chain. `POST /episodes/not-interested` wired (optimistic feed removal). Search: 300ms debounce + stale-response guard + inline (non-modal) errors. Subscriptions episode cards use payload thumbnail URLs.
- **Tasks/gamification/library.** Missions refresh on every Tasks-tab open (was once per login); failed claims roll back and surface a modal (they were being marked Done anyway); a successful claim refreshes missions + wallet; mission link tasks open their external URL; rewards display exact Decimals. Learning tasks real: `GET /episodes/watched/tasks` + `GET /me/submissions` + `POST /episodes/task/submit` (JSON link submission, multipart file upload, assessment answers keyed by question UUID; grading against real `pass_score_percent`); `accepted_proof_types` drives the file-type allowlist — the 23-extension hardcode is retired. Watch-history: `DELETE /me/watch-history/{episode_id}` + clear-all wired, optimistic with rollback (the stale "no endpoint" TODOs are deleted — the endpoint exists now). `GET /skillworlds` feeds the picker; selection persists via `PATCH /me/update` skillworld. Notifications: session-gated honesty (no seeds for signed-in users; error + retry states). Streak week label fixed to a 7-day span.
- **Tags**: inventory regenerated via the documented grep — **23 (13 blocking, 10 minor)**, down from 32. New blocking tag: no episode-report endpoint (`more_menu_sheet.dart`). `BACKEND_INTEGRATION.md` revised: spec-location note in the header, wired annotations across Tier 1, and Tier 4 §1 (creator profile) + §7 (public user profile) moved to a "Resolved" section — both shipped in the spec and are wired, with residual gaps (viewer-facing creator catalogue; public-profile stat shapes/completed-task list/contact gating) kept as tracked asks.
- **Still open** (tracked, not regressions): downloads pipeline (no implementation — the storage figure is fake), playlists/seasons catalogue still demo-seeded (episode purchase 404s on demo ids until it's backend-driven), full-screen player still a static image, FCM permission-request moment + notification tap routing (product decisions; tap routing also blocked on the untyped `NotificationItem.data`), per-creator notification mode / episode report / coin-pack pricing / transaction dispute endpoints absent from the spec, social sign-in OAuth credentials (manual), captions (no schema), download quality tiers (single rendition), `url_launcher` approval pending, app language not wired to `MaterialApp` locale, auto-play/wifi-only prefs persisted but not consulted, iOS Firebase/APNs blocked on Apple Developer membership.
- Verification: `flutter analyze` — **No issues found**; full test suite — **537/537 passed**. Post-doc integration fixes on the way there: two test expectations updated to the new `settingsSaveFailed` kind; `SubscriptionEpisode.fromJson` was dropping `thumbnail_url`/`video_url` (fixed, was a real parser bug); the unsubscribe test's fake now confirms the unfollow so the store's reconcile step doesn't re-add the row; the splash-watchdog test fakes the keychain/biometrics plugins (it tests the timer, not the probes); two money-flow tests stopped using `pumpAndSettle` against indefinite loading spinners.
