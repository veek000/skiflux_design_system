/// Subscriptions state — followed creators and their latest episodes.
///
/// No seed sits behind this. Signed out (or before the backend answers) the
/// lists are empty and the tab shows its real empty state; a failed load keeps
/// the error so the screen can offer a retry. Sample creators used to fill in
/// whenever the backend returned nothing, which made "Subscribed to Amara
/// Design" a claim about an account that does not exist.
///
/// Follow/unfollow are optimistic writes against
/// `POST /creators/{creator_id}/follow/` (a toggle): the list updates first,
/// the call confirms it, and a failure rolls the list back and rethrows so the
/// caller can surface the error. Success toasts belong after the `await`.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/token_store.dart';
import '../../../shared/utils/formatting.dart';
import '../../playlists/data/season_providers.dart';
import 'subscriptions_repository.dart';

// `relativeAgeLabel` / `countLabel` used to live here; they now belong to every
// content surface, so they moved to `shared/utils/formatting.dart`. Re-exported
// because this file is the import the subscription screens and tests already
// reach for.
export '../../../shared/utils/formatting.dart' show countLabel, relativeAgeLabel;

enum SubscriptionFeedFilter { recent, today, continueWatching, unwatched }

extension SubscriptionFeedFilterLabel on SubscriptionFeedFilter {
  String get label => switch (this) {
    SubscriptionFeedFilter.recent => 'Recent',
    SubscriptionFeedFilter.today => 'Today',
    SubscriptionFeedFilter.continueWatching => 'Continue watching',
    SubscriptionFeedFilter.unwatched => 'Unwatched',
  };
}

enum SubscriptionListSort { mostRelevant, newActivity, aToZ }

extension SubscriptionListSortLabel on SubscriptionListSort {
  String get label => switch (this) {
    SubscriptionListSort.mostRelevant => 'Most relevant',
    SubscriptionListSort.newActivity => 'New activity',
    SubscriptionListSort.aToZ => 'A–Z',
  };
}

enum CreatorNotificationMode { all, personalized, none }

extension CreatorNotificationModeLabel on CreatorNotificationMode {
  String get label => switch (this) {
    CreatorNotificationMode.all => 'All',
    CreatorNotificationMode.personalized => 'Personalized',
    CreatorNotificationMode.none => 'None',
  };
}

class SubscribedCreator {
  SubscribedCreator({
    required this.name,
    required this.username,
    required this.initials,
    this.id = '',
    this.followersCount,
    this.notificationMode = CreatorNotificationMode.personalized,
    this.hasUnseen = false,
  });

  /// Spec `FollowedCreator` — `{id, first_name, last_name, username,
  /// avatar_public_id, bio, skillworld, followers_count}`.
  factory SubscribedCreator.fromJson(Map<String, dynamic> json) {
    final first = _string(json['first_name']) ?? '';
    final last = _string(json['last_name']) ?? '';
    final username = _string(json['username']) ?? '';
    final full = '$first $last'.trim();
    final name = full.isNotEmpty ? full : username;
    var initials = '?';
    if (first.isNotEmpty || last.isNotEmpty) {
      initials = '${first.isNotEmpty ? first[0] : ''}'
              '${last.isNotEmpty ? last[0] : ''}'
          .toUpperCase();
    } else if (username.isNotEmpty) {
      initials = username[0].toUpperCase();
    }
    return SubscribedCreator(
      id: json['id']?.toString() ?? '',
      name: name,
      username: username,
      initials: initials,
      followersCount: json['followers_count'] is int
          ? json['followers_count'] as int
          : null,
    );
  }

  /// Backend creator UUID — what `POST /creators/{id}/follow/` and
  /// `GET /creators/{id}` take. Empty only for rows built before the payload
  /// carried one; follow writes require it.
  final String id;

  final String name;
  final String username;
  final String initials;
  final int? followersCount;

  /// Local-only preference — the spec has no per-creator notification
  /// endpoint, so this never syncs (and the UI must not claim it does).
  CreatorNotificationMode notificationMode;
  bool hasUnseen;

  String get handle => '@$username';

  /// True when [other] identifies this creator (id first, then username).
  bool matches(String idOrUsername) =>
      idOrUsername.isNotEmpty &&
      (id == idOrUsername || username == idOrUsername);
}

class SubscriptionEpisode {
  const SubscriptionEpisode({
    required this.epNumber,
    required this.title,
    required this.creatorUsername,
    required this.duration,
    required this.views,
    required this.postedAgo,
    this.isNew = false,
    this.postedToday = false,
    this.watchProgress = 0,
    this.id = '',
    this.creatorId = '',
    this.creatorName = '',
    this.description = '',
    this.thumbnailUrl,
    this.videoUrl,
    this.season,
  });

  /// Spec `Episode` — the same schema the home feed parses.
  factory SubscriptionEpisode.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    var creatorUsername = '';
    var creatorId = '';
    var creatorName = '';
    if (creator is Map) {
      creatorUsername = _string(creator['username']) ?? '';
      creatorId = creator['id']?.toString() ?? '';
      creatorName = _string(creator['name']) ?? creatorUsername;
    }
    final createdAt = DateTime.tryParse(
      _string(json['created_at']) ?? '',
    )?.toLocal();
    final age = createdAt == null ? null : DateTime.now().difference(createdAt);
    final order = json['order'];
    final durationSeconds = json['video_duration'] is int
        ? json['video_duration'] as int
        : 0;
    final viewCount = json['view_count'] is int ? json['view_count'] as int : 0;
    final seasonId = _string(json['season_id']);

    return SubscriptionEpisode(
      id: json['id']?.toString() ?? '',
      epNumber: order is num ? order.toInt() : 0,
      title: _string(json['title']) ?? '',
      description: _string(json['description']) ?? '',
      creatorUsername: creatorUsername,
      creatorId: creatorId,
      creatorName: creatorName,
      duration: _durationLabel(durationSeconds),
      views: '${countLabel(viewCount)} views',
      postedAgo: relativeAgeLabel(createdAt),
      // "New" = dropped in the last 3 days; "today" = the last 24 hours. Both
      // are presentation heuristics over `created_at`, not backend flags.
      isNew: age != null && age.inHours < 72,
      postedToday: age != null && age.inHours < 24,
      thumbnailUrl: _string(json['thumbnail_url']),
      videoUrl: _string(json['video_url']),
      season: seasonId == null
          ? null
          : SeasonArg(
              id: seasonId,
              title: _string(json['season_title']),
              creatorName: creatorName,
              creatorId: creatorId.isEmpty ? null : creatorId,
              skillworld: _string(json['skillworld']),
            ),
    );
  }

  /// Backend episode UUID; empty for legacy synthetic rows.
  final String id;

  final int epNumber;
  final String title;
  final String creatorUsername;

  /// Creator UUID from the payload's nested `creator` — used for profile
  /// navigation and follow writes.
  final String creatorId;
  final String creatorName;
  final String description;
  final String duration;
  final String views;
  final String postedAgo;
  final bool isNew;
  final bool postedToday;
  final double watchProgress;
  final String? thumbnailUrl;
  final String? videoUrl;

  /// The season this episode belongs to, when the caller knew it.
  ///
  /// Null on a row parsed from a payload that carried no `season_id`, and on
  /// the legacy synthetic rows. The player modal's "View Playlist" link is
  /// hidden in that case — there is no playlist to open, and a link that does
  /// nothing is worse than no link.
  final SeasonArg? season;

  bool get isUnwatched => watchProgress == 0;
  bool get isContinueWatching => watchProgress > 0 && watchProgress < 1;
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  String get epTag => 'EP ${epNumber.toString().padLeft(2, '0')}';

  /// "22k views · 5 hrs ago", dropping either half the payload didn't carry
  /// rather than printing a dangling separator around a blank.
  String get meta =>
      [views, postedAgo].where((s) => s.isNotEmpty).join(' · ');
}

class SubscriptionsState {
  SubscriptionsState({
    required this.creators,
    required this.episodes,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

  final List<SubscribedCreator> creators;
  final List<SubscriptionEpisode> episodes;
  final bool isLoading;

  /// True once `GET /creators/following/` has answered — before that,
  /// membership checks are "unknown", not "no".
  final bool hasLoaded;

  /// Last load failure; cleared on retry. The screen renders a retry panel
  /// instead of pretending the user follows nobody.
  final Object? error;

  SubscriptionsState copyWith({
    List<SubscribedCreator>? creators,
    List<SubscriptionEpisode>? episodes,
    bool? isLoading,
    bool? hasLoaded,
    Object? error,
    bool clearError = false,
  }) {
    return SubscriptionsState(
      creators: creators ?? this.creators,
      episodes: episodes ?? this.episodes,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether this creator is in the followed list, by UUID or username.
  bool isSubscribed(String idOrUsername) =>
      creators.any((c) => c.matches(idOrUsername));

  SubscribedCreator creatorOf(SubscriptionEpisode e) {
    for (final c in creators) {
      if ((e.creatorId.isNotEmpty && c.id == e.creatorId) ||
          (e.creatorUsername.isNotEmpty && c.username == e.creatorUsername)) {
        return c;
      }
    }
    // The episode payload itself names the creator — use it before "Unknown".
    if (e.creatorName.isNotEmpty || e.creatorUsername.isNotEmpty) {
      final name = e.creatorName.isNotEmpty ? e.creatorName : e.creatorUsername;
      return SubscribedCreator(
        id: e.creatorId,
        name: name,
        username: e.creatorUsername,
        initials: name[0].toUpperCase(),
      );
    }
    return SubscribedCreator(name: 'Unknown', username: 'unknown', initials: '?');
  }

  int newCountFor(SubscribedCreator c) => episodes
      .where(
        (e) =>
            e.isNew &&
            ((e.creatorId.isNotEmpty && e.creatorId == c.id) ||
                e.creatorUsername == c.username),
      )
      .length;

  List<SubscribedCreator> sortedCreators(SubscriptionListSort sort) {
    final list = List<SubscribedCreator>.of(creators);
    switch (sort) {
      case SubscriptionListSort.mostRelevant:
        break;
      case SubscriptionListSort.newActivity:
        list.sort((a, b) {
          if (a.hasUnseen != b.hasUnseen) return a.hasUnseen ? -1 : 1;
          return newCountFor(b).compareTo(newCountFor(a));
        });
      case SubscriptionListSort.aToZ:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return list;
  }

  List<SubscriptionEpisode> sortedEpisodes(
    SubscriptionFeedFilter filter, {
    SubscribedCreator? creator,
  }) {
    var source = episodes;
    if (creator != null) {
      source = source
          .where(
            (e) =>
                (creator.id.isNotEmpty && e.creatorId == creator.id) ||
                e.creatorUsername == creator.username,
          )
          .toList();
    }
    final sorted = source.toList()
      ..sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return 0;
      });
    switch (filter) {
      case SubscriptionFeedFilter.recent:
        return sorted;
      case SubscriptionFeedFilter.today:
        return sorted.where((e) => e.postedToday).toList();
      case SubscriptionFeedFilter.continueWatching:
        return sorted.where((e) => e.isContinueWatching).toList();
      case SubscriptionFeedFilter.unwatched:
        return sorted.where((e) => e.isUnwatched).toList();
    }
  }

  List<SubscriptionEpisode> feed({
    SubscriptionFeedFilter filter = SubscriptionFeedFilter.recent,
    String? creatorUsername,
  }) {
    SubscribedCreator? creator;
    if (creatorUsername != null) {
      for (final c in creators) {
        if (c.matches(creatorUsername)) {
          creator = c;
          break;
        }
      }
    }
    return sortedEpisodes(filter, creator: creator);
  }

  bool get isEmpty => creators.isEmpty;
}

class SubscriptionsNotifier extends Notifier<SubscriptionsState> {
  @override
  SubscriptionsState build() {
    Future.microtask(_load);
    return SubscriptionsState(
      creators: const [],
      episodes: const [],
      isLoading: true,
    );
  }

  Future<void> _load() async {
    try {
      // Nothing to fetch without a session; an empty list is the truth here.
      if (!await ref.read(tokenStoreProvider).hasSession()) {
        if (!ref.mounted) return;
        state = state.copyWith(
          creators: const [],
          episodes: const [],
          isLoading: false,
          hasLoaded: true,
          clearError: true,
        );
        return;
      }
      final repo = ref.read(subscriptionsRepositoryProvider);
      final creators = await repo.getFollowingCreators();
      final episodes = await repo.getFollowingEpisodes();
      if (!ref.mounted) return;
      state = state.copyWith(
        creators: creators.results,
        episodes: episodes.results,
        isLoading: false,
        hasLoaded: true,
        clearError: true,
      );
    } catch (error) {
      if (!ref.mounted) return;
      // Keep whatever was already on screen; expose the failure for a retry
      // panel. No sample data — an invented subscription list is worse than
      // an honest error.
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Re-fetch after a failure or a follow change.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }

  /// Follow [c] — optimistic add, real `POST /creators/{id}/follow/`,
  /// rollback + rethrow on failure. Callers toast success only after this
  /// future completes.
  Future<void> subscribe(SubscribedCreator c) async {
    if (state.creators.any(
      (x) => x.matches(c.id.isNotEmpty ? c.id : c.username),
    )) {
      return;
    }
    if (c.id.isEmpty) {
      // Without a creator UUID there is no endpoint to call — surfacing this
      // beats silently "following" nobody.
      throw const SkifluxFailure(SkifluxErrorKind.likeCommentReactionFailed);
    }
    final before = state.creators;
    state = state.copyWith(creators: [...before, c]);
    try {
      final result = await ref
          .read(subscriptionsRepositoryProvider)
          .toggleFollow(c.id);
      if (!ref.mounted) return;
      if (result.isFollowing == false) {
        // The toggle landed as an unfollow — the server already had a follow.
        // Reconcile to what the server says.
        state = state.copyWith(
          creators: state.creators.where((x) => !x.matches(c.id)).toList(),
        );
      }
      // New follows change the episode feed; refresh quietly.
      unawaited(Future.microtask(_load));
    } catch (_) {
      if (ref.mounted) state = state.copyWith(creators: before);
      rethrow;
    }
  }

  /// Unfollow — optimistic removal of the creator and their episodes, with
  /// full rollback on failure.
  Future<void> unsubscribe(SubscribedCreator creator) async {
    if (creator.id.isEmpty) {
      throw const SkifluxFailure(SkifluxErrorKind.likeCommentReactionFailed);
    }
    final beforeCreators = state.creators;
    final beforeEpisodes = state.episodes;
    // Remove by identity (id, then username), not by reference — callers may
    // hold a row built from a profile payload rather than the list's object.
    bool sameCreator(SubscribedCreator c) =>
        (creator.id.isNotEmpty && c.id == creator.id) ||
        (creator.username.isNotEmpty && c.username == creator.username);
    state = state.copyWith(
      creators: beforeCreators.where((c) => !sameCreator(c)).toList(),
      episodes: beforeEpisodes
          .where(
            (e) =>
                !(e.creatorId.isNotEmpty && e.creatorId == creator.id) &&
                e.creatorUsername != creator.username,
          )
          .toList(),
    );
    try {
      final result = await ref
          .read(subscriptionsRepositoryProvider)
          .toggleFollow(creator.id);
      if (!ref.mounted) return;
      if (result.isFollowing == true) {
        // Server state was already "not following"; the toggle re-followed.
        // Put the row back to match.
        state = state.copyWith(creators: [...state.creators, creator]);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          creators: beforeCreators,
          episodes: beforeEpisodes,
        );
      }
      rethrow;
    }
  }

  /// Single production predicate for "does the signed-in user follow X".
  bool isSubscribed(String idOrUsername) => state.isSubscribed(idOrUsername);

  /// Local-only: the spec exposes no per-creator notification preference
  /// endpoint, so this survives only as long as the process does.
  void setNotificationMode(
    SubscribedCreator creator,
    CreatorNotificationMode mode,
  ) {
    creator.notificationMode = mode;
    state = state.copyWith(creators: List.of(state.creators));
  }
}

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, SubscriptionsState>(
      SubscriptionsNotifier.new,
    );

// ── Formatting helpers (pure; unit-testable) ─────────────────────────

String _durationLabel(int seconds) {
  if (seconds <= 0) return '0:00';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
