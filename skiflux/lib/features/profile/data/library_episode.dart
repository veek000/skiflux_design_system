/// The episode shape the profile library screens render — Liked Videos, Saved
/// Videos, Watch History and (once there is a pipeline) Downloads.
///
/// All three endpoints return the OpenAPI `Episode` schema, so they share one
/// model rather than three near-identical ones. It deliberately keeps the raw
/// numbers (`viewCount`, `durationSeconds`) alongside their formatted labels:
/// the row shows the label, but sorting and progress maths need the number.
library;

import '../../home/data/home_feed_store.dart';

class LibraryEpisode {
  const LibraryEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorName,
    required this.creatorUsername,
    required this.creatorInitials,
    this.creatorAvatarUrl,
    this.order,
    this.thumbnailUrl,
    this.videoUrl,
    this.durationSeconds = 0,
    this.viewCount = 0,
    this.likeCount,
    this.commentCount,
    this.saveCount,
    this.skillworld,
    this.watchProgress = 0,
  });

  /// Backend episode UUID — what like / save / history writes post against.
  final String id;

  final String title;
  final String description;

  final String creatorName;
  final String creatorUsername;
  final String creatorInitials;
  final String? creatorAvatarUrl;

  /// Position within its season, 1-10. Null when the API omitted it.
  final int? order;

  final String? thumbnailUrl;
  final String? videoUrl;

  /// `video_duration`, in seconds. 0 when unknown — the duration pill is then
  /// hidden rather than showing "0:00".
  final int durationSeconds;

  final int viewCount;

  /// Engagement counts off the same `Episode` payload. Required by the schema,
  /// but left nullable so a legacy or hand-built episode renders no number on
  /// the action rail rather than a fabricated zero.
  final int? likeCount;
  final int? commentCount;
  final int? saveCount;

  final String? skillworld;

  /// 0 = untouched, 1 = finished. Only watch history knows this; liked and
  /// saved rows leave it at 0.
  final double watchProgress;

  String get epTag =>
      order == null ? 'EP' : 'EP ${order!.toString().padLeft(2, '0')}';

  /// "12:04", or "1:02:33" past the hour. Empty when the API omitted it.
  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
    return '$m:$ss';
  }

  /// "1.2K views" / "3.4M views" — the row has no room for seven digits.
  String get viewsLabel {
    final n = viewCount;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  LibraryEpisode copyWith({double? watchProgress}) => LibraryEpisode(
    id: id,
    title: title,
    description: description,
    creatorName: creatorName,
    creatorUsername: creatorUsername,
    creatorInitials: creatorInitials,
    creatorAvatarUrl: creatorAvatarUrl,
    order: order,
    thumbnailUrl: thumbnailUrl,
    videoUrl: videoUrl,
    durationSeconds: durationSeconds,
    viewCount: viewCount,
    likeCount: likeCount,
    commentCount: commentCount,
    saveCount: saveCount,
    skillworld: skillworld,
    watchProgress: watchProgress ?? this.watchProgress,
  );

  /// Hands the episode to [VideoFeedCard], which only speaks [HomeFeedItem].
  HomeFeedItem toFeedItem() {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    return HomeFeedItem(
      type: hasVideo ? FeedContentType.video : FeedContentType.image,
      epTag: epTag,
      title: title,
      description: description,
      coverAsset: 'assets/home_video_cover.png',
      coverUrl: thumbnailUrl,
      videoUrl: hasVideo ? videoUrl : null,
      creatorName: creatorName,
      creatorUsername: creatorUsername,
      creatorInitials: creatorInitials,
      episodeId: id,
      // Without these the modal player's rail renders bare icons: `_railCount`
      // maps a null count to an empty label and the number disappears.
      likeCount: likeCount,
      commentCount: commentCount,
      saveCount: saveCount,
      durationSeconds: durationSeconds > 0 ? durationSeconds : null,
      skillworld: skillworld,
    );
  }

  /// OpenAPI `Episode` → [LibraryEpisode].
  factory LibraryEpisode.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];

    var name = 'Creator';
    var username = '';
    var initials = 'C';
    String? avatarUrl;

    if (creator is Map) {
      final c = Map<String, dynamic>.from(creator);

      name = _string(c['name']) ?? 'Creator';
      username = _string(c['username']) ?? '';
      avatarUrl = _string(c['avatar_url']);

      if (name.isNotEmpty) {
        final parts = name.trim().split(RegExp(r'\s+'));

        if (parts.length >= 2) {
          initials =
              '${parts.first[0]}${parts.last[0]}'.toUpperCase();
        } else {
          initials = name[0].toUpperCase();
        }
      } else if (username.isNotEmpty) {
        initials = username[0].toUpperCase();
      }
    }

    return LibraryEpisode(
      id: _string(json['id']) ?? '',
      title: _string(json['title']) ?? 'Episode',
      description: _string(json['description']) ?? '',
      creatorName: name,
      creatorUsername: username,
      creatorInitials: initials.isEmpty ? 'C' : initials,
      creatorAvatarUrl: avatarUrl,
      order: _int(json['order']),
      thumbnailUrl:
      _string(json['thumbnail_url']) ??
          _string(json['preview_url']),
      videoUrl: _string(json['video_url']),
      durationSeconds: _int(json['video_duration']) ?? 0,
      viewCount: _int(json['view_count']) ?? 0,
      likeCount: _int(json['like_count']),
      commentCount: _int(json['comment_count']),
      saveCount: _int(json['save_count']),
      skillworld: _string(json['skillworld']),
    );
  }
  // factory LibraryEpisode.fromJson(Map<String, dynamic> json) {
  //   final creator = json['creator'];
  //   var name = 'Creator';
  //   var username = '';
  //   var initials = 'C';
  //   String? avatarUrl;
  //   if (creator is Map) {
  //     final c = Map<String, dynamic>.from(creator);
  //     final first = _string(c['first_name']) ?? '';
  //     final last = _string(c['last_name']) ?? '';
  //     final display = _string(c['display_name']);
  //     username = _string(c['username']) ?? '';
  //     avatarUrl =
  //         _string(c['avatar_url']) ??
  //             _string(c['profile_image']) ??
  //             _string(c['profile_image_url']) ??
  //             _string(c['avatar']);
  //     name = (display != null && display.isNotEmpty)
  //         ? display
  //         : ('$first $last'.trim().isNotEmpty
  //               ? '$first $last'.trim()
  //               : (username.isNotEmpty ? username : 'Creator'));
  //     if (first.isNotEmpty || last.isNotEmpty) {
  //       initials =
  //           '${first.isNotEmpty ? first[0] : ''}'
  //                   '${last.isNotEmpty ? last[0] : ''}'
  //               .toUpperCase();
  //     } else if (username.isNotEmpty) {
  //       initials = username[0].toUpperCase();
  //     }
  //   }
  //
  //   return LibraryEpisode(
  //     id: _string(json['id']) ?? '',
  //     title: _string(json['title']) ?? 'Episode',
  //     description: _string(json['description']) ?? '',
  //     creatorName: name,
  //     creatorUsername: username,
  //     creatorInitials: initials.isEmpty ? 'C' : initials,
  //     creatorAvatarUrl: avatarUrl,
  //     order: _int(json['order']),
  //     thumbnailUrl: _string(json['thumbnail_url']) ?? _string(json['preview_url']),
  //     videoUrl: _string(json['video_url']),
  //     durationSeconds: _int(json['video_duration']) ?? 0,
  //     viewCount: _int(json['view_count']) ?? 0,
  //     likeCount: _int(json['like_count']),
  //     commentCount: _int(json['comment_count']),
  //     saveCount: _int(json['save_count']),
  //     skillworld: _string(json['skillworld']),
  //   );
  // }

  /// The feed's own model in the shape the library and downloads use.
  ///
  /// One episode described by two endpoints. Downloading from the feed needs
  /// this shape, because it is what the downloads registry persists and what a
  /// Downloads row renders. Returns null without a backend episode id — a
  /// client-only catalogue item has no identity to key a download on.
  static LibraryEpisode? fromFeedItem(HomeFeedItem item) {
    final id = item.episodeId;
    if (id == null || id.isEmpty) return null;
    return LibraryEpisode(
      id: id,
      title: item.title,
      description: item.description,
      creatorName: item.creatorName,
      creatorUsername: item.creatorUsername,
      creatorInitials: item.creatorInitials,
      // Feed only carries the formatted `epTag` ("EP 04"); Downloads rows
      // render [epTag] from [order]. Without this parse every download showed
      // a bare "EP" pill.
      order: orderFromEpTag(item.epTag),
      thumbnailUrl: item.coverUrl,
      videoUrl: item.videoUrl,
      durationSeconds: item.durationSeconds ?? 0,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      saveCount: item.saveCount,
      skillworld: item.skillworld,
    );
  }

  /// `"EP 04"` / `"EP04"` → `4`. Null when the tag has no number.
  static int? orderFromEpTag(String epTag) {
    final match = RegExp(r'EP\s*(\d+)', caseSensitive: false).firstMatch(epTag);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Wire-shaped, so it round-trips through [LibraryEpisode.fromJson].
  ///
  /// Exists for the downloads registry, which persists what is on disk to
  /// `shared_preferences` — a downloaded episode has to survive a relaunch
  /// with the title, creator and thumbnail its row needs, without a fetch.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'creator': {
      'display_name': creatorName,
      'username': creatorUsername,
    },
    'order': order,
    'thumbnail_url': thumbnailUrl,
    'video_url': videoUrl,
    'video_duration': durationSeconds,
    'view_count': viewCount,
    'like_count': likeCount,
    'comment_count': commentCount,
    'save_count': saveCount,
    'skillworld': skillworld,
  };
}

/// One `WatchHistoryItem`: the episode, plus how far and when it was watched.
class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.episode,
    required this.watchDurationSeconds,
    required this.completed,
    required this.viewedAt,
  });

  final LibraryEpisode episode;
  final int watchDurationSeconds;
  final bool completed;
  final DateTime viewedAt;

  /// 0–1. `completed` wins over the arithmetic: a user who skipped the outro
  /// is still done, and the backend is the one that decided so.
  double get progress {
    if (completed) return 1;
    final total = episode.durationSeconds;
    if (total <= 0) return 0;
    return (watchDurationSeconds / total).clamp(0.0, 1.0);
  }

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['episode'];
    final episode = LibraryEpisode.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
    final completed = json['completed'] == true;
    final watched = _int(json['watch_duration_seconds']) ?? 0;
    final viewedAt =
        DateTime.tryParse(_string(json['viewed_at']) ?? '')?.toLocal() ??
        DateTime.now();

    return WatchHistoryEntry(
      episode: episode.copyWith(
        watchProgress: completed
            ? 1
            : (episode.durationSeconds > 0
                  ? (watched / episode.durationSeconds).clamp(0.0, 1.0)
                  : 0),
      ),
      watchDurationSeconds: watched,
      completed: completed,
      viewedAt: viewedAt,
    );
  }
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
