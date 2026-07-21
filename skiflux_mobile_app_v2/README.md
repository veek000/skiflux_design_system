# Skiflux Mobile App V2

Flutter mobile app for **Skiflux**, built entirely on the
[`skiflux_design_system`](../skiflux_design_system/README.md) package (sibling path
dependency). Screens mirror the Figma file
[Skiflux](https://www.figma.com/design/863bu2TwQqgzIRgPD8bXkG/Skiflux)
"Home & In-app Flow" frames.

## Run it

```
cd skiflux_mobile_app_v2
flutter pub get
flutter run
```

See [EMULATOR_GUIDE.md](EMULATOR_GUIDE.md) for Windows/Android-emulator setup.

## Project layout

```
lib/
  main.dart                    # entry point only — runApp
  app/
    app.dart                   # SkifluxMobileAppV2 root widget (MaterialApp + theme)
  features/
    home/
      home_screen.dart         # video feed, top bar, bottom nav (Figma 198:13684)
      sheets/
        comments_sheet.dart    # comments overlay (198:13767)
        more_menu_sheet.dart   # more/actions overlay (1256:27071)
    profile/
      profile_screen.dart            # creator profile (198:14048)
      public_user_profile_screen.dart # learner profile (3092:14632)
      my_profile_screen.dart         # signed-in My Profile tab
    leaderboard/
      leaderboard_screen.dart  # league leaderboard + podium (1256:25612)
    notifications/
      notifications_screen.dart # all/unread tabs + sections (1256:30744)
    tasks/
      tasks_screen.dart           # Tasks tab (Task Flow 1256:12977)
      task_shared_widgets.dart    # reward pill, episode row, open episode
      submission_task_screen.dart # submission detail + file upload
      quiz_intro_screen.dart      # quiz "Before you start"
      quiz_assessment_screen.dart # timed quiz + review mode
      quiz_result_screen.dart     # pass/fail / task-completed result
      data/tasks_store.dart       # learning + mission demo store
    playlists/
      playlist_menu_sheet.dart    # EP chip sheet (1256:27214, playing-row highlight)
      playlist_screen.dart        # playlist detail page (198:14183)
      playlist_episode_row.dart   # shared episode row (detail page + menu sheet)
      data/playlists_store.dart   # episodes + SkillCoin wallet + player prefs
    home/sheets/
      more_menu_sheet.dart        # ⋯ menu (wired)
      playback_speed_sheet.dart
      episode_unlock_sheet.dart
      episode_resources_sheet.dart
      notify_settings_sheet.dart
    streaks/
      streak_screen.dart       # streak tracker (Streak Flow 3092:14400)
      milestone_sheet.dart     # milestone celebration overlay (2259:13266)
    search/ subscriptions/     # see PROJECT.md work log
  shared/
    sheets/
      skiflux_sheet.dart       # showSkifluxSheet — blur + scrim bottom-sheet shell
      share_sheet.dart         # share overlay (198:13910) — home, streaks, quiz result
    widgets/
      video_feed_card.dart     # video player card (home feed + episode player modal)
      playlist_deck.dart       # stacked playlist thumbnail (search, profile, playlist cover)
assets/                        # feed placeholders, streak decor, badges
test/                          # widget smoke tests
```

### Tasks tab (quick map)

| Screen | Entry | Figma |
|--------|--------|--------|
| Learning / Mission / Marketplace | Bottom nav **Tasks** | TF15 / 14 / 13 |
| Submission detail | Pending / Action Needed → Start / Fix & Resubmit | TF12–09 |
| Quiz intro → assessment → result | Quiz Start Task / View Result | TF08–01 |
| View Result | Any **Completed** card | TF01 (result shell) |

Packages (app): `file_picker` (upload), `share_plus` available; Share Result uses in-app `showShareSheet`.

Conventions:

- **One folder per feature** under `features/`; a feature owns its screen plus
  any sheets/widgets only it uses.
- Anything used by two or more features lives in `shared/`.
- All colors, text styles, spacing, radii, icons, and components come from
  `package:skiflux_design_system` — no hardcoded design values in app code.

Full project documentation and handoff notes: [../PROJECT.md](../PROJECT.md)
