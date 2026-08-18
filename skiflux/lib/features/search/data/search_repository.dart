/// `GET /search` — global paginated search.
///
/// The spec's `GlobalSearchResponse` groups results as `{episodes, seasons,
/// creators, users}`, each a DRF page (`{count, next, previous, results}`).
/// Bodies arrive either bare or wrapped in the `{data: …}` envelope, and the
/// spec (oddly) declares an array of the response object — [SearchResults]
/// parsing tolerates all three shapes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'search_index.dart';

class SearchRepository extends ApiRepository {
  const SearchRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.searchFailed;

  Future<SearchResults> search(
    String query, {
    int limit = 10,
    int offset = 0,
  }) => guard(() async {
    final response = await dio.get<dynamic>(
      '/search',
      queryParameters: {'q': query, 'limit': limit, 'offset': offset},
    );
    return SearchResults.fromResponse(query, response.data);
  });
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);
