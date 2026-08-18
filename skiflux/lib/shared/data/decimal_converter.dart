import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

/// Money fields cross the wire as decimal-formatted strings (`"500.00"`) — a
/// deliberate backend choice to avoid binary floating point. Parsing into
/// [Decimal] keeps that exactness; `double.parse` would reintroduce the very
/// bug the string format exists to prevent.
class DecimalConverter implements JsonConverter<Decimal, String> {
  const DecimalConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  /// The backend formats money to two decimal places, but `Decimal.toString()`
  /// drops trailing zeros ("500.00" would come back as "500"). Values carrying
  /// more than 2dp of real precision pass through untouched.
  @override
  String toJson(Decimal object) =>
      object.scale <= 2 ? object.toStringAsFixed(2) : object.toString();
}

/// For the rare spec'd field that arrives as a JSON *number* — per the
/// OpenAPI schema, `UserWallet.withdrawable_balance` is `type: number,
/// format: double`, unlike every other money field. Parsing via `toString()`
/// adopts the shortest-decimal form the backend's encoder emitted; the value
/// never passes through binary-float arithmetic on the Dart side.
class DecimalFromNumConverter implements JsonConverter<Decimal, num> {
  const DecimalFromNumConverter();

  @override
  Decimal fromJson(num json) => Decimal.parse(json.toString());

  @override
  num toJson(Decimal object) => object.toDouble();
}
