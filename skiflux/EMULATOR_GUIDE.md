# How to view Skiflux on your emulator (Windows)

You already have Flutter at:

```
C:\Users\timmy\Dev\flutter\bin\flutter.bat
```

The runnable app is:

```
C:\Users\timmy\skiflux\skiflux
```

---

## 1. One-time setup

### Open a terminal

PowerShell or **Windows Terminal** is fine.

### (Optional) Add Flutter to PATH for this session

```powershell
$env:Path = "C:\Users\timmy\Dev\flutter\bin;" + $env:Path
```

Or use the full path every time:  
`C:\Users\timmy\Dev\flutter\bin\flutter.bat`

### Check Flutter + devices

```powershell
flutter doctor
flutter devices
```

You want at least one of:

- An **Android emulator** (e.g. `sdk gphone64 ...`)
- A **physical phone** with USB debugging
- **Chrome** (web — quickest smoke test)

---

## 2. Start an Android emulator

### Option A — Android Studio (most common)

1. Open **Android Studio**
2. **More Actions → Virtual Device Manager** (or **Tools → Device Manager**)
3. Pick a phone (e.g. **Pixel 6 / Pixel 7**, API 33+)
4. Click **▶ Play**
5. Wait until the emulator home screen appears

### Option B — Command line

List AVDs:

```powershell
flutter emulators
```

Launch one (name will match the list):

```powershell
flutter emulators --launch <emulator_id>
```

Example:

```powershell
flutter emulators --launch Pixel_7_API_34
```

---

## 3. Run the Home screen

```powershell
cd C:\Users\timmy\skiflux\skiflux
flutter pub get
flutter run
```

If multiple devices are connected:

```powershell
flutter devices
flutter run -d <device_id>
```

Examples:

```powershell
flutter run -d emulator-5554    # Android emulator
flutter run -d chrome           # browser (quick preview)
```

Hot reload after code changes: press **`r`** in the terminal.  
Hot restart: **`R`**.  
Quit: **`q`**.

---

## 4. VS Code / Cursor (GUI)

1. Open folder: `C:\Users\timmy\skiflux\skiflux`
2. Install extension: **Flutter** (and **Dart**)
3. Bottom-right status bar → select your **emulator**
4. Open `lib/main.dart` → press **F5** or **Run → Start Debugging**

---

## 5. What you should see

Figma frame: **Home & In-app Flow 11** (`198:13684`)

- Top: search · creator “Amara Design / @amara” · notifications
- Center: video/code cover with EP 01, title **Code**, action rail
- Bottom: **Home** (active) · Tasks · Subscriptions · Profile

---

## 6. Common issues

| Problem                   | Fix                                                                                              |
|---------------------------|--------------------------------------------------------------------------------------------------|
| `flutter` not recognized  | Use full path or add `C:\Users\timmy\Dev\flutter\bin` to System PATH                             |
| No devices                | Start emulator first, then `flutter devices`                                                     |
| Gradle / Android licenses | `flutter doctor --android-licenses` → accept all                                                 |
| Fonts look wrong          | Fonts are in the design_system package; run from `skiflux` after `flutter pub get` |
| Build slow first time     | Normal — Android downloads dependencies once                                                     |

---

## 7. Quickest path (copy-paste)

```powershell
$env:Path = "C:\Users\timmy\Dev\flutter\bin;" + $env:Path
# Start emulator from Android Studio first, then:
cd C:\Users\timmy\skiflux\skiflux
flutter pub get
flutter run
```

If you only want a fast check without the emulator:

```powershell
cd C:\Users\timmy\skiflux\skiflux
flutter run -d chrome
```

