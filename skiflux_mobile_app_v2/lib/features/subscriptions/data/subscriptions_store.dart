/// Subscriptions domain models + seeded demo data.
///
/// ⚠️ Demo content only — mirrors the search dataset's creators. Seeded as
/// "already subscribed" so the tab lands on the populated home (flow 05);
/// unsubscribing everything surfaces the empty state (flow 04).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feed filter — the "Recent" control's sheet options (user-specified).
enum SubscriptionFeedFilter { recent, today, continueWatching, unwatched }

extension SubscriptionFeedFilterLabel on SubscriptionFeedFilter {
  String get label => switch (this) {
        SubscriptionFeedFilter.recent => 'Recent',
        SubscriptionFeedFilter.today => 'Today',
        SubscriptionFeedFilter.continueWatching => 'Continue watching',
        SubscriptionFeedFilter.unwatched => 'Unwatched',
      };
}

/// All Subscriptions sort — the "Filter" link's sheet options
/// (user-specified).
enum SubscriptionListSort { mostRelevant, newActivity, aToZ }

extension SubscriptionListSortLabel on SubscriptionListSort {
  String get label => switch (this) {
        SubscriptionListSort.mostRelevant => 'Most relevant',
        SubscriptionListSort.newActivity => 'New activity',
        SubscriptionListSort.aToZ => 'A–Z',
      };
}

/// Per-creator post-notification level — the bell pill's dropdown options
/// (user-specified: All / Personalized / None, plus Unsubscribe).
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

  final String name;
  final String username;
  final String initials;

  /// Bell dropdown in All Subscriptions — All / Personalized / None.
  CreatorNotificationMode notificationMode;

  /// Purple dot on the avatar in All Subscriptions (unseen content).
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

  final int epNumber;
  final String title;

  /// Key into the creators list.
  final String creatorUsername;
  final String duration;
  final String views;

  /// "5 hrs ago" — display only.
  final String postedAgo;

  /// Purple "New" label + sorts to the top of the feed.
  final bool isNew;

  /// Posted today — the "Today" filter bucket.
  final bool postedToday;

  /// 0 = untouched, 0<x<1 = continue watching, 1 = finished.
  final double watchProgress;

  bool get isUnwatched => watchProgress == 0;
  bool get isContinueWatching => watchProgress > 0 && watchProgress < 1;

  String get epTag => 'EP ${epNumber.toString().padLeft(2, '0')}';
  String get meta => '$views · $postedAgo';
}

/// In-memory snapshot for the subscriptions tab.
class SubscriptionsState {
  SubscriptionsState({
    required this.creators,
    required this.episodes,
  });

  final List<SubscribedCreator> creators;
  final List<SubscriptionEpisode> episodes;

  SubscribedCreator creatorOf(SubscriptionEpisode e) =>
      creators.firstWhere((c) => c.username == e.creatorUsername);

  int newCountFor(SubscribedCreator c) =>
      episodes.where((e) => e.creatorUsername == c.username && e.isNew).length;

  /// All Subscriptions list, sorted per the "Filter" sheet choice.
  List<SubscribedCreator> sortedCreators(SubscriptionListSort sort) {
    final list = List<SubscribedCreator>.of(creators);
    switch (sort) {
      case SubscriptionListSort.mostRelevant:
        break; // seed order = relevance for the demo dataset
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

  /// Feed for the home / creator-filtered screens: New first, then the rest,
  /// each group keeping seed order (already newest-first).
  List<SubscriptionEpisode> feed({
    String? creatorUsername,
    SubscriptionFeedFilter filter = SubscriptionFeedFilter.recent,
  }) {
    Iterable<SubscriptionEpisode> list = episodes.where(
      // Unsubscribed creators drop out of the feed.
      (e) => creators.any((c) => c.username == e.creatorUsername),
    );
    if (creatorUsername != null) {
      list = list.where((e) => e.creatorUsername == creatorUsername);
    }
    list = switch (filter) {
      SubscriptionFeedFilter.recent => list,
      SubscriptionFeedFilter.today => list.where((e) => e.postedToday),
      SubscriptionFeedFilter.continueWatching =>
        list.where((e) => e.isContinueWatching),
      SubscriptionFeedFilter.unwatched => list.where((e) => e.isUnwatched),
    };
    final sorted = list.toList()
      ..sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return 0; // stable: keeps seed (recency) order within groups
      });
    return sorted;
  }
}

/// Riverpod choice: [NotifierProvider] — creators list mutates (bell mode /
/// unsubscribe). Episodes are fixed demo seed. Was a static abstract store.
class SubscriptionsNotifier extends Notifier<SubscriptionsState> {
  @override
  SubscriptionsState build() {
    return SubscriptionsState(
      creators: [
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
      ],
      episodes: _seedEpisodes,
    );
  }

  void unsubscribe(SubscribedCreator c) {
    state = SubscriptionsState(
      creators: state.creators.where((x) => x.username != c.username).toList(),
      episodes: state.episodes,
    );
  }

  void setNotificationMode(
    SubscribedCreator c,
    CreatorNotificationMode mode,
  ) {
    c.notificationMode = mode;
    state = SubscriptionsState(
      creators: List<SubscribedCreator>.of(state.creators),
      episodes: state.episodes,
    );
  }

  static const List<SubscriptionEpisode> _seedEpisodes = [
    // Amara — 3 new (matches the "3 new" story badge in Figma).
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
    // Kojo
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
    // Lola
    SubscriptionEpisode(
      epNumber: 2,
      title: 'Easing Curves that Feel Right',
      creatorUsername: 'lolamotion',
      duration: '12:40',
      views: '9k views',
      postedAgo: '1 day ago',
      isNew: true,
    ),
    // Dan — older, watched.
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

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, SubscriptionsState>(
  SubscriptionsNotifier.new,
);
