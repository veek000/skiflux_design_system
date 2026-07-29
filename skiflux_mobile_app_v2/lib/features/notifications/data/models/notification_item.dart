import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

/// One row from `GET /me/notifications`.
///
/// **The spec documents this endpoint's 200 as "No response body"** — the
/// shape below is inferred, and every field except [id] carries a default so a
/// payload that names things differently degrades to a renderable card instead
/// of throwing mid-list. `NotificationsRepository.parse` maps the aliases we
/// consider likely (`message`/`body`, `created_at`/`send_time`, `is_read`/
/// `read`) before this factory runs; see the blocking TODO there.
@freezed
abstract class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    /// Server id, used for `POST /me/{id}/read`. Empty when the payload
    /// omits it — such a row can be read locally but not synced.
    @Default('') String id,
    @Default('') String title,

    /// Card body copy.
    @Default('') String message,

    /// Server-side category ("new_episode", "coin_earned", …). Mapped onto the
    /// screen's icon keys by `NotificationsNotifier`; an unrecognised value
    /// falls through to the generic bell.
    @Default('') String type,

    /// Null when the payload has no parseable timestamp — the adapter then
    /// stamps the row with "now" so it still sorts and groups.
    DateTime? createdAt,
    @Default(false) bool isRead,

    /// Label for the optional action pill ("Watch EP. 04"). Absent for
    /// informational cards.
    String? actionLabel,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}
