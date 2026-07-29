# Backend Integration Status

> Fresh cross-reference of `skiflux_mobile_app_v2` against **SkiFlux API.yaml**
> (OpenAPI 3.0.3, title SkiFlux API v1.0.0) plus platform-tasks.md,
> payment-flows.md, withdrawal-flows.md.
>
> Generated: **2026-07-28** (Grok full re-scan — not a copy of prior mappings).
>
> In-code inventory: **43** `TODO(backend, …)` tags (38 blocking, 5 minor) —
> matches [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md) after excluding the
> prose mention in `auth_endpoints.dart`. Spec scan: **269** paths / **280**
> operations → ~**107** learner/mobile-relevant (non-`/admin/*`, non-`/creator/*`
> studio). `/api/v1/profile/me/*` is a legacy duplicate of `/api/v1/me/*` —
> mobile must use **`/me/*` only**.

## Scope rules (confirmed)

| Rule | Implication for mobile |
|------|------------------------|
| `/admin/*` out of scope | Never call; admin web only |
| `/creator/*` out of scope | Creator studio web only |
| Password reset is **OTP-based** | `POST /auth/forgot-password` → OTP → `POST /auth/reset-password` with `{email, otp, new_password, confirm_new_password}` — not token-link |
| Money fields are **decimal-formatted strings** (except one) | Use `package:decimal` + `DecimalConverter`; never `double.parse` on money. Exception: `UserWallet.withdrawable_balance` is JSON **number** (`format: double`) → `DecimalFromNumConverter` |

## Classification legend

| Code | Meaning |
|------|---------|
| **A · DONE** | Live network call against a real endpoint; behaviour matches intent |
| **B · READY** | Endpoint (+ usually schema) exists; app still on demo data / not wired |
| **C · NEEDS ADAPTER** | Endpoint exists but wire shape ≠ current UI/store models; map in repository |
| **D · BLOCKED** | No mobile endpoint, response undocumented with no usable schema, or open product question that needs backend answer |

Many features are **B + C**: endpoint is ready, but freezed/UI mapping is still required. Primary letter is the **blocker to ship**.

---

## Executive summary

### Already integrated (A)

| Area | What works |
|------|------------|
| **Auth email pipeline** | `AuthRepository` + `AuthFlowNotifier`: signup, login, verify-register-email, resend-register-otp, forgot-password, reset-password (OTP), logout, token refresh interceptor |
| **Session storage** | `TokenStore` + `AuthInterceptor` refresh on 401 |
| **Biometric gate (local)** | On-device `local_auth` only; no server exchange (correct per spec) |
| **Network base** | Dio `API_BASE_URL` + `/api/v1` prefix, `ApiRepository` helpers |

Token JSON field names remain **description-only** in OpenAPI; `AuthTokens.fromJson` is a deliberate tolerant adapter (still **A**).

### Models ready, stores not wired (B/C)

Freezed models exist and are **OpenAPI-aligned** (2026-07-27 chip):

- Wallet: `UserWallet`, `SkillcoinTransaction`, `WithdrawalAccount`, `WithdrawalMethod`, `WithdrawalRequest`, `SavedCard`
- Tasks: `PlatformTask` (`PlatformTaskUser` shape)

`wallet_store.dart` / `tasks_store.dart` still seed **demo** data and do **not** call the API.

### Highest-value READY next (recommended build order)

1. **Profile core** — `GET/PATCH /me/profile` + `/me/update` (identity for My Profile, Edit Profile, biometric email/avatar)
2. **Wallet read** — `GET /wallet/my-wallet`, `my-transactions`, `summary` (models ready)
3. **FCM devices** — `POST /me/devices` (endpoint **confirmed** in OpenAPI)
4. **Home feed** — `GET /episodes/recommendations` (+ optional following)
5. **Platform tasks** — `GET /me/platform-tasks` + start/submit/claim (models ready)
6. **Streaks / leaderboard / notifications / liked / saved / watch-history**
7. **Wallet write** — top-up + withdrawals (follow payment-flows.md / withdrawal-flows.md)
8. **Comments + social actions** (like/save/follow)
9. **Episode learning tasks** — `GET /episodes/watched/tasks` + submit
10. **Search + skillworlds**

### Still blocked on backend (D) — see also [BACKEND_AI_BUILD_SPEC.md](BACKEND_AI_BUILD_SPEC.md)

| Gap | Why blocked |
|-----|-------------|
| Coin packs / SkillCoin price list | No mobile pricing endpoint; app has static `kCoinPacks` |
| Transaction dispute | No `POST …/report` (or equivalent) |
| Public user profile by username/id | No learner `GET /users/{…}` |
| Watch-history delete | No `DELETE /me/watch-history/{…}` |
| Downloads inventory API | No server list; client-local using `Episode.download_url` is intended |
| Share deep-link catalogue | No content URL / share-metadata API |
| Learner season/playlist catalogue | Only `GET /seasons/{season_id}/episodes` (need id first); no list-seasons for learners |
| Creator public profile for learners | No `GET /creators/{id}` (only follow + following list + nested `Episode.creator`) |
| Several response bodies | Description-only: login tokens, `GET /me/profile`, `GET /me/leaderboard`, `GET /me/notifications`, `GET /skillworlds`, many POST action 200s |

---

## Full classification table

### Auth & session

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Login | **A** | `POST /auth/login` | Wired; response body undocumented → `AuthTokens` adapter |
| Signup | **A** / **C** | `POST /auth/signup` | Wired. OpenAPI **requires** `first_name`, `last_name`; app treats them optional — ensure UI always sends them or backend relaxes |
| Verify register email | **A** | `POST /auth/verify-register-email` | Wired; tokens optional if body empty |
| Resend register OTP | **A** | `POST /auth/resend-register-otp` | Wired |
| Forgot password | **A** | `POST /auth/forgot-password` | Wired (OTP send) |
| Reset password | **A** | `POST /auth/reset-password` | OTP + new passwords; matches backend confirmation |
| Verify forgot-password OTP alone | **B** | `POST /auth/verify-forgot-password-otp` | Exists; app holds OTP client-side until reset (works without this call) |
| Token refresh | **A** | `POST /auth/token/refresh` | Interceptor; body `{refresh_token}` |
| Logout | **A** | `POST /auth/logout` | Wired; local clear always |
| Social Google/Apple mobile | **B** | `POST /auth/social/mobile/{google,apple}` | Repository ready; **native SDK** not integrated (`auth_chrome.dart` tag) |
| Biometric preference sync | **B** | `GET/POST /me/biometrics`, `/me/biometrics/toggle` | App settings are local only; no session-exchange endpoint (by design) |
| Biometric email greeting | **C** | `GET /me/profile` (or login body) | Tag: cache email — profile response schema not attached in OpenAPI; `UserProfile` schema exists |
| Biometric avatar | **C** | `GET /me/profile` | Same; `UserProfile.avatar_url` |
| Change password (settings) | **B** | `POST /auth/change-password` | Endpoint exists; not in app settings UI flow yet |
| Complete onboarding | **B** | `POST /profile/complete-onboarding/` | multipart username/skillworld/goal/avatar |

### Home & playback

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Home feed | **C** | `GET /episodes/recommendations` (primary); `GET /episodes/following/` | Tag: demo feed. Map `Episode` → `HomeFeedItem` (video_url, thumbnail_url, creator, counts) |
| Feed thumbnails / CDN | **C** | Fields on `Episode` | Once feed is live, drop local assets (`video_feed_card`, `full_screen_player`) |
| Track view | **B** | `POST /episodes/track-view` | No schema body documented in scan — confirm payload |
| Rate episode | **B** | `POST /episodes/{id}/rate/` | Ready |
| Not interested | **B** | `POST /episodes/not-interested` | Ready |
| Episode resources (read) | **B** | `GET /episodes/{id}/resources/` | Accepts `bearerAuth` **and** admin; mobile may use learner JWT. Write resource routes are studio-oriented |

### Comments

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| List comments | **C** | `GET /episodes/{id}/comments` → `EpisodeComment[]` | Flat fields (`user_first_name`, `audio_url`, …) ≠ nested DS comment model |
| Post comment / voicenote | **C** | `POST /episodes/comment` multipart | `text` + `audio_file` |
| Like / reply / edit / delete / report | **B** | `/comments/*` | Ready once list is wired |

### Subscriptions / creators

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Subscriptions store | **C** | `GET /creators/following/` + `GET /episodes/following/` | Replace seeded creators/episodes; map `FollowedCreator` + `Episode` |
| Follow toggle | **B** | `POST /creators/{creator_id}/follow/` | Returns `is_following`, `followers_count` |
| Creator profile screen | **D** / **C** | Nested `Episode.creator` only | **No** dedicated learner `GET /creators/{id}`; identity incomplete unless expanded Creator schema is enough |
| Episode thumbnails (subs widgets) | **C** | `Episode.thumbnail_url` | With subscriptions wire-up |

### Playlists / unlock / coins catalogue

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Playlist catalogue + locks | **D** / **C** | `GET /seasons/{season_id}/episodes`; `POST /episodes/purchase` | No learner season list / playlist cover URL API. Product “playlist” ≈ season; unlock ≈ purchase |
| Coin packs + NGN rate | **D** | — | **No** coin-pack / pricing endpoint. Top-up uses fiat amounts via `/wallet/topup/*` + methods discovery |
| Cover / episode thumbs | **C** | `thumbnail_url` on Episode | When content endpoints wired |

### Tasks

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Platform missions | **B** / **C** | `GET /me/platform-tasks`; `POST …/start|submit|claim|complete` | Freezed `PlatformTask` matches `PlatformTaskUser`. UI `tasks_store` still demo missions + learning mix |
| Learning / episode tasks | **C** | `GET /episodes/watched/tasks`; `POST /episodes/task/submit`; `GET /me/submissions` | `WatchedEpisodeTaskItem` + quiz/project submit shapes ≠ current seed models |
| Task coins as int in UI | **C** | `skillcoin_reward` string decimal | Must use Decimal; UI currently `int` coins on learning/missions seed |

### Wallet & payments

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Balance | **B** | `GET /wallet/my-wallet` | Freezed `UserWallet` ready (string decimals + num withdrawable) |
| Ledger | **C** | `GET /wallet/my-transactions` | Freezed `SkillcoinTransaction` ready; **UI** still `CoinTxn` with `int delta` |
| Summary cells | **B** | `GET /wallet/summary` | `total_earned/spent/withdrawn` decimal strings |
| Transaction reference | **B** | `SkillcoinTransaction.reference_id` | Tag on wallet_store |
| Dispute / report txn | **D** | — | No endpoint |
| Saved cards | **B** | `GET/POST/DELETE /wallet/cards…` | Freezed `SavedCard`; settings `payment_store` demo |
| Top-up methods / initiate / verify / charge | **B** | `/wallet/topup/*` | See payment-flows.md; amount_fiat decimal strings |
| Withdrawal methods / banks / accounts / request | **B** | `/wallet/withdrawals/*` | Freezed models ready; amount decimal string |
| Bank default in wallet UI | **C** | accounts list | Map `WithdrawalAccount` → UI bank row |

### Profile & settings

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| My Profile identity | **C** | `GET /me/profile` | Likely `UserProfile` schema (xp, rank, balance strings, avatar_url, …). Response not explicitly $ref'd in path op |
| Auth gate on My Profile | **A** / **C** | Session via `TokenStore` | Auth layer **exists** now; tag text “no auth layer” is **stale** — still demo identity on screen |
| Edit profile load/save | **C** | `GET /me/profile`; `PATCH /me/update` | Multipart avatar + fields; email not in update schema (read-only) |
| Avatar upload | **B** | `PATCH /me/update` multipart `avatar` | Matches tag path intent (`/me/update` not `/me/profile`) |
| SkillWorld persist | **B** / **C** | `PATCH /me/update` `skillworld` array; `GET /skillworlds` | Skillworlds list response undocumented |
| Badges | **C** | `GET /me/badges` → `UserBadge[]` | `Badge` has name/description, **no artwork URL** in schema |
| Liked / saved | **C** | `GET /me/liked`, `/me/saved` → `Episode[]` | Map to library row models; thumbs from `thumbnail_url` |
| Watch history | **C** | `GET /me/watch-history` | Progress = `watch_duration_seconds` / episode duration; no delete |
| Watch-history delete | **D** | — | Tag expects DELETE |
| Downloads list | **D** | Client-local | Use `download_url` for offline files; no server inventory |
| Public user profile | **D** | Search `users` only | No dedicated profile-by-id |
| Settings prefs (full) | **C** | Partial: `GET/PATCH /me/notification-preferences` | 7 notification booleans only. No autoplay/download quality/language/watch-history privacy API |
| Biometric / 2FA flags in settings | **B** / **D** | biometrics endpoints; 2FA unknown | 2FA not in OpenAPI mobile surface |

### Gamification

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Streaks | **C** | `GET /me/streak` → `StreakSummary` | Field renames; **current week only** (`week`), not multi-week history UI seed |
| Leaderboard | **C** | `GET /me/leaderboard` | Response **undocumented** (description only) → treat as **D** until schema confirmed; endpoint exists |

### Search & share

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Search | **C** | `GET /search?q=` → `GlobalSearchResponse` | Nested paginated buckets: episodes/seasons/creators/users — map seasons→playlists UI |
| Search thumbs | **C** | Episode/season media fields | |
| Share sheet targets | **D** | — | Use OS share + client-built URLs if deep-link base known; no backend catalogue |

### Notifications & FCM

| Feature / screen | Status | Endpoint(s) | Notes |
|------------------|--------|-------------|-------|
| Notification feed | **C** / **D** | `GET /me/notifications` | **No response schema** in OpenAPI — blocked on shape confirmation |
| Mark read | **B** | `POST /me/{id}/read` | Path is odd (`/me/{id}/read`) — confirm id = notification id |
| FCM token register | **B** | `POST /me/devices` | **Confirmed** in OpenAPI: `{token, platform?, device_id?}` → 201. Tag “unverified” is outdated |

---

## Decimal / money handling (Step 3)

| Check | Result |
|-------|--------|
| `DecimalConverter` / `DecimalFromNumConverter` | Present in `lib/shared/data/decimal_converter.dart` |
| Money freezed fields | `UserWallet.balance/bonus_balance` string→Decimal; `withdrawable_balance` num→Decimal; `SkillcoinTransaction.amount`; `WithdrawalRequest.amount/netAmount/fee`; `PlatformTask.skillcoinReward` |
| `double.parse` on money in lib | **None found** (only docs mention in converter comments; `toDouble` only on Decimal→JSON for the one num field) |
| UI wallet store | Still uses **int** `CoinTxn.delta` for demo — **not** a parse bug today, but **must not** map API amounts via `int.parse`/`double.parse` when wiring; use Decimal |
| `UserProfile.balance` / `bonus_balance` | Spec: **string** (readOnly) — when profile freezed model is added, use `DecimalConverter` |
| Top-up / withdraw requests | Spec: `amount_fiat`, `amount` as **string decimal** — send `DecimalConverter.toJson` / two-decimal strings |

**Violations fixed this pass:** none (read-only documentation task; no code bugs found).

---

## What changed since last mapping (2026-07-26, 49 tags)

| Delta | Detail |
|-------|--------|
| Tag count | **49 → 43** — Tier 1 auth closed ~8 tags; biometric session-exchange tag removed by design |
| Auth | **A** for full email/OTP/reset/logout/refresh path (was entirely blocked) |
| Freezed wallet + platform-task models | Spec-aligned (2026-07-27); still **unwired** to stores |
| FCM `/me/devices` | Was “unverified”; **now confirmed** in OpenAPI |
| Home feed tag | Added; maps to recommendations/following |
| Password reset | Confirmed OTP (app already implements correctly) |
| Admin/creator | Reconfirmed out of scope |
| Stale tag copy | My Profile “no auth layer” is outdated (auth exists; identity still demo) |

---

## Related files

| File | Role |
|------|------|
| [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md) | Per-tag inventory from grep |
| [BACKEND_AI_BUILD_SPEC.md](BACKEND_AI_BUILD_SPEC.md) | Machine-oriented backend build contract for **D** items + undocumented schemas |
| `skiflux_mobile_app_v2/lib/features/auth/data/*` | Live auth integration |
| `skiflux_mobile_app_v2/lib/features/wallet/data/models/*` | Ready wallet models |
| `skiflux_mobile_app_v2/lib/features/tasks/data/models/*` | Ready platform-task model |
| `skiflux_mobile_app_v2/lib/shared/data/decimal_converter.dart` | Money parsing |
| `skiflux_mobile_app_v2/lib/shared/network/*` | Dio + ApiRepository |
