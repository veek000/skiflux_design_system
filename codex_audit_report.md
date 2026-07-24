# Codex Audit Report — Skiflux Mobile App

**Audit date:** 2026-07-24  
**Auditor:** Gemini/Antigravity  
**Scope:** All files/changes attributable to Codex, plus any files found in the repo with no matching Session Log entry.  
**Verification:** audit-only. `flutter analyze` → **No issues found** (18.9s). `flutter test` → **58 / 58 passed** (0 changes made).

---

## Step 0 — Scope Identification

### SESSION LOG Cross-Reference

| Log Entry | Author | Notes |
|---|---|---|
| 2026-07-23 — Claude — Settings Flow | Claude | Clearly attributed |
| 2026-07-22 — Claude — Backend Integration Tagging | Claude | Clearly attributed |
| 2026-07-22 — DeepSeek — Controller Disposal Audit | DeepSeek | Clearly attributed |
| 2026-07-22 — DeepSeek — Test Coverage Build | DeepSeek | Clearly attributed |
| 2026-07-22 — DeepSeek — SkifluxInputField Testability Fix | DeepSeek | Clearly attributed |
| 2026-07-22 — DeepSeek — Const Hints Fix + Viewport Verification | DeepSeek | Clearly attributed |
| 2026-07-22 — Claude — Comment Cleanup | Claude | Clearly attributed |
| 2026-07-21 — Claude — Corrections pass + Watch History/Downloads/Saved Videos | Claude | Clearly attributed |
| 2026-07-21 — Claude — Unlock/Buy-Coins + Profile Flow | Claude | Clearly attributed |
| 2026-07-20 — Claude — View Playlist + modal_bottom_sheet | Claude | Clearly attributed |
| 2026-07-20 — Claude — Error modal: headerless layout + copy pass | Claude | Clearly attributed |
| 2026-07-20 — Claude — Playlist/player/public-profile accuracy pass | Claude | Clearly attributed |
| 2026-07-20 — Grok — Error modal layout + copy polish | Grok | Clearly attributed |
| 2026-07-20 — Grok — CI/CD Setup | Grok | Clearly attributed |
| 2026-07-20 — Grok — Riverpod Migration Pass 4 + cross-check | Grok | Clearly attributed |
| 2026-07-20 — Grok — Error handling rollout | Grok | Clearly attributed |
| 2026-07-20 — Grok — Toast Generalization | Grok | Clearly attributed |
| 2026-07-20 — Grok — Centralized Error Handling Layer | Grok | Clearly attributed |
| 2026-07-20 — Grok — Error modal display correction | Grok | Clearly attributed |
| 2026-07-19 — Grok — Riverpod Migration Pass 1 | Grok | Clearly attributed |
| 2026-07-19 — Grok — Riverpod Migration Pass 2 | Grok | Clearly attributed |
| 2026-07-19 — Grok — Riverpod Migration Pass 3 | Grok | Clearly attributed |
| 2026-07-19 — Grok — Riverpod Migration Cleanup | Grok | Clearly attributed |
| 2026-07-22 — Antigravity — Widget Structure Refactor | Antigravity | Clearly attributed |
| 2026-07-23 — Gemini — Lint Rigor Upgrade | Gemini | Clearly attributed |
| 2026-07-23 — Grok — Secrets/Env Strategy | Grok | Clearly attributed |
| 2026-07-24 — Gemini — Documentation Reconciliation | Gemini | Clearly attributed |
| **2026-07-24 — Codex — Figma onboarding and authentication flow** | **Codex** | ← **ONLY Codex-attributed entry** |
| 2026-07-24 — Gemini — Auth Flow Lint & Syntax Error Fixes | Gemini | Clearly attributed (fixes to Codex output) |
| 2026-07-24 — Gemini — Wallet & Settings Feature Audit | Gemini | Clearly attributed |
| 2026-07-24 — Gemini — Money-Adjacent Flows Error Handling Wiring | Gemini | Clearly attributed |
| 2026-07-24 — Gemini — Money-Adjacent Flows: Real Validation + Error Path Tests | Gemini | Clearly attributed |

### Git Log Cross-Reference

**Commits identified:**

| Commit | Date | Author | Attribution Assessment |
|---|---|---|---|
| `ba47b5f` | 2026-07-24 | Asuquo Victor | Codex commit — message "feat: implement modular architecture and centralized error handling for mobile app v2". Files: `features/auth/auth_flow.dart` (new), `app/app.dart` (modified), `PROJECT.md` (modified), `README.md` (modified), `test/widget_test.dart` (modified) |
| `7cedd75` | 2026-07-23 | Asuquo Victor | "feat: implement modular architecture and centralized error handling for mobile app v2" — **same commit message prefix as Codex commit**. Contains 74 files across settings, env config, tests. SESSION LOG shows the corresponding entries all attributed to Claude (Settings), DeepSeek (Tests), and Grok (Secrets). **Git history is NOT the ground truth for attribution** — this large commit bundles many sessions' work pushed simultaneously. |
| `2afbb7a` | 2026-07-21 | Asuquo Victor | "feat: implement extensive feature set..." — wallet, profile library screens, confirm_sheet. SESSION LOG entries attributed to Claude (Unlock/Buy-Coins, Corrections pass). |
| `14cf254` | 2026-07-20 | Asuquo Victor | Riverpod migration, error/toast, GitHub Actions. SESSION LOG attributes to Grok/Claude. |
| `81cd3b6` | 2026-07-21 | Asuquo Victor | Minor `my_profile_screen.dart` tweak. |
| `c8cd3ab` | Earlier | Asuquo Victor | Monorepo restructure. |

**Key finding:** The only commit whose SESSION LOG entry is directly and explicitly attributed to Codex is `ba47b5f`. Commit `7cedd75` has the same commit-message prefix but its contents map cleanly to other SESSION LOG entries (Claude, DeepSeek, Grok). The duplicate commit message is a user push artifact, not a Codex authorship indicator.

### Definitive Codex-Attributable Scope

**One file built by Codex, zero others:**

| File | Reason for inclusion |
|---|---|
| `lib/features/auth/auth_flow.dart` | Explicitly stated in the only Codex SESSION LOG entry: "added `features/auth/auth_flow.dart`" |

**Files modified by Codex (not created):**

| File | Change |
|---|---|
| `lib/app/app.dart` | Changed `home: HomeScreen()` → `home: AuthFlow()` |
| `test/widget_test.dart` | Added `'App loads root widget'` test; kept existing `'Home screen loads'` test intact |
| `PROJECT.md` | Added the Codex SESSION LOG entry (18 lines) |
| `README.md` | Reformatted (later superseded by Gemini's documentation reconciliation) |

**Files with no Session Log entry — GAP CHECK:**

Cross-referencing every file in `lib/features/auth/` against SESSION LOG entries:

- `lib/features/auth/auth_flow.dart` — covered by Codex + Gemini lint-fix entries ✓

No other files exist under `lib/features/auth/` (confirmed: directory contains exactly 1 file). No orphaned files found anywhere else.

> [!NOTE]
> `lib/features/auth/` is a new directory with only one file. Every other `lib/features/` directory already had a matching work-log item (confirmed in the Antigravity widget-structure audit and the Gemini documentation reconciliation). No gap was found.

---

## Step 1 — Structural Convention Audit

### Reference convention (observed from `tasks/` and `leaderboard/`):

```
lib/features/<feature>/
  <feature>_screen.dart     (one screen → one file)
  <feature>_screen_2.dart   (when a feature has multiple distinct screens)
  sheets/<name>_sheet.dart  (sheets/overlays)
  data/<feature>_store.dart (Riverpod providers + state models)
  widgets/<name>.dart       (shared sub-widgets, only when reused)
```

### `lib/features/auth/auth_flow.dart` — 557 lines, 30,769 bytes

**Structure finding: MONOLITH — justified by design, but split should be considered.**

The file bundles:
- `AuthStage` enum (19 states)
- `AuthFlowState` + `AuthFlowNotifier` + `authFlowProvider` (state layer)
- `AuthFlow` root `ConsumerStatefulWidget` (splash timer + stage switcher)
- `_SplashScreen`, `_BrandMark` (2 private widgets)
- `_OnboardingScreen` (3 pages parameterized)
- `_CreateAccount`, `_SignInScreen` / `_SignInScreenState`, `_ForgotPassword`, `_ResetPassword`, `_VerificationScreen`, `_SuccessScreen`, `_BiometricScreen`, `_ClaimIdentity`, `_GoalsScreen`, `_SkillworldScreen`, `_LegalScreen` (12 screen-level private classes)
- `_ScrollableForm`, `_Progress`, `_Pill`, `_AuthLink`, `_LegalLinks`, `_ChoiceRow`, `_SkillCard`, `_AuthScaffold` (8 shared layout helpers)

**Comparable features split into multiple files:** `tasks/` has 6 files, `playlists/` has 5+. Even `streaks/` (3 screens) uses 2 files + `data/`.

**Assessment:** This is clearly a "one massive file" approach that deviates from the project convention. The convention splits each distinct screen into its own file. That said, authentication flows are often kept together in Flutter codebases because the stage-machine switch is the unit of coherence — the private classes cannot be imported independently anyway, so the split would be cosmetic. However, the `data/` layer (state + provider) is explicitly required by project convention to live in `data/<feature>_store.dart`, and it's currently embedded in the same file.

**Verdict:** The state layer (`AuthFlowState`, `AuthFlowNotifier`, `authFlowProvider`) **should** be extracted to `lib/features/auth/data/auth_store.dart` per project convention. The screen widgets bundled in one file are an acceptable compromise given the state-machine nature, but the data layer must follow the convention.

**No `data/` subdirectory exists** — this is the only concrete structural gap against the project convention.

---

## Step 2 — Design System Consistency

### Imports (lines 1–7)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
```

Correctly imports via the barrel — ✓

### Token Usage — Full Scan

| Category | Evidence | Status |
|---|---|---|
| **Colors** | `SkifluxColors.backgroundPrimary` (L221), `SkifluxColors.backgroundBrand` (L241), `SkifluxColors.contentPrimaryInverse` (L242), `SkifluxColors.contentBrand` (L308/365/507/…), `SkifluxColors.backgroundPressed` (L309), `SkifluxColors.borderSecondary` (L388), `SkifluxColors.backgroundPositiveSubtle` (L445), `SkifluxColors.contentPositive` (L450), `SkifluxColors.backgroundBrandOpacity50` (L552), `SkifluxColors.backgroundHover` (L555/556), `SkifluxColors.contentDisabled` (L555), `SkifluxColors.backgroundPrimaryBrand` (L556), `SkifluxColors.contentTertiary` (multiple), `SkifluxColors.contentSecondary` (L556) | ✓ All semantic tokens |
| **Raw Material Colors** | `Colors.transparent` — L555 in `_ChoiceRow` border: `Border.all(color: selected ? SkifluxColors.contentBrand : Colors.transparent, width: 2)` | ⚠️ **One deviation** — `Colors.transparent` is acceptable here (truly transparent, no semantic equivalent), but worth noting |
| **Typography** | `SkifluxTypography.headingH5ExtraBold`, `headingH6Bold`, `headingH6ExtraBold`, `headingH7Bold`, `headingH8Bold`, `headingH9Bold`, `headingH10Bold`, `bodyP8Regular`, `bodyP9Regular`, `bodyP10Regular`, `bodyP10Semibold`, `bodyP11Regular`, `uiInputLabel`, `uiBadgeTagMedium`, `codeInline` — all design system tokens | ✓ |
| **Spacing** | Uses literal `EdgeInsets` values (8, 12, 16, 24, 28, 32, 36) directly rather than `SkifluxSpacing.*` tokens | ⚠️ **Systematic deviation** — every other screen in the app uses `SkifluxSpacing.spaceS` etc. |
| **Radii** | `SkifluxRadii.borderPill` (L310, 551), `SkifluxRadii.borderM` (L389), `SkifluxRadii.borderL` (L555, 556) — all design-system tokens | ✓ |
| **Icons** | `RemixIcons.mail_check_fill` (L363), `RemixIcons.checkbox_circle_fill` (L448), `RemixIcons.fingerprint_fill` (L505), `RemixIcons.user_fill` (L505 — fixed by Gemini), `RemixIcons.arrow_left_s_line` (L548), `RemixIcons.brush_fill`, `RemixIcons.braces_fill`, etc. | ✓ All Remix |
| **Components** | `SkifluxButton` (multiple, with correct `type:`, `expanded:`, `onPressed:` usage), `SkifluxInputField` (multiple, with `label:`, `keyboardType:`, `obscureText:`, `hasError:`, `caption:`, `controller:`, `onChanged:`) | ✓ Correctly used |
| **Raw Material Widgets** | `Scaffold` via `_AuthScaffold` wrapper (acceptable — no `SkifluxScaffold` exists in the DS), `TextButton` (used for secondary actions: "Forgot password?", "Login with Password", "Resend Code", "Sign up" links) | ⚠️ **`TextButton` deviation** — project convention uses `SkifluxButton(type: tertiary/tertiaryMono)` for secondary actions. `TextButton` is raw Material and bypasses the design system button token map. **Line references:** L338 ("Forgot password?"), L412 ("Resend Code"), L498 ("Login with Password"), L534 ("Switch accounts"), L548 (back arrow button in `_LegalScreen`) |
| **OTP Boxes** | `_VerificationScreen` renders 6 static `Container` boxes (L382–395) with `border: Border.all(color: SkifluxColors.borderSecondary), borderRadius: SkifluxRadii.borderM` — no `TextField` inside; purely decorative. Shows hardcoded `'–'` placeholder text, non-interactive | ⚠️ **Functional gap** — these are non-interactive demo boxes; no real OTP input exists. Not a token issue per se, but a significant feature incompleteness |
| **Timer Display** | L398: `'05:59'` hardcoded string; no actual countdown logic | ⚠️ **Hardcoded demo content** |
| **Demo Email** | L371: `'veek@nexacorp.io'` (verification screen), L513: `'veek@nexacorp.io'` (biometric screen) — hardcoded demo value | ⚠️ **Hardcoded demo content** — expected for a demo flow, but should be noted |

### Spacing Deviation — Evidence

```dart
// L258, L281, L493 etc. — literal spacing throughout
padding: const EdgeInsets.all(16),
padding: const EdgeInsets.all(24),
const SizedBox(height: 36),
const SizedBox(height: 32),
```

Comparable screen (e.g. `add_bank_sheet.dart` L52):
```dart
padding: const EdgeInsets.all(SkifluxSpacing.spaceL), // SkifluxSpacing.spaceL = 24
```

The token values match (24 = `spaceL`, 16 = `spaceM`, 8 = `spaceS`), so visually correct — but it's inconsistent with the project pattern of using named tokens rather than literals.

---

## Step 3 — Riverpod Assessment

### State Layer Analysis

```dart
// lines 11–31 — AuthStage enum: 19 auth stages
// lines 34–63 — AuthFlowState: immutable, copyWith pattern ✓
// lines 65–66 — authFlowProvider: NotifierProvider<AuthFlowNotifier, AuthFlowState> ✓
// lines 68–87 — AuthFlowNotifier extends Notifier<AuthFlowState> ✓
```

**Verdict: Riverpod usage is correct and complete.**

- `authFlowProvider` is a `NotifierProvider` — consistent with the project's pattern for mutable feature state.
- `AuthFlowState` is `@immutable` with `copyWith` — consistent with e.g. `StreaksState`, `CommentsState`.
- State mutations go through `AuthFlowNotifier` methods (`show`, `setUsername`, `setGoal`, `setSkillworld`, `clearError`, `signIn`), not inline state manipulation — ✓
- `AuthFlow` (root widget) correctly uses `ConsumerStatefulWidget` / `ConsumerState` — ✓
- `ref.watch(authFlowProvider)` in `build()`, `ref.read(authFlowProvider.notifier)` for mutations — ✓
- **No `setState` for feature-level state.** The `_splashTimer` cancel in `dispose()` is pure lifecycle management, not state management — ✓
- `_SignInScreen` uses `_SignInScreenState extends State<_SignInScreen>` (not Consumer) but correctly: sign-in is a form widget that receives its state from the parent ConsumerWidget via props. The `error` string is passed in from `ref.watch(authFlowProvider).signInError` at the `AuthFlow` level — this is the correct delegation pattern ✓

**The only potential Riverpod concern:**

`AuthStage.fingerprint / faceId` state (`state.stage == AuthStage.faceId`) in `_BiometricScreen.onSwitch` calls `notifier.show(AuthStage.faceId)` — but `_BiometricScreen` is a StatelessWidget receiving callbacks, so `ref` is held by `_AuthFlowState`. Correct pattern ✓.

**Is `authFlowProvider` appropriate as a `NotifierProvider` (not `autoDispose`)?**

The auth session should persist for the app's lifetime — non-auto-dispose is correct. Once `HomeScreen` replaces `AuthFlow` via `Navigator.pushReplacement`, the provider still exists in the `ProviderScope` (intentional — the user's username/goal are still in the state even after navigating away). This is acceptable for a demo but worth noting: when a real auth backend replaces the demo, the `authFlowProvider` should probably be cleared/invalidated on successful login.

---

## Step 4 — Controller Disposal and Error Handling

### Controller Disposal

| Controller | Location | Disposed? |
|---|---|---|
| `_email` (`TextEditingController`) | `_SignInScreenState` line 336 | ✓ `dispose()` at line 337 |
| `_password` (`TextEditingController`) | `_SignInScreenState` line 336 | ✓ `dispose()` at line 337 |
| `_splashTimer` (`Timer?`) | `_AuthFlowState` line 97 | ✓ `_splashTimer?.cancel()` at line 111 |

**Disposal status: Clean.** All 3 disposable resources are properly cleaned up.

**Missing controllers for OTP input:** The 6 OTP boxes are static Containers with no TextEditingController — the OTP feature simply does not exist as interactive code, so there is nothing to dispose. This is a functional gap, not a disposal leak.

### Error Handling

`ErrorDisplay.show` is **not called anywhere** in `auth_flow.dart`.

**Flows that could plausibly fail when real backend is introduced:**

| Flow | Failure Mode | Current Handling | Should Be |
|---|---|---|---|
| `_CreateAccount` → submit | Registration failure (email taken, server error) | `onSubmit: () => notifier.show(AuthStage.verifyEmail)` — always succeeds | `ErrorDisplay.show` via try/catch in a real submit handler |
| `_SignInScreen` → "Sign in" | Wrong credentials, server error | `notifier.signIn(email, password)` — demo string match only; error stored as `signInError` string in state | Demo handling is appropriate *for now*; modal error via `ErrorDisplay.show` when backend lands |
| `_VerificationScreen` → "Verify email" | Invalid OTP code, expired code | `onComplete: () => notifier.show(...)` — always succeeds | `ErrorDisplay.show` |
| `_ForgotPassword` → "Send Reset Link" | Email not found | `onSend: () => notifier.show(AuthStage.verifyReset)` — always succeeds | `ErrorDisplay.show` |
| `_ResetPassword` → "Reset Password" | Token expired, mismatch | Always succeeds | `ErrorDisplay.show` |

**The sign-in error state is a special case:** Codex implemented inline field-level error display (the `hasError` + `caption` fields on `SkifluxInputField`) for credential errors, which is the correct UX pattern for auth (inline, not modal). This is acceptable and aligns with Figma auth flows. The `ErrorDisplay` modal should be reserved for server/network failures at those endpoints.

**Missing `SkifluxErrorKind` for auth:** No `authFailed` or `sessionExpired` error kind exists in `error_handler.dart` (the table in PROJECT.md mentions "Session expired / auth → modal" but no `SkifluxErrorKind` maps to it). This is a gap that predates Codex and is not Codex's fault — but the auth flow's introduction makes it more urgent.

---

## Step 5 — Test Coverage

### Tests for Codex-built work

| Test file | Coverage of `auth_flow.dart` |
|---|---|
| `test/widget_test.dart` | Added by Codex: `'App loads root widget'` — pumps `SkifluxMobileAppV2` → `AuthFlow` → `expect(find.byType(SkifluxMobileAppV2), findsOneWidget)`. **This test only confirms the widget tree builds; it does not exercise any auth stage transitions, form validation, or stage-machine logic.** |

**No tests exist for:**
- Auth stage transitions (splash → onboardingOne → createAccount → verifyEmail → etc.)
- The `AuthFlowNotifier.signIn` logic (wrong email / wrong password / success paths)
- `_VerificationScreen` OTP complete callback
- `_ClaimIdentity` / `_GoalsScreen` / `_SkillworldScreen` selection flow
- `_BiometricScreen` verify / switch callbacks
- `authFlowProvider` Riverpod unit tests (comparable to `notifications_test.dart`, `streaks_test.dart`, etc.)

**Coverage gap: significant.** Every other feature provider has unit tests. `authFlowProvider` has none. Given that `AuthFlowNotifier.signIn` has branching logic (3 paths), and the stage machine has 19 states, this is the most testable unmissed coverage gap in the entire codebase.

---

## Step 6 — Verification

**`flutter analyze`** → `No issues found! (ran in 18.9s)`  
**`flutter test`** → `58 / 58 passed`  
**Changes made during this audit:** None.

> [!IMPORTANT]
> This was a read-only audit. Zero source files were modified. The baseline matches the known post-wiring state (58 tests = 54 prior + 4 money-flow tests).

---

## Prioritised Follow-Up Recommendations

Ranked by impact / urgency:

### P1 — Missing `SkifluxErrorKind` for auth failures
**File:** `lib/shared/error_handling/error_handler.dart`  
**Issue:** No `authFailed` / `sessionExpired` kind exists despite PROJECT.md's decision table listing it. When real auth backend lands, every auth error path needs a kind to route to the correct modal copy.  
**Effort:** S — add 2–3 enum values + `_forKind` cases.  

### P2 — Extract `data/auth_store.dart` from `auth_flow.dart`
**File:** `lib/features/auth/auth_flow.dart` → new `lib/features/auth/data/auth_store.dart`  
**Issue:** `AuthStage`, `AuthFlowState`, `AuthFlowNotifier`, `authFlowProvider` are embedded in the UI file. Project convention is explicit: state layer lives in `data/<feature>_store.dart`. Every other feature (`tasks`, `wallet`, `notifications`, etc.) follows this.  
**Effort:** M — mechanical extraction, import update in `auth_flow.dart`.  

### P3 — Add `authFlowProvider` unit tests
**File:** new `test/providers/auth_test.dart`  
**Issue:** `AuthFlowNotifier.signIn` has 3 branches (no-account, wrong-password, success). `consumeCelebration`-style once-per-session transitions exist. Every other feature provider (`notificationsProvider`, `tasksProvider`, `streaksProvider`, etc.) has a test file. Auth is the only gap.  
**Effort:** M — ~6–10 tests. Pattern: follow `test/providers/notifications_test.dart`.  

### P4 — Add auth stage transition widget tests
**File:** new or extended test file  
**Issue:** The 19-state switch in `AuthFlow.build` is untested. At minimum: splash → onboardingOne (timer fires), createAccount → verifyEmail (submit), signIn → fingerprint (correct credentials), signIn → error state (wrong credentials).  
**Effort:** M–L.  

### P5 — Replace `TextButton` with `SkifluxButton(type: tertiary)` for secondary auth actions
**File:** `lib/features/auth/auth_flow.dart` — lines 338, 412, 498, 534, 548  
**Issue:** 5 `TextButton` usages for secondary/link actions. Project convention uses `SkifluxButton(type: SkifluxButtonType.tertiary)` for these. `TextButton` bypasses the DS token map (letter spacing, font weight, press states).  
**Effort:** S — mechanical replacement.  

### P6 — Replace literal spacing values with `SkifluxSpacing` tokens
**File:** `lib/features/auth/auth_flow.dart` — pervasive  
**Issue:** `EdgeInsets.all(16)`, `SizedBox(height: 36)`, etc. throughout. Values are numerically correct (16 = `spaceM`, 24 = `spaceL`) but bypass the named tokens. Inconsistent with rest of app.  
**Effort:** S — find-and-replace with mapping.  

### P7 — Make OTP boxes interactive (when auth backend is added)
**File:** `lib/features/auth/auth_flow.dart` — `_VerificationScreen` lines 379–415  
**Issue:** 6 static container boxes show `'–'` placeholders. No `TextField`, no OTP logic, no actual input. Timer `'05:59'` is hardcoded. This is acceptable for the demo phase but must be implemented before real backend integration — OTP verification is a blocking auth step.  
**Effort:** L — requires OTP input widget + real countdown timer + backend call.  

### P8 — Wire `ErrorDisplay.show` to auth submit paths
**File:** `lib/features/auth/auth_flow.dart`  
**Issue:** Account creation, email verification, password reset, and biometric verify paths currently have no error handling. When a real backend is integrated, every submit handler needs a `try/catch` → `ErrorDisplay.show(context, ref, e, stackTrace: st)`.  
**Effort:** M — requires P1 (add `authFailed` kind) first. Pattern: follow `withdraw_screen.dart`.  

### P9 — Clear/invalidate `authFlowProvider` on successful login
**File:** `lib/features/auth/auth_flow.dart` — biometric `onVerify` / skillworld `onContinue`  
**Issue:** After `Navigator.pushReplacement(HomeScreen)`, `authFlowProvider` stays alive in `ProviderScope` with all user-entered data (username, goal, skillworld). For a demo this is harmless; with real credentials it would keep the session token/username in memory unnecessarily.  
**Effort:** XS — call `ref.invalidate(authFlowProvider)` before navigation.  

---

## Summary Table

| Area | Finding | Severity |
|---|---|---|
| File count / scope | 1 file built, 4 modified | — |
| Structural convention | No `data/` subdirectory; state layer in UI file | Medium |
| Monolith size | 557 lines, 19+ private classes in one file | Low (acceptable for state machine) |
| Design system — tokens | ✓ 100% semantic color/typography/radii tokens | Pass |
| Design system — spacing | Literal values throughout (not `SkifluxSpacing`) | Low |
| Design system — `TextButton` | 5 raw `TextButton` usages vs `SkifluxButton(tertiary)` | Low |
| Design system — `Colors.transparent` | 1 usage (acceptable) | Negligible |
| Riverpod | ✓ Correct `NotifierProvider` pattern, no `setState` for feature state | Pass |
| Controller disposal | ✓ `_email`, `_password`, `_splashTimer` all disposed | Pass |
| Error handling | No `ErrorDisplay.show` wiring; no `authFailed` error kind | Medium |
| Test coverage | 0 provider unit tests, 0 stage-transition tests; only smoke test | High |
| Hardcoded demo values | `'veek@nexacorp.io'` (2×), `'05:59'` countdown, `'skiflux'` demo password in notifier | Expected for demo, document for backend pass |
