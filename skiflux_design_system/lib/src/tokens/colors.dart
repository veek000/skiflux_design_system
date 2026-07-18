import 'package:flutter/material.dart';

/// Skiflux color tokens from Figma variables.
///
/// Sources:
/// - Collection **Primitive Color** (Mode 1)
/// - Collection **Semantic Color** (mode: Light only)
///
/// Light mode only — no dark theme is defined in Semantic Color.
abstract final class SkifluxColors {
  // ── Primitive Brand ──────────────────────────────────────────────
  /// Variable: `Brand/50`
  static const Color brand50 = Color(0xFFF6F2FD);

  /// Variable: `Brand/100`
  static const Color brand100 = Color(0xFFDDCFEE);

  /// Variable: `Brand/200`
  static const Color brand200 = Color(0xFFBB9FDD);

  /// Variable: `Brand/300`
  static const Color brand300 = Color(0xFF9A70CD);

  /// Variable: `Brand/400`
  static const Color brand400 = Color(0xFF7840BC);

  /// Variable: `Brand/500` — primary purple
  static const Color brand500 = Color(0xFF5610AB);

  /// Variable: `Brand/600`
  static const Color brand600 = Color(0xFF450D89);

  /// Variable: `Brand/700` — deep purple
  static const Color brand700 = Color(0xFF340A67);

  /// Variable: `Brand/800`
  static const Color brand800 = Color(0xFF220644);

  /// Variable: `Brand/900`
  static const Color brand900 = Color(0xFF110322);

  // ── Primitive Blue ───────────────────────────────────────────────
  /// Variable: `Blue/ 50`
  static const Color blue50 = Color(0xFFE3EFFF);

  /// Variable: `Blue/ 100`
  static const Color blue100 = Color(0xFFCCE5FF);

  /// Variable: `Blue/ 200`
  static const Color blue200 = Color(0xFF99CAFF);

  /// Variable: `Blue/ 300`
  static const Color blue300 = Color(0xFF66B0FF);

  /// Variable: `Blue/ 400`
  static const Color blue400 = Color(0xFF3395FF);

  /// Variable: `Blue/ 500`
  static const Color blue500 = Color(0xFF007BFF);

  /// Variable: `Blue/ 600`
  static const Color blue600 = Color(0xFF0062CC);

  /// Variable: `Blue/ 700`
  static const Color blue700 = Color(0xFF004A99);

  /// Variable: `Blue/ 800`
  static const Color blue800 = Color(0xFF003166);

  /// Variable: `Blue/ 900`
  static const Color blue900 = Color(0xFF001933);

  // ── Primitive Green ──────────────────────────────────────────────
  /// Variable: ` Green / 50` (name includes leading space in Figma)
  static const Color green50 = Color(0xFFF2FDF6);

  /// Variable: ` Green / 100`
  static const Color green100 = Color(0xFFE0FAEA);

  /// Variable: ` Green / 200`
  static const Color green200 = Color(0xFFBEF4D2);

  /// Variable: ` Green / 300`
  static const Color green300 = Color(0xFF85EAAA);

  /// Variable: ` Green / 400`
  static const Color green400 = Color(0xFF48E080);

  /// Variable: ` Green / 500`
  static const Color green500 = Color(0xFF21C05B);

  /// Variable: ` Green / 600`
  static const Color green600 = Color(0xFF1B9D4A);

  /// Variable: ` Green / 700`
  static const Color green700 = Color(0xFF157A3A);

  /// Variable: ` Green / 800`
  static const Color green800 = Color(0xFF0F5729);

  /// Variable: ` Green / 900`
  static const Color green900 = Color(0xFF0A391B);

  // ── Primitive Orange ─────────────────────────────────────────────
  /// Variable: ` Orange / 50`
  static const Color orange50 = Color(0xFFFFF6F0);

  /// Variable: ` Orange / 100`
  static const Color orange100 = Color(0xFFFEEADC);

  /// Variable: ` Orange / 200`
  static const Color orange200 = Color(0xFFFDD3B4);

  /// Variable: ` Orange / 300`
  static const Color orange300 = Color(0xFFFBAC74);

  /// Variable: ` Orange / 400`
  static const Color orange400 = Color(0xFFFA832E);

  /// Variable: ` Orange / 500`
  static const Color orange500 = Color(0xFFDB5E06);

  /// Variable: ` Orange / 600`
  static const Color orange600 = Color(0xFFB34D05);

  /// Variable: ` Orange / 700`
  static const Color orange700 = Color(0xFF8B3C04);

  /// Variable: ` Orange / 800`
  static const Color orange800 = Color(0xFF632B03);

  /// Variable: ` Orange / 900`
  static const Color orange900 = Color(0xFF411C02);

  // ── Primitive Magenta ────────────────────────────────────────────
  /// Variable: ` Magenta / 50`
  static const Color magenta50 = Color(0xFFFDF2FA);

  /// Variable: ` Magenta / 100`
  static const Color magenta100 = Color(0xFFFBE0F4);

  /// Variable: ` Magenta / 200`
  static const Color magenta200 = Color(0xFFF5BCE8);

  /// Variable: ` Magenta / 300`
  static const Color magenta300 = Color(0xFFED82D4);

  /// Variable: ` Magenta / 400`
  static const Color magenta400 = Color(0xFFE444BF);

  /// Variable: ` Magenta / 500`
  static const Color magenta500 = Color(0xFFC41C9D);

  /// Variable: ` Magenta / 600`
  static const Color magenta600 = Color(0xFFA11781);

  /// Variable: ` Magenta / 700`
  static const Color magenta700 = Color(0xFF7D1264);

  /// Variable: ` Magenta / 800`
  static const Color magenta800 = Color(0xFF590D47);

  /// Variable: ` Magenta / 900`
  static const Color magenta900 = Color(0xFF3A082E);

  // ── Primitive Yellow ─────────────────────────────────────────────
  /// Variable: ` Yellow / 50`
  static const Color yellow50 = Color(0xFFFFFBF0);

  /// Variable: ` Yellow / 100`
  static const Color yellow100 = Color(0xFFFEF6DC);

  /// Variable: ` Yellow / 200`
  static const Color yellow200 = Color(0xFFFDEBB4);

  /// Variable: ` Yellow / 300`
  static const Color yellow300 = Color(0xFFFBDA74);

  /// Variable: ` Yellow / 400`
  static const Color yellow400 = Color(0xFFFAC72E);

  /// Variable: ` Yellow / 500`
  static const Color yellow500 = Color(0xFFDBA506);

  /// Variable: ` Yellow / 600`
  static const Color yellow600 = Color(0xFFB38705);

  /// Variable: ` Yellow / 700`
  static const Color yellow700 = Color(0xFF8B6904);

  /// Variable: ` Yellow / 800`
  static const Color yellow800 = Color(0xFF634B03);

  /// Variable: ` Yellow / 900`
  static const Color yellow900 = Color(0xFF413102);

  // ── Primitive Red ────────────────────────────────────────────────
  /// Variable: `Red/50`
  static const Color red50 = Color(0xFFFEF1F1);

  /// Variable: `Red/100`
  static const Color red100 = Color(0xFFFCDEDE);

  /// Variable: `Red/200`
  static const Color red200 = Color(0xFFF9B8B8);

  /// Variable: `Red/300`
  static const Color red300 = Color(0xFFF47B7B);

  /// Variable: `Red/400`
  static const Color red400 = Color(0xFFEF3939);

  /// Variable: `Red/500`
  static const Color red500 = Color(0xFFD01111);

  /// Variable: `Red/600`
  static const Color red600 = Color(0xFFAA0E0E);

  /// Variable: `Red/700`
  static const Color red700 = Color(0xFF840B0B);

  /// Variable: `Red/800`
  static const Color red800 = Color(0xFF5E0808);

  /// Variable: `Red/900`
  static const Color red900 = Color(0xFF3D0505);

  // ── Primitive Neutral ────────────────────────────────────────────
  /// Variable: `Neutral/50`
  static const Color neutral50 = Color(0xFFF2F2F2);

  /// Variable: `Neutral/100`
  static const Color neutral100 = Color(0xFFE5E5E5);

  /// Variable: `Neutral/150`
  static const Color neutral150 = Color(0xFFD9D9D9);

  /// Variable: `Neutral/200`
  static const Color neutral200 = Color(0xFFCCCCCC);

  /// Variable: `Neutral/250`
  static const Color neutral250 = Color(0xFFBFBFBF);

  /// Variable: `Neutral/300`
  static const Color neutral300 = Color(0xFFB2B2B2);

  /// Variable: `Neutral/350`
  static const Color neutral350 = Color(0xFFA6A6A6);

  /// Variable: `Neutral/400`
  static const Color neutral400 = Color(0xFF999999);

  /// Variable: `Neutral/450`
  static const Color neutral450 = Color(0xFF8C8C8C);

  /// Variable: `Neutral/500`
  static const Color neutral500 = Color(0xFF808080);

  /// Variable: `Neutral/550`
  static const Color neutral550 = Color(0xFF737373);

  /// Variable: `Neutral/600`
  static const Color neutral600 = Color(0xFF666666);

  /// Variable: `Neutral/650`
  static const Color neutral650 = Color(0xFF595959);

  /// Variable: `Neutral/700`
  static const Color neutral700 = Color(0xFF4D4D4D);

  /// Variable: `Neutral/750`
  static const Color neutral750 = Color(0xFF404040);

  /// Variable: `Neutral/800`
  static const Color neutral800 = Color(0xFF333333);

  /// Variable: `Neutral/850`
  static const Color neutral850 = Color(0xFF262626);

  /// Variable: `Neutral/900`
  static const Color neutral900 = Color(0xFF1A1A1A);

  /// Variable: `Neutral/950`
  static const Color neutral950 = Color(0xFF0D0D0D);

  // ── Primitive Primary (black / white) ────────────────────────────
  /// Variable: `Primary/Black`
  static const Color black = Color(0xFF000000);

  /// Variable: `Primary/Black 50` (50% opacity)
  static const Color black50 = Color(0x80000000);

  /// Variable: `Primary/White`
  static const Color white = Color(0xFFFFFFFF);

  /// Variable: `Primary/White 50` (50% opacity)
  static const Color white50 = Color(0x80FFFFFF);

  // ── Semantic Content (Light) ─────────────────────────────────────
  /// Variable: `Content/Primary` → Neutral/900
  static const Color contentPrimary = neutral900;

  /// Variable: `Content/Secondary` → Neutral/800
  static const Color contentSecondary = neutral800;

  /// Variable: `Content/Tertiary` → Neutral/600
  static const Color contentTertiary = neutral600;

  /// Variable: `Content/Primary Inverse` → Primary/White
  static const Color contentPrimaryInverse = white;

  /// Variable: `Content/Secondary Inverse` → Neutral/100
  static const Color contentSecondaryInverse = neutral100;

  /// Variable: `Content/Tertiary Inverse` → Neutral/200
  static const Color contentTertiaryInverse = neutral200;

  /// Variable: `Content/Disabled` → Neutral/300
  static const Color contentDisabled = neutral300;

  /// Variable: `Content/Brand` → Brand/500
  static const Color contentBrand = brand500;

  /// Variable: `Content/Brand Inactive` → Brand/200
  static const Color contentBrandInactive = brand200;

  /// Variable: `Content/Link` → Brand/400
  static const Color contentLink = brand400;

  /// Variable: `Content/Link Hover` → Brand/600
  static const Color contentLinkHover = brand600;

  /// Variable: `Content/Link Pressed` → Brand/700
  static const Color contentLinkPressed = brand700;

  /// Variable: `Content/Info` → Blue/ 400
  static const Color contentInfo = blue400;

  /// Variable: `Content/Info Bold` → Blue/ 600
  static const Color contentInfoBold = blue600;

  /// Variable: `Content/Notice` → Yellow / 500
  static const Color contentNotice = yellow500;

  /// Variable: `Content/Notice Bold` → Yellow / 700
  static const Color contentNoticeBold = yellow700;

  /// Variable: `Content/Negative` → Red/500
  static const Color contentNegative = red500;

  /// Variable: `Content/Negative Bold` → Red/600
  static const Color contentNegativeBold = red600;

  /// Variable: `Content/Positive` → Green / 500
  static const Color contentPositive = green500;

  /// Variable: `Content/Positive Bold` → Green / 600
  static const Color contentPositiveBold = green600;

  // ── Semantic Background (Light) ──────────────────────────────────
  /// Variable: `Background/Primary` → Primary/White
  static const Color backgroundPrimary = white;

  /// Variable: `Background/Hover` → Neutral/50
  static const Color backgroundHover = neutral50;

  /// Variable: `Background/Pressed` → Neutral/100
  static const Color backgroundPressed = neutral100;

  /// Variable: `Background/Selected` → Brand/100
  static const Color backgroundSelected = brand100;

  /// Variable: `Background/Primary Brand` → Brand/100
  static const Color backgroundPrimaryBrand = brand100;

  /// Variable: `Background/Disabled` → Neutral/50
  static const Color backgroundDisabled = neutral50;

  /// Variable: `Background/Inverse` → Neutral/900
  static const Color backgroundInverse = neutral900;

  /// Variable: `Background/Brand` → Brand/500
  static const Color backgroundBrand = brand500;

  /// Variable: `Background/Brand Opacity 50` → Brand/50
  static const Color backgroundBrandOpacity50 = brand50;

  /// Variable: `Background/Brand Disabled` → Brand/200
  static const Color backgroundBrandDisabled = brand200;

  /// Variable: `Background/Brand Hover` → Brand/600
  static const Color backgroundBrandHover = brand600;

  /// Variable: `Background/Brand Pressed` → Brand/700
  static const Color backgroundBrandPressed = brand700;

  /// Variable: `Background/Info` → Blue/ 400
  static const Color backgroundInfo = blue400;

  /// Variable: `Background/Info Subtle` → Blue/ 100
  static const Color backgroundInfoSubtle = blue100;

  /// Variable: `Background/Notice` → Yellow / 500
  static const Color backgroundNotice = yellow500;

  /// Variable: `Background/Notice Subtle` → Yellow / 100
  static const Color backgroundNoticeSubtle = yellow100;

  /// Variable: `Background/Negative` → Red/500
  static const Color backgroundNegative = red500;

  /// Variable: `Background/Negative Subtle` → Red/100
  static const Color backgroundNegativeSubtle = red100;

  /// Variable: `Background/Positive` → Green / 500
  static const Color backgroundPositive = green500;

  /// Variable: `Background/Positive Subtle` → Green / 100
  static const Color backgroundPositiveSubtle = green100;

  // ── Semantic Border (Light) ──────────────────────────────────────
  /// Variable: `Border/Primary` → Neutral/600
  static const Color borderPrimary = neutral600;

  /// Variable: `Border/Secondary` → Neutral/200
  static const Color borderSecondary = neutral200;

  /// Variable: `Border/Tertiary` → Neutral/100
  static const Color borderTertiary = neutral100;

  /// Variable: `Border/Disabled` → Neutral/100
  static const Color borderDisabled = neutral100;

  /// Variable: `Border/Brand` → Brand/500
  static const Color borderBrand = brand500;

  /// Variable: `Border/Inverse` → Primary/White
  static const Color borderInverse = white;

  /// Variable: `Border/Focus` → Brand/500
  static const Color borderFocus = brand500;

  /// Variable: `Border/Info` → Blue/ 500
  static const Color borderInfo = blue500;

  /// Variable: `Border/Notice` → Yellow / 500
  static const Color borderNotice = yellow500;

  /// Variable: `Border/Negative` → Red/500
  static const Color borderNegative = red500;

  /// Variable: `Border/Positive` → Green / 500
  static const Color borderPositive = green500;

  /// Variable: `Border/Mono` → Neutral/900
  static const Color borderMono = neutral900;

  // ── Semantic Overlay (Light) ─────────────────────────────────────
  /// Variable: `Overlay/50` → Primary/Black @ 50%
  static const Color overlay50 = black50;

  /// Variable: `Overlay/50Inverse` → Primary/White @ 50%
  static const Color overlay50Inverse = white50;

  // ── Semantic Surface (Light) — placeholders only ─────────────────
  /// Variable: `Surface/L0` … `Surface/L6` all resolve to Primary/White in Light.
  /// These are fill placeholders; real elevation uses effect styles
  /// `Shadow/L1`…`Shadow/L6` — see [SkifluxEffects] in `effects.dart`.
  static const Color surfaceL0 = white;
  static const Color surfaceL1 = white;
  static const Color surfaceL2 = white;
  static const Color surfaceL3 = white;
  static const Color surfaceL4 = white;
  static const Color surfaceL5 = white;
  static const Color surfaceL6 = white;

  /// Material [ColorScheme] mapped from semantic Light tokens only.
  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: brand500,
        onPrimary: white,
        primaryContainer: brand100,
        onPrimaryContainer: brand700,
        secondary: brand400,
        onSecondary: white,
        secondaryContainer: brand50,
        onSecondaryContainer: brand700,
        tertiary: blue500,
        onTertiary: white,
        error: red500,
        onError: white,
        errorContainer: red100,
        onErrorContainer: red700,
        surface: white,
        onSurface: neutral900,
        onSurfaceVariant: neutral600,
        outline: neutral200,
        outlineVariant: neutral100,
        shadow: black,
        scrim: black50,
        inverseSurface: neutral900,
        onInverseSurface: white,
        inversePrimary: brand200,
        surfaceTint: brand500,
      );
}
