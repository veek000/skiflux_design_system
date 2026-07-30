# Skiflux Mobile App — User Journey

Status key: ✅ confirmed against `SkiFlux_API.yaml` · ⚠️ backend gap (see
`BACKEND_INTEGRATION.md` for detail) · 🖥️ client-only, no backend call

---

## 1. Onboarding & Auth

1. **Signup** — email, first name, last name, password + confirm.
   ✅ `POST /auth/signup`
2. **Email OTP** — 6-digit code sent to email.
   ✅ `POST /auth/verify-register-email` (resend via `/auth/resend-register-otp`)
3. **Username + profile picture** (screen 1 of onboarding wizard)
4. **"Why are you using Skiflux" goal picker** (screen 2)
5. **SkillWorld interest picker** (screen 3)
   - Steps 3–5 are collected client-side across three screens, then submitted
     as **one combined call** at the end of the wizard:
     ✅ `POST /profile/complete-onboarding/` (multipart — avatar is a file;
     body includes `username`, `avatar`, `goal[]`, `skillworld[]`, `country`)
   - Do not persist partial progress to the backend after each screen —
     there's no partial-save endpoint, and none is needed.
6. **Home feed** — onboarding complete.

### Login
- Password login: ✅ `POST /auth/login`
- Biometric (if enabled in settings): device-level Face ID/fingerprint check
  happens 🖥️ client-only; app then uses stored credentials/token to complete
  ✅ `POST /auth/login` — biometrics never talks to the backend directly, it's
  a local gate in front of the same login call.
- "Use password instead" fallback: always available, same login endpoint.
- Forgot password: email → ✅ `POST /auth/forgot-password` → OTP →
  ✅ `POST /auth/verify-forgot-password-otp` → new password →
  ✅ `POST /auth/reset-password` → login.
- ⚠️ **Email-verification-on-login toggle** (opt-in OTP at every login) —
  not present in current auth flow. Backend requirement, not yet built.

---

## 2. Home Feed

- Video plays, unmuted by default (intentional design decision, not a bug).
- **Like** — ✅ `POST /episodes/like` (toggle)
- **Save** — ✅ `POST /episodes/save` (toggle)
- **Share** — 🖥️ native OS share sheet, no backend call (confirm this is the
  intent — no share-tracking endpoint exists if analytics are wanted later)
- **Caption toggle** — ⚠️ no subtitle/caption data on the `Episode` schema.
  Planned but not yet built on the backend.
- **Download (video, for offline)** — quality tiers ⚠️ pending backend
  (see §6). Storage used by downloads is 🖥️ client-only (device filesystem),
  no backend call needed.
- **Watch progress → task unlock**: client posts progress periodically —
  ✅ `POST /episodes/track-view` (`watch_duration_seconds`, `completed`).
  Once the 50% threshold is met server-side, the episode's task becomes
  visible via ✅ `GET /episodes/watched/tasks`.
- **Top bar**: creator name + username.
  - Follow icon (hidden if already following) — ✅
    `POST /creators/{creator_id}/follow/` (single toggle endpoint; same call
    handles follow *and* unfollow, no separate endpoints).
  - Tapping the arrow beside the name → Creator Profile (see §4). ⚠️ **The
    endpoint powering that screen doesn't exist yet** — see Backend
    Integration doc, this is the top-priority gap.

### More menu (3-dot — appears in home feed cards and in the season-episode modal)
- Same reusable component in both contexts.
- **View Task** button — 🖥️ client-side visibility logic: hidden unless (a)
  watch progress ≥ 50% *and* (b) the episode has an attached task. Both facts
  are already available from calls the client has made — no new endpoint
  needed to decide visibility.
- **Download Asset** button — 🖥️ client-side visibility logic: hidden if the
  episode has no resources. Data comes from ✅
  `GET /episodes/{episode_id}/resources/`.

---

## 3. Tasks

### Learning Tasks (Project-based or Assessment/CBT)
- Gated by 50% watch (see §2). Once unlocked:
  ✅ `POST /episodes/task/submit`
- Attached per-episode, surfaced via `watched/tasks`.

### Missions (platform tasks — ungated, coin-earning)
- Examples: follow Skiflux's social accounts, refer a friend, complete
  profile, link a social account, first deposit.
- ✅ Maps to `/me/platform-tasks` family:
  `GET /me/platform-tasks`, `POST .../start`, `.../claim`, `.../complete`,
  `.../submit`.
- ⚠️ Confirm with backend that `link_social` (the existing trigger type) is
  actually what fires for "follow Skiflux on our socials" — don't assume the
  name matches without checking.

### Marketplace
- Coming soon — nothing in spec, consistent with current product status.

---

## 4. Creator Profile

⚠️ **Backend gap — recommended design (not yet built):**
- `GET /creators/{creator_id}/profile/` — profile header (name, username,
  avatar, bio, SkillWorld, follower count, `is_following`)
- `GET /creators/{creator_id}/episodes/?skillworld=` — paginated episode
  list, filterable by SkillWorld tag
- `GET /creators/{creator_id}/seasons/` — paginated seasons (Playlist tab)

Once built:
- **Recent episodes** tab, sortable/filterable by SkillWorld tag.
- **Playlist tab** — all seasons. Save/download/share an entire season
  (season-level actions likely reuse the same like/save endpoints scoped to
  all episodes in the season — confirm with backend whether a season-level
  bulk-save endpoint is needed or whether the client should loop per-episode
  calls; not yet decided).
- Individual episode tap → opens as a modal, reusing the same player and
  3-dot More menu component from the home feed.
- **Subscribe / Unfollow button** — same toggle endpoint as the home feed
  follow icon: ✅ `POST /creators/{creator_id}/follow/`. Not a separate
  "subscribe" call.
- **Post notification mode** (All / Personalized-to-my-SkillWorld / Off) —
  ⚠️ backend gap, recommended design:
  `PATCH /creators/{creator_id}/notifications/` with
  `{"mode": "all" | "skillworld_only" | "off"}`, value also returned inline
  on the followed-creators list so the client doesn't need an extra call per
  creator.

---

## 5. Subscriptions

- Followed creators list — ✅ `GET /creators/following/`
- Latest episodes from followed creators — ✅ `GET /episodes/following/`
- Per-creator recent uploads + seasons on this screen route through the same
  creator-profile endpoints from §4 once built.

---

## 6. Comments

- Text or voice note — ✅ single unified endpoint/schema
  (`EpisodeComment` has both `text` and `audio_public_id`/`audio_url` on the
  same object — not two separate comment types).
- Create: `POST /episodes/comment` · Reply: `POST /comments/{id}/reply/` ·
  Like: `POST /comments/like` · Report: `POST /comments/{id}/report/`

---

## 6a. Public User Profile (viewable via Search or Comments)

⚠️ **Backend gap** — see `BACKEND_INTEGRATION.md` Tier 4 #7.

- **Entry points:** tapping a user from Search results, or tapping a
  commenter's name/avatar in a video's comment section.
- Shows: XP, leaderboard position, skills, completed task count and list.
- Completed tasks: project-type items show a preview/view-file link;
  assessment-type items show only the score (no preview/download) — same
  rule already applied to the user's own profile, just extended to public
  viewing.
- Contact: raw email intentionally visible/contactable (platform is
  positioned as a proof-of-work job portfolio — users want to be found by
  recruiters). Gating/rate-limiting approach still pending confirmation with
  backend, see integration doc.
- This reverses an earlier "Public Profile MVP" decision that had removed
  follow/message and skills — noted for continuity so this isn't flagged as
  a regression later.

---

## 7. Profile

- Wallet balance, XP, streak, leaderboard position, badges, downloaded
  videos, watch history, saved, liked — all ✅ confirmed:
  `/wallet/my-wallet`, `/me/streak`, `/me/leaderboard`, `/me/badges`,
  `/me/watch-history`, `/me/saved`, `/me/liked`.
- Downloaded videos list is 🖥️ client-side (on-device), not a backend list.

---

## 8. Settings

| Setting | Status | Notes |
|---|---|---|
| Edit profile (name, username) | ✅ | `PATCH /me/update` |
| Change password | ✅ | `POST /auth/change-password` |
| Biometric toggle | ✅ | `/me/biometrics`, `/me/biometrics/toggle` — device does the actual check, backend only stores preference |
| Email-verification-on-login | ⚠️ | backend requirement, not yet built |
| Wallet (balance, history, withdraw, add funds) | ✅ | see `BACKEND_INTEGRATION.md` payment section |
| Payment methods (saved cards) | ✅ | `/wallet/cards*` |
| Withdrawal accounts | ✅ | `/wallet/withdrawals/accounts*` |
| Notification toggles (app-wide) | ✅ | `/me/notification-preferences` |
| Download quality (480/720/1080p) | ⚠️ | backend requirement — needs multi-rendition video URLs; not yet built |
| Storage used, delete-all-downloads | 🖥️ | client-only, device filesystem |
| Wifi-only download toggle | 🖥️ | client-only, checks network type before starting download |
| Auto-scroll toggle | 🖥️ | client-only local preference (unless cross-device sync desired later) |
| App language | 🖥️ | client-only locale switch, unless server-driven copy is wanted later |
| Save watch history toggle | ⚠️ | must be backend — affects recommendation engine server-side, a client-only flag does nothing |
| Personalized recommendations toggle | ⚠️ | must be backend, same reason |
| Request my data (export via email) | ⚠️ | backend requirement, not yet built |
| Privacy policy / Terms of use | ✅ | privacy policy screen already exists in app, don't rebuild |
| Delete account | ⚠️ | backend requirement, not yet built |
| Help center — in-app webview live chat | 🖥️ | webview pointing at support tool URL, no custom backend needed beyond what support tooling provides |
| Help center — email support | 🖥️ | opens native mail composer |
| Help center — blog links | 🖥️ | static/CMS-driven links |
| App store rating link | 🖥️ | platform-specific deep link (App Store / Play Store) |
| Logout | ✅ | `POST /auth/logout` |

---

## 9. Search & Notifications

- Search (episodes, playlists/seasons, creators/users) — ✅ `GET /search`
- Notifications feed — ✅ `GET /me/notifications`

---

## Open items tracked in BACKEND_INTEGRATION.md
1. Public creator-profile endpoint family (§4)
2. Per-creator notification mode (§4)
3. Caption/subtitle support (§2) — planned, not yet built
4. Download quality tiers / multi-rendition video (§8)
5. Email-verification-on-login toggle (§1, §8)
6. Request-my-data export + delete account (§8)
7. Public user profile (§6a) — new feature, endpoint family + email
   exposure/gating decision
