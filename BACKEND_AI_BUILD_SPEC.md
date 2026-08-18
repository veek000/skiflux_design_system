# BACKEND_AI_BUILD_SPEC

**Audience:** AI coding assistant working on the SkiFlux **backend** (Django/DRF).  
**Not** for human product prose. Do not invent fields. Prefer OpenAPI updates that match this contract.

**Client:** Flutter app `skiflux`, base path prefix **`/api/v1`**, auth scheme **`Authorization: Bearer <JWT>`** (`bearerAuth`).  
**Out of scope for mobile forever:** all `/api/v1/admin/*` and `/api/v1/creator/*` (and studio-only resource write endpoints). Do not build mobile against them.

**Money rule (global):**

- Fiat and Skillcoin money fields MUST be JSON **strings** formatted as decimal, e.g. `"500.00"`, `"0.10"`.
- Client uses Python-Decimal-equivalent (`package:decimal` / `Decimal.parse`). Client MUST NOT receive IEEE doubles for money except the already-documented exception below.
- **Exception (keep stable):** `UserWallet.withdrawable_balance` is OpenAPI `type: number, format: double`. Do not change without coordinating mobile (`DecimalFromNumConverter`). Prefer eventually migrating it to string decimal like siblings.
- On write requests (`amount`, `amount_fiat`, `skillcoin_reward` admin config, etc.) accept and return **strings**, never floats.

**Response envelope:**

- payment-flows.md / withdrawal-flows.md describe `{status, status_code, message, data}`.
- OpenAPI operation responses for wallet often show the bare schema (e.g. `UserWallet`) at 200.
- Mobile `ApiRepository` currently expects **bare object**, bare **array**, or DRF `{count,next,previous,results}` — it does **not** unwrap `{data: …}` except inside `AuthTokens` (which checks `data`/`tokens`/`session`).
- **Requirement for new/changed endpoints:** either (1) return bare payload matching OpenAPI schema **or** (2) document and guarantee a single envelope and update OpenAPI; if envelope is used, put the schema **inside** `data` and tell mobile. Do not mix per-route.

**Legacy alias:** `/api/v1/profile/me/*` duplicates `/api/v1/me/*`. Keep both if needed for web; document that mobile only calls **`/me/*`**.

---

## 0. Document OpenAPI response schemas (currently description-only)

These endpoints exist and mobile will call them. Missing response schemas force guesswork.

### 0.1 Auth token-minting responses

| Method | Path |
|--------|------|
| POST | `/api/v1/auth/login` |
| POST | `/api/v1/auth/token/refresh` |
| POST | `/api/v1/auth/social/mobile/google` |
| POST | `/api/v1/auth/social/mobile/apple` |

**Required response JSON (200)** — pick **one** canonical spelling and document it; mobile already accepts both:

```json
{
  "access": "<jwt>",
  "refresh": "<jwt>"
}
```

Also accepted by current client: `access_token`/`refresh_token`, or same pair nested under `tokens` | `data` | `session`.

**Refresh request body (already implemented client-side):**

```json
{ "refresh_token": "<jwt>" }
```

**Logout request body:** same `{ "refresh_token": "<jwt>" }` with Bearer access token.

**Signup (POST `/api/v1/auth/signup`):** 201 may be empty. Do not return tokens (client expects OTP then login/verify).

**OpenAPI signup required fields today:** `email`, `password`, `password_confirm`, `first_name`, `last_name`. Mobile may omit names if UI allows empty — either keep required and mobile will always send non-empty strings, or make `first_name`/`last_name` optional in OpenAPI. Do not silently 500.

**Password reset (confirmed product rule):**

1. `POST /api/v1/auth/forgot-password` body `{ "email": "user@example.com" }` → send OTP email.
2. `POST /api/v1/auth/verify-forgot-password-otp` body `{ "email", "otp" }` — the client **calls this** on the code screen, so a wrong or expired code is rejected there rather than two screens later on the new-password form. **This call must not consume the code:** the same `otp` is sent again in step 3, which is the step that spends it. If the implementation invalidates the code on verify, say so and the client will drop the pre-check — do not leave it consuming silently, because the reset then fails 100% of the time with a message that looks like a rejected password.
3. `POST /api/v1/auth/reset-password` body:

```json
{
  "email": "user@example.com",
  "otp": "123456",
  "new_password": "...",
  "confirm_new_password": "..."
}
```

Must reject wrong OTP / mismatch passwords with 4xx JSON, not 500. Report a rejected **code** under an `otp` key (`{"otp": ["This code has expired."]}`) rather than as a bare `detail` — the client routes an `otp` error back to the code screen, where the resend is, and leaves everything else on the password form.

### 0.2 Profile

| Method | Path | Action |
|--------|------|--------|
| GET | `/api/v1/me/profile` | Attach schema **`UserProfile`** (already in components) as 200 body |
| PATCH | `/api/v1/me/update` | Attach 200 body = updated **`UserProfile`** (or same fields) |

**UserProfile money fields (must remain strings):**

- `balance`: string decimal, readOnly  
- `bonus_balance`: string decimal, readOnly  
- `xp`: integer  
- `rank`: integer | null  
- `avatar_url`: string URI or empty  
- `email`, `username`, `first_name`, `last_name`, `bio`, `country`, `phone`  
- `skillworld`: array of enum strings  
- `goal`: array of enum strings  
- `biometrics_enabled`: boolean  
- `streak_count`, `task_done`, `episode_completed`, `current_level`  
- `earned_badges`: array  
- `watch_history_preview`: as currently implemented  

**PATCH multipart fields (already in OpenAPI):**  
`first_name`, `last_name`, `username`, `bio`, `country`, `goal`, `skillworld`, `phone`, `avatar` (binary).  
**Email is not updatable** via this endpoint (mobile shows read-only email).

### 0.3 Notifications list

| Method | Path |
|--------|------|
| GET | `/api/v1/me/notifications` |

Query already: `limit`, `offset`, `unread_only`.

**Required 200 body** — either bare array or DRF page. Prefer:

```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "uuid-or-int",
      "title": "string",
      "body": "string",
      "message": "string",
      "icon": "string",
      "type": "string",
      "created_at": "ISO-8601",
      "is_read": false,
      "action": null
    }
  ]
}
```

Pick exact field names and publish them. Mobile UI seed expects roughly: title, body, icon, time, action?, unread. Map `is_read` ↔ unread, `created_at` ↔ time.

**Mark read:** `POST /api/v1/me/{id}/read` — document that `{id}` is **notification id**. Consider renaming path to `/me/notifications/{id}/read` in a versioned change if possible; if kept, document unambiguously.

### 0.4 Leaderboard

| Method | Path |
|--------|------|
| GET | `/api/v1/me/leaderboard` |

Query: `level`, `page_size`, `search`.

**Required 200 body (minimum for current UI):**

```json
{
  "current_user_rank": 12,
  "better_than_percent": 80,
  "results": [
    {
      "rank": 1,
      "first_name": "string",
      "last_name": "string",
      "username": "string",
      "avatar_url": "string|null",
      "xp": 1200
    }
  ]
}
```

Publish exact schema in OpenAPI. Mobile will adapt names/initials client-side if needed.

### 0.5 Skillworlds list

| Method | Path |
|--------|------|
| GET | `/api/v1/skillworlds` |

Public (no auth) allowed.

**Required 200 body:**

```json
[
  {
    "id": "uuid-or-slug",
    "name": "string",
    "slug": "string",
    "description": "string",
    "icon_url": "string|null"
  }
]
```

### 0.6 POST action endpoints with empty 200

Document request + response for:

- `POST /episodes/like` `{ "episode_id": "uuid" }` → `{ "liked": true }` preferred  
- `POST /episodes/save` `{ "episode_id": "uuid" }` → `{ "saved": true }`  
- `POST /episodes/purchase` `{ "episode_id": "uuid" }` → purchase result + new balances as string decimals if changed  
- `POST /episodes/track-view` — **document body** (episode_id, duration_seconds?, completed?)  
- `POST /episodes/task/submit` — already has request schemas; document 200 body (submission id, status)  
- `POST /episodes/comment` — document created `EpisodeComment`  

---

## 1. BLOCKED features — implement or explicitly reject

### 1.1 Coin packs / SkillCoin purchase catalogue

**Mobile need:** Wallet “Buy coins” packs UI (`coins`, `priceNaira`/`price_fiat`, badge, save%).

**Missing endpoint (propose):**

```
GET /api/v1/wallet/coin-packs
```

**200 response:**

```json
{
  "rate_fiat_per_skillcoin": {
    "NGN": "1.0000",
    "USD": "0.1000"
  },
  "packs": [
    {
      "id": "uuid",
      "skillcoins": "100.00",
      "price_fiat": "1000.00",
      "currency": "NGN",
      "badge": "popular|best_value|null",
      "save_percent": 10
    }
  ]
}
```

Notes:

- `skillcoins` and `price_fiat` MUST be **string decimals**.  
- Alternatively, if product decision is “no packs, only free-amount top-up”, document that and return empty packs; mobile will drop pack UI and use `GET /wallet/topup/methods` only. **State which** in OpenAPI description.

Top-up remains:

- `GET /wallet/topup/methods`  
- `POST /wallet/topup/initiate` `{ "amount_fiat": "1000.00", "currency": "NGN", "gateway_name": "paystack", "idempotency_key"?, "redirect_url"?, "save_card"? }`  
- `POST /wallet/topup/verify` `{ "tx_ref": "...", "gateway_reference"? }`  
- `POST /wallet/topup/charge-card` `{ "saved_card_id": "uuid", "amount_fiat": "1000.00", "currency"?, "idempotency_key"? }`  

### 1.2 Transaction dispute / report

**Mobile need:** Transaction details “Report” → case id.

**Missing endpoint (propose):**

```
POST /api/v1/wallet/transactions/{reference_or_id}/report
```

**Request:**

```json
{
  "reason": "string",
  "details": "string"
}
```

**201/200:**

```json
{
  "case_id": "uuid",
  "status": "open"
}
```

If product uses support tickets instead, document mapping to `support` APIs and give mobile the exact path + body. Do not leave “report” as a dead button without a contract.

### 1.3 Public user profile (learner → other learner)

**Mobile need:** `PublicUserProfile` screen: name, username, league, xp, rank, tasksDone, skills, badges, completed tasks.

**Missing endpoint (propose):**

```
GET /api/v1/users/{user_id}
```

and/or

```
GET /api/v1/users/by-username/{username}
```

**200 body (minimum):**

```json
{
  "id": "uuid",
  "first_name": "string",
  "last_name": "string",
  "username": "string",
  "avatar_url": "string|null",
  "bio": "string",
  "xp": 0,
  "rank": 1,
  "current_level": "string",
  "task_done": 0,
  "skillworld": ["..."],
  "earned_badges": [
    {
      "id": "uuid",
      "name": "string",
      "description": "string",
      "icon_url": "string|null",
      "earned_at": "ISO-8601"
    }
  ]
}
```

Privacy: omit email unless viewer is self. **Badge artwork:** current `Badge` schema has no image URL — add `icon_url` or `image_url` if mobile must show art.

### 1.4 Creator public profile (learner)

**Mobile need:** Creator profile screen (subscribe/notify, identity).

**Exists today:**

- `GET /creators/following/` → `FollowedCreator`  
- `POST /creators/{creator_id}/follow/`  
- `Episode.creator` nested object  

**Missing:**

```
GET /api/v1/creators/{creator_id}
```

**200 body (minimum):**

```json
{
  "id": "uuid",
  "username": "string",
  "first_name": "string",
  "last_name": "string",
  "display_name": "string",
  "avatar_url": "string|null",
  "bio": "string",
  "skillworld": "string",
  "followers_count": 0,
  "is_following": false
}
```

Also document full **`Creator`** nested schema on `Episode` (fields + types).

Per-creator notification mode (`all` / `personalized` / `none`) does **not** exist — only global `NotificationPreferences`. Either:

- add `PATCH /me/creator-notification-preferences/{creator_id}` `{ "mode": "all|personalized|none" }`, or  
- document that mobile must drop per-creator notify UI.

### 1.5 Watch-history delete

**Mobile need:** Remove item from history rail/screen.

**Missing:**

```
DELETE /api/v1/me/watch-history/{episode_id}
```

**204** empty. Optionally:

```
DELETE /api/v1/me/watch-history
```

to clear all (settings “clear history” if product needs it).

**GET already exists:** `/me/watch-history` → `WatchHistoryItem[]` with `episode`, `watch_duration_seconds`, `completed`, `viewed_at`. Keep.

### 1.6 Downloads inventory

**Decision required in OpenAPI description:**

- Preferred: **client-local only**. Episodes already expose `download_url`. No server download list.  
- If server-side download entitlements are required later, add:

```
GET /api/v1/me/downloads
POST /api/v1/me/downloads { "episode_id": "uuid" }
DELETE /api/v1/me/downloads/{episode_id}
```

Until then, mark as client-only in API docs so mobile stops waiting.

### 1.7 Share / deep links

**Missing:** content share metadata endpoint.

**Propose (optional):**

```
GET /api/v1/share-links?type=episode|season|creator&id={uuid}
```

```json
{
  "url": "https://skiflux.app/e/{id}",
  "title": "string",
  "description": "string",
  "image_url": "string|null"
}
```

If not product priority, document “client constructs URL from known web base + id” and give the base URL template.

### 1.8 Learner season / playlist catalogue

**Mobile “playlists” map to seasons + episodes.**

**Exists:**

- `GET /seasons/{season_id}/episodes` → `Episode[]`  
- Search returns paginated `seasons`  

**Missing for browse UI:**

```
GET /api/v1/seasons
```

Query: `skillworld`, `page_size`, `cursor|offset`.

**Season object must include HTTP cover URL**, not only Cloudinary public id:

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "cover_url": "https://...",
  "creator": { "id": "uuid", "username": "string", "display_name": "string" },
  "episode_count": 0,
  "skillworld": "string"
}
```

**Purchase / lock state:** `POST /episodes/purchase` exists. Add on `Episode` for the authenticated user:

- `is_purchased`: boolean  
- `is_locked`: boolean  
- `skillcoin_price`: string decimal **or** null if free  

Without `is_purchased` / price, mobile cannot render lock UI correctly from catalogue alone.

### 1.9 Badge artwork

`Badge` schema: `id`, `name`, `description`, `is_active`, `created_at` — **no image**.

**Add:**

- `icon_url`: string uri | null  
or  
- `image_url`: string uri | null  

`UserBadge` remains `{ id, badge, earned_at }`.

### 1.10 Streak multi-week history

`GET /me/streak` → `StreakSummary` with **single** `week` + `milestone`.

Mobile UI seeds multi-week history. Either:

- extend response:

```json
"history": [
  {
    "start_date": "YYYY-MM-DD",
    "end_date": "YYYY-MM-DD",
    "days": [
      {
        "weekday": "Mon",
        "date": "YYYY-MM-DD",
        "day_of_month": 1,
        "status": "completed|missed|upcoming"
      }
    ]
  }
]
```

or document “client only shows current week” so mobile drops multi-week UI.

### 1.11 Settings beyond notification preferences

**Exists:** `GET/PATCH /me/notification-preferences` with booleans:

`new_episodes`, `task_updates`, `comment_replies`, `comment_likes`, `coin_earnings`, `badges`, `platform_announcements`.

**Mobile also stores locally:** `biometricLogin`, `twoFactorAuth`, `autoPlayNext`, `downloadQuality`, `downloadOnWifiOnly`, `appLanguage`, `saveWatchHistory`, `personalisedRecommendations`.

**Biometrics:** `GET /me/biometrics`, `POST /me/biometrics/toggle` → `{ "biometrics_enabled": bool }` — preference only; verification is on-device. Do **not** add biometric session-exchange.

**Missing (implement only if product requires server sync):**

```
GET/PATCH /api/v1/me/app-preferences
```

```json
{
  "auto_play_next": true,
  "download_quality": "high|standard|data_saver",
  "download_on_wifi_only": true,
  "app_language": "en",
  "save_watch_history": true,
  "personalised_recommendations": true
}
```

`twoFactorAuth`: if not in product backend, document unsupported; mobile keeps UI off or local-only.

---

## 2. READY endpoints — shapes mobile will consume (no backend build if already correct)

Implement only if response differs from below; otherwise mobile wires as-is.

### 2.1 Wallet

| Method | Path | Response |
|--------|------|----------|
| GET | `/wallet/my-wallet` | `UserWallet` |
| GET | `/wallet/my-transactions` | `SkillcoinTransaction[]` |
| GET | `/wallet/summary` | `WalletFinancialSummary` |
| GET | `/wallet/cards` | `SavedCard[]` |
| POST | `/wallet/cards/add` | per payment-flows.md |
| DELETE | `/wallet/cards/{id}` | 204 |
| POST | `/wallet/cards/{id}/set-default` | 200 |
| GET | `/wallet/topup/methods` | currencies + rates (string decimals) + saved_cards |
| POST | `/wallet/topup/initiate` | checkout URL / tx_ref (document schema) |
| POST | `/wallet/topup/verify` | status |
| POST | `/wallet/topup/charge-card` | `PaymentTransaction` |
| GET | `/wallet/withdrawals/methods` | `[{method, gateway, flow, label}]` |
| GET | `/wallet/withdrawals/banks?gateway=` | bank list |
| POST | `/wallet/withdrawals/accounts` | `WithdrawalAccount` |
| GET | `/wallet/withdrawals/accounts/list` | `WithdrawalAccount[]` |
| DELETE | `/wallet/withdrawals/accounts/{id}` | 204 |
| POST | `/wallet/withdrawals/connect/onboard` | Stripe URL |
| GET | `/wallet/withdrawals/connect/status` | status |
| POST | `/wallet/withdrawals/request` | body `{ "account_id": "uuid", "amount": "500.00" }` → `WithdrawalRequest` |
| GET | `/wallet/withdrawals/requests` | `WithdrawalRequest[]` |

**Business rules mobile assumes (withdrawal-flows.md):**

- `withdrawable_balance = balance − bonus_balance − active_holds` (server-computed; client never recomputes holds).  
- Request creates hold immediately; status `pending|processing|completed|failed|cancelled|rejected`.  
- `fee = amount × withdrawal_fee_percentage / 100`; `net_amount = amount − fee`; both string decimals.  
- Amount in **Skillcoins**, string decimal.

**UserWallet fields:**

| Field | Type |
|-------|------|
| id | uuid string |
| balance | string decimal |
| bonus_balance | string decimal |
| withdrawable_balance | **number** (double) — exception |
| is_locked | bool |
| is_platform_wallet | bool |
| updated_at | date-time |

**SkillcoinTransaction fields:**

| Field | Type |
|-------|------|
| id | uuid |
| amount | string decimal (signed: + credit, − debit) |
| transaction_type | enum (13 values + future-safe) |
| transaction_type_label | string (display) |
| status | posted\|pending\|cancelled\|refunded\|failed |
| description | string |
| reference_id | uuid \| null |
| created_at | date-time |

### 2.2 Platform tasks (platform-tasks.md)

Base: `/me/platform-tasks` (not admin).

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/me/platform-tasks` | List active + user status |
| POST | `/me/platform-tasks/{task_id}/start` | optional start |
| POST | `/me/platform-tasks/{task_id}/submit` | manual → claimable |
| POST | `/me/platform-tasks/{task_id}/claim` | grant XP + skillcoins |
| POST | `/me/platform-tasks/{task_id}/complete` | legacy submit+claim |

**Lifecycle:** `not_started` → `in_progress` → `claimable` → `claimed`.  
**Rewards only on claim**, not on underlying action.

**List item (`PlatformTaskUser`) — required fields include:**

```
id, slug, title, description, category,
trigger_type, action_type, verification_mode,
progress_target, progress_current,
duration_minutes, external_url, icon, metadata, sort_order,
xp_reward: int,
skillcoin_reward: string decimal,   // e.g. "25.00"
is_active: bool,
status, claimable, completed,
started_at, claimable_at, claimed_at, completed_at
```

### 2.3 Content feed & library

| Method | Path | Use |
|--------|------|-----|
| GET | `/episodes/recommendations` | Home feed primary |
| GET | `/episodes/following/` | Home / subs “new from following” |
| GET | `/me/liked` | Liked videos |
| GET | `/me/saved` | Saved videos |
| GET | `/me/watch-history` | History |
| GET | `/episodes/{id}/comments` | Comments |
| POST | `/episodes/comment` | multipart text/audio |
| GET | `/episodes/watched/tasks` | Learning tasks from watched eps |
| POST | `/episodes/task/submit` | Project/assessment submit |
| GET | `/me/submissions` | Submission history |
| GET | `/search?q=` | Global search |
| POST | `/me/devices` | FCM: `{ "token": string, "platform": "android"|"ios"|"web", "device_id"?: string }` → 201 |

**Episode (critical media fields for mobile):**

| Field | Type | Mobile use |
|-------|------|------------|
| id | uuid | key |
| title, description | string | UI |
| thumbnail_url | uri string | replace local assets |
| video_url | uri string | video_player |
| preview_url | uri string | preview |
| download_url | uri string | offline |
| video_duration | int seconds | progress = watch_duration / this |
| view_count, like_count, comment_count, save_count | int | chrome |
| access_type | enum | free/paid |
| creator | Creator object | author chip |
| tasks | EpisodeTask[] | learning |
| resources | EpisodeResource[] | extras |
| skillworld, season_id, season_title | | filters |

**Comments (`EpisodeComment`):** flat names — `user_first_name`, `user_last_name`, `user_avatar`, `text`, `audio_url`, `like_count`, `is_liked`, `replies`, timestamps. Keep stable; mobile will adapt.

**Streak (`StreakSummary`):**

| Field | Type |
|-------|------|
| current_streak_count | int |
| is_streak_active | bool |
| best_streak | int |
| total_streak_xp_earned | int |
| week | StreakWeek |
| milestone | StreakMilestone |

Day `status`: `completed` | `missed` | `upcoming`.

---

## 3. Client adapter expectations (do not break these)

When changing existing fields:

1. **Snake_case** on the wire; mobile freezed models use `fieldRename: snake` / explicit `@JsonKey`.  
2. **Skillcoin amounts** always string decimals except `withdrawable_balance`.  
3. **Do not** rename `transaction_type_label` — UI displays it verbatim.  
4. **Do not** remove `is_active` from platform task list items.  
5. **Withdrawal amount** is Skillcoins string, not fiat.  
6. **FCM** path is `/me/devices` not `/creator/devices`.  
7. Avatar upload field name is **`avatar`** on `PATCH /me/update`, multipart.  

---

## 4. Acceptance checklist for backend AI

- [ ] OpenAPI 200 schemas added for login/refresh/social tokens, `/me/profile`, `/me/notifications`, `/me/leaderboard`, `/skillworlds`, and key POSTs  
- [ ] Money fields string-decimal except documented withdrawable_balance  
- [ ] Decision recorded for coin packs: new endpoint **or** free-amount-only  
- [ ] Decision recorded for dispute, public user profile, creator GET, watch-history DELETE, downloads, share links, season list + cover_url + purchase flags, badge icon_url, streak history  
- [ ] Envelope policy documented (bare vs `{data}`) and consistent  
- [ ] `/admin/*` and `/creator/*` remain unused by mobile contracts  

**Mobile contact points (read-only for backend AI):**

- Freezed: `skiflux/lib/features/wallet/data/models/*`  
- Freezed: `skiflux/lib/features/tasks/data/models/platform_task.dart`  
- Auth: `skiflux/lib/features/auth/data/auth_endpoints.dart`, `auth_repository.dart`, `auth_tokens.dart`  
- Status narrative: `BACKEND_INTEGRATION_STATUS.md`  
- Tags: `BACKEND_INTEGRATION.md`  

---

## 5. Explicit non-goals

- Do not implement mobile against admin finance processing, admin gamification CRUD, creator studio episode CRUD, or admin moderation.  
- Do not add a server biometric login that accepts device biometrics proof instead of JWT — mobile verifies biometrics locally and reuses stored refresh/access tokens.  
- Do not change money to JSON numbers “for convenience”.  

