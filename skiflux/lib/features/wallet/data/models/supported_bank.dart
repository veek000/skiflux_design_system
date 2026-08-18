import 'package:flutter/foundation.dart';

/// One bank from `GET /wallet/withdrawals/banks` — the gateway's own list,
/// used to populate the Add Bank Account picker. The response is untyped in
/// the OpenAPI spec (`additionalProperties: {}`), so parsing is tolerant and
/// entries without both a name and a code are dropped rather than guessed.
///
/// A plain class instead of freezed: no codegen for an untyped payload.
@immutable
class SupportedBank {
  const SupportedBank({required this.name, required this.code});

  /// Display name ("Guaranty Trust Bank").
  final String name;

  /// Gateway bank code — what `POST /wallet/withdrawals/accounts` sends as
  /// `bank_code`.
  final String code;

  /// Null when the entry is unusable (no name or no code) — callers drop it.
  static SupportedBank? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final name = _string(json, const ['name', 'bank_name', 'label']);
    final code = _string(json, const ['code', 'bank_code', 'id']);
    if (name == null || code == null) return null;
    return SupportedBank(name: name, code: code);
  }

  static String? _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SupportedBank && other.name == name && other.code == code;

  @override
  int get hashCode => Object.hash(name, code);
}
