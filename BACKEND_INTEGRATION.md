# Skiflux Mobile — Backend Integration Status

Reflects the full app rundown against `SkiFlux_API.yaml` as of this pass.
Tiering follows the existing convention: **Tier 1** ready now · **Tier 2**
needs adapter/wiring on the mobile side · **Tier 3** needs new UI built
against existing endpoints · **Tier 4** blocked — backend work required
before mobile can build anything.

---

## Tier 1 — Ready now (endpoint exists, confirmed against spec)

**Auth / Onboarding**
- `POST /auth/signup`, `/auth/verify-register-email`, `/auth/resend-register-otp`
- `POST /profile/complete-onboarding/` (multipart — username, avatar, goal, skillworld, country — single combined call, not per-screen)
- `POST /auth/login`, `/auth/logout`
- `POST /auth/forgot-password`, `/auth/verify-forgot-password-otp`, `/auth/reset-password`
- `GET/POST /me/biometrics`, `/me/biometrics/toggle` (local device check + backend preference storage)

**Home Feed / Episodes**
- `POST /episodes/like`, `/episodes/save` (toggles)
- `POST /episodes/track-view` (watch progress)
- `GET /episodes/watched/tasks` (unlocked tasks)
- `GET /episodes/{episode_id}/resources/`, `/resources/files/`, `/resources/{id}/link/`

**Creators**
- `POST /creators/{creator_id}/follow/` (single toggle — follow, unfollow, and "subscribe" all use this one call)
- `GET /creators/following/`
- `GET /episodes/following/`

**Tasks**
- `POST /episodes/task/submit`
- `GET/POST /me/platform-tasks`, `.../start`, `.../claim`, `.../complete`, `.../submit`

**Comments**
- `POST /episodes/comment` (single schema handles both text and voice note via `text` / `audio_public_id` / `audio_url` fields)
- `POST /comments/{id}/reply/`, `/comments/like`, `/comments/{id}/report/`

**Profile**
- `GET /wallet/my-wallet`, `/me/streak`, `/me/leaderboard`, `/me/badges`
- `GET /me/watch-history`, `/me/saved`, `/me/liked`

**Settings**
- `PATCH /me/update` (profile edit)
- `POST /auth/change-password`
- `GET/PATCH /me/notification-preferences` (app-wide toggles: new_episodes, task_updates, comment_replies, comment_likes, coin_earnings, badges, platform_announcements)

**Payments (from prior sessions)**
- `GET /wallet/topup/methods`, `POST /wallet/topup/initiate` (with `payment_method: all|card|bank_transfer`), `POST /wallet/topup/verify`, `POST /wallet/topup/charge-card`
- `GET/POST/DELETE /wallet/cards*`
- `GET/POST /wallet/withdrawals/accounts*`, `/wallet/withdrawals/request`

**Search / Notifications**
- `GET /search`
- `GET /me/notifications`

---

## Tier 3 — Client-only, no backend work needed

These were flagged during the rundown as things to *not* mistakenly build
backend calls for:

- Storage used by downloaded videos, delete-all-downloads button
- Wifi-only-download enforcement (check network type before download starts)
- Auto-scroll toggle (home feed) — local preference only, unless cross-device
  sync is wanted later, in which case this moves to Tier 4
- App language — local locale switch, unless server-driven copy is wanted
  later
- Native share sheet — no tracking endpoint exists or is needed unless
  share-count analytics become a requirement
- 3-dot "More menu" visibility logic (View Task / Download Asset shown or
  hidden) — computed client-side from data already fetched (watch progress +
  resource list), not a new call
- Help center: in-app webview (points at support tool URL), email support
  (native mail composer), blog links (static/CMS), app store rating link
  (platform deep link) — none need custom Skiflux backend endpoints

---

## Tier 4 — Blocked: backend work required

### 1. Public creator-profile endpoint family
**Blocks:** Creator Profile screen entirely (arrow tap from home feed top
bar), Playlist/seasons tab, SkillWorld-sortable episode list.

Current `creator/list-episodes` and `creator/list-seasons` are creator-owner
endpoints (a creator managing their own dashboard), not viewer-facing. No
`creators/{creator_id}/...` equivalent exists for another user to view.

**Recommended shape** (mirrors the admin equivalent structurally, minus
admin-only analytics):
- `GET /creators/{creator_id}/profile/` → name, username, avatar, bio,
  skillworld, follower_count, is_following
- `GET /creators/{creator_id}/episodes/?skillworld=<id>` → paginated,
  filterable by SkillWorld
- `GET /creators/{creator_id}/seasons/` → paginated seasons for Playlist tab

**Priority: highest** — this blocks an entire screen, not just a field.

### 2. Per-creator post-notification mode
**Blocks:** "All notifications" vs. "Personalized (SkillWorld-only)" control
on the Creator Profile screen.

The existing `/me/notification-preferences` is app-wide, not scoped per
followed creator — cannot be repurposed for this.

**Recommended shape:**
`PATCH /creators/{creator_id}/notifications/` with body
`{"mode": "all" | "skillworld_only" | "off"}`. Recommend including `"off"`
as a third state even though it wasn't explicitly requested — once "all vs.
filtered" exists, a mute option is a near-free addition and users will
expect it. Also return this value inline on `GET /creators/following/` so
the client isn't making a separate call per creator to display current
state.

### 3. Caption/subtitle support
**Status:** Backend has a plan for this, not yet implemented.
**Blocks:** Caption toggle on video player.
No subtitle/caption field currently exists on the `Episode` schema. Mobile
should not attempt to build a caption toggle UI ahead of this — there's
nothing to toggle yet.

### 4. Download quality tiers (480p / 720p / 1080p)
**Status:** New backend requirement, added this session.
**Blocks:** Download-quality picker in Settings.
Need to confirm whether episodes are served as multiple bitrate/resolution
renditions, or a single file. If single-file today, quality selection is not
buildable until multi-rendition support (or on-the-fly transcoding at
download time) is added server-side.

### 5. Email-verification-on-login toggle
**Status:** New backend requirement, added this session.
**Blocks:** "Enable email verification when logging in" setting.
Current auth flow has OTP at signup and at password reset, but no
opt-in "require OTP at every login" mechanism. Needs a user-level flag
checked during the login flow before issuing a session token.

### 6. Request-my-data export + delete account
**Status:** New backend requirement, added this session — confirmed not
built (compliance-relevant, not optional polish).
**Blocks:** "Request my data" and "Delete account" buttons in Privacy & Data
settings.
Recommended shape:
- `POST /me/data-export-request` → triggers async job, result emailed to
  user's registered address (NDPR-relevant — mirrors compliance handling
  already established for email templates elsewhere in the product)
- `POST /me/delete-account` (or `DELETE /me`) → should trigger the same kind
  of soft-delete/anonymization flow most compliance regimes require, not a
  hard delete — confirm data retention requirements with backend dev before
  they implement this, since the "how" here has legal implications beyond
  just wiring an endpoint.

### 7. Public user profile (viewable by others — job-portfolio positioning)
**Status:** New feature, confirmed intentional — reverses an earlier "Public
Profile MVP" decision that had removed follow/message and the skills
section. Platform is positioned as a proof-of-work job portfolio, so users
want to be findable and contactable.

**Blocks:** Tapping a user from Search results or from a comment (avatar/name)
to view their public profile.

No endpoint exists for this today — everything under `/profile/me/...` is
self-only, no `/users/{id}/...` equivalent.

**Recommended shape:**
- `GET /users/{user_id}/profile/` → username, avatar, xp, leaderboard_position,
  skills[], completed_task_count
- `GET /users/{user_id}/completed-tasks/` → paginated; each item tagged
  `project` or `assessment` — project items include `preview_url`/`file_url`,
  assessment items include only `score` (no preview/download). This is the
  same rule already locked for the user's own profile — just extend its
  scope to public viewing rather than deciding it fresh.
- Contact mechanism — **flagged, needs a decision, not just an endpoint:**
  raw email is confirmed wanted (recruiters need to reach users directly),
  but this is a real spam/scraping risk specifically *because* it's a job
  platform (this is exactly the profile type scraper bots target hardest).
  Two mitigations worth considering before backend builds this open:
  - Gate visibility behind viewer authentication (logged-in users only, not
    anonymous API access)
  - Rate-limit the public-profile endpoint per viewer regardless
  If neither is wanted, confirm explicitly that fully open, ungated email
  exposure is the deliberate choice before backend ships it that way.

**Priority: high** — blocks two entry points (search results, comment
avatars), not just one screen.

1. Build the three public creator-profile endpoints above — any concern with
   the recommended shape, or a preference for a different structure?
2. Add `notifications` mode field per followed creator — confirm the
   three-state (`all` / `skillworld_only` / `off`) design works on your end.
3. Timeline for caption/subtitle support?
4. Are episodes served as single-file or multi-rendition today? If
   single-file, what's the plan/timeline for multi-rendition support?
5. Add opt-in "require OTP at login" as a user flag — any blockers?
6. Build data-export-request and delete-account endpoints — confirm
   soft-delete/anonymization approach and data retention window before
   implementation starts.
7. Build public user profile endpoints (§Tier 4 #7) — confirm whether raw
   email exposure should be gated to authenticated viewers, rate-limited, or
   fully open as-is.
