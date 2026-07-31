/// Display formatting for SkillCoin amounts.
///
/// Rewards cross the wire as decimal strings (`"2.50"`) and are held as
/// [Decimal] — never `double`, and never truncated to `int` for display: a
/// 2.50-coin mission must read "+2.50", not "+3".
library;

import 'package:decimal/decimal.dart';

/// "500.00" → "500" · "2.50" → "2.50" · "0.125" → "0.125".
///
/// Whole amounts drop the fraction entirely; fractional amounts keep the
/// backend's two-decimal money form. Anything carrying more than 2dp of real
/// precision passes through untouched (mirrors `DecimalConverter.toJson`).
String formatSkillcoin(Decimal value) {
  if (value.isInteger) return value.toBigInt().toString();
  return value.scale <= 2 ? value.toStringAsFixed(2) : value.toString();
}
