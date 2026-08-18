library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

class UsersRepository extends ApiRepository {
  const UsersRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<Map<String, dynamic>> getUserById(String userId) async {
    return getObject(
      '/users/$userId',
      parse: (json) => json,
    );
  }

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    return getObject(
      '/users/by-username/$username',
      parse: (json) => json,
    );
  }
}

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(apiClientProvider)),
);
