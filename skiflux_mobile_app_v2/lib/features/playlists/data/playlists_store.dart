/// Demo playlists + SkillCoin wallet for unlock flows
/// (Home & In-app + Other Video Player).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/data/topup_repository.dart';

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
    // TODO(backend, blocking): replace local coverAsset file path with real CDN/backend playlist cover image URL — expects: String (network URL)
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
  String get detailMeta => '$viewsLabel · $episodeCount Episodes';
}

/// Badge shown on a coin pack card.
enum CoinPackBadge { none, bestValue, save }

/// A SkillCoin bundle offered in the Buy Coins flow (Other Video Player
/// Flow 04, `1256:27630`). Price is in Naira; rate is 1 coin = ₦6.
// TODO(backend, blocking): replace static kCoinPacks + kCoinRateNaira with backend-driven pricing and available coin pack offerings — expects: List<{coins: int, priceNaira: int, badge: CoinPackBadge, savePercent: int?}> plus rateNairaPerCoin: int
class CoinPack {
  const CoinPack({
    required this.coins,
    required this.priceNaira,
    this.badge = CoinPackBadge.none,
    this.savePercent,
  });

  final int coins;
  final int priceNaira;
  final CoinPackBadge badge;
  final int? savePercent;

  /// "₦600" / "₦1,100" — thousands-separated Naira.
  String get priceLabel => '₦${thousands(priceNaira)}';

  String? get badgeLabel => switch (badge) {
    CoinPackBadge.none => null,
    CoinPackBadge.bestValue => 'Best Value',
    CoinPackBadge.save => 'Save $savePercent%',
  };

  /// Thousands-separates an integer: 1240 → "1,240".
  static String thousands(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
  factory CoinPack.fromJson(Map<String, dynamic> json) {
    return CoinPack(
      coins: json['coins'] as int,
      priceNaira: json['price_naira'] as int? ?? json['price'] as int? ?? 0,
      badge: _parseBadge(json['badge'] as String?),
      savePercent: json['save_percent'] as int?,
    );
  }

  static CoinPackBadge _parseBadge(String? val) {
    if (val == 'best_value') return CoinPackBadge.bestValue;
    if (val == 'save') return CoinPackBadge.save;
    return CoinPackBadge.none;
  }
}

final coinPacksProvider = FutureProvider<List<CoinPack>>((ref) async {
  try {
    // Attempt to fetch from topup methods or a dedicated pricing endpoint.
    // The backend spec currently lacks a dedicated packs endpoint, so we
    // expect the packs to be returned as part of the topup configuration.
    final data = await ref.watch(topupRepositoryProvider).getTopupMethods();
    final packsRaw = data['coin_packs'] as List<dynamic>?;
    if (packsRaw != null && packsRaw.isNotEmpty) {
      return packsRaw.map((e) => CoinPack.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Snapshot of wallet + default playlist.
class PlaylistsState {
  PlaylistsState({required this.skillCoins, required this.defaultPlaylist});

  int skillCoins;
  final Playlist defaultPlaylist;

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
}

/// Riverpod choice: [NotifierProvider] — skillCoins and episode lock state
/// mutate via unlock (was ChangeNotifier). Matches notifications Pass 1.
// TODO(backend, blocking): replace in-memory SkillCoin wallet (balance, playlists, episode lock states) with real backend — expects: {skillCoins: int, playlists: List<{id: String, title: String, creatorName: String, creatorUsername: String, episodes: List<{id: String, number: int, title: String, duration: String, coinCost: int, state: PlaylistEpisodeState}>, description: String, viewsLabel: String, coverUrl: String}>}
class PlaylistsNotifier extends Notifier<PlaylistsState> {
  @override
  PlaylistsState build() {
    return PlaylistsState(skillCoins: 100, defaultPlaylist: _seedPlaylist());
  }

  /// Syncs the SkillCoin balance from `GET /wallet/my-wallet` (whole coins).
  void setSkillCoins(int coins) {
    state = PlaylistsState(
      skillCoins: coins < 0 ? 0 : coins,
      defaultPlaylist: state.defaultPlaylist,
    );
  }

  /// Returns `true` if unlock succeeded, `false` if not enough coins.
  bool tryUnlock(String episodeId) {
    final ep = state.byId(episodeId);
    if (ep == null || !ep.isLocked) return true;
    if (state.skillCoins < ep.coinCost) {
      state = PlaylistsState(
        skillCoins: state.skillCoins,
        defaultPlaylist: state.defaultPlaylist,
      );
      return false;
    }
    state.skillCoins -= ep.coinCost;
    ep.state = PlaylistEpisodeState.unlocked;
    state = PlaylistsState(
      skillCoins: state.skillCoins,
      defaultPlaylist: state.defaultPlaylist,
    );
    return true;
  }

  /// Credits [coins] to the wallet (Buy Coins success).
  void topUp(int coins) {
    state.skillCoins += coins;
    state = PlaylistsState(
      skillCoins: state.skillCoins,
      defaultPlaylist: state.defaultPlaylist,
    );
  }

  /// Debits [coins] from the wallet (withdrawal), clamped at zero.
  void withdraw(int coins) {
    state.skillCoins = (state.skillCoins - coins).clamp(0, 1 << 31);
    state = PlaylistsState(
      skillCoins: state.skillCoins,
      defaultPlaylist: state.defaultPlaylist,
    );
  }

  void unlockForDemo(String episodeId) {
    final ep = state.byId(episodeId);
    if (ep == null) return;
    if (ep.isLocked && state.skillCoins >= ep.coinCost) {
      state.skillCoins -= ep.coinCost;
    }
    ep.state = PlaylistEpisodeState.unlocked;
    state = PlaylistsState(
      skillCoins: state.skillCoins,
      defaultPlaylist: state.defaultPlaylist,
    );
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

final playlistsProvider = NotifierProvider<PlaylistsNotifier, PlaylistsState>(
  PlaylistsNotifier.new,
);

/// SkillCoin packs offered in Buy Coins (Other Video Player Flow 04).
/// Rate: 1 coin = ₦6 (Flow 03 `1256:27795`).
const int kCoinRateNaira = 6;

// Removed static kCoinPacks; use coinPacksProvider instead.

/// Playback prefs for More Menu chips (session-local).
class PlayerPrefsState {
  const PlayerPrefsState({
    this.speed = 1.0,
    this.captionsOn = false,
    this.autoScrollOn = false,
  });

  final double speed;
  final bool captionsOn;
  final bool autoScrollOn;

  String get speedLabel {
    if (speed == speed.roundToDouble()) return '${speed.toInt()}.0x';
    return '${speed}x';
  }

  /// The same value without the trailing `.0`, for the full-screen player's
  /// 48px control circle — Figma `3416:12837` prints "1x", not "1.0x".
  String get speedLabelShort {
    if (speed == speed.roundToDouble()) return '${speed.toInt()}x';
    return '${speed}x';
  }

  PlayerPrefsState copyWith({
    double? speed,
    bool? captionsOn,
    bool? autoScrollOn,
  }) {
    return PlayerPrefsState(
      speed: speed ?? this.speed,
      captionsOn: captionsOn ?? this.captionsOn,
      autoScrollOn: autoScrollOn ?? this.autoScrollOn,
    );
  }
}

/// Riverpod choice: [NotifierProvider] — speed/captions/auto-scroll toggle
/// (was ChangeNotifier). Separate from playlists wallet.
class PlayerPrefsNotifier extends Notifier<PlayerPrefsState> {
  @override
  PlayerPrefsState build() => const PlayerPrefsState();

  void setSpeed(double value) {
    state = state.copyWith(speed: value);
  }

  void toggleCaptions() {
    state = state.copyWith(captionsOn: !state.captionsOn);
  }

  void toggleAutoScroll() {
    state = state.copyWith(autoScrollOn: !state.autoScrollOn);
  }
}

final playerPrefsProvider =
    NotifierProvider<PlayerPrefsNotifier, PlayerPrefsState>(
      PlayerPrefsNotifier.new,
    );
