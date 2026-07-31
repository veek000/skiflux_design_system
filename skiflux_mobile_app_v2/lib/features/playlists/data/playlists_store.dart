/// Demo playlists + the SkillCoin balance view used by unlock flows
/// (Home & In-app + Other Video Player).
///
/// Money honesty: `skillCoins` here is a *derived whole-coin view* of the
/// wallet's real [Decimal] balance (`walletProvider.remoteWallet.balance`),
/// synced by the wallet store using floor — it never mints, spends, or
/// invents coins on its own. All actual money movement goes through the
/// wallet repositories (`topup`, `withdrawals`, `episodes/purchase`).
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
import '../../wallet/data/topup_repository.dart';
import 'seasons_repository.dart';

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
    this.coverUrl,
    this.declaredEpisodeCount,
  });

  final String id;
  final String title;
  final String creatorName;
  final String creatorUsername;
  final List<PlaylistEpisode> episodes;
  final String description;
  final String viewsLabel;

  /// Placeholder art, used only when [coverUrl] is null.
  final String coverAsset;

  /// `SeasonList.cover_url` — the real cover. Null for a seeded playlist, or a
  /// season the backend has no artwork for.
  final String? coverUrl;

  /// `SeasonList.episode_count`, kept because the list endpoint sends a count
  /// without the rows: a season shell can say "8 Episodes" before its episodes
  /// have been fetched.
  final int? declaredEpisodeCount;

  bool get hasNetworkCover => coverUrl != null && coverUrl!.isNotEmpty;

  int get episodeCount =>
      episodes.isNotEmpty ? episodes.length : (declaredEpisodeCount ?? 0);

  String get metaLine => '$creatorName · $episodeCount Episodes';

  /// Views are omitted by `SeasonList`, so a backend-loaded playlist drops that
  /// half of the line rather than printing a number nobody sent.
  String get detailMeta => viewsLabel.isEmpty
      ? '$episodeCount Episodes'
      : '$viewsLabel · $episodeCount Episodes';

  Playlist copyWith({List<PlaylistEpisode>? episodes}) => Playlist(
    id: id,
    title: title,
    creatorName: creatorName,
    creatorUsername: creatorUsername,
    episodes: episodes ?? this.episodes,
    description: description,
    viewsLabel: viewsLabel,
    coverAsset: coverAsset,
    coverUrl: coverUrl,
    declaredEpisodeCount: declaredEpisodeCount,
  );
}

/// Badge shown on a coin pack card.
enum CoinPackBadge { none, bestValue, save }

/// A SkillCoin bundle offered in the Buy Coins flow (Other Video Player
/// Flow 04, `1256:27630`). [price] is the exact fiat (Naira) amount that
/// `POST /wallet/topup/initiate` will charge — a [Decimal], never a double,
/// and never defaulted: a pack whose price can't be parsed is dropped.
class CoinPack {
  CoinPack({
    required this.coins,
    required this.price,
    this.badge = CoinPackBadge.none,
    this.savePercent,
  });

  final int coins;

  /// Exact fiat price in Naira.
  final Decimal price;

  final CoinPackBadge badge;
  final int? savePercent;

  /// "₦600" / "₦1,100" — thousands-separated; a fractional price keeps its
  /// decimals ("₦1,100.50") rather than being rounded either way.
  String get priceLabel => '₦${thousandsOf(price)}';

  /// The wire form for `amount_fiat` — string decimal, 2dp.
  String get amountFiatWire => price.toStringAsFixed(2);

  /// Effective per-coin rate for this pack ("≈ ₦5.50 / coin"), computed from
  /// the pack's own price so discounted packs don't display a false flat
  /// rate. Approximate by construction, hence the ≈.
  String get approxRateLabel {
    if (coins <= 0) return '';
    final rate = (price / Decimal.fromInt(coins)).toDecimal(
      scaleOnInfinitePrecision: 2,
    );
    return '≈ ₦${thousandsOf(rate)} / coin';
  }

  String? get badgeLabel => switch (badge) {
    CoinPackBadge.none => null,
    CoinPackBadge.bestValue => 'Best Value',
    CoinPackBadge.save => savePercent == null ? 'Save' : 'Save $savePercent%',
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

  /// Thousands-separates a [Decimal], keeping real fractional digits and
  /// dropping a bare ".00" ("1100.00" → "1,100", "1100.50" → "1,100.50").
  static String thousandsOf(Decimal value) {
    final normalized = value.scale <= 0 || value == value.truncate()
        ? value.truncate().toBigInt().toString()
        : value.toStringAsFixed(2);
    final parts = normalized.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final intDigits = sign.isEmpty ? parts.first : parts.first.substring(1);
    final buf = StringBuffer(sign);
    for (var i = 0; i < intDigits.length; i++) {
      if (i > 0 && (intDigits.length - i) % 3 == 0) buf.write(',');
      buf.write(intDigits[i]);
    }
    if (parts.length > 1 && parts[1] != '00') buf.write('.${parts[1]}');
    return buf.toString();
  }

  /// Tolerant parse for a backend pack entry. Money convention: prices may
  /// arrive as string decimals ("1100.00") or JSON ints; a pack with no
  /// valid positive price (or no coin count) returns null and is dropped —
  /// prices are never defaulted to zero.
  static CoinPack? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);

    final coins = _intFrom(json['coins']) ?? _intFrom(json['skillcoins']);
    final price = _decimalFrom(json['price_naira']) ??
        _decimalFrom(json['price_fiat']) ??
        _decimalFrom(json['price']);
    if (coins == null || coins <= 0 || price == null || price <= Decimal.zero) {
      return null;
    }
    return CoinPack(
      coins: coins,
      price: price,
      badge: _parseBadge(json['badge'] as String?),
      savePercent: _intFrom(json['save_percent']),
    );
  }

  static int? _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.floor();
    if (value is String) {
      final d = Decimal.tryParse(value.trim());
      // Floor: never advertise more coins than the pack grants.
      return d?.floor().toBigInt().toInt();
    }
    return null;
  }

  static Decimal? _decimalFrom(Object? value) {
    if (value is String) return Decimal.tryParse(value.trim());
    if (value is int) return Decimal.fromInt(value);
    // A double price would reintroduce binary floating point — parse its
    // shortest-decimal form instead of multiplying through doubles.
    if (value is num) return Decimal.tryParse(value.toString());
    return null;
  }

  static CoinPackBadge _parseBadge(String? val) {
    if (val == 'best_value' || val == 'popular') return CoinPackBadge.bestValue;
    if (val == 'save') return CoinPackBadge.save;
    return CoinPackBadge.none;
  }
}

/// Coin packs for the Buy Coins surfaces.
///
/// The OpenAPI spec has **no coin-pack endpoint** (confirmed against
/// SkiFlux_API.yaml — `GET /wallet/coin-packs` is only *proposed* in
/// BACKEND_AI_BUILD_SPEC.md §1.1). `GET /wallet/topup/methods` is untyped,
/// so if the backend starts including `coin_packs` / `packs` there they are
/// used; otherwise the static client-fallback pricing below is shown.
/// Entries without a valid price are dropped, never defaulted.
final coinPacksProvider = FutureProvider<List<CoinPack>>((ref) async {
  try {
    final data = await ref.watch(topupRepositoryProvider).getTopupMethods();
    final packsRaw = data['coin_packs'] ?? data['packs'];
    if (packsRaw is List && packsRaw.isNotEmpty) {
      final parsed = packsRaw
          .map(CoinPack.tryParse)
          .whereType<CoinPack>()
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return _fallbackCoinPacks();
  } catch (_) {
    // Discovery failed (offline / signed out). The packs are the app's own
    // offer catalogue, not user data, so the client fallback is still shown;
    // any purchase is charged at exactly the displayed amount and only
    // credited after backend verification.
    return _fallbackCoinPacks();
  }
});

/// CLIENT FALLBACK PRICING — not backend-sourced (no pack endpoint exists in
/// the spec). The displayed price is exactly what `topup/initiate` charges;
/// coins credited are decided and verified by the backend.
List<CoinPack> _fallbackCoinPacks() => [
  CoinPack(coins: 100, price: Decimal.fromInt(600)),
  CoinPack(
    coins: 200,
    price: Decimal.fromInt(1100),
    badge: CoinPackBadge.bestValue,
  ),
  CoinPack(
    coins: 500,
    price: Decimal.fromInt(2500),
    badge: CoinPackBadge.save,
    savePercent: 17,
  ),
  CoinPack(
    coins: 1000,
    price: Decimal.fromInt(4500),
    badge: CoinPackBadge.save,
    savePercent: 25,
  ),
];

/// Snapshot of the coin view + default playlist.
class PlaylistsState {
  PlaylistsState({
    required this.skillCoins,
    required this.defaultPlaylist,
    this.fromBackend = false,
  });

  /// Whole-coin display balance — floor of the wallet's real Decimal
  /// balance, synced by the wallet store. Not a source of truth.
  int skillCoins;
  final Playlist defaultPlaylist;

  /// True once `GET /seasons` has answered. While false the catalogue — and
  /// every lock state in it — is the demo seed, so nothing here should be
  /// treated as this user's real entitlements.
  final bool fromBackend;

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

/// Riverpod choice: [NotifierProvider] — episode lock state mutates via
/// unlock. The coin figure is a mirror of the wallet (see [setSkillCoins]).
///
/// The catalogue starts as the demo seed and is replaced by `GET /seasons` +
/// `GET /seasons/{id}/episodes` on [refreshFromBackend]; from then on every
/// lock state is the server's own `is_locked` / `is_purchased`.
class PlaylistsNotifier extends Notifier<PlaylistsState> {
  @override
  PlaylistsState build() {
    // Seeded at 0, not a fake balance: a signed-in user sees their real
    // balance as soon as the wallet refresh lands, and a signed-out user is
    // honestly shown zero coins rather than 100 that don't exist.
    return PlaylistsState(skillCoins: 0, defaultPlaylist: _seedPlaylist());
  }

  /// Syncs the SkillCoin display from `GET /wallet/my-wallet`. Callers pass
  /// the floor of the real Decimal balance — a spendable balance is never
  /// rounded up.
  void setSkillCoins(int coins) {
    state = PlaylistsState(
      skillCoins: coins < 0 ? 0 : coins,
      defaultPlaylist: state.defaultPlaylist,
      fromBackend: state.fromBackend,
    );
  }

  /// Loads the real catalogue: `GET /seasons`, then the first season's
  /// episodes.
  ///
  /// Signed out this is a no-op — the seed *is* the demo, and there are no
  /// entitlements to speak of. Signed in, the seed is replaced wholesale, so a
  /// user never sees fabricated "Unlocked" rows against their own account. A
  /// failure leaves whatever was already there: stale beats wrong, and beats a
  /// blank screen.
  ///
  /// Only the first season is hydrated because every playlist surface in the
  /// app reads [PlaylistsState.defaultPlaylist]; a real browse list is a
  /// screen that does not exist yet.
  Future<void> refreshFromBackend() async {
    if (_loading) return;
    _loading = true;
    try {
      if (!await ref.read(tokenStoreProvider).hasSession()) return;
      final seasons = await ref.read(seasonsRepositoryProvider).getSeasons();
      if (seasons.isEmpty) return;
      final hydrated = await ref
          .read(seasonsRepositoryProvider)
          .getSeasonWithEpisodes(seasons.first);
      state = PlaylistsState(
        skillCoins: state.skillCoins,
        defaultPlaylist: hydrated,
        fromBackend: true,
      );
    } catch (_) {
      // Keep the current catalogue — see the doc above.
    } finally {
      _loading = false;
    }
  }

  bool _loading = false;

  /// Marks [episodeId] unlocked after `POST /episodes/purchase` returned
  /// 2xx, mirroring the confirmed spend locally (clamped at zero) until the
  /// authoritative wallet refresh lands. Never call this before the backend
  /// has accepted the purchase.
  void markPurchased(String episodeId) {
    final ep = state.byId(episodeId);
    if (ep == null) return;
    var coins = state.skillCoins;
    if (ep.isLocked) {
      coins = (coins - ep.coinCost).clamp(0, coins);
    }
    ep.state = PlaylistEpisodeState.unlocked;
    state = PlaylistsState(
      skillCoins: coins,
      defaultPlaylist: state.defaultPlaylist,
      fromBackend: state.fromBackend,
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

/// Client-side coin→naira estimate (Flow 03 `1256:27795`). Display-only and
/// always presented with a ≈; anywhere a backend-computed amount exists it is
/// used instead of this rate.
const int kCoinRateNaira = 6;

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
