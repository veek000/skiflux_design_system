/// Helpers for backend JSON bodies that may be bare or wrapped.
///
/// payment-flows.md / withdrawal-flows.md describe
/// `{status, status_code, message, data}` while many OpenAPI operation
/// responses show the bare resource. Mobile accepts both.
library;

/// Returns the payload map the app should parse.
///
/// - Bare object → itself
/// - `{ "data": { ... } }` → inner map (also peels one nesting level if
///   `data` is itself a success envelope — rare)
/// - Other shapes → original map (callers may still fail on fromJson)
Map<String, dynamic> unwrapObject(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    // Prefer the nested resource when present; keep top-level only when
    // `data` is empty metadata.
    if (data.isNotEmpty) return data;
  }
  return json;
}

/// Returns a list payload from a bare array, `{results: []}`, or `{data: []}`.
List<dynamic> unwrapList(Object? raw) {
  if (raw is List) return raw;
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is List) return data;
    if (data is Map) {
      final nested = data['results'];
      if (nested is List) return nested;
    }
    final results = map['results'];
    if (results is List) return results;
  }
  throw FormatException(
    'Expected a JSON array or list envelope, got ${raw.runtimeType}',
  );
}
