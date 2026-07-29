# Skiflux Mobile App — Task Tracker

> Last updated: 2026-07-28 (login connection failure diagnosed and fixed; button loading spinner + app-wide offline bar landed; social sign-in implemented and now credential-blocked rather than code-blocked)
> Status legend: ✅ Done &nbsp;|&nbsp; 🔄 In progress / prompt sent, awaiting report &nbsp;|&nbsp; ⏸ Blocked &nbsp;|&nbsp; ⬜ Not started
> Model legend: model recommendations reflect cost/capability routing established this project — override as needed based on actual task complexity.

This is a live tracking document. Update status markers as tasks complete. Do not let this drift from `PROJECT.md`'s Session Log — this file is the at-a-glance dashboard; `PROJECT.md` remains the detailed historical record.

---

## Phase 1 — Foundation

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | State management migration + ViewModel layer (Riverpod, all 4 passes + full-app cross-check) | ✅ | Fully verified, `PROJECT.md` Current Architecture documents the standard |
| 2 | Centralized error handling layer (toast vs. modal classification) | ✅ | Modal uses `showSkifluxSheet`, no header/close X, icon-in-circle, no em dashes in copy |
| 2a | Toast generalization (success/error/info variants) | ✅ | All known `SnackBar` call sites migrated to `SkifluxToast` |
| 2b | Offline handling: `SkifluxButton.loading` spinner + app-wide connectivity bar | ✅ | Done 2026-07-28. Login "couldn't connect" reported by Veek traced to a request that failed silently — the button reset with no error shown. Button now has a real `loading` state (spinner in place of the label, taps blocked); `ConnectivityBanner` + `ConnectivityNotifier` add the TikTok/Instagram pattern — a thin persistent bar under the status bar for as long as the app can't reach the backend, self-retiring via a backoff probe, green "Back online" acknowledgement. No new packages: reachability is driven by the app's own traffic through a dio interceptor, not a platform plugin. 14 store/interceptor tests + 2 button tests. |
| 3 | CI/CD basics (GitHub Actions) | ✅ | Live, verified working, branch protection enabled |
| 4 | Crash reporting (Sentry) | ✅ | Live, DSN active, real event confirmed on dashboard |
| 4a | Rotate Sentry DSN (was pasted in AI conversation) | ⬜ | **You — manual, ~5 min** |
| 4b | Diagnose phone APK splash-screen crash | ✅ | Resolved — new build installed successfully on phone. Root cause not formally confirmed (likely a side effect of the Kotlin/Gradle compatibility fix from the Sentry work, or a stale prior build). Revisit if it recurs. |
| 5 | Widget size/structure audit (`tasks_screen.dart`, `subscriptions_screen.dart`) | ✅ | Re-scan found 2 more extractions after first pass |
| 6 | Controller disposal audit | ✅ | 17 controllers checked, zero leaks |
| 7 | Real test coverage | ✅ | 100+ tests, zero known regressions (5 pre-existing shader test failures noted as environment-related, not yet independently confirmed) |
| 8 | Lint rigor (`very_good_analysis`-style curated ruleset) | ✅ | 36 violations fixed; `unawaited_futures` re-examined and confirmed correct |
| 9 | Secrets/env strategy (`--dart-define-from-file`) | ✅ | `.gitignore` protected, CI-safe placeholder config |
| 9a | Follow-up: real-filename config verification, `ci.json` sanity check, prod missing-secret hardening | ✅ | Completed in same pass |
| 10 | List rendering audit | ✅ | 8 real issues fixed across 6 files, 10 false positives correctly left alone |
| 11 | Font asset audit | ✅ | **Decision: keep all 22 fonts, no removals** (future-build flexibility) |
| 12 | Adopt `freezed` for backend-integration models | ✅ | DeepSeek's output was NOT freezed (dev-prerelease codegen bug) — remediated 2026-07-26: all 7 models rebuilt as real freezed 3.2.5 models, Decimal money fields. Spec-alignment follow-up closed 2026-07-27 (withdrawable_balance as JSON number → `DecimalFromNumConverter`, `cancelled` status, SkillcoinTransaction label/status/13-type enum w/ unknown fallback, PlatformTask `is_active`); 16 smoke tests vs doc + spec payloads |
| 13 | Backend integration tagging (`BACKEND_INTEGRATION.md`) | ✅ | 32 tags as of 2026-07-28 (27 blocking, 5 minor), down from 49 — doc auto-generated |
| 14 | Wallet & Settings feature audit | ✅ | Riverpod/design-system/disposal all clean; 4 error-handling gaps found |
| 15 | Error handling wired into 4 money-adjacent flows | ✅ | + real validation logic added + tests proving each path fires |
| 16 | App icon + notification icon | ✅ | Adaptive icon fixed (safe-zone foreground + white background), verified via real build |
| 16a | Notification icon visual check on real device | ⬜ | **You — manual check status bar rendering** |

---

## Auth / Onboarding Rework (Codex output corrected)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 17 | Codex-built `auth_flow.dart` full audit | ✅ | Scope confirmed via git history; 9 prioritized follow-ups (P1–P9) |
| 18 | P1 — Add `authFailed`/`sessionExpired` error kinds | ✅ | |
| 19 | P2 — Extract state layer to `auth_store.dart` | ✅ | 556→477 lines, clean separation |
| 20 | P3 — Auth provider unit tests | ✅ | 27 tests, state machine fully mapped |
| 21 | P4 — Auth stage-transition widget tests | ✅ | Merged with P9 |
| 21a | P9 — `ref.invalidate(authFlowProvider)` on successful login | ✅ | Merged with P4 |
| 22 | P5/P6 — Cosmetic fixes (`TextButton`→`SkifluxButton`, spacing tokens) | ⬜ | Low priority, batchable |
| 23 | P7 — Interactive OTP boxes | ⏸ | Backend-blocked (no real OTP verification yet) |
| 24 | P8 — Wire `ErrorDisplay` into remaining auth submit paths + replace `startsWith` string-matching error classification with typed field | ⬜ | |
| 25 | Transition guards on `authFlowProvider.show()` | ⬜ | Optional — demo-appropriate scope discussed, not yet sent. Revisit once real backend auth session state exists |
| 26 | Splash screen: Lottie JSON animation | 🔄 | First DeepSeek attempt failed (task was over-bundled with Figma-fidelity work) — retry as its own tightly-scoped, detailed DeepSeek prompt, separate from #28's Figma work |
| 27 | Post-splash video screen (bundled 2.7MB local video + poster frame) | 🔄 | Same batch as #26 — DeepSeek, own scoped prompt |
| 28 | Onboarding/Terms/Privacy — rebuild to match 3 Figma nodes | 🔄 | Routed to Claude Code (Figma-accurate work) |
| 29 | Google/Apple sign-in implementation | ⏸ | Code complete 2026-07-28 (see #44) — now blocked on OAuth credentials, not on code |
| 30 | Task submission confirmation → bottom sheet (was centered `Dialog`) | ✅ | Done 2026-07-26 via `showSuccessSheet` direct swap; test asserts sheet present / Dialog absent |
| 30a | Biometric login implementation (Face ID / fingerprint) | ✅ | Done + fully verified 2026-07-26: `FlutterFragmentActivity` swap landed, `USE_BIOMETRIC` in manifest, Riverpod 3.x `.valueOrNull` compile error fixed, clean `flutter build apk --debug` passed. **Note**: spec has NO biometric session-exchange endpoint — `POST /me/biometrics/toggle` stores preference only; verification is on-device by design (see mapping). Figma deviation ("Login with Password" secondary styling) still undecided. |

---

## New Feature Corrections (from app walkthrough)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 31 | **Home screen full-screen video redesign** | ⬜ | This is the real scope behind the original "video feed prototype" Phase 3 item — `PageView.builder`, vertical scroll, one-video-at-a-time. Everything below (32, 33) lives inside this redesign. Grok (state) + Claude Code (visual) |
| 32 | Video description: truncate 2 lines + "View More" → detail modal | ⬜ | Reuse `playlist_description_sheet.dart` pattern. Sequence after #31. Confirmed 2026-07-26: `video_feed_card.dart` DOES show a description, hard-truncated at `maxLines: 1` with ellipsis |
| 33 | Follow/unfollow `+` button on creator avatar (conditional on subscription state) | ⬜ | Reads from `subscriptionsProvider` |
| 34 | Download progress notification (Netflix-style, system tray) | ⏸ | **Double-blocked**: (1) no real downloads system exists yet — backend "Downloads management" unbuilt, (2) needs own scoping — foreground service + `flutter_local_notifications`, nontrivial. Do not start until downloads system is itself scoped. |
| 35 | Native OS file/image picker — avatar upload (`edit_profile_screen.dart`, `image_picker`) + task submission file upload (`submission_task_screen.dart`, `file_picker`) | ✅ | Done + build-verified 2026-07-26. Camera+gallery source sheet, no new Android permissions (by design), iOS plist strings added (needs Mac to verify), 10MB cap + graceful denial/cancel. Backend upload wiring separate (real endpoint now known: multipart `PATCH /me/update {avatar}`). |

*Note: app walkthrough with Claude is ongoing — more items likely to be added here as remaining features are reviewed.*

---

## Backend Integration

### Reference docs received from backend dev
- `withdrawal-flows.md` — full wallet/withdrawal spec (hold/payout pipeline, fees, Paystack + Stripe Connect)
- `payment-flows.md` — top-ups, saved cards, webhooks
- `platform-tasks.md` — full missions spec (status lifecycle, UI decision tree)
- Full OpenAPI spec (`SkiFlux API.yaml` = `SkiFlux API (1).yaml`, MD5-identical) — cross-referenced against `BACKEND_INTEGRATION.md`'s tags; **re-run 2026-07-26 against all 49 current tags** (spec unchanged since first run). Where the OpenAPI spec and the flow .md docs conflict (e.g. `withdrawable_balance` type), treat the spec as authoritative until the backend dev says otherwise — flagged in PROJECT.md.

### Tier 1 — Ready to build now, no blockers

| # | Task | Status | Model |
|---|------|--------|-------|
| 35 | Auth integration (login/signup/token refresh) | ✅ | Claude — done 2026-07-28. Network foundation (dio client + auth/refresh interceptors, `flutter_secure_storage` token store, `ApiRepository`/`ApiException` failure mapping onto `SkifluxErrorKind`) + `AuthRepository` covering login, signup, OTP verify/resend, forgot/reset password, both mobile social endpoints, logout blacklist. Response shape isolated in `AuthTokens.fromJson` (one file to change when 61b is answered). Social buttons still inert — native `id_token` needs a new dependency, awaiting sign-off. |
| 36 | Wallet + Withdrawal integration | ⬜ | Grok |
| 37 | Platform Tasks (missions) integration | ⬜ | DeepSeek V4 Pro |
| 38 | Thumbnail URL wiring (playlists/subscriptions/profile/creator/search — all reuse `Episode.thumbnail_url`) | ⬜ | DeepSeek V4 Flash |
| 39 | Profile auth gate (token-presence check) | ⬜ | DeepSeek V4 Flash |

### Tier 2 — Shape mismatches, fixable via adapter/translation layer (no backend dev action needed)

| # | Task | Status | Model | Approach |
|---|------|--------|-------|----------|
| 40 | Streaks adapter | ⬜ | DeepSeek V4 Pro | Map `current_streak_count`→`streak` etc.; UI change optional if surfacing new `milestone` sub-fields |
| 41 | Wallet transactions adapter | ⬜ | DeepSeek V4 Pro | Map `transaction_type`→`CoinTxnKind`, Decimal parsing |
| 42 | Comments adapter | ⬜ | DeepSeek V4 Pro | Flatten nested author/body to match backend's flat fields |
| 43 | Search adapter | ⬜ | DeepSeek V4 Pro | Map `seasons`→`playlists` concept, flatten nested `creator` |

### Tier 3 — Real backend features not yet wired into the app

| # | Task | Status | Model | Notes |
|---|------|--------|-------|-------|
| 44 | Social sign-in (Google/Apple) wiring | ⏸ | Grok | **Code complete 2026-07-28**, now credential-blocked. Native `id_token` flow implemented in `social_auth.dart` and posted to `/auth/social/mobile/{google,apple}`. Each button hides itself rather than failing when its prerequisite is missing, so the blockers are visible at setup rather than at runtime: **(a)** Google needs a real `GOOGLE_SERVER_CLIENT_ID` (the backend's Web OAuth client) + `GOOGLE_IOS_CLIENT_ID` in `config/env/dev.json`, plus both debug and release Android SHA-1s registered in the Google Cloud project; **(b)** iOS additionally needs `CFBundleURLSchemes` in `Info.plist` filled with the REVERSED_CLIENT_ID (left an empty placeholder on purpose — a wrong value fails at runtime, an empty one fails at setup); **(c)** Apple is gated to iOS/macOS until a Service ID + registered https redirect URI exist for the Android web fallback (tagged minor in `BACKEND_INTEGRATION.md`); **(d)** `Runner.entitlements` + the pbxproj `CODE_SIGN_ENTITLEMENTS` wiring were authored on Windows and need a Mac to verify, and the capability still has to be enabled on the App ID in the developer portal. |
| 45 | Biometric toggle wiring | ⬜ | DeepSeek V4 Flash | **UI already exists** — just needs `POST /me/biometrics/toggle` connection |
| 46 | Stripe Connect withdrawal path | ⬜ | Claude Code | Genuinely new UI — hosted-redirect flow, app currently only has bank-form UI |
| 47 | Wallet financial summary display | ⬜ | DeepSeek V4 Flash | Optional — bonus endpoint data |
| 48 | Notification preferences wiring to settings | ⬜ | DeepSeek V4 Flash | |
| 49 | Platform task progress-bar UI | ⬜ | DeepSeek V4 Flash | Backend already tracks `progress_current`/`progress_target` |
| 50 | Withdrawal fee/net-amount display before confirm | ⬜ | DeepSeek V4 Flash | |
| 51 | Push notifications (FCM) — client setup | ⏸ | Grok | Blocked on Firebase project + config files (`google-services.json`, `GoogleService-Info.plist`). Recommend: backend dev owns Firebase project + send-side logic; mobile owns receive/display + device-token registration (check if `POST /me/devices` is the registration endpoint) |

### Tier 4 — Blocked, needs backend dev action

| # | Task | Status | Notes |
|---|------|--------|-------|
| 52 | Notifications response shape | ⏸ | Endpoint exists, response body undocumented |
| 53 | Leaderboard response shape | ⏸ | Same issue |
| 54 | Learning Tasks/Quiz submission mapping | ⏸ | Two endpoints, field names don't map cleanly — needs real conversation, possibly own reference doc |
| 55 | Coin pack pricing endpoint | ⏸ | No mobile-facing endpoint exists |
| 56 | Public user profile endpoint | ⏸ | Only admin-only version exists |
| 57 | Downloads management API | ⏸ | Nothing exists — confirm intentional client-only vs. missing |
| 58 | Watch-history delete endpoint | ⏸ | Read-only currently (re-verified 2026-07-26: only GET exists) |
| 59 | Share/deep-link generation endpoint | ⏸ | Confirm intentional client-side vs. missing |
| 60 | Remaining settings persistence (auto-play, download quality, Wi-Fi-only, language, watch-history toggle, recommendations) | ⏸ | No endpoints yet |
| 61 | Auto-caption generation pipeline (Whisper API) | ⏸ | Architectural decision, not started |
| 61a | Transaction dispute endpoint (`transaction_details_screen.dart` "report" action) | ⏸ | New tag 2026-07-26 — no dispute/support-ticket-create endpoint in spec (only ticket *rating* exists) |
| 61b | Auth + profile response bodies undocumented | ⏸ | `POST /auth/login`, `/auth/signup`, `/auth/token/refresh`, social logins, and `GET /me/profile` all have description-only responses in the spec (no schema). Descriptions promise access/refresh tokens and the full profile payload — need documented shapes before Tier 1 auth/profile integration hardens |
| 61c | Per-user episode purchase state | ⏸ | `Episode` schema has no `is_purchased`/unlocked field — app can't tell locked vs unlocked paid episodes from the list responses. Needs a field or a purchases-list endpoint |
| 61d | Badge artwork + playlist cover URLs | ⏸ | `Badge` has no image/asset URL (app renders badge art); learner-facing `Season` exposes `cover_image_public_id` (Cloudinary id) but not a ready URL (creator-side `SeasonPerformance` has `cover_image_url`) |

### `BACKEND_REQUESTS.md` generation
| # | Task | Status | Notes |
|---|------|--------|-------|
| 62 | Generate `BACKEND_REQUESTS.md` (consolidated ask for backend dev — Tier 4 items in plain product language) | ⏸ | **Paused** — waiting until full app walkthrough with Claude is complete, to catch any additional missing functionality first |

---

## Phase 3 — Performance / UX Polish

| # | Task | Status | Model |
|---|------|--------|-------|
| 63 | Caption rendering support | ⬜ | Claude Code |
| 64 | DevTools profiling pass | ⬜ | Grok first, escalate to GPT-5.6 Sol if inconclusive |
| 65 | Widget rebuild scoping (`Consumer`/`Selector`) | ⬜ | Claude Code |
| 66 | Video preload buffer (production, 1 video ahead, lowest quality) | ⬜ | Grok |
| 67 | Background prefetch of secondary screens | ⬜ | Grok |
| 68 | `cached_network_image` rollout | ⬜ | DeepSeek V4 Flash |
| 69 | Image sizing strategy (thumbnail/medium/full per context) | ⬜ | DeepSeek V4 Flash |
| 70 | Rendering hygiene pass (`RepaintBoundary`, pure `build()`) | ⬜ | DeepSeek V4 Flash |
| 71 | Sheet blur overlay → solid scrim (Option A confirmed) + cold-launch latency | ⬜ prompt ready | Replace `BackdropFilter` blur in `showSkifluxSheet` with a solid semi-transparent scrim across all sheets (comments, more-menu, share, playlist menu, episode unlock, notify settings, week picker, milestone, confirm, success, error). Removes the per-frame blur cost and likely resolves cold-open jank. Pair with #64 DevTools profiling to confirm improvement. |
| 71a | Full-screen video orientation matching (portrait video → portrait fullscreen, landscape → landscape) | ⏸ needs clarification | **Decision needed from Veek**: is this for the home feed's short-form videos (TikTok-style, typically portrait — where "full screen" is usually already the default view, not a separate mode), or a different context (Playlists/episode playback, longer creator content — closer to YouTube's rotate-to-landscape pattern)? The right implementation differs significantly. If YouTube-style: app needs orientation-change support (currently likely portrait-locked), clean lock/unlock transition, decision on what happens to bottom nav/chrome during landscape. |

---

## Phase 4 — Quality & Compliance

| # | Task | Status | Model |
|---|------|--------|-------|
| 72 | Accessibility pass (`Semantics`, tap targets, contrast) | ⬜ | Claude Code |
| 73 | Localization plumbing — `.arb`/codegen setup | ⬜ | DeepSeek V4 Pro (one-time setup) |
| 74 | Localization — string extraction, feature by feature | ⬜ | DeepSeek V4 Flash (batched, not one sweep) |

---

## Phase 5 — Pre-Launch

| # | Task | Status | Notes |
|---|------|--------|-------|
| 75 | App icons + splash screens | ✅ | See #16 above |
| 76 | Privacy policy + data collection disclosure | ✅ | In-app onboarding screen + website page, same content, no login required. Re-check content accuracy against current features (payments, biometrics, comments, social login) closer to submission |
| 77 | Versioning/release strategy | ⬜ | You (decision) + DeepSeek V4 Flash (implementation) |
| 78 | App size audit (`flutter build apk --analyze-size`) | ⬜ | DeepSeek V4 Flash |
| 79 | CD pipeline to TestFlight/App Store Connect (fastlane) | ⬜ | GPT-5.6 Sol — depends on Apple Developer account + App Store Connect app record existing first |

---

## Process Notes (standing rules)

- **Multi-tool workflow**: Grok (backend implementation, state/security/money-sensitive logic) + DeepSeek (full-app deep scans, large-scale mechanical changes — always with detailed explicit prompts and incremental per-section verification, not one unverified sweep) → Antigravity (best-practices verification layer across all other tools' output) → Claude Code (Figma-accurate UI work)
- **ChatGPT/Codex removed from rotation** (2026-07-26) — monthly usage limit reached; suspected lower-tier model used on its one task (unconfirmed); that task's failure may also reflect scope-bundling (Figma-fidelity + mechanical implementation combined in one prompt) rather than the model itself — worth keeping in mind if reconsidering it later
- **Model routing**: DeepSeek V4 Flash for low-risk/mechanical/audit tasks; DeepSeek V4 Pro (Think High) for judgment-heavy classification/mapping/logic and now also large-scale deep-scan work; Grok for backend implementation, proven state-layer, security-sensitive, and money-adjacent work; Claude Code for anything with a real Figma reference; GPT-5.6 Sol reserved for CLI/fastlane automation
- Every completed task must be logged in `PROJECT.md`'s Session Log
- Incoming tool always independently re-verifies a prior "Complete" claim before continuing — never trust the log alone
- `BACKEND_INTEGRATION.md` is auto-generated from in-code `TODO(backend, ...)` tags — never hand-edited, regenerate via `grep -rn "TODO(backend" lib/`
- Pure Dart-level refactors: `flutter analyze` + `flutter test` sufficient verification. Anything touching native/platform config (icons, Gradle, dependencies): full `flutter build apk --debug` required.
- New/unfamiliar tools contributing code must be audited against design system + Riverpod conventions before being trusted — do not assume consistency.
- This tracker `.md` is updated immediately after every status change — not batched.
- **Skeleton loading**: not built speculatively against demo data (nothing to load yet — everything is instant local data). Instead, add skeleton/placeholder loading UI as a standard requirement WITHIN each backend integration task (Tier 1/2/3 items) wherever that specific screen gains real network latency — home feed, leaderboard, notifications, streaks, search, wallet/transactions, profile screens, comments. Do not build a generic skeleton system ahead of knowing the real loading behavior.

---

## Open Items Requiring Your Direct Action (not delegatable to AI tools)

- [ ] Rotate Sentry DSN
- [ ] Visually confirm notification icon renders correctly on a real device
- [ ] Complete the full app walkthrough with Claude (in progress) before finalizing `BACKEND_REQUESTS.md`
- [ ] Decide Firebase/FCM ownership arrangement with backend dev, obtain config files
- [ ] Confirm `/me/devices` is the correct device-token registration endpoint with backend dev
- [ ] Re-check privacy policy content accuracy against current app features before submission
- [ ] Scope the downloads system itself before download-progress-notification work can begin
- [ ] Create the Google OAuth clients (Web + iOS + Android) and put `GOOGLE_SERVER_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `config/env/dev.json`; register the debug and release Android SHA-1s — Google sign-in stays hidden until then
- [ ] Fill `CFBundleURLSchemes` in `ios/Runner/Info.plist` with the REVERSED_CLIENT_ID once the iOS OAuth client exists
- [ ] Register an Apple Service ID + https redirect URI (needed only for Sign in with Apple on Android), and enable the Sign in with Apple capability on the App ID in the developer portal
- [ ] On a Mac: verify `Runner.entitlements` and the `CODE_SIGN_ENTITLEMENTS` pbxproj entries build and sign correctly (authored from Windows, unverified)
