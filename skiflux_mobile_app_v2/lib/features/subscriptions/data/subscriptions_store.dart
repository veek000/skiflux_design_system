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
    return SubscriptionsState(
      creators: _seedCreators,
      episodes: _seedEpisodes,
      isLoading: true,
    );
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      
      final creatorsRes = await repo.getFollowingCreators();
      final episodesRes = await repo.getFollowingEpisodes();
      
      if (!ref.mounted) return;

      final creatorsList = (creatorsRes['results'] as List?)?.cast<Map<String, dynamic>>().map((e) => SubscribedCreator.fromJson(e)).toList() ?? [];
      final episodesList = (episodesRes['results'] as List?)?.cast<Map<String, dynamic>>().map((e) => SubscriptionEpisode.fromJson(e)).toList() ?? [];
      
      state = state.copyWith(
        creators: creatorsList.isNotEmpty ? creatorsList : _seedCreators,
        episodes: episodesList.isNotEmpty ? episodesList : _seedEpisodes,
        isLoading: false,
      );
    } catch (_) {
      if (!ref.mounted) return;
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

  bool isSubscribed(String username) =>
      state.creators.any((c) => c.username == username);

  void setNotificationMode(SubscribedCreator creator, CreatorNotificationMode mode) {
    creator.notificationMode = mode;
    state = state.copyWith(creators: List.of(state.creators));
  }

  static final List<SubscribedCreator> _seedCreators = [
    SubscribedCreator(
      name: 'Amara Design',
      username: 'amara',
      initials: 'A',
      notificationMode: CreatorNotificationMode.all,
      hasUnseen: true,
    ),
    SubscribedCreator(
      name: 'Kojo Sketches',
      username: 'kojosketch',
      initials: 'K',
      hasUnseen: true,
    ),
    SubscribedCreator(
      name: 'Design Dan',
      username: 'designdan',
      initials: 'D',
      notificationMode: CreatorNotificationMode.none,
    ),
    SubscribedCreator(
      name: 'Lola Motion',
      username: 'lolamotion',
      initials: 'L',
      hasUnseen: true,
    ),
  ];

  static const List<SubscriptionEpisode> _seedEpisodes = [
    SubscriptionEpisode(
      epNumber: 6,
      title: 'Designing Interfaces People Trust',
      creatorUsername: 'amara',
      duration: '20:00',
      views: '22k views',
      postedAgo: '5 hrs ago',
      isNew: true,
      postedToday: true,
    ),
    SubscriptionEpisode(
      epNumber: 5,
      title: 'Introduction to UI Design Thinking',
      creatorUsername: 'amara',
      duration: '18:24',
      views: '31k views',
      postedAgo: '9 hrs ago',
      isNew: true,
      postedToday: true,
    ),
    SubscriptionEpisode(
      epNumber: 4,
      title: 'Design Critique, Live',
      creatorUsername: 'amara',
      duration: '24:45',
      views: '48k views',
      postedAgo: '2 days ago',
      isNew: true,
    ),
    SubscriptionEpisode(
      epNumber: 3,
      title: 'Color Systems from Scratch',
      creatorUsername: 'amara',
      duration: '15:30',
      views: '102k views',
      postedAgo: '1 week ago',
      watchProgress: 0.4,
    ),
    SubscriptionEpisode(
      epNumber: 8,
      title: 'Auto Layout Deep Dive',
      creatorUsername: 'kojosketch',
      duration: '21:12',
      views: '18k views',
      postedAgo: '3 hrs ago',
      isNew: true,
      postedToday: true,
    ),
    SubscriptionEpisode(
      epNumber: 7,
      title: 'Prototyping Motion in Figma',
      creatorUsername: 'kojosketch',
      duration: '19:03',
      views: '54k views',
      postedAgo: '4 days ago',
      watchProgress: 0.75,
    ),
    SubscriptionEpisode(
      epNumber: 2,
      title: 'Easing Curves that Feel Right',
      creatorUsername: 'lolamotion',
      duration: '12:40',
      views: '9k views',
      postedAgo: '1 day ago',
      isNew: true,
    ),
    SubscriptionEpisode(
      epNumber: 1,
      title: 'Portfolio Reviews, Unfiltered',
      creatorUsername: 'designdan',
      duration: '28:10',
      views: '76k views',
      postedAgo: '2 weeks ago',
      watchProgress: 1,
    ),
  ];
}

final subscriptionsProvider = NotifierProvider<SubscriptionsNotifier, SubscriptionsState>(
  SubscriptionsNotifier.new,
);
