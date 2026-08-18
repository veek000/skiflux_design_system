/// The season cache + the SkillCoin balance view used by unlock flows
/// (Home & In-app + Other Video Player).
///
/// There is no seeded catalogue behind this any more. Every season the app
/// shows is fetched by `season_providers.dart` and registered here via
/// [PlaylistsNotifier.cacheSeason]; the cache exists so the unlock sheet can
/// resolve an episode by id no matter which screen opened it.
///
/// Money honesty: `skillCoins` here is a *derived whole-coin view* of the
/// wallet's real [Decimal] balance (`walletProvider.remoteWallet.balance`),
/// synced by the wallet store using floor — it never mints, spends, or
/// invents coins on its own. All actual money movement goes through the
/// wallet repositories (`topup`, `withdrawals`, `episodes/purchase`).
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/formatting.dart';
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
    this.skillworld,
    this.viewCount,
    this.createdAt,
    this.thumbnailUrl,
    this.videoUrl,
  });

  final String id;
  final int number;
  final String title;
  final String duration;
  final int coinCost;
  PlaylistEpisodeState state;

  /// `Episode.skillworld` — the world this episode belongs to, used by the
  /// creator profile's category pills.
  ///
  /// Mutable so a caller that knows the owning season can fill in a payload
  /// that omitted it; that has to happen in place, because [state] is mutated
  /// by [PlaylistsNotifier.markPurchased] and a copied row would stop
  /// reflecting purchases.
  String? skillworld;

  /// `Episode.view_count`. Null when the payload didn't carry one; the row
  /// then prints no view figure rather than inventing "22k".
  final int? viewCount;

  /// `Episode.created_at`, for "5 hrs ago" and newest-first ordering.
  final DateTime? createdAt;

  /// `Episode.thumbnail_url`. Null only when the payload omitted a field the
  /// schema requires; the row then falls back to the placeholder cover.
  final String? thumbnailUrl;

  /// `Episode.video_url` — the stream. Carried so a row opened from a creator
  /// profile or a season sheet can actually *play*: the player modal these
  /// screens open builds its feed item from this, and without it the modal
  /// fell back to image mode and showed a still.
  final String? videoUrl;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  String get epTag => 'EP ${number.toString().padLeft(2, '0')}';

  bool get isLocked => state == PlaylistEpisodeState.locked;
  bool get isUnlocked =>
      state == PlaylistEpisodeState.unlocked ||
      state == PlaylistEpisodeState.completed;

  /// "22k views · 5 hrs ago", trimmed to whatever is actually known — empty
  /// when the payload carried neither.
  String get metaLine {
    final parts = <String>[
      if (viewCount != null) '${countLabel(viewCount!)} views',
      if (createdAt != null) relativeAgeLabel(createdAt),
    ];
    return parts.join(' · ');
  }
}

class Playlist {
  Playlist({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.creatorUsername,
    required this.episodes,
    // Both default to empty rather than to the old demo copy ("Learn how to
    // design scalable systems…" / "550.7k views"). Every construction site
    // passes these explicitly, so the defaults only ever stood to put fake
    // blurbs and fake view counts on a season the backend said nothing about.
    this.description = '',
    this.viewsLabel = '',
    this.coverAsset = 'assets/home_video_cover.png',
    this.coverUrl,
    this.declaredEpisodeCount,
    this.creatorId,
    this.skillworld,
  });

  final String id;
  final String title;
  final String creatorName;
  final String creatorUsername;

  /// `SeasonList.creator.id` — the creator UUID, which is what
  /// `GET /creators/{id}` takes and what the profile filters its seasons by.
  /// A username is not a substitute: the two namespaces are different.
  final String? creatorId;

  /// `SeasonList.skillworld`, the raw backend value (`design`, `code`, …).
  /// Mapped through `SkillWorld.fromBackendValue` for display.
  final String? skillworld;

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
    creatorId: creatorId,
    skillworld: skillworld,
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
    // Marketing tags (Best Value / Save N%) are intentionally not shown —
    // packs are presented as plain coin + price.
    return CoinPack(coins: coins, price: price);
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
/// the spec). Prices are `coins × [kCoinRateNaira]` so a debit of ₦N credits
/// exactly the pack's coin count when the backend uses the same flat rate.
/// (Discounted "Save 17%" prices used to under-credit because initiate only
/// sends `amount_fiat` and the server converts at the flat rate.)
List<CoinPack> _fallbackCoinPacks() => [
  for (final coins in const [100, 200, 500, 1000])
    CoinPack(
      coins: coins,
      price: Decimal.fromInt(coins * kCoinRateNaira),
    ),
];

/// Snapshot of the coin view + every season the app has loaded this session.
class PlaylistsState {
  PlaylistsState({required this.skillCoins, this.seasonsById = const {}});

  /// Whole-coin display balance — floor of the wallet's real Decimal
  /// balance, synced by the wallet store. Not a source of truth.
  int skillCoins;

  /// Seasons keyed by season id, registered by
  /// [PlaylistsNotifier.cacheSeason] as each one is fetched. This is a lookup
  /// table, not a catalogue: it holds what has been shown, in no order, and a
  /// screen that wants a list of seasons asks the backend, not this map.
  final Map<String, Playlist> seasonsById;

  /// The season an episode belongs to, across everything cached.
  Playlist? seasonOf(String episodeId) {
    for (final season in seasonsById.values) {
      for (final e in season.episodes) {
        if (e.id == episodeId) return season;
      }
    }
    return null;
  }

  /// Resolves an episode by id across every cached season. The unlock sheet
  /// depends on this, so any season a screen displays must be cached first or
  /// its rows cannot be purchased.
  PlaylistEpisode? byId(String id) {
    if (id.isEmpty) return null;
    for (final season in seasonsById.values) {
      for (final e in season.episodes) {
        if (e.id == id) return e;
      }
    }
    return null;
  }

  /// Episode number lookup, optionally scoped to one season. Numbers only
  /// identify an episode *within* a season, so an unscoped call returns the
  /// first match and is only safe when a single season is cached.
  PlaylistEpisode? byNumber(int number, {String? seasonId}) {
    final seasons = seasonId != null
        ? [if (seasonsById[seasonId] != null) seasonsById[seasonId]!]
        : seasonsById.values;
    for (final season in seasons) {
      for (final e in season.episodes) {
        if (e.number == number) return e;
      }
    }
    return null;
  }
}

/// Riverpod choice: [NotifierProvider] — episode lock state mutates via
/// unlock. The coin figure is a mirror of the wallet (see [setSkillCoins]).
///
/// Every season here arrived from `GET /seasons/{id}/episodes` by way of
/// `season_providers.dart`, so every lock state is the server's own
/// `is_locked` / `is_purchased` and nothing else.
class PlaylistsNotifier extends Notifier<PlaylistsState> {
  @override
  PlaylistsState build() {
    // Zero, not a fake balance: a signed-in user sees their real balance as
    // soon as the wallet refresh lands, and a signed-out user is honestly
    // shown zero coins rather than 100 that don't exist. The season cache
    // starts empty for the same reason.
    return PlaylistsState(skillCoins: 0);
  }

  /// Syncs the SkillCoin display from `GET /wallet/my-wallet`. Callers pass
  /// the floor of the real Decimal balance — a spendable balance is never
  /// rounded up.
  void setSkillCoins(int coins) {
    state = PlaylistsState(
      skillCoins: coins < 0 ? 0 : coins,
      seasonsById: state.seasonsById,
    );
  }

  /// Registers a hydrated season so its episodes can be resolved by id later
  /// — most importantly by the unlock sheet, which only receives an episode
  /// id and has no idea which screen opened it.
  ///
  /// A season with no episodes is ignored: caching a shell would let [byId]
  /// answer "not found" for an episode that simply hasn't been fetched.
  void cacheSeason(Playlist season) {
    if (season.id.isEmpty || season.episodes.isEmpty) return;
    state = PlaylistsState(
      skillCoins: state.skillCoins,
      seasonsById: {...state.seasonsById, season.id: season},
    );
  }

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
      seasonsById: state.seasonsById,
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
