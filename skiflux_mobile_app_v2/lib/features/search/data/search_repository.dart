library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/error_handling/error_handler.dart';

class SearchRepository extends ApiRepository {
  const SearchRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.searchFailed;

  Future<Map<String, dynamic>> search(String query) async {
    return getObject(
      '/search',
      query: {'q': query},
      parse: (json) => json,
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);
