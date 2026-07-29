import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/platform_task.dart';

/// Learner platform-task lifecycle — `/me/platform-tasks`.
class PlatformTasksRepository extends ApiRepository {
  const PlatformTasksRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<List<PlatformTask>> list() => getList(
    '/me/platform-tasks',
    parse: _parseTask,
  );

  Future<void> start(String taskId) => post(
    '/me/platform-tasks/$taskId/start',
  );

  Future<void> submit(String taskId) => post(
    '/me/platform-tasks/$taskId/submit',
  );

  /// Grants XP + Skillcoins. Rewards land only on claim (platform-tasks.md).
  Future<void> claim(String taskId) => post(
    '/me/platform-tasks/$taskId/claim',
  );

  Future<void> complete(String taskId) => post(
    '/me/platform-tasks/$taskId/complete',
  );

  static PlatformTask _parseTask(Map<String, dynamic> json) {
    // Harden against partial payloads (docs omit fields the OpenAPI requires).
    final normalized = Map<String, dynamic>.from(json);
    normalized.putIfAbsent('action_type', () => json['trigger_type'] ?? '');
    normalized.putIfAbsent('trigger_type', () => json['action_type'] ?? '');
    normalized.putIfAbsent('metadata', () => <String, dynamic>{});
    normalized.putIfAbsent('icon', () => 'star');
    normalized.putIfAbsent('progress_target', () => 1);
    normalized.putIfAbsent('progress_current', () => 0);
    normalized.putIfAbsent('sort_order', () => 0);
    normalized.putIfAbsent('xp_reward', () => 0);
    normalized.putIfAbsent('skillcoin_reward', () => '0.00');
    normalized.putIfAbsent('verification_mode', () => 'manual');
    normalized.putIfAbsent('category', () => 'custom');
    normalized.putIfAbsent('slug', () => json['id']?.toString() ?? '');
    normalized.putIfAbsent('title', () => 'Task');
    normalized.putIfAbsent('description', () => '');
    normalized.putIfAbsent('status', () => 'not_started');
    normalized.putIfAbsent('claimable', () => false);
    normalized.putIfAbsent('completed', () => false);
    return PlatformTask.fromJson(normalized);
  }
}

final platformTasksRepositoryProvider = Provider<PlatformTasksRepository>(
  (ref) => PlatformTasksRepository(ref.watch(apiClientProvider)),
);
