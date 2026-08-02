# Skiflux Mobile App — Task Tracker

> Last updated: 2026-08-01 (walkthrough-defect sweep + UX/perf batch: comment edit/delete/reply/report, voice-note playback, creator-season lookup, real watch-progress bar, TikTok tap-to-pause, sheet scrim, cached images, in-app payment checkout with all three spec payment paths)
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
| 13 | Backend integration tagging (`BACKEND_INTEGRATION.md`) | ✅ | 23 tags as of 2026-07-31 (13 blocking, 10 minor), down from 32 — inventory regenerated via the documented grep |
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
| 22 | P5/P6 — Cosmetic fixes (`TextButton`→`SkifluxButton`, spacing tokens) | ✅ | Verified 2026-08-01 — auth already carries no `TextButton`/`ElevatedButton`, no raw `SizedBox`/`EdgeInsets` numbers, no raw `TextStyle`. The only two remaining `TextButton`s app-wide (Downloads / Watch History "Clear all") are correct per Figma — red *text*, not a filled pill — and were deduped into `shared/widgets/clear_all_action.dart` |
| 23 | P7 — Interactive OTP boxes | ⏸ | Backend-blocked (no real OTP verification yet) |
| 24 | P8 — Wire `ErrorDisplay` into remaining auth submit paths + replace `startsWith` string-matching error classification with typed field | ⬜ | |
| 25 | Transition guards on `authFlowProvider.show()` | ⬜ | Optional — demo-appropriate scope discussed, not yet sent. Revisit once real backend auth session state exists |
| 26 | Splash screen: Lottie JSON animation | ✅ | First DeepSeek attempt failed (task was over-bundled with Figma-fidelity work) — retry as its own tightly-scoped, detailed DeepSeek prompt, separate from #28's Figma work |
| 27 | Post-splash video screen (bundled 2.7MB local video + poster frame) | 🔄 | Same batch as #26 — DeepSeek, own scoped prompt |
| 28 | Onboarding/Terms/Privacy — rebuild to match 3 Figma nodes | ✅ | Routed to Claude Code (Figma-accurate work) |
| 29 | Google/Apple sign-in implementation | ⏸ | Code complete 2026-07-28 (see #44) — now blocked on OAuth credentials, not on code |
| 30 | Task submission confirmation → bottom sheet (was centered `Dialog`) | ✅ | Done 2026-07-26 via `showSuccessSheet` direct swap; test asserts sheet present / Dialog absent |
| 30a | Biometric login implementation (Face ID / fingerprint) | ✅ | Done + fully verified 2026-07-26: `FlutterFragmentActivity` swap landed, `USE_BIOMETRIC` in manifest, Riverpod 3.x `.valueOrNull` compile error fixed, clean `flutter build apk --debug` passed. **Note**: spec has NO biometric session-exchange endpoint — `POST /me/biometrics/toggle` stores preference only; verification is on-device by design (see mapping). Figma deviation ("Login with Password" secondary styling) still undecided. |

---

## New Feature Corrections (from app walkthrough)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 31 | **Home screen full-screen video redesign** | ✅ | This is the real scope behind the original "video feed prototype" Phase 3 item — `PageView.builder`, vertical scroll, one-video-at-a-time. Everything below (32, 33) lives inside this redesign. Grok (state) + Claude Code (visual) |
| 32 | Video description: truncate 2 lines + "View More" → detail modal | ✅ | Reuse `playlist_description_sheet.dart` pattern. Sequence after #31. Confirmed 2026-07-26: `video_feed_card.dart` DOES show a description, hard-truncated at `maxLines: 1` with ellipsis |
| 33 | Follow/unfollow `+` button on creator avatar (conditional on subscription state) | ✅ | Verified 2026-08-01 — already live as `_AvatarWithFollowCta` in the home top bar; badge hidden when `subscriptionsProvider.isSubscribed` or when the payload carried no creator UUID |
| 34 | Downloads: real client-side pipeline | ✅ | Done 2026-08-01. Was a `List<LibraryEpisode>` in memory: "downloading" appended to that list, nothing was fetched, the list was empty after relaunch, and the screen multiplied its length by a hardcoded `112` MB. Now `video_url` streams to the app documents dir via Dio with real progress + cancel, the registry persists to `shared_preferences` and round-trips through a new `LibraryEpisode.toJson`, sizes are read from the files, delete/clear-all remove real bytes, and rows restore across launches (entries whose file vanished are pruned rather than listed as playable). The stored-and-ignored "Download on Wi-Fi only" setting is now enforced via `connectivity_plus` before a byte moves, with its own error kind. "SD 480p" removed — the backend serves one rendition and never says which. |
| 34a | Download progress notification (Netflix-style, system tray) | ✅ | Done 2026-08-02. New dependency **`flutter_local_notifications: 22.2.0`** (approved by request) + Java 8 desugaring in `android/app/build.gradle.kts` (`isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4`) — verified with a full `flutter build apk --debug`. `shared/notifications/download_notifications.dart` posts one silent, ongoing notification per episode on its own `skiflux.downloads` channel: a determinate bar that advances with the transfer (`onlyAlertOnce` so it never buzzes, `ongoing` so it can't be swiped away mid-download), resolving to "Downloaded — available offline" or "Download failed". Cancelled by delete / clear-all rather than left reporting a failure the user caused. Tray updates are throttled to whole-percent changes — `onReceiveProgress` fires per chunk and each update is a platform-channel round trip. **Android only**: iOS has no progress-notification API, so every method is a no-op there rather than posting a stream of banners. No foreground service — the transfer is an in-process `dio` download, so it lives and dies with the app; surviving a swipe-away is a separate piece of work. |
| 35 | Native OS file/image picker — avatar upload (`edit_profile_screen.dart`, `image_picker`) + task submission file upload (`submission_task_screen.dart`, `file_picker`) | ✅ | Done + build-verified 2026-07-26. Camera+gallery source sheet, no new Android permissions (by design), iOS plist strings added (needs Mac to verify), 10MB cap + graceful denial/cancel. Backend upload wiring separate (real endpoint now known: multipart `PATCH /me/update {avatar}`). |

| 36a | More Menu: real episode assets, conditional rows, real full-screen player | ✅ | Done 2026-08-01. `Episode.resources` and `Episode.tasks` are inline on the viewer payload (`:9518` / `:9513`) and were never parsed, so the More Menu offered both cards on every episode. New `EpisodeResource` model (`ResourceTypeEnum` file/link, `FileTypeEnum` glyphs, real name/size/host) feeds a rewritten Episode Resources sheet — it previously showed four hardcoded filenames (`design_tokens.fig`, `component_kit.zip`, `episode_notes.pdf`, `color_styles.xlsx`) on every episode, with a download button that only toasted. Rows with no usable URL are dropped, server `order` respected, files/links open via `openExternalUrl`. **View Task**, **Episode Resources** and **Download** now each hide when the episode has nothing behind them. Full-screen player plays the **real episode video** (was a bundled `home_video_raw1.png`) with tap-to-pause and a progress bar from the real clock (was frozen at a hardcoded 100/393); its close + playback-speed discs moved from flush-against-the-top to `SafeArea` + `spaceL`, matching the home top bar's baseline. Note: `GET /episodes/{id}/resources/` exists but is **Studio-side** (`adminBearerAuth`, "owned by the creator") — the inline array is the viewer-facing source. 9 new parsing tests. |
| 36b | Share → OS share sheet | ✅ | Done 2026-08-02. `shared/sheets/share_sheet.dart` was a custom row of eight branded circles (Copy Link, WhatsApp, X, Message, Telegram, Snapchat, Facebook, Instagram) and **every one of them did nothing but close the sheet** — no intent, no clipboard, no link. It also offered targets the user may not have installed. Replaced with the platform sheet via `share_plus`, which was already an approved dependency with **zero call sites**. All 9 entry points now pass real content (episode + creator, playlist + creator, profile handle, streak length, quiz score). `shareableMediaUrl()` withholds pre-signed URLs: the query string *is* the credential and it expires, so sharing one puts a short-lived access token in someone's chat history and hands them a dead link — a clean path-only URL passes through. 5 new tests. Still blocked on #59 for a real shareable page URL. |
| 36c | Home-feed tap-to-pause never fired | ✅ | Done 2026-08-02. The gesture was wrapped around the video widget itself, several layers down a six-child `Stack`, with the full-bleed legibility gradient painted over it; it worked in the full-screen player (flat stack, nothing above the media) and not in the feed. Now a dedicated `Positioned.fill` tap layer at a known depth — over the media and the gradient, under the EP chip / "View More" / action rail — and the gradient is explicitly `IgnorePointer`. |
| 36d | Creator profile "Recent": placeholder art, no playback | ✅ | Done 2026-08-02. Every row on every creator's profile drew the same bundled `assets/home_video_cover.png` (an explicit `TODO(backend, blocking)` that was not actually blocked — `Episode.thumbnail_url` is required and `GET /seasons/{id}/episodes` returns `Episode[]`). Tapping a row opened the player modal with a `SubscriptionEpisode` carrying neither `videoUrl` nor `thumbnailUrl`, so the modal fell to image mode and showed a still. `PlaylistEpisode` now carries `videoUrl` (parsed from `video_url`, falling back to `preview_url` for locked rows), the card renders the episode's own thumbnail, and both travel into the modal. |
| 36e | Comment voice notes silently did nothing | ✅ | Done 2026-08-02. `SkifluxComposeBar._startRecording` returned on a refused mic grant and on any throw — but the parent had already switched the bar to its recording state, so the user saw a (flat) waveform, tapped send, and **nothing happened at all**: `stop()` returned null, `onSendVoiceNote` was never called, and the `onSend` fallback is ignored when there is no text. New `onRecordingFailed` callback covers permission refusal, a recorder that throws, and a zero-byte capture; the comments sheet toasts the reason and returns the bar to idle. Separately, `like_count` was parsed and kept in sync through every optimistic toggle and then rendered nowhere — it now shows beside the thumb-up. |
| 36f | Leaderboard: podium shrank instead of the rank table | ✅ | Done 2026-08-02. Second pass on the same defect — the first added a `0.72` clamp, but a clamped shrink is still a shrink, and at 0.72 the 1st-place XP line still closed onto the step on exactly the short screens the clamp was meant to rescue. The podium now **never** scales: the rank table (a scroll view, so height only costs it visible rows) takes whatever is left, and past `minRankCardFloor` the whole board scrolls. `_ShrinkToFit` deleted. The XP line's step clearance is a named constant at `spaceM` (was `spaceXs`) and stays in logical pixels on purpose — the labels are laid out in logical pixels too, so a clearance that scaled with the art would close exactly where the text did not. Podium test tightened from a 0.7 tolerance to an equality. |
| 36g | Learning-task rewards never appear | ⚠️ client-side done, backend gap | 2026-08-02. The reward chips have always been implemented on the card; they stay hidden because **`WatchedEpisodeTaskItem` and `EpisodeTask` declare no reward fields at all** — unlike `PlatformTaskUser`, which has `xp_reward` and `skillcoin_reward`. Nothing to bind to, and inventing "+25" is not an option. New `WatchedEpisodeTask.rewardHints` gathers every place a reward could plausibly arrive — the untyped `completion_criteria` blob, a `reward`/`rewards` object nested inside it, and reward-shaped keys at the top level of the row — so the chips light up the moment the backend sends one under any of those names, with no further client change. 10 new tests. **Backend ask: add `xp_reward: int` and `skillcoin_reward: decimal-string` to `WatchedEpisodeTaskItem` and `EpisodeTask`, matching `PlatformTaskUser`.** |
| 36i | Session expiry was invisible; provider retries hid every failure | ✅ | Done 2026-08-02. Two defects behind "a fresh install loads data, hours later it just shows skeletons forever". (1) `sessionLostProvider` was signalled by `AuthInterceptor` when a refresh was rejected — and **nothing listened to it**. The keychain was cleared, the app stayed on Home, every provider quietly took its "no session" branch, and the user was never told or routed anywhere. The app shell now listens, invalidates the cached profile, toasts "Your session expired", and resets the stack to `AuthFlow`. (2) Riverpod 3 retries a throwing provider automatically — ten attempts backing off to 6.4s — and while a retry is pending the state is `AsyncLoading` **carrying** the error, not `AsyncError`. Every screen matches `AsyncLoading()` first, so that is ~40s of skeleton on a fast failure and minutes when each attempt burns a 15s connect timeout. Worse, a 401 was retried like anything else: ten attempts is ten `POST /auth/token/refresh` calls against a session already declared dead, which on a rotating-refresh backend can destroy a session the first refresh would have recovered. New `skifluxRetry` policy: two attempts (400ms, 1.2s), transport failures and 5xx/408/429 only — never a 401, never any other 4xx, never a programming error. 9 new tests. |
| 36j | Payment hand-back could never fire; add-card skipped verify | ✅ | Done 2026-08-02 after reading `payment-flows.md`. (1) The app sent **no** `redirect_url`, on the reading that the spec's `nullable: true` meant the backend owned the return. The backend does own a default (`PAYMENT_REDIRECT_URL`), but it is a *web* page on another host, so the WebView had nothing to recognise and the checkout could not hand back. The app now always sends `EnvConfig.paymentReturnUrl`, and `showCheckout` gained a third detector: our own `tx_ref` appearing in the URL query, which the gateway appends to whichever return URL it was actually given. (2) `POST /wallet/cards/add` returns `checkout_url` **and** `tx_ref`; the app parsed only the URL and, on return, just re-read `GET /wallet/cards`. The doc requires `POST /wallet/topup/verify` with the `skf-card-…` ref **first** — re-reading alone only worked when a webhook happened to land in time, which is the race behind a saved card that sometimes wasn't there. `startAddCard` now returns an `AddCardHandOff` and both the automatic and the manual ("I've added my card") paths verify before re-reading. |
| 36k | Two of three Download entry points were still stubs | ✅ | Done 2026-08-02. The real pipeline (#34) was wired to the feed's More Menu only. The Watch History row menu and the identical menu on the profile tab both still ran `SkifluxToast.info(context, 'Episode queued for download')` under a `TODO(backend, blocking): no offline download pipeline exists` — a toast describing a queue that did not exist, over a pipeline that had been built. All three now share `downloadEpisode()`, so the tray notification, the Wi-Fi-only check and the error copy cannot drift apart again. |
| 36l | Debug diagnostics could not actually fire a notification | ✅ | Done 2026-08-02. The Push diagnostics panel showed the permission state and the FCM token and nothing else — there was no way to make a notification appear, so "the notification test doesn't work" was accurate: there was no test. `flutter_local_notifications` (added for #34a) makes a local one possible, which exercises everything except the FCM transport: the runtime grant, the channel, and the monochrome tray icon. `DownloadNotifications` → `LocalNotifications` with a `sendTest()` that returns false rather than lying when the platform or the permission says no, so the tile can report *which*. |
| 36m | Biometric gate showed a generic silhouette | ✅ | Done 2026-08-02. The avatar sat behind a `TODO(backend)` reading "the spec's only avatar source is `GET /me`, which needs the session this screen is unlocking" — wrong conclusion: the biometric gate is *re*-auth, the token pair is already in the keychain, and the prompt authorises reuse of that session rather than minting one, so `GET /me/profile` was callable all along. Now the real picture, falling back to the account's initials (not the glyph) while the profile is in flight — a blank silhouette beside "Welcome Back" and "Not Veek?" reads as the wrong account. |
| 36h | Layout fixes: withdraw field, downloads empty state, notification sections | ✅ | Done 2026-08-02. (1) `SkifluxInputField`'s prefix/suffix slots have a 48×48 minimum and anything that doesn't centre itself is pinned to the slot's top-left — an `Icon` happens to centre, a `Text` in a `Padding` does not, which is why the withdraw amount field's trailing "Coins" label sat against the top edge. Both slots now go through a `Center(widthFactor: 1)`; fixes every input in the app, not just that one. (2) Downloads' empty state was wrapped in a `Center` on top of `SkifluxEmptyState`'s own 48px padding, pushing it to mid-screen — Watch History renders the identical state bare, and Downloads now matches. (3) The notifications list added a `SizedBox` *before* the "Earlier" section unconditionally, so a list with nothing newer than two days old opened with a stray 16px band above its first heading, and inter-section gaps varied by which of the three happened to be present; rebuilt as a `ListView.separated` over the present sections. |

*Note: app walkthrough with Claude is ongoing — more items likely to be added here as remaining features are reviewed.*

---

## Backend Integration

### Reference docs received from backend dev
- `withdrawal-flows.md` — full wallet/withdrawal spec (hold/payout pipeline, fees, Paystack + Stripe Connect)
- `payment-flows.md` — top-ups, saved cards, webhooks
- `platform-tasks.md` — full missions spec (status lifecycle, UI decision tree)
- Full OpenAPI spec (`SkiFlux API.yaml` = `SkiFlux API (1).yaml`, MD5-identical) — cross-referenced against `BACKEND_INTEGRATION.md`'s tags; **re-run 2026-07-26 against all 49 current tags**. Where the OpenAPI spec and the flow .md docs conflict (e.g. `withdrawable_balance` type), treat the spec as authoritative until the backend dev says otherwise — flagged in PROJECT.md. **2026-07-31: the spec now lives at repo root `SkiFlux_API.yaml`** (copied from Downloads; the repo copy is the working reference from here on). The spec has grown since the first runs — several formerly-blocked Tier 4 items now exist (creator profile, public user profile, watch-history delete) and are wired.

### Tier 1 — Ready to build now, no blockers

| # | Task | Status | Model |
|---|------|--------|-------|
| 35 | Auth integration (login/signup/token refresh) | ✅ | Claude — done 2026-07-28. Network foundation (dio client + auth/refresh interceptors, `flutter_secure_storage` token store, `ApiRepository`/`ApiException` failure mapping onto `SkifluxErrorKind`) + `AuthRepository` covering login, signup, OTP verify/resend, forgot/reset password, both mobile social endpoints, logout blacklist. Response shape isolated in `AuthTokens.fromJson` (one file to change when 61b is answered). Social buttons still inert — native `id_token` needs a new dependency, awaiting sign-off. |
| 36 | Wallet + Withdrawal integration | ✅ | Done 2026-07-31 (writes; reads landed 2026-07-28). All previously fake money flows are real: top-up `initiate → external checkout → verify → wallet refresh` (client-side coin minting deleted); withdrawals with real bank list + server-side account-name verification (hardcoded 6-bank list and fake "Amara Design" verification deleted), fee/net from the 201 response, real `withdrawable_balance` ceiling (floored), `is_locked` gates the button; cards via hosted `POST /wallet/cards/add` — raw PAN/CVV entry UI deleted (PCI); balances read the real Decimal wallet; fabricated transaction references removed (local rows pending-only until the backend ledger replaces them). External checkout links open via `external_link.dart` clipboard fallback — `url_launcher` still awaiting dependency sign-off |
| 37 | Platform Tasks (missions) integration | ✅ | Done 2026-07-31 (repository landed 2026-07-28). Missions refresh on every Tasks-tab open (was once per login); failed claims roll back and surface a modal (were marked Done anyway); successful claim refreshes missions + wallet; link tasks open their external URL; rewards display exact Decimals |
| 38 | Thumbnail URL wiring (playlists/subscriptions/profile/creator/search — all reuse `Episode.thumbnail_url`) | 🔄 | Subscriptions episode cards use payload thumbnail URLs (2026-07-31); playlists catalogue + profile rails still demo-seeded — their thumbnail tags remain |
| 39 | Profile auth gate (token-presence check) | ✅ | Done 2026-07-31 — session-gated honesty app-wide (no demo seeds for signed-in users on profile/notifications/comments) plus cold-start session restore: splash resolves a stored session → biometric gate or straight into the app (no more marketing carousel for returning users) |

### Tier 2 — Shape mismatches, fixable via adapter/translation layer (no backend dev action needed)

| # | Task | Status | Model | Approach |
|---|------|--------|-------|----------|
| 40 | Streaks adapter | ⬜ | DeepSeek V4 Pro | Map `current_streak_count`→`streak` etc.; UI change optional if surfacing new `milestone` sub-fields |
| 41 | Wallet transactions adapter | ✅ | Done 2026-07-31 — `UserWallet`/`SavedCard`/`SkillcoinTransaction` spec-aligned, codegen re-run; `ApiRepository.guard` now also catches `TypeError`/`ArgumentError` |
| 42 | Comments adapter | ✅ | Done 2026-07-31 — `GET /episodes/{id}/comments` + `POST /episodes/comment` with spec body `{episode_id, text}`, flat field parsing, voice-note upload, optimistic post with rollback + surfaced errors (was silently swallowed), real counts |
| 43 | Search adapter | ✅ | Done 2026-07-31 — 300ms debounce, stale-response guard, inline (non-modal) errors |

### Tier 3 — Real backend features not yet wired into the app

| # | Task | Status | Model | Notes |
|---|------|--------|-------|-------|
| 44 | Social sign-in (Google/Apple) wiring | ⏸ | Grok | **Code complete 2026-07-28**, now credential-blocked. Native `id_token` flow implemented in `social_auth.dart` and posted to `/auth/social/mobile/{google,apple}`. Each button hides itself rather than failing when its prerequisite is missing, so the blockers are visible at setup rather than at runtime: **(a)** Google needs a real `GOOGLE_SERVER_CLIENT_ID` (the backend's Web OAuth client) + `GOOGLE_IOS_CLIENT_ID` in `config/env/dev.json`, plus both debug and release Android SHA-1s registered in the Google Cloud project; **(b)** iOS additionally needs `CFBundleURLSchemes` in `Info.plist` filled with the REVERSED_CLIENT_ID (left an empty placeholder on purpose — a wrong value fails at runtime, an empty one fails at setup); **(c)** Apple is gated to iOS/macOS until a Service ID + registered https redirect URI exist for the Android web fallback (tagged minor in `BACKEND_INTEGRATION.md`); **(d)** `Runner.entitlements` + the pbxproj `CODE_SIGN_ENTITLEMENTS` wiring were authored on Windows and need a Mac to verify, and the capability still has to be enabled on the App ID in the developer portal. |
| 45 | Biometric toggle wiring | ✅ | DeepSeek V4 Flash | Closed 2026-07-31 — cold-start race fixed (`SettingsNotifier.ready` hydration future); the gate now honors the stored preference |
| 46 | Stripe Connect withdrawal path | ⬜ | Claude Code | Genuinely new UI — hosted-redirect flow, app currently only has bank-form UI |
| 47 | Wallet financial summary display | ⬜ | DeepSeek V4 Flash | Optional — bonus endpoint data |
| 48 | Notification preferences wiring to settings | ✅ | DeepSeek V4 Flash | Done 2026-07-31 — `GET/PATCH /me/notification-preferences` with optimistic toggle + rollback + SharedPreferences offline cache (toggles previously reset every launch) |
| 49 | Platform task progress-bar UI | ⬜ | DeepSeek V4 Flash | Backend already tracks `progress_current`/`progress_target` |
| 50 | Withdrawal fee/net-amount display before confirm | ✅ | Done 2026-07-31 inside #36 — fee/net taken from the `POST /wallet/withdrawals/request` 201 response | |
| 50b | Top-up redirect URL — confirmed backend-owned | ✅ | Confirmed against the spec 2026-08-01: `redirect_url` is `nullable: true` on **both** `TopupInitiateRequest` (`:13438`) and `AddCardRequest` (`:7977`), so omitting it makes the backend use its own registered return URL — which is the one the gateway has allow-listed. The app no longer invents one (an earlier pass defaulted to `$apiBaseUrl/payments/return`, which the gateway would likely have rejected). The WebView instead detects the hand-back by **host**, matching `EnvConfig.apiHost`. `TOPUP_REDIRECT_URL` remains as an opt-in exact-prefix override for when the backend dev names a specific URL |
| 50a | In-app checkout WebView + all three spec payment paths | ✅ | Done 2026-08-01. `webview_flutter` added; `shared/webview/checkout_screen.dart` hosts the gateway's own page in-app, watches for the `redirect_url` (new `EnvConfig.topupRedirectUrl`, overridable per environment since gateways allow-list redirect targets) and **self-verifies** — the browser hand-off had no way back, so the user had to remember to return and tap "I've paid". PAN/CVV still never touch our UI; the origin is shown in a padlock bar because a WebView has no address bar. Wired into buy-coins screen, buy-coins sheet and add-card sheet. Also implemented the spec's **third** payment path: `POST /wallet/topup/charge-card` ("one-tap top-up… no checkout redirect needed") — the repository method existed but had zero call sites, so a saved card still forced a full redirect. `PaymentMethodSelector` now takes a shared `TopupMethod` enum (card / bank_transfer / savedCard) and surfaces the default saved card as a third row. APK build-verified |
| 51 | Push notifications (FCM) — client setup | ✅ Android | Grok | Done 2026-08-01. **Permission timing**: asked after sign-in, never at cold start, behind a soft pre-prompt sheet — declining that costs nothing, so iOS's once-ever OS prompt is only spent on a user who already said yes. "Not now" has a 14-day cooldown; the OS prompt is recorded as spent before awaiting so a mid-prompt crash can't earn a second ask. **Tap routing**: no longer blocked — not every notification *has* a destination ("Welcome to Skiflux" has no episode behind it), so every tap opens the Notifications screen, which is right for all types and wrong for none. Per-type deep links still wait on `NotificationItem.data` being typed (see 52). **Testability**: debug-only "Push diagnostics" section in Settings → Notifications shows permission state, a copyable FCM token, and a prompt-state reset. **Icons verified**: `ic_notification` is pure-white monochrome at all 5 densities (24/36/48/72/96px) — correct for the Android tray. iOS still blocked on Apple Developer membership (APNs) |

### Tier 4 — Blocked, needs backend dev action

| # | Task | Status | Notes |
|---|------|--------|-------|
| 52 | Notifications response shape | ✅ | List wired 2026-07-31 (session-gated, error + retry states). Remaining backend ask: `NotificationItem.data` is typed `{}` — tap routing stays blocked until the per-type payload is documented (tag in `notifications_repository.dart`) |
| 53 | Leaderboard response shape | ⏸ | Same issue. (Unrelated layout fix 2026-08-01: on a short window the podium was scaled by whatever was left after reserving 200px for the rank card — *unclamped*, so a 480-tall window resolved to a **0.09** scale and the 1st-place XP line landed on the podium art. The rank card is a scroll view so it yields first now; the podium never scales past 0.72, and past that the whole board scrolls.) |
| 54 | Learning Tasks/Quiz submission mapping | ✅ | Done 2026-07-31 — `GET /episodes/watched/tasks` + `GET /me/submissions` + `POST /episodes/task/submit` (JSON link submission, multipart file upload, assessment answers keyed by question UUID); grading vs real `pass_score_percent`; `accepted_proof_types` drives the file-type allowlist (23-extension hardcode retired) |
| 55 | Coin pack pricing endpoint | ⏸ | Still no mobile-facing endpoint (re-checked 2026-07-31). Top-up flow itself is wired; packs remain client-side fallback pricing until this exists |
| 56 | Public user profile endpoint | ✅ | Now exists in spec — `GET /users/by-username/{username}` wired 2026-07-31; all fabricated fallback data (xp 350, rank 12, fake badges/tasks) removed, honest states. Residual backend asks: completed-task list, documented stat-field shapes, email/contact gating decision (tags in `public_user_profile_provider.dart`) |
| 57 | Downloads management API | 🔄 | Client pipeline built 2026-08-01 (see #34). Still no backend API: no offline entitlement, no expiry, and no per-rendition URLs — so "Download quality" cannot be honoured and paid-episode offline access has no policy. Confirm intentional client-only vs. missing |
| 58 | Watch-history delete endpoint | ✅ | Now exists in spec — `DELETE /me/watch-history/{episode_id}` + clear-all wired 2026-07-31, optimistic with rollback (stale "no endpoint" TODOs deleted) |
| 59 | Share/deep-link generation endpoint | ⏸ | Confirm intentional client-side vs. missing |
| 60 | Remaining settings persistence (auto-play, download quality, Wi-Fi-only, language, watch-history toggle, recommendations) | 🔄 | Persisted locally as of 2026-07-31, but three are not yet *consulted*: auto-play and Wi-Fi-only are stored and ignored, and app language is not wired to `MaterialApp`'s locale. Download quality still needs multi-rendition support (`BACKEND_INTEGRATION.md` Tier 4 §4). Skill-world selection is fully real — `GET /skillworlds` feeds the picker, `PATCH /me/update` persists it. New `SkifluxErrorKind.settingsSaveFailed` (toast) covers save failures |
| 61 | Auto-caption generation pipeline (Whisper API) | ⏸ | Architectural decision, not started |
| 61a | Transaction dispute endpoint (`transaction_details_screen.dart` "report" action) | ⏸ | New tag 2026-07-26, re-confirmed absent 2026-07-31 — no dispute/support-ticket-create endpoint in spec (only ticket *rating* exists) |
| 61e | Episode report endpoint (`more_menu_sheet.dart` "report" action) | ⏸ | New tag 2026-07-31 — `POST /comments/{id}/report/` exists for comments, but there is no episode-level equivalent |
| 61f | Per-creator notification mode | ⏸ | Re-confirmed absent 2026-07-31 — `/me/notification-preferences` is app-wide, cannot be scoped per followed creator. See `BACKEND_INTEGRATION.md` Tier 4 §2 for the recommended three-state shape |
| 61g | Viewer-facing creator catalogue (episodes/seasons) | ⏸ | `GET /creators/{creator_id}` now exists and is wired, but there is still no viewer-facing episodes/seasons listing, so playlists/seasons stay demo-seeded — and **episode purchase 404s on demo ids** until the catalogue is backend-driven |
| 61b | Auth + profile response bodies undocumented | ⏸ | `POST /auth/login`, `/auth/signup`, `/auth/token/refresh`, social logins, and `GET /me/profile` all have description-only responses in the spec (no schema). Descriptions promise access/refresh tokens and the full profile payload — need documented shapes before Tier 1 auth/profile integration hardens |
| 61c | Per-user episode purchase state | ⏸ | `Episode` schema has no `is_purchased`/unlocked field — app can't tell locked vs unlocked paid episodes from the list responses. Needs a field or a purchases-list endpoint |
| 61d | Badge artwork + playlist cover URLs | ⏸ | `Badge` has no image/asset URL (app renders badge art); learner-facing `Season` exposes `cover_image_public_id` (Cloudinary id) but not a ready URL (creator-side `SeasonPerformance` has `cover_image_url`). 2026-07-31: badges endpoint corrected to `/me/badges`, parsing made tolerant, catalogue join hardened — the art still matches on name (minor tag in `badge_catalogue.dart`) |

### `BACKEND_REQUESTS.md` generation
| # | Task | Status | Notes |
|---|------|--------|-------|
| 62 | Generate `BACKEND_REQUESTS.md` (consolidated ask for backend dev — Tier 4 items in plain product language) | ⏸ | **Paused** — waiting until full app walkthrough with Claude is complete, to catch any additional missing functionality first |

---

## Phase 3 — Performance / UX Polish

| # | Task | Status | Model |
|---|------|--------|-------|
| 63 | Caption rendering support | ⬜ | Claude Code — **note 2026-08-01**: the More Menu's "Caption" row already flips an On/Off chip, but `captionsOn` is read nowhere except that row, and `Episode` carries no caption/subtitle track at all. So the control currently advertises a feature that does not exist. Either a caption track lands on Episode (WebVTT URL) or the row should go — flagged in `more_menu_sheet.dart`. **Your call.** |
| 64 | DevTools profiling pass | ⬜ | Grok first, escalate to GPT-5.6 Sol if inconclusive |
| 65 | Widget rebuild scoping (`Consumer`/`Selector`) | ⬜ | Claude Code |
| 66 | Video preload buffer (production, 1 video ahead, lowest quality) | ⬜ | Grok |
| 67 | Background prefetch of secondary screens | ⬜ | Grok |
| 68 | `cached_network_image` rollout | ✅ | Done 2026-08-01 — all 11 `Image.network`/`NetworkImage` sites migrated behind `shared/widgets/network_image.dart` (`SkifluxNetworkImage` widget + `skifluxImageProvider` for `ImageProvider` slots). Shimmer placeholder by default, caller-supplied error fallback because it differs by surface; the feed card uses its brand fill instead of a shimmer so covers don't flash while scrolling |
| 69 | Image sizing strategy (thumbnail/medium/full per context) | ⬜ | DeepSeek V4 Flash |
| 70 | Rendering hygiene pass (`RepaintBoundary`, pure `build()`) | ⬜ | DeepSeek V4 Flash |
| 71 | Sheet blur overlay → solid scrim (Option A confirmed) + cold-launch latency | ✅ | Done 2026-08-01 — the `BackdropFilter` in `showSkifluxSheet`'s `buildModalBarrier` is now a `FadeTransition` over a solid `Overlay/50` `ColoredBox`, so all 11+ sheets lose the per-frame full-screen GPU read-back. Final alpha is unchanged (`black50` = `0x80`; the old code multiplied that by another 0.5 while animating). Still pair with #64 to confirm the cold-open improvement numerically |
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
- [ ] Visually confirm notification icon renders correctly on a real device — asset side verified 2026-08-01 (pure-white monochrome, all 5 densities, correct sizes); what remains is seeing it in a real tray
- [x] ~~Confirm the top-up **return URL** with the backend dev~~ — answered 2026-08-02 by `payment-flows.md`: `redirect_url` is "where the gateway sends the user afterwards (**your app page**)", and the gateway appends `?status=…&tx_ref=…` to it. The app now always sends `EnvConfig.paymentReturnUrl` (`https://skiflux.app/payments/return` — a URL that deliberately does not have to exist, because the WebView intercepts navigation to it) and additionally recognises the return by its own `tx_ref` in the query. Set `TOPUP_REDIRECT_URL` only to override
- [ ] **Decide the payment-method axis** — the app asks "Card / Bank transfer / Saved card" and sends `payment_method`, hardcoding `currency: "NGN"`. `payment-flows.md` §1.1 says the axis is **currency + gateway**, discovered from `GET /wallet/topup/methods` (`currencies[].gateways[]`, `skillcoin_rate`, `is_default`), with "the frontend must never hardcode gateways". Reconciling the two is a design change, not a bug fix — see the notes below #50b
- [ ] Test a real push end to end: Settings → Notifications → Push diagnostics (debug builds) → copy the FCM token → send from Firebase Console with the app **backgrounded** (Android only draws a tray notification when backgrounded)
- [ ] Complete the full app walkthrough with Claude (in progress) before finalizing `BACKEND_REQUESTS.md`
- [ ] Decide Firebase/FCM ownership arrangement with backend dev, obtain config files
- [ ] Confirm `/me/devices` is the correct device-token registration endpoint with backend dev
- [ ] Re-check privacy policy content accuracy against current app features before submission
- [x] ~~Scope the downloads system itself before download-progress-notification work can begin~~ — done; see #34 (pipeline) and #34a (tray progress, 2026-08-02)
- [ ] Ask the backend dev for `xp_reward` / `skillcoin_reward` on `WatchedEpisodeTaskItem` + `EpisodeTask` — see #36g. Learning-task cards can render the reward the design shows the moment either arrives; today the payload carries no reward at all
- [ ] Decide whether the thumb-**down** should appear on your own comments. It is hidden there by design (it opens a report, and reporting yourself is not a thing) — but ownership is *inferred* from a display-name match, so on a test account that wrote every comment there is no thumb-down anywhere. A real `is_mine` / `user_id` on `EpisodeComment` would make this exact instead of a guess
- [ ] Create the Google OAuth clients (Web + iOS + Android) and put `GOOGLE_SERVER_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `config/env/dev.json`; register the debug and release Android SHA-1s — Google sign-in stays hidden until then
- [ ] Fill `CFBundleURLSchemes` in `ios/Runner/Info.plist` with the REVERSED_CLIENT_ID once the iOS OAuth client exists
- [ ] Register an Apple Service ID + https redirect URI (needed only for Sign in with Apple on Android), and enable the Sign in with Apple capability on the App ID in the developer portal
- [ ] On a Mac: verify `Runner.entitlements` and the `CODE_SIGN_ENTITLEMENTS` pbxproj entries build and sign correctly (authored from Windows, unverified)
- [x] ~~Approve the `url_launcher` dependency~~ — approved 2026-07-31 and wired; as of 2026-08-01 payment checkout no longer uses it at all (in-app WebView, see #50a). `url_launcher` remains for genuinely external links: mission URLs, help centre, store rating
- [ ] Apple Developer membership — blocks iOS Firebase/APNs setup
