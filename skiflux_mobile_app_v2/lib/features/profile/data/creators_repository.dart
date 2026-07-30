library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

class CreatorsRepository extends ApiRepository {
  const CreatorsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<Map<String, dynamic>> getCreator(String creatorId) async {
    return getObject(
      '/creators/$creatorId',
      parse: (json) => json,
    );
  }
}

final creatorsRepositoryProvider = Provider<CreatorsRepository>(
  (ref) => CreatorsRepository(ref.watch(apiClientProvider)),
);
