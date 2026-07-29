import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/notification_item.dart';

/// In-app notification feed — `GET /me/notifications` and the per-item
/// mark-read.
///
/// Both endpoints are documented in the spec with an empty response body, so
/// [parse] normalises aliases rather than trusting field names; see the
/// blocking TODO below.
class NotificationsRepository extends ApiRepository {
  const NotificationsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const listPath = '/me/notifications';

  /// Mark-read lives at `/me/{id}/read`, not `/me/notifications/{id}/read` —
  /// that flat shape is what the spec declares (`v1_me_read_create`).
  static String readPath(String id) => '/me/$id/read';

  /// [limit]/[offset] are the spec's pagination params; [unreadOnly] filters
  /// server-side (the screen's Unread tab filters the loaded page locally, so
  /// this stays unused until the feed paginates).
  Future<List<NotificationItem>> list({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) => getList(
    listPath,
    parse: parse,
    query: {
      'limit': ?limit,
      'offset': ?offset,
      'unread_only': ?unreadOnly,
    },
  );

  /// 200 with no body. Callers mark the row read locally first and treat a
  /// failure here as "sync it next time", not as a UI error.
  Future<void> markRead(String id) => post(readPath(id));

  /// Normalises an undocumented row into [NotificationItem].
  ///
  /// Public so provider tests can exercise the alias handling without a Dio
  /// round trip.
  // TODO(backend, blocking): document the `GET /me/notifications` response
  // body — the spec declares 200 "No response body", so the field names below
  // are inferred — expects: List<{id: String, title: String, message: String,
  // type: String, created_at: DateTime, is_read: bool, action_label: String?}>
  static NotificationItem parse(Map<String, dynamic> json) {
    // FCM-style payloads nest the interesting bits under `data`; fall back to
    // it for the two fields most likely to live there.
    final data = json['data'];
    final nested = data is Map ? Map<String, dynamic>.from(data) : const {};

    return NotificationItem(
      id: _string(json, const ['id', 'notification_id', 'uuid']),
      title: _string(json, const ['title', 'heading', 'subject']),
      message: _string(json, const ['message', 'body', 'description']),
      type:
          _string(json, const ['type', 'notification_type', 'category', 'event'])
              .ifEmpty(
                () => _string(nested, const ['type', 'notification_type']),
              ),
      createdAt: _dateTime(json, const [
        'created_at',
        'send_time',
        'sent_at',
        'timestamp',
        'time',
      ]),
      isRead: _isRead(json),
      actionLabel:
          _optionalString(json, const [
            'action_label',
            'action',
            'cta_label',
          ]) ??
          _optionalString(nested, const ['action_label', 'action']),
    );
  }

  static String _string(Map<dynamic, dynamic> json, List<String> keys) =>
      _optionalString(json, keys) ?? '';

  static String? _optionalString(Map<dynamic, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      // Ids may arrive as ints.
      if (value is num) return '$value';
    }
    return null;
  }

  static DateTime? _dateTime(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
      // Epoch seconds vs milliseconds — anything below this threshold can only
      // be seconds (it would otherwise be 1970).
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          value < 100000000000 ? value * 1000 : value,
        ).toLocal();
      }
    }
    return null;
  }

  /// True when any of the read spellings says so. `read_at` counts as read
  /// whenever it is set; `unread` inverts.
  static bool _isRead(Map<String, dynamic> json) {
    for (final key in const ['is_read', 'read', 'seen']) {
      final value = json[key];
      if (value is bool) return value;
    }
    final readAt = json['read_at'];
    if (readAt != null) return true;
    final unread = json['unread'];
    if (unread is bool) return !unread;
    return false;
  }
}

extension on String {
  /// `''` is how the normalisers report "absent"; this chains a fallback.
  String ifEmpty(String Function() other) => isEmpty ? other() : this;
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);
