# Skiflux Mobile — Backend Integration Status

Reflects the full app rundown against `SkiFlux_API.yaml` — which now lives at
the **repo root** (`SkiFlux_API.yaml`, copied 2026-07-31 from the local
Downloads copy that had been the working reference; the repo copy is the
authoritative reference from here on).
Last revised **2026-07-31** after the backend-integration sweep: most Tier 1
endpoints now have real calls in the app, and two of the original Tier 4
blockers (public creator profile, public user profile) turned out to have
shipped in the spec since the first pass — they've moved to the new
"Resolved" section below.
Tiering follows the existing convention: **Tier 1** ready now · **Tier 2**
needs adapter/wiring on the mobile side · **Tier 3** needs new UI built
against existing endpoints · **Tier 4** blocked — backend work required
before mobile can build anything.

In-code tag inventory (re-grepped 2026-07-31 via
`grep -rn "TODO(backend" lib/`): **23 tags — 13 blocking, 10 minor** (down
from 32; two additional grep hits are prose references, not tags).

---

## Tier 1 — Ready now (endpoint exists, confirmed against spec)

Items marked **wired** have real calls in the app as of 2026-07-31.

**Auth / Onboarding** — all wired
- `POST /auth/signup`, `/auth/verify-register-email`, `/auth/resend-register-otp`
- `POST /profile/complete-onboarding/` (multipart — username, avatar, goal, skillworld, country — single combined call, not per-screen) — **wired 2026-07-31** at the Welcome step; the wizard previously dropped all of this data
- `POST /auth/login`, `/auth/logout` — logout **wired 2026-07-31**: Settings "Log out" now actually signs out (was toast-only); session email cleared on sign-out
- `POST /auth/forgot-password`, `/auth/verify-forgot-password-otp`, `/auth/reset-password`
- `GET/POST /me/biometrics`, `/me/biometrics/toggle` (local device check + backend preference storage) — cold-start race fixed 2026-07-31; the gate honors the stored preference, and a stored session now restores from splash (biometric gate or straight in — no more marketing carousel for returning users)

**Home Feed / Episodes** — wired
- `POST /episodes/like`, `/episodes/save` (toggles) — **wired 2026-07-31** via the library endpoints + engagement provider with rollback; save is now tappable
- `POST /episodes/track-view` (watch progress) — **wired 2026-07-31** via a throttled `ViewTracker` (10s interval, completion at 95%, flush on page change/dispose) — unblocks the watch-history / continue-watching / task-unlock chain
- `POST /episodes/purchase` — **wired 2026-07-31** into the unlock sheet, server-authoritative (failure = modal, no local deduction)
- `POST /episodes/not-interested` — **wired 2026-07-31**, optimistic feed removal
- `GET /episodes/watched/tasks` (unlocked tasks) — **wired 2026-07-31**
- `GET /episodes/{episode_id}/resources/`, `/resources/files/`, `/resources/{id}/link/`

**Creators**
- `POST /creators/{creator_id}/follow/` (single toggle — follow, unfollow, and "subscribe" all use this one call) — **wired 2026-07-31** with optimistic rollback from every entry point (was a local-list edit with a success toast)
- `GET /creators/{creator_id}` — **now exists in spec, wired 2026-07-31** (moved up from Tier 4 §1 — see Resolved)
- `GET /creators/following/`
- `GET /episodes/following/` — subscriptions episode cards now use payload thumbnail URLs

**Tasks** — wired
- `POST /episodes/task/submit` — **wired 2026-07-31**: JSON link submission, multipart file upload, assessment answers keyed by question UUID; grading against real `pass_score_percent`; `accepted_proof_types` drives the file-type allowlist (23-extension hardcode retired)
- `GET /me/submissions` — **wired 2026-07-31**
- `GET/POST /me/platform-tasks`, `.../start`, `.../claim`, `.../complete`, `.../submit` — missions now refresh on every Tasks-tab open; failed claims roll back and surface a modal; successful claims refresh missions + wallet; link tasks open their external URL; rewards display exact Decimals

**Comments** — wired
- `GET /episodes/{id}/comments` + `POST /episodes/comment` (spec body `{episode_id, text}`; single schema handles both text and voice note via `text` / `audio_public_id` / `audio_url` fields) — **wired 2026-07-31**: flat field parsing, voice-note upload, optimistic post with rollback + surfaced errors (was silently swallowed), real counts, no demo-seed substitution when signed in
- `POST /comments/{id}/reply/`, `/comments/like`, `/comments/{id}/report/`

**Profile**
- `GET /wallet/my-wallet`, `/me/streak`, `/me/leaderboard`, `/me/badges` — badges **wired 2026-07-31**: endpoint corrected to `/me/badges`, tolerant parsing, catalogue join hardened
- `GET /me/watch-history`, `/me/saved`, `/me/liked` — saved/liked **wired 2026-07-31** (library endpoints)
- `DELETE /me/watch-history/{episode_id}` + clear-all — **now exists in spec, wired 2026-07-31**, optimistic with rollback (the stale "no endpoint" TODOs are deleted; this closes the old tracker item 58)
- `GET /users/by-username/{username}` — **now exists in spec, wired 2026-07-31** (moved up from Tier 4 §7 — see Resolved)
- `GET /skillworlds` — **wired 2026-07-31**, feeds the skill-world picker; selection persists via `PATCH /me/update` skillworld

**Settings**
- `PATCH /me/update` (profile edit)
- `POST /auth/change-password` — **wired 2026-07-31** with loading + error states (was fake success)
- `GET/PATCH /me/notification-preferences` (app-wide toggles: new_episodes, task_updates, comment_replies, comment_likes, coin_earnings, badges, platform_announcements) — **wired 2026-07-31** with optimistic toggle + rollback + SharedPreferences offline cache (toggles previously reset every launch)

**Payments** — **all wired 2026-07-31** (these flows previously showed success with zero backend calls)
- `GET /wallet/topup/methods`, `POST /wallet/topup/initiate` (with `payment_method: all|card|bank_transfer`), `POST /wallet/topup/verify`, `POST /wallet/topup/charge-card` — top-up is initiate → external checkout hand-off → verify → wallet refresh; client-side coin minting deleted. Checkout links open via `lib/shared/utils/external_link.dart` (clipboard fallback — `url_launcher` not yet an approved dependency; swap point documented in the file)
- `GET/POST/DELETE /wallet/cards*` + `POST /wallet/cards/add` — raw PAN/CVV entry UI **deleted** (PCI); hosted checkout flow instead
- `GET /wallet/withdrawals/banks`, `GET/POST /wallet/withdrawals/accounts*` (server-side account-name verification — the hardcoded 6-bank list and fake "Amara Design" verification are deleted), `DELETE /wallet/withdrawals/accounts/{id}`, `/wallet/withdrawals/request` — fee/net taken from the 201 response; the amount ceiling is the real `withdrawable_balance` (floored); `is_locked` gates the button
- Balances read the real Decimal wallet (demo int-100 seed removed; whole-coin display floors, never rounds up). Fabricated transaction references removed — local rows are pending-only until the backend ledger replaces them (including when empty). `UserWallet` / `SavedCard` / `SkillcoinTransaction` models spec-aligned, codegen re-run

**Search / Notifications** — wired
- `GET /search` — **wired 2026-07-31**: 300ms debounce, stale-response guard, inline (non-modal) errors
- `GET /me/notifications` — **wired 2026-07-31**: session-gated honesty (no seeds for signed-in users; error + retry states). The `data` payload is still `{}`-typed in the spec, so notification tap-routing stays blocked (tag in `notifications_repository.dart`)

---

## Resolved since the first pass — shipped in the spec, wired 2026-07-31

These were Tier 4 blockers in the original rundown; the spec has since grown
the endpoints and the app now calls them.

### R1. Public creator profile (was Tier 4 §1)
`GET /creators/{creator_id}` now exists and the Creator Profile screen is
wired to it (AsyncNotifier with retry). The creator UUID is threaded through
navigation — the old username-as-id bug is fixed. **Residual gap:** the
Playlist/seasons catalogue is still demo-seeded (no viewer-facing
creator-episodes/seasons listing wired yet — episode purchase 404s on demo
ids until the catalogue is backend-driven), so the SkillWorld-sortable
episode list and Playlist tab portions of the original ask remain open.

### R2. Public user profile (was Tier 4 §7)
`GET /users/by-username/{username}` now exists and the public-profile screen
is wired to it. **All** fabricated fallback data (xp 350, rank 12, fake
badges/tasks) is removed — honest empty/error states instead. **Residual
gaps** (tags in `public_user_profile_provider.dart`): `earned_badges`,
`task_done` and `episode_completed` shapes are undocumented; there is no
completed-task list endpoint, so the portfolio section can't be built yet;
`email` is omitted by design while the product wants a contact mechanism —
the gating/rate-limit decision from the original §7 write-up still needs an
answer before that ships.

---

## Tier 3 — Client-only, no backend work needed

These were flagged during the rundown as things to *not* mistakenly build
backend calls for:

- Storage used by downloaded videos, delete-all-downloads button — note: no
  download pipeline exists yet at all; the storage figure shown is fake
- Wifi-only-download enforcement (check network type before download starts)
  — the preference now persists locally but is not yet consulted (no
  pipeline to enforce it in)
- Auto-scroll toggle (home feed) — local preference only, unless cross-device
  sync is wanted later, in which case this moves to Tier 4. Auto-play is
  likewise persisted but not yet consulted by the feed
- App language — local locale switch, unless server-driven copy is wanted
  later. Persisted, but not yet wired to `MaterialApp`'s locale
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
**Resolved 2026-07-31 — moved to §R1 above.** The profile endpoint shipped
and is wired; only the viewer-facing creator episodes/seasons listings
remain open (tracked in R1's residual gap).

### 2. Per-creator post-notification mode
**Blocks:** "All notifications" vs. "Personalized (SkillWorld-only)" control
on the Creator Profile screen.

Still absent from the spec as of the 2026-07-31 re-check. The existing
`/me/notification-preferences` is app-wide, not scoped per followed creator
— cannot be repurposed for this.

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
**Status:** Backend requirement, still open.
**Blocks:** Download-quality picker in Settings.
Need to confirm whether episodes are served as multiple bitrate/resolution
renditions, or a single file. If single-file today, quality selection is not
buildable until multi-rendition support (or on-the-fly transcoding at
download time) is added server-side. (Note the download pipeline itself is
also unbuilt on the mobile side — see Tier 3 notes.)

### 5. Email-verification-on-login toggle
**Status:** Backend requirement, still open.
**Blocks:** "Enable email verification when logging in" setting.
Current auth flow has OTP at signup and at password reset, but no
opt-in "require OTP at every login" mechanism. Needs a user-level flag
checked during the login flow before issuing a session token.

### 6. Request-my-data export + delete account
**Status:** Still not built (compliance-relevant, not optional polish).
**Blocks:** "Request my data" and "Delete account" buttons in Privacy & Data
settings. As of 2026-07-31 the app is honest about this: the fake "Account
Deleted" sheets are replaced with "Coming soon" affordances, and the 2FA row
is hidden (also no endpoint).
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
**Resolved 2026-07-31 — moved to §R2 above.** The by-username endpoint
shipped and is wired; the completed-task list, the undocumented stat-field
shapes and the contact-mechanism decision remain open (tracked in R2's
residual gaps).

### 8. Episode report endpoint
**Status:** New tag 2026-07-31 (`more_menu_sheet.dart`).
**Blocks:** "Report" action in the episode 3-dot menu.
`POST /comments/{id}/report/` exists for comments, but there is no
episode-level report endpoint in the spec.

### 9. Coin pack pricing endpoint
**Status:** Still open (carried over from the tracker's Tier 4).
**Blocks:** Server-driven top-up pack list. The top-up *flow* is fully wired
(initiate/verify), but pack definitions remain client-side fallback pricing
because no backend source exists.

### 10. Transaction dispute endpoint
**Status:** Still open (tag in `transaction_details_screen.dart`).
**Blocks:** "Report" action on a transaction. No dispute/support-ticket-create
endpoint exists in the spec (only ticket *rating*). Expected shape:
`POST /wallet/transactions/{reference}/report → {caseId}`.

---

1. ~~Build the three public creator-profile endpoints~~ — **partially
   shipped**: `GET /creators/{creator_id}` exists and is wired. Still needed:
   viewer-facing `GET /creators/{creator_id}/episodes/?skillworld=<id>` and
   `.../seasons/` so the catalogue can stop being demo-seeded.
2. Add `notifications` mode field per followed creator — confirm the
   three-state (`all` / `skillworld_only` / `off`) design works on your end.
3. Timeline for caption/subtitle support?
4. Are episodes served as single-file or multi-rendition today? If
   single-file, what's the plan/timeline for multi-rendition support?
5. Add opt-in "require OTP at login" as a user flag — any blockers?
6. Build data-export-request and delete-account endpoints — confirm
   soft-delete/anonymization approach and data retention window before
   implementation starts.
7. ~~Build public user profile endpoints~~ — **partially shipped**:
   `GET /users/by-username/{username}` exists and is wired. Still needed:
   documented shapes for `earned_badges`/`task_done`/`episode_completed`, a
   public completed-task list endpoint, and the email-exposure
   gating/rate-limit decision.
8. Add an episode-level report endpoint (mirror of the comment one).
9. Add a mobile-facing coin-pack pricing endpoint (packs are client-side
   fallback until then).
10. Add a transaction dispute/support-ticket endpoint.
11. Document the `NotificationItem.data` payload per notification type so
    tap-routing can be built.
