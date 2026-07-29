# FCM push notifications — Step 0 findings + Step 1 proposal

> Generated for the client receive-side FCM task.  
> **No code edits were made.** Waiting on package approval + Android package-name decision.

---

## Step 0 — Ground truth

Package policy lives in `AGENTS.md` (not `CLAUDE.md`): do not add packages without explicit confirmation.

### 1. Root `android/build.gradle.kts` — Kotlin 1.8 pin (verbatim)

```kotlin
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
        }
    }
}
```

- Kotlin plugin in `settings.gradle.kts`: `org.jetbrains.kotlin.android` **2.2.20**
- This pin exists because `sentry_flutter`'s native module refused to compile against the default 1.6
- **Rule:** adding `google-services` must not perturb this block

### 2. `android/app/build.gradle.kts`

| Field | Value |
|--------|--------|
| Plugins | `com.android.application`, `kotlin-android`, `dev.flutter.flutter-gradle-plugin` |
| `namespace` | `com.skiflux.skiflux_mobile_app_v2` |
| `applicationId` | `com.skiflux.skiflux_mobile_app_v2` |
| SDK versions | Flutter defaults (`compileSdk` / `minSdk` / `targetSdk`) |
| Java / Kotlin target | 17 |

No `google-services` plugin yet.

### 3. `AndroidManifest.xml` — current permissions

Declared today:

- `RECORD_AUDIO` — voice-note recording (`audio_waveforms`)
- `USE_BIOMETRIC` — biometric sign-in gate (`local_auth`)

Existing comment (minimal-permission posture — leave intact):

> Avatar picking (`image_picker`) and task-submission files (`file_picker`) intentionally declare NO permissions: image_picker rides the system photo picker (Android 13+) / ACTION_GET_CONTENT and camera-capture intents, and file_picker rides the Storage Access Framework — none of which need READ_MEDIA_* or CAMERA. Declaring CAMERA here would *impose* a runtime grant requirement on the capture intent.

Not present yet:

- `POST_NOTIFICATIONS`
- `com.google.firebase.messaging.default_notification_icon` meta-data

### 4. `MainActivity.kt`

```kotlin
class MainActivity : FlutterFragmentActivity()
```

Confirmed `FlutterFragmentActivity` (required by `local_auth` biometric prompt). **Do not change.**

### 5. `pubspec.yaml` — current dependencies

**Runtime:** `skiflux_design_system` (path), `cupertino_icons`, `shared_preferences`, `dio`, `flutter_secure_storage`, `flutter_svg`, `timeago`, `file_picker`, `share_plus`, `flutter_riverpod`, `modal_bottom_sheet`, `sentry_flutter`, `lottie`, `json_annotation`, `freezed_annotation`, `decimal`, `local_auth`, `image_picker`

**Dev:** `flutter_test`, `flutter_lints`, `flutter_launcher_icons`, **`freezed: 3.2.5` (exact pin)**, `build_runner`, `json_serializable`

- freezed exact pin is the precedent for how FCM packages should be pinned
- No Firebase packages yet

### 6. Config files presence

| File | In project? | In Downloads? |
|------|-------------|---------------|
| `android/app/google-services.json` | **Absent** | Present at `C:\Users\timmy\Downloads\google-services.json` |
| `ios/Runner\GoogleService-Info.plist` | **Absent** | Present at `C:\Users\timmy\Downloads\GoogleService-Info.plist` |

Configs are available to copy. Never scaffold placeholders.

Firebase project (throwaway): **`skiflux-fcm-test`**, project number `829997105528`.

### 7. Package-name comparisons (critical)

#### Android — **MISMATCH**

| Source | Literal value |
|--------|----------------|
| `applicationId` (`android/app/build.gradle.kts`) | `com.skiflux.skiflux_mobile_app_v2` |
| `package_name` (`google-services.json`) | `com.skiflux.skifluxMobileAppV2` |

Underscores vs camelCase. Mismatch fails **silently** at FCM registration — no error, no notification, everything else green.

#### iOS — **MATCH**

| Source | Literal value |
|--------|----------------|
| `PRODUCT_BUNDLE_IDENTIFIER` (pbxproj) | `com.skiflux.skifluxMobileAppV2` |
| `BUNDLE_ID` (`GoogleService-Info.plist`) | `com.skiflux.skifluxMobileAppV2` |

### 8. Notification icon

`ic_notification.png` present in all five densities:

- `res/drawable-mdpi/`
- `res/drawable-hdpi/`
- `res/drawable-xhdpi/`
- `res/drawable-xxhdpi/`
- `res/drawable-xxxhdpi/`

### 9. iOS other ground truth

- `Info.plist` has camera / Face ID / mic / photo library usage strings
- No `UIBackgroundModes` / `remote-notification` yet
- No Mac in this environment → no `pod install`, no Xcode capability edits, no device test

### Precedents used for design of later steps

| Concern | Precedent |
|---------|-----------|
| Init order | `main.dart`: binding → `EnvConfig.validate()` → optional Sentry → `runApp(ProviderScope(...))` |
| Platform capability wrapper | `lib/features/auth/data/biometric_store.dart` — non-throwing probes, provider override in tests |
| Foreground display | `SkifluxToast.info` (`lib/shared/toast/skiflux_toast.dart`) |
| Test fake pattern | `test/flows/auth_flow_test.dart` `_FakeBiometrics` |
| Flutter / Dart | Flutter **3.44.8**, Dart **3.12.2** |

---

## Step 1 — Dependency proposal (needs confirmation)

Per freezed exact-pin precedent and FlutterFire **BoM 4.17.1** (2026-07-14):

```yaml
  # FCM receive/display (throwaway Firebase project skiflux-fcm-test).
  # Exact pins: freezed-style, avoid caret resolving onto a broken prerelease.
  # FlutterFire BoM 4.17.1 pair — firebase_messaging depends on this core line.
  firebase_core: 4.12.1
  firebase_messaging: 16.4.3
```

### Why these versions

- Official co-released pair from FlutterFire BoM 4.17.1 (do not mix across BoMs)
- Constraints: Dart ≥3.6, Flutter ≥3.27 — satisfied by Flutter 3.44.8 / Dart 3.12.2
- Exact pins only — no `^` caret ranges
- Receive/display only; **not** adding `flutter_local_notifications` (tracker #34, out of scope)

### Tradeoffs

- Native Android/iOS Firebase SDKs pulled in via Gradle/CocoaPods → APK size up
- Transitive permissions must be reviewed in the merged manifest after build
- No new UI package; reuses existing `SkifluxToast`

---

## Blocker — Android package mismatch (choose one)

| Option | Action | Notes |
|--------|--------|-------|
| **A (recommended for throwaway)** | Re-register Android app in Firebase Console as `com.skiflux.skiflux_mobile_app_v2`, re-download `google-services.json` | Keeps app `applicationId` correct; only config file changes |
| **B** | Change app `applicationId` (and optionally `namespace`) to `com.skiflux.skifluxMobileAppV2` to match the JSON you already have | Changes Android app identity |
| **C** | Proceed with mismatch for now | Builds/tests can go green; **Android FCM registration silently fails** until fixed |

iOS does **not** need this decision (bundle IDs already match).

---

## Waiting on you before Steps 2+

1. Confirm packages: `firebase_core: 4.12.1` + `firebase_messaging: 16.4.3` (exact)
2. Choose **A / B / C** for the Android package mismatch

Until both are confirmed, **no** edits to `pubspec.yaml`, Gradle, manifest, or config file copies.

---

## Deferred iOS checklist (blocked on paid Apple Developer membership)

Do not fake or stub these — track only:

- [ ] APNs auth key generation + upload to Firebase (without this, iOS delivers nothing)
- [ ] Push Notifications capability in Xcode
- [ ] Build / signing / physical-device test
- [ ] `pod install` (no Mac in this environment)

---

## Scope reminders (from task)

**In scope:** `firebase_core` + `firebase_messaging`, Gradle plugin, manifest, Info.plist, Riverpod messaging service (3 app states), foreground via toast, tests, full verification.

**Out of scope:**

- Device-token registration to Skiflux backend (`POST /me/devices` unverified) — leave `// TODO(backend, blocking): ...`
- Send-side logic
- Tap-handling / deep-link routing (tracker #58)
- Podfile edits
- `flutter_local_notifications` (tracker #34)

**Throwaway Firebase project:** swapping later means replace `google-services.json`, `GoogleService-Info.plist`, and regenerate `firebase_options.dart` — nothing else.
