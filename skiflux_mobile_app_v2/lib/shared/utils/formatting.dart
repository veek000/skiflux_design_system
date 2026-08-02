/// Pure display formatters shared by every content surface.
///
/// These live here rather than in a feature store because the same episode
/// can be rendered by the feed, a season sheet, a creator profile and a search
/// result: three copies of "22k views" drift, and a drifted copy is how a
/// fabricated figure survives a cleanup.
///
/// Every function here is honest about absence — a null timestamp reads as
/// "Recently", not as a precise invention.
library;

/// 1200 → "1.2k", 3_400_000 → "3.4M", 940 → "940".
String countLabel(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

/// "5 hrs ago" / "2 days ago" / "Just now" from a payload timestamp.
/// Null (missing/unparseable `created_at`) reads as "Recently" — a vague
/// truth rather than a precise invention.
String relativeAgeLabel(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return 'Recently';
  final delta = (now ?? DateTime.now()).difference(createdAt);
  if (delta.isNegative || delta.inMinutes < 1) return 'Just now';
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes} min${delta.inMinutes == 1 ? '' : 's'} ago';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours} hr${delta.inHours == 1 ? '' : 's'} ago';
  }
  if (delta.inDays < 7) {
    return '${delta.inDays} day${delta.inDays == 1 ? '' : 's'} ago';
  }
  final weeks = delta.inDays ~/ 7;
  if (weeks < 5) return '$weeks week${weeks == 1 ? '' : 's'} ago';
  final months = delta.inDays ~/ 30;
  if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
  final years = delta.inDays ~/ 365;
  return '$years year${years == 1 ? '' : 's'} ago';
}
