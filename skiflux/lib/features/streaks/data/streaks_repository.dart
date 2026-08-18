import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/streak_summary.dart';

/// Learner streak stats — `GET /me/streak`.
class StreaksRepository extends ApiRepository {
  const StreaksRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const streakPath = '/me/streak';

  Future<StreakSummary> getStreak() => getObject(
    streakPath,
    parse: StreakSummary.fromJson,
  );
}

final streaksRepositoryProvider = Provider<StreaksRepository>(
  (ref) => StreaksRepository(ref.watch(apiClientProvider)),
);
