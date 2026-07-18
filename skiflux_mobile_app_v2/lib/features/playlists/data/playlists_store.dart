/// Demo playlists + SkillCoin wallet for unlock flows
/// (Home & In-app + Other Video Player).
library;

import 'package:flutter/foundation.dart';

enum PlaylistEpisodeState { unlocked, locked, completed }

class PlaylistEpisode {
  PlaylistEpisode({
    required this.id,
    required this.number,
    required this.title,
    required this.duration,
    required this.coinCost,
    this.state = PlaylistEpisodeState.locked,
  });

  final String id;
  final int number;
  final String title;
  final String duration;
  final int coinCost;
  PlaylistEpisodeState state;

  String get epTag => 'EP ${number.toString().padLeft(2, '0')}';

  bool get isLocked => state == PlaylistEpisodeState.locked;
  bool get isUnlocked =>
      state == PlaylistEpisodeState.unlocked ||
      state == PlaylistEpisodeState.completed;
}

class Playlist {
  Playlist({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.creatorUsername,
    required this.episodes,
    this.description =
        'Learn how to design scalable systems with reusable components, '
        'tokens, and patterns. Build a library that ships faster and stays '
        'consistent across products.',
    this.viewsLabel = '550.7k views',
    this.coverAsset = 'assets/home_video_cover.png',
  });

  final String id;
  final String title;
  final String creatorName;
  final String creatorUsername;
  final List<PlaylistEpisode> episodes;
  final String description;
  final String viewsLabel;
  final String coverAsset;

  int get episodeCount => episodes.length;
  String get metaLine => '$creatorName · $episodeCount Episodes';
  String get detailMeta =>
      '$viewsLabel · $episodeCount Episodes';
}

/// Session store: coins + default playlist (UI Design System).
class PlaylistsStore extends ChangeNotifier {
  PlaylistsStore._();

  static final PlaylistsStore instance = PlaylistsStore._();

  /// Demo wallet — enough to unlock a few 25-coin episodes.
  int skillCoins = 100;

  late final Playlist defaultPlaylist = _seedPlaylist();

  PlaylistEpisode? byId(String id) {
    for (final e in defaultPlaylist.episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  PlaylistEpisode? byNumber(int number) {
    for (final e in defaultPlaylist.episodes) {
      if (e.number == number) return e;
    }
    return null;
  }

  /// Returns `true` if unlock succeeded, `false` if not enough coins.
  bool tryUnlock(String episodeId) {
    final ep = byId(episodeId);
    if (ep == null || !ep.isLocked) return true;
    if (skillCoins < ep.coinCost) {
      notifyListeners();
      return false;
    }
    skillCoins -= ep.coinCost;
    ep.state = PlaylistEpisodeState.unlocked;
    notifyListeners();
    return true;
  }

  void unlockForDemo(String episodeId) {
    final ep = byId(episodeId);
    if (ep == null) return;
    if (ep.isLocked && skillCoins >= ep.coinCost) {
      skillCoins -= ep.coinCost;
    }
    ep.state = PlaylistEpisodeState.unlocked;
    notifyListeners();
  }

  static Playlist _seedPlaylist() {
    return Playlist(
      id: 'pl-ui-design-system',
      title: 'UI Design System',
      creatorName: 'Amara Design',
      creatorUsername: 'amara',
      description:
          'A complete walkthrough of building a modern design system — '
          'from foundations (color, type, spacing) to components, '
          'documentation, and shipping the library to production teams.',
      viewsLabel: '550.7k views',
      episodes: [
        PlaylistEpisode(
          id: 'ep-01',
          number: 1,
          title: 'Introduction to UI Design Thinking',
          duration: '12:40',
          coinCost: 0,
          state: PlaylistEpisodeState.completed,
        ),
        PlaylistEpisode(
          id: 'ep-02',
          number: 2,
          title: 'Color Tokens & Hierarchy',
          duration: '15:10',
          coinCost: 25,
          state: PlaylistEpisodeState.unlocked,
        ),
        PlaylistEpisode(
          id: 'ep-03',
          number: 3,
          title: 'Spacing & Layout Grid',
          duration: '14:05',
          coinCost: 25,
          state: PlaylistEpisodeState.unlocked,
        ),
        PlaylistEpisode(
          id: 'ep-04',
          number: 4,
          title: 'Typography Scale',
          duration: '11:20',
          coinCost: 25,
          state: PlaylistEpisodeState.locked,
        ),
        PlaylistEpisode(
          id: 'ep-05',
          number: 5,
          title: 'Component Anatomy',
          duration: '18:00',
          coinCost: 25,
          state: PlaylistEpisodeState.locked,
        ),
        PlaylistEpisode(
          id: 'ep-06',
          number: 6,
          title: 'Design Systems from Scratch',
          duration: '20:15',
          coinCost: 25,
          state: PlaylistEpisodeState.locked,
        ),
        PlaylistEpisode(
          id: 'ep-07',
          number: 7,
          title: 'Accessibility & Contrast',
          duration: '13:30',
          coinCost: 25,
          state: PlaylistEpisodeState.locked,
        ),
        PlaylistEpisode(
          id: 'ep-08',
          number: 8,
          title: 'Shipping the Library',
          duration: '16:45',
          coinCost: 25,
          state: PlaylistEpisodeState.locked,
        ),
      ],
    );
  }
}

/// Playback prefs for More Menu chips (session-local).
class PlayerPrefsStore extends ChangeNotifier {
  PlayerPrefsStore._();

  static final PlayerPrefsStore instance = PlayerPrefsStore._();

  double speed = 1.0;
  bool captionsOn = false;
  bool autoScrollOn = false;

  String get speedLabel {
    if (speed == speed.roundToDouble()) return '${speed.toInt()}.0x';
    return '${speed}x';
  }

  void setSpeed(double value) {
    speed = value;
    notifyListeners();
  }

  void toggleCaptions() {
    captionsOn = !captionsOn;
    notifyListeners();
  }

  void toggleAutoScroll() {
    autoScrollOn = !autoScrollOn;
    notifyListeners();
  }
}
