# Token summary

**Source file:** Skiflux (`863bu2TwQqgzIRgPD8bXkG`)  
**Node:** Design System page `107:6437`  
**Extraction:** Figma Plugin API local variables + local text styles + effect styles + component bindings

| Token name | Value | Source |
|---|---|---|
| brand50 | `#F6F2FD` | Variable `Brand/50` |
| brand100 | `#DDCFEE` | Variable `Brand/100` |
| brand200 | `#BB9FDD` | Variable `Brand/200` |
| brand300 | `#9A70CD` | Variable `Brand/300` |
| brand400 | `#7840BC` | Variable `Brand/400` |
| brand500 | `#5610AB` | Variable `Brand/500` |
| brand600 | `#450D89` | Variable `Brand/600` |
| brand700 | `#340A67` | Variable `Brand/700` |
| brand800 | `#220644` | Variable `Brand/800` |
| brand900 | `#110322` | Variable `Brand/900` |
| blue50…blue900 | `#E3EFFF`…`#001933` | Variables `Blue/ 50`…`Blue/ 900` |
| green50…green900 | `#F2FDF6`…`#0A391B` | Variables ` Green / 50`…` Green / 900` |
| orange50…orange900 | `#FFF6F0`…`#411C02` | Variables ` Orange / *` |
| magenta50…magenta900 | `#FDF2FA`…`#3A082E` | Variables ` Magenta / *` |
| yellow50…yellow900 | `#FFFBF0`…`#413102` | Variables ` Yellow / *` |
| red50…red900 | `#FEF1F1`…`#3D0505` | Variables `Red/*` |
| neutral50…neutral950 | `#F2F2F2`…`#0D0D0D` | Variables `Neutral/*` |
| black / black50 | `#000000` / @50% | `Primary/Black`, `Primary/Black 50` |
| white / white50 | `#FFFFFF` / @50% | `Primary/White`, `Primary/White 50` |
| contentPrimary | `#1A1A1A` | Semantic `Content/Primary` → Neutral/900 |
| contentSecondary | `#333333` | Semantic `Content/Secondary` |
| contentTertiary | `#666666` | Semantic `Content/Tertiary` |
| contentPrimaryInverse | `#FFFFFF` | Semantic `Content/Primary Inverse` |
| contentSecondaryInverse | `#E5E5E5` | Semantic `Content/Secondary Inverse` |
| contentTertiaryInverse | `#CCCCCC` | Semantic `Content/Tertiary Inverse` |
| contentDisabled | `#B2B2B2` | Semantic `Content/Disabled` |
| contentBrand | `#5610AB` | Semantic `Content/Brand` |
| contentBrandInactive | `#BB9FDD` | Semantic `Content/Brand Inactive` |
| contentLink / Hover / Pressed | Brand 400/600/700 | Semantic `Content/Link*` |
| contentInfo / Bold | Blue 400/600 | Semantic `Content/Info*` |
| contentNotice / Bold | Yellow 500/700 | Semantic `Content/Notice*` |
| contentNegative / Bold | Red 500/600 | Semantic `Content/Negative*` |
| contentPositive / Bold | Green 500/600 | Semantic `Content/Positive*` |
| backgroundPrimary | `#FFFFFF` | Semantic `Background/Primary` |
| backgroundHover | `#F2F2F2` | Semantic `Background/Hover` |
| backgroundPressed | `#E5E5E5` | Semantic `Background/Pressed` |
| backgroundSelected | `#DDCFEE` | Semantic `Background/Selected` |
| backgroundBrand | `#5610AB` | Semantic `Background/Brand` |
| backgroundBrandHover | `#450D89` | Semantic `Background/Brand Hover` |
| backgroundBrandPressed | `#340A67` | Semantic `Background/Brand Pressed` |
| backgroundBrandDisabled | `#BB9FDD` | Semantic `Background/Brand Disabled` |
| backgroundBrandOpacity50 | `#F6F2FD` | Semantic `Background/Brand Opacity 50` |
| borderPrimary…borderMono | (see colors.dart) | Semantic `Border/*` |
| overlay50 / overlay50Inverse | black/white @50% | Semantic `Overlay/*` |
| surfaceL0…L6 | `#FFFFFF` (placeholder) | Semantic `Surface/L*` — use effects for elevation |
| shadowL1 | blur 2@(0,0) 8% + blur 4@(0,2) 8% | Effect style `Shadow/L1` |
| shadowL2 | blur 4@(0,0) 8% + blur 8@(0,4) 10% | Effect style `Shadow/L2` |
| shadowL3 | blur 6@(0,0) 8% + blur 16@(0,8) 10% | Effect style `Shadow/L3` |
| shadowL4 | blur 8@(0,0) 8% + blur 20@(0,10) 10% | Effect style `Shadow/L4` |
| shadowL5 | blur 10@(0,0) 8% + blur 24@(0,12) 10% | Effect style `Shadow/L5` |
| shadowL6 | blur 12@(0,0) 8% + blur 32@(0,16) 10% | Effect style `Shadow/L6` |
| innerShadow | `#FFF8F4` @30%, blur ≈0.53, offset (0,≈1.07) | Effect style `Inner shadow` |
| space3xs…space12xl | 0…112 | Variables `Space/*` |
| radius none…pill | 0…999 | Variables `Radius/*` |
| border width none…xl | 0…8 | Variables `Width/*` |
| font Creato Display | `"Creato Display"` | Variable `Font Family/Creato Display` |
| font DM Sans | `"DM Sans"` | Variable `Font Family/DM Sans` |
| font DM Mono | `"DM Mono"` | Variable `Font Family/DM Mono` |
| fontWeight regular…extrabold | 400/500/600/700/800 | Variables `Font Weight/*` |
| headingH1…H10* | Creato Display sizes 72→16 | Text styles `Heading Style/*` |
| bodyP1…P11* | DM Sans sizes 48→10 | Text styles `Body Style/*` |
| code* | DM Mono | Text styles `Code Style/*` |
| ui* | Creato Display / DM Sans Italic placeholder | Text styles `UI Style/*` |
| Remix Icon set | line + fill, 24×24 grid | Figma Remix Icons library + [Remix-Design/RemixIcon](https://github.com/Remix-Design/RemixIcon); Flutter `remixicon` package |
| icon size S / M / L | 16 / 24 / 32 | `Space/L`, `Space/XL`, `Space/2XL` (Figma UI icon sizes) |

## Brand constraint status

| Constraint | Status |
|---|---|
| Deep purple `#340A67` | Match — `Brand/700` |
| Primary purple `#5610AB` | Match — `Brand/500` |
| Light background `#F6F2FD` | Match — `Brand/50` |
| Neon cyan `#00E0FF` | Logo gradient only — not a token |
| Near-black / Carbon | Use `Content/Primary` `#1A1A1A` |
| Fonts | Creato Display, DM Sans, DM Mono only |
| Light mode only | Match — Semantic mode `Light` |
| 4-point star ✦ | Present as asset (`Star 1`, `sparkling-2-fill`) |
| Elevation | Effect styles `Shadow/L1`–`L6` |
