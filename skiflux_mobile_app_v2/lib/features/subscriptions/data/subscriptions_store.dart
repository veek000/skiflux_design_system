library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscriptions_repository.dart';

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
    this.notificationMode = CreatorNotificationMode.personalized,
    this.hasUnseen = false,
  });

  factory SubscribedCreator.fromJson(Map<String, dynamic> json) {
    final name = (json['display_name'] as String?) ?? (json['username'] as String?) ?? '';
    return SubscribedCreator(
      name: name,
      username: (json['username'] as String?) ?? '',
      initials: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
    );
  }

  final String name;
  final String username;
  final String initials;
  CreatorNotificationMode notificationMode;
  bool hasUnseen;

  String get handle => '@$username';
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
  });

  factory SubscriptionEpisode.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] ?? {};
    return SubscriptionEpisode(
      epNumber: (json['episode_number'] as int?) ?? 0,
      title: (json['title'] as String?) ?? '',
      creatorUsername: (creator['username'] as String?) ?? '',
      duration: (json['duration_formatted'] as String?) ?? '0:00',
      views: '${json['view_count'] ?? 0} views',
      postedAgo: 'Recently',
    );
  }

  final int epNumber;
  final String title;
  final String creatorUsername;
  final String duration;
  final String views;
  final String postedAgo;
  final bool isNew;
  final bool postedToday;
  final double watchProgress;

  bool get isUnwatched => watchProgress == 0;
  bool get isContinueWatching => watchProgress > 0 && watchProgress < 1;

  String get epTag => 'EP ${epNumber.toString().padLeft(2, '0')}';
  String get meta => '$views · $postedAgo';
}

class SubscriptionsState {
  SubscriptionsState({
    required this.creators, 
    required this.episodes,
    this.isLoading = false,
  });

  final List<SubscribedCreator> creators;
  final List<SubscriptionEpisode> episodes;
  final bool isLoading;

  SubscriptionsState copyWith({
    List<SubscribedCreator>? creators,
    List<SubscriptionEpisode>? episodes,
    bool? isLoading,
  }) {
    return SubscriptionsState(
      creators: creators ?? this.creators,
      episodes: episodes ?? this.episodes,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  SubscribedCreator creatorOf(SubscriptionEpisode e) {
    try {
      return creators.firstWhere((c) => c.username == e.creatorUsername);
    } catch (_) {
      return SubscribedCreator(name: 'Unknown', username: 'unknown', initials: '?');
    }
  }

  int newCountFor(SubscribedCreator c) =>
      episodes.where((e) => e.creatorUsername == c.username && e.isNew).length;

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

  List<SubscriptionEpisode> sortedEpisodes(SubscriptionFeedFilter filter, {SubscribedCreator? creator}) {
    var source = episodes;
    if (creator != null) {
      source = source.where((e) => e.creatorUsername == creator.username).toList();
    }
    switch (filter) {
      case SubscriptionFeedFilter.recent:
        return source;
      case SubscriptionFeedFilter.today:
        return source.where((e) => e.postedToday).toList();
      case SubscriptionFeedFilter.continueWatching:
        return source.where((e) => e.isContinueWatching).toList();
      case SubscriptionFeedFilter.unwatched:
        return source.where((e) => e.isUnwatched).toList();
    }
  }

  List<SubscriptionEpisode> feed({
    SubscriptionFeedFilter filter = SubscriptionFeedFilter.recent,
    String? creatorUsername,
  }) {
    SubscribedCreator? creator;
    if (creatorUsername != null) {
      try {
        creator = creators.firstWhere((c) => c.username == creatorUsername);
      } catch (_) {}
    }
    return sortedEpisodes(filter, creator: creator);
  }

  bool get isEmpty => creators.isEmpty;
}

class SubscriptionsNotifier extends Notifier<SubscriptionsState> {
  @override
  SubscriptionsState build() {
    _load();
    return SubscriptionsState(creators: [], episodes: [], isLoading: true);
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      
      final creatorsRes = await repo.getFollowingCreators();
      final episodesRes = await repo.getFollowingEpisodes();
      
      final creatorsList = (creatorsRes['results'] as List?)?.cast<Map<String, dynamic>>().map((e) => SubscribedCreator.fromJson(e)).toList() ?? [];
      final episodesList = (episodesRes['results'] as List?)?.cast<Map<String, dynamic>>().map((e) => SubscriptionEpisode.fromJson(e)).toList() ?? [];
      
      state = state.copyWith(
        creators: creatorsList,
        episodes: episodesList,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void unsubscribe(SubscribedCreator creator) {
    state = state.copyWith(
      creators: state.creators.where((c) => c != creator).toList(),
      episodes: state.episodes.where((e) => e.creatorUsername != creator.username).toList(),
    );
  }
  
  void subscribe(SubscribedCreator c) {
    if (state.creators.any((x) => x.username == c.username)) return;
    state = state.copyWith(
      creators: [...state.creators, c],
      episodes: state.episodes,
    );
  }

  void setNotificationMode(SubscribedCreator creator, CreatorNotificationMode mode) {
    creator.notificationMode = mode;
    state = state.copyWith(creators: List.of(state.creators));
  }
}

final subscriptionsProvider = NotifierProvider<SubscriptionsNotifier, SubscriptionsState>(
  SubscriptionsNotifier.new,
);
