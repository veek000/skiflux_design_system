# Skiflux Mobile App V2

Flutter mobile app for **Skiflux**, built entirely on the [`skiflux_design_system`](../skiflux_design_system/README.md) package (sibling path dependency). Screens mirror the Figma file [Skiflux](https://www.figma.com/design/863bu2TwQqgzIRgPD8bXkG/Skiflux) "Home & In-app Flow" frames.

## Quick Start

```bash
cd skiflux_mobile_app_v2
flutter pub get
flutter run --dart-define-from-file=config/env/dev.json
```

> **Note**: Copy `config/env/dev.json.example` to `config/env/dev.json` for local development. See [EMULATOR_GUIDE.md](EMULATOR_GUIDE.md) for Windows/Android-emulator setup.

## Project Layout

```
lib/
  main.dart                           # Entry point — initializes EnvConfig, Sentry SDK, and runApp(ProviderScope)
  app/
    app.dart                          # SkifluxMobileAppV2 root widget (MaterialApp + theme)
  config/
    env_config.dart                   # Environment & secrets configuration reader
  features/
    auth/
      auth_flow.dart                  # Authentication flow (onboarding, login, signup, OTP)
    home/
      home_screen.dart                # Video feed, top bar, bottom nav (Figma 198:13684)
      sheets/
        buy_coins_sheet.dart          # Coin purchase overlay
        comments_sheet.dart           # Comments overlay (198:13767)
        episode_resources_sheet.dart  # Episode learning resources
        episode_unlock_sheet.dart     # Episode SkillCoin unlock modal
        more_menu_sheet.dart          # ⋯ More/actions overlay (1256:27071)
        notify_settings_sheet.dart    # Creator notification preferences
        playback_speed_sheet.dart     # Video playback speed controls
      data/
        home_feed_store.dart          # Home video feed state provider
    leaderboard/
      leaderboard_screen.dart         # League leaderboard + podium (1256:25612)
      data/
        leaderboard_store.dart        # Leaderboard rankings data
    notifications/
      notifications_screen.dart       # All/unread notification tabs (1256:30744)
      data/
        notifications_store.dart      # Notifications state notifier
    playlists/
      playlist_screen.dart            # Playlist detail page (198:14183)
      playlist_episode_row.dart       # Shared episode row
      playlist_description_sheet.dart # Full description sheet
      playlist_menu_sheet.dart        # Episode menu sheet (1256:27214)
      data/
        playlists_store.dart          # Playlists + player prefs provider
    profile/
      profile_screen.dart             # Creator profile (198:14048)
      my_profile_screen.dart          # Signed-in My Profile tab
      public_user_profile_screen.dart # Learner profile (3092:14632)
      badges_screen.dart              # Earned achievement badges
      downloads_screen.dart           # Offline downloaded videos
      liked_videos_screen.dart        # Liked episodes collection
      saved_videos_screen.dart        # Saved playlists/episodes
      watch_history_screen.dart       # Recently watched video history
      library_episode_row.dart        # Library video list row
    search/
      search_screen.dart              # Search input + recent history
      search_results_screen.dart      # Search results grid/list
      search_result_widgets.dart      # Filter chips & result cards
      data/
        search_index.dart             # Pure demo search index
        recent_searches_store.dart    # Persistent search recents
    settings/
      settings_screen.dart            # Settings menu root
      edit_profile_screen.dart        # Profile details editor
      payment_methods_screen.dart     # Saved cards & payment methods
      add_card_sheet.dart             # Add new payment card modal
      bank_accounts_screen.dart       # Linked bank accounts
      notification_settings_screen.dart # Push notification toggles
      download_quality_screen.dart    # Video download quality options
      app_language_screen.dart        # Language selector
      security_screen.dart            # Security & biometric options
      change_password_screen.dart     # Password update form
      help_centre_screen.dart         # FAQ & support contact
      privacy_data_screen.dart        # Privacy policy & data controls
    streaks/
      streak_screen.dart              # Streak tracker (Streak Flow 3092:14400)
      milestone_sheet.dart            # Milestone celebration overlay (2259:13266)
      week_picker_sheet.dart          # Streak history week selector
      data/
        streaks_store.dart            # Streak progress state provider
    subscriptions/
      subscriptions_screen.dart       # Creator subscriptions & feed
      all_subscriptions_screen.dart   # Full creator directory list
      subscription_widgets.dart       # Story row & feed card widgets
      filter_sheet.dart               # Feed category & sorting filter
      data/
        subscriptions_store.dart      # Subscription state provider
    tasks/
      tasks_screen.dart               # Tasks tab (Task Flow 1256:12977)
      task_shared_widgets.dart        # Reward pill & episode row widgets
      submission_task_screen.dart     # Project task submission & upload
      quiz_intro_screen.dart          # Assessment intro screen
      quiz_assessment_screen.dart     # Timed quiz assessment
      quiz_result_screen.dart         # Pass/fail result summary
      data/
        tasks_store.dart              # Learning & mission task provider
    wallet/
      wallet_screen.dart              # SkillCoin balance & transaction history
      buy_coins_screen.dart           # SkillCoin purchase packages
      withdraw_screen.dart            # Earnings cashout to bank
      add_bank_sheet.dart             # Link new bank account sheet
  shared/
    error_handling/
      error_handler.dart              # Error classification & crash reporting hook
    sheets/
      skiflux_sheet.dart              # showSkifluxSheet — blur + scrim bottom-sheet shell
      share_sheet.dart                # Share overlay — home, streaks, quiz result
      confirm_sheet.dart              # Action confirmation modal sheet
      success_sheet.dart              # Success celebration modal sheet
    toast/
      skiflux_toast.dart              # Floating SnackBar toast notifications
    widgets/
      video_feed_card.dart            # Video player card
      playlist_deck.dart              # Stacked playlist thumbnail
assets/                               # Feed placeholders, streak decor, badges
config/                               # Environment configuration files (dev, prod, ci)
test/                                 # Unit, widget, and flow test suites
```

## Tasks Tab Navigation Map

| Screen | Entry Path | Figma Reference |
|---|---|---|
| Learning / Mission / Marketplace | Bottom nav **Tasks** | TF15 / 14 / 13 |
| Submission detail | Pending / Action Needed → Start / Fix & Resubmit | TF12–09 |
| Quiz intro → assessment → result | Quiz Start Task / View Result | TF08–01 |
| View Result | Any **Completed** card | TF01 (result shell) |

## Conventions

- **Feature Ownership**: Each domain lives in `lib/features/<feature_name>/` and owns its screens, sheets, and widgets.
- **Shared Code**: Anything consumed by two or more feature domains lives under `lib/shared/`.
- **Design System Rules**: All colors, typography, spacing, radii, icons, and base buttons/inputs come strictly from `package:skiflux_design_system`.
- **State Management**: The application is 100% migrated to **Riverpod** (`flutter_riverpod`).

## Full Architecture & Reference Documentation

For detailed internal documentation, consult [PROJECT.md](../PROJECT.md):
- **[Current Architecture](../PROJECT.md#current-architecture-as-of-2026-07-19)**: State management rules and complete Riverpod provider inventory table.
- **[Error Handling & Crash Reporting](../PROJECT.md#error-handling--crash-reporting)**: `ErrorDisplay` classifier, toast vs modal decision matrix, and Sentry crash reporting integration.
- **[Secrets & Environment Configuration](../PROJECT.md#secrets--environment-configuration)**: Compile-time `--dart-define-from-file` strategy, file structure, and `EnvConfig` usage.
- **[Session Log](../PROJECT.md#session-log)**: Chronological history of implementation phases, refactoring passes, and verification logs.
