library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

class SubscriptionsRepository extends ApiRepository {
  const SubscriptionsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<Map<String, dynamic>> getFollowingCreators({int limit = 20, int offset = 0}) async {
    return getObject(
      '/creators/following/',
      query: {'limit': limit, 'offset': offset},
      parse: (json) => json,
    );
  }

  Future<Map<String, dynamic>> getFollowingEpisodes({int limit = 20, int offset = 0}) async {
    return getObject(
      '/episodes/following/',
      query: {'limit': limit, 'offset': offset},
      parse: (json) => json,
    );
  }
}

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  (ref) => SubscriptionsRepository(ref.watch(apiClientProvider)),
);
