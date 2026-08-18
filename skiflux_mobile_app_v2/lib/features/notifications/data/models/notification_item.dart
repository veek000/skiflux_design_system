import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

/// One row from `GET /me/notifications`, mirroring the spec's
/// `NotificationItem` — `{id, type, title, body, data, is_read, created_at}`.
///
/// Every field except [id] keeps a default so a payload that names something
/// differently degrades to a renderable card instead of throwing mid-list.
/// `NotificationsRepository.parse` runs first and tries the documented key
/// ahead of any tolerated alias.
///
/// [actionLabel] has **no** field in the schema — it can only come out of the
/// freeform `data` object; see the blocking TODO on `parse`.
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

    /// Deep-link map from `NotificationItem.data` (episode_id, season_id, …).
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}
