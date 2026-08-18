/// `GET /creators/{creator_id}` — public creator profile.
///
/// The path parameter is the creator **UUID** (spec: `format: uuid`), not the
/// username; navigation sites pass the id carried on episode / search / follow
/// payloads.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'creator_profile_provider.dart';

class CreatorsRepository extends ApiRepository {
  const CreatorsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// Returns the spec's `PublicCreatorProfile`, follow state included.
  Future<CreatorProfile> getCreator(String creatorId) => getObject(
    '/creators/$creatorId',
    parse: CreatorProfile.fromJson,
  );
}

final creatorsRepositoryProvider = Provider<CreatorsRepository>(
  (ref) => CreatorsRepository(ref.watch(apiClientProvider)),
);
