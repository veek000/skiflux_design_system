/// The one endpoint that spends SkillCoins on content.
///
/// Lives in the wallet feature because an episode unlock is a money write:
/// the sheet may only flip an episode to "unlocked" after this returns 2xx,
/// and the wallet must be re-read afterwards — the response body
/// (`EpisodePurchaseResponse`) carries only `episode_id`, no balances.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// `POST /episodes/purchase` — body `EpisodePurchaseRequest`
/// (`{episode_id}`); 201 returns `EpisodePurchaseResponse` (`{episode_id}`)
/// inside the standard envelope.
const kEpisodePurchasePath = '/episodes/purchase';

class EpisodePurchaseRepository extends ApiRepository {
  const EpisodePurchaseRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.coinPurchaseFailed;

  /// Purchases [episodeId] with SkillCoins. Returns the purchased episode id
  /// the backend confirmed. Throws [SkifluxFailure] (coinPurchaseFailed) on
  /// anything but 2xx — callers must not deduct coins or unlock on failure.
  Future<String> purchase(String episodeId) => post(
    kEpisodePurchasePath,
    body: {'episode_id': episodeId},
    parse: (json) => json['episode_id']?.toString() ?? episodeId,
  ).then((v) => v!);
}

final episodePurchaseRepositoryProvider = Provider<EpisodePurchaseRepository>(
  (ref) => EpisodePurchaseRepository(ref.watch(apiClientProvider)),
);
