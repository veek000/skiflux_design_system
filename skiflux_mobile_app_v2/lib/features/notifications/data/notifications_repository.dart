import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/notification_item.dart';

/// In-app notification feed — `GET /me/notifications` and the per-item
/// mark-read.
///
/// The list response is now documented as `NotificationListResponse`:
/// `{count, results, next, offset, limit}` wrapping `NotificationItem`
/// (`{id, type, title, body, data, is_read, created_at}`). [getList] unwraps
/// the `results` envelope; the pagination fields are unused because the screen
/// loads a single page.
///
/// [parse] still normalises aliases — the documented spelling is tried first —
/// because two fields the UI needs are *not* in the schema: the action pill's
/// label and the card's icon. See [parse].
///
/// Mark-read remains a 200 with no body.
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

  /// `POST /me/notifications/mark-all-read` — bulk mark read. Idempotent.
  Future<void> markAllRead() => post('/me/notifications/mark-all-read');

  /// Maps a `NotificationItem` row onto the app's model.
  ///
  /// The documented key is first in every list below; the rest are tolerated
  /// spellings kept because they cost nothing.
  ///
  /// Two of the screen's elements have no field to read:
  ///
  /// - **The icon.** Derived from `type` by `NotificationsNotifier.iconKeyFor`,
  ///   which matches on substrings and falls back to a bell.
  /// - **The action pill** ("Watch EP. 04", "View Reply"). No `action_label`
  ///   exists, so the only plausible home is the freeform `data` object — which
  ///   the schema declares as `{}` with no contents. Until that is pinned down,
  ///   a card without one simply renders no pill.
  ///
  /// Public so provider tests can exercise the alias handling without a Dio
  /// round trip.
  // TODO(backend, blocking): `NotificationItem.data` is typed `{}` — the app
  // reads the action pill's label and deep-link target out of it and cannot
  // know what it carries — expects: data: {action_label: String?, action_type:
  // String?, episode_id: String?, comment_id: String?}, plus the enumerated
  // `type` vocabulary so the icon table can stop matching on substrings
  static NotificationItem parse(Map<String, dynamic> json) {
    // The documented `data` object is where anything beyond the six flat fields
    // has to live.
    final data = json['data'];
    final nested = data is Map ? Map<String, dynamic>.from(data) : const {};

    return NotificationItem(
      id: _string(json, const ['id', 'notification_id', 'uuid']),
      title: _string(json, const ['title', 'heading', 'subject']),
      // `body` is the documented name.
      message: _string(json, const ['body', 'message', 'description']),
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
      // Not a schema field at any level — `data` is the only candidate.
      actionLabel:
          _optionalString(nested, const [
            'action_label',
            'action',
            'cta_label',
          ]) ??
          _optionalString(json, const ['action_label', 'action', 'cta_label']),
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
