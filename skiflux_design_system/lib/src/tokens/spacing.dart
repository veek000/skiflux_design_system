/// Spacing scale from Figma collection **Spacing** (Mode 1).
///
/// Scopes in Figma: WIDTH_HEIGHT, GAP.
/// Use these named constants — do not hardcode raw numbers in components.
abstract final class SkifluxSpacing {
  /// Variable: `Space/3XS`
  static const double space3xs = 0;

  /// Variable: `Space/2XS`
  static const double space2xs = 2;

  /// Variable: `Space/XS`
  static const double spaceXs = 4;

  /// Variable: `Space/S`
  static const double spaceS = 8;

  /// Variable: `Space/M`
  static const double spaceM = 12;

  /// Variable: `Space/L`
  static const double spaceL = 16;

  /// Variable: `Space/XL`
  static const double spaceXl = 24;

  /// Variable: `Space/2XL`
  static const double space2xl = 32;

  /// Variable: `Space/3XL`
  static const double space3xl = 40;

  /// Variable: `Space/4XL`
  static const double space4xl = 48;

  /// Variable: `Space/5XL`
  static const double space5xl = 56;

  /// Variable: `Space/6XL`
  static const double space6xl = 64;

  /// Variable: `Space/7XL`
  static const double space7xl = 72;

  /// Variable: `Space/8XL`
  static const double space8xl = 80;

  /// Variable: `Space/9XL`
  static const double space9xl = 88;

  /// Variable: `Space/10XL`
  static const double space10xl = 96;

  /// Variable: `Space/11XL`
  static const double space11xl = 104;

  /// Variable: `Space/12XL`
  static const double space12xl = 112;
}

/// Raw unit ladder from Figma collection **Unit** (Mode 1).
/// Prefer [SkifluxSpacing] for layout gaps; use Unit only when a Figma binding
/// references a bare unit token (e.g. font-adjacent sizes, 10, 20, 28).
abstract final class SkifluxUnit {
  /// Variable: `0`
  static const double u0 = 0;

  /// Variable: `2`
  static const double u2 = 2;

  /// Variable: `4`
  static const double u4 = 4;

  /// Variable: `8`
  static const double u8 = 8;

  /// Variable: `10`
  static const double u10 = 10;

  /// Variable: `12`
  static const double u12 = 12;

  /// Variable: `14`
  static const double u14 = 14;

  /// Variable: `16`
  static const double u16 = 16;

  /// Variable: `18`
  static const double u18 = 18;

  /// Variable: `20`
  static const double u20 = 20;

  /// Variable: `24`
  static const double u24 = 24;

  /// Variable: `26`
  static const double u26 = 26;

  /// Variable: `28`
  static const double u28 = 28;

  /// Variable: `32`
  static const double u32 = 32;

  /// Variable: `36`
  static const double u36 = 36;

  /// Variable: `40`
  static const double u40 = 40;

  /// Variable: `48`
  static const double u48 = 48;

  /// Variable: `56`
  static const double u56 = 56;

  /// Variable: `64`
  static const double u64 = 64;

  /// Variable: `72`
  static const double u72 = 72;

  /// Variable: `80`
  static const double u80 = 80;

  /// Variable: `88`
  static const double u88 = 88;

  /// Variable: `96`
  static const double u96 = 96;

  /// Variable: `104`
  static const double u104 = 104;

  /// Variable: `112`
  static const double u112 = 112;

  /// Variable: `120`
  static const double u120 = 120;
}
