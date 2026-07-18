# Skiflux Design System (Flutter)

Extracted from Figma file **Skiflux**  
`https://www.figma.com/design/863bu2TwQqgzIRgPD8bXkG/Skiflux?node-id=107-6437`

All values come from Figma variables, local text styles, effect styles, and component bindings on the **Design System** page (`107:6437`). Light mode only (Semantic Color mode: **Light**).

## Package layout

```
lib/
  skiflux_design_system.dart   # public barrel — the only import consumers need
  src/
    tokens/
      colors.dart        # palettes + semantic Content/Background/Border/Surface tokens
      typography.dart    # SkifluxFontFamily, SkifluxFontWeight, all text styles, textTheme
      spacing.dart       # SkifluxSpacing, SkifluxUnit, SkifluxBorderWidth
      radii.dart         # SkifluxRadii (xs…pill) + BorderRadius helpers
      effects.dart       # Shadow/L1–L6 + Inner shadow (elevation)
      icons.dart         # SkifluxIcon widget + SkifluxIcons helpers (Remix Icon)
    theme/
      app_theme.dart     # SkifluxAppTheme.light — ThemeData assembled from tokens
    components/
      avatar.dart badge.dart button.dart button_icon.dart chip.dart
      comment.dart compose_bar.dart input_field.dart mobile_tab.dart
      radio.dart segment_button.dart spinner.dart switch.dart
      top_nav_bar.dart voice_waveform.dart
```

See [PROJECT.md](PROJECT.md) for the full handoff documentation (what's been built, Figma node map, component API notes, and known gotchas).

## Usage

```dart
import 'package:skiflux_design_system/skiflux_design_system.dart';

MaterialApp(
  theme: SkifluxAppTheme.light,
  home: ...,
);

// Elevation via effect styles (not Surface/* color variables)
Container(
  decoration: BoxDecoration(
    color: SkifluxColors.backgroundPrimary,
    borderRadius: SkifluxRadii.borderL,
    boxShadow: SkifluxEffects.shadowL2,
  ),
);
```

### Text fonts (bundled in this package)

Registered in `pubspec.yaml` under `assets/fonts/`:

| Family | Source | Files |
|--------|--------|--------|
| **Creato Display** | Your pack (`Downloads/creato_display`) | All OTF weights Thin→Black + italics |
| **DM Sans** | [Google Fonts / google/fonts](https://github.com/google/fonts/tree/main/ofl/dmsans) | Variable roman + italic |
| **DM Mono** | [Google Fonts / google/fonts](https://github.com/google/fonts/tree/main/ofl/dmmono) | Regular, Medium, Italic |

OFL licenses are included next to the font files. No other typefaces are used.

When depending on this package from a host app, fonts declared in a package’s `pubspec.yaml` are available automatically (family names match Figma: `Creato Display`, `DM Sans`, `DM Mono`).

### Icons — Remix Icon

Figma’s Design System page uses the **Remix Icons** library (line + fill).  
Source: [Remix-Design/RemixIcon](https://github.com/Remix-Design/RemixIcon)

This package depends on [`remixicon`](https://pub.dev/packages/remixicon) and exposes helpers in `icons.dart`:

```dart
import 'package:skiflux_design_system/skiflux_design_system.dart';

// Full catalog (RemixIcons / Remix)
Icon(RemixIcons.home_3_line)
Icon(RemixIcons.add_fill)

// Skiflux helpers (sizes match Figma 16 / 24)
SkifluxIcon(SkifluxIcons.searchLine, size: SkifluxIcons.sizeS)
SkifluxIcons.icon(RemixIcons.sparkling_2_fill, color: SkifluxColors.contentBrand)

// On buttons / inputs — pass as leadingIcon / trailingIcon
SkifluxButton(
  label: 'Continue',
  leadingIcon: SkifluxIcon(SkifluxIcons.addFill, size: SkifluxIcons.sizeS),
  onPressed: () {},
)
```

Naming matches Figma layers: `add-fill` → `RemixIcons.add_fill`, `search-line` → `RemixIcons.search_line`.

## Brand decisions (confirmed)

| Item | Decision |
|------|----------|
| Neon cyan `#00E0FF` | Logo gradient only — not a design token |
| Near-black / “Carbon” | Use `Content/Primary` (`#1A1A1A` / `Neutral/900`) |
| Fonts | Creato Display, DM Sans, DM Mono only |
| Notification badge fill | `Content/Negative` |
| Code / mono UI | DM Mono (Code text styles) |
| Elevation | Effect styles `Shadow/L1`–`L6` (Surface/L* are white placeholders) |

## 4-point star motif

- Vector **Star 1** (`198:16122`) on the Design System page
- Icon **sparkling-2-fill 1** (`848:39476`)

## Components present

Button, Button Icon, Button group, Text Fields, Input label, Spinner, Switch, Radio, Chips, Notification Badge, Mobile Icon Tab, Segment Buttons, Top Navigation Bar 1/2, Status headers, Avatar, Search Container, Compose bar, Comment, Task Toaster, password strength, achievement Badges, Flame Asset, Remix Icons.

## Components not found (not invented)

Card (generic) · Modal/Dialog · List item · Bottom sheet · Checkbox · Tooltip · material text Tabs

Full token table: [TOKEN_SUMMARY.md](TOKEN_SUMMARY.md)
