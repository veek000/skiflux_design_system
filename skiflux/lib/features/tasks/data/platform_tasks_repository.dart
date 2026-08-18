import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/network/json_envelope.dart';
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

  Future<PlatformTask?> start(String taskId) => _postTask(
    '/me/platform-tasks/$taskId/start',
  );

  Future<PlatformTask?> submit(String taskId) => _postTask(
    '/me/platform-tasks/$taskId/submit',
  );

  /// Grants XP + Skillcoins. Rewards land only on claim (platform-tasks.md).
  Future<PlatformTask?> claim(String taskId) => _postTask(
    '/me/platform-tasks/$taskId/claim',
  );

  Future<PlatformTask?> complete(String taskId) => _postTask(
    '/me/platform-tasks/$taskId/complete',
  );

  /// Mission writes POST and — per the spec — answer with the updated
  /// `PlatformTaskUser`, which lets the card flip on the server's word rather
  /// than the app's hope. A 2xx with a missing/unparseable body is still a
  /// success (null); a non-2xx throws.
  ///
  /// Failures surface as [SkifluxErrorKind.taskSubmission] (modal): a failed
  /// claim is lost coins, not a quiet content hiccup. No dedicated
  /// mission-claim kind exists yet.
  Future<PlatformTask?> _postTask(String path) => guard(() async {
    final response = await dio.post<dynamic>(path);
    final data = response.data;
    if (data is Map) {
      final body = unwrapObject(Map<String, dynamic>.from(data));
      if (body['id'] != null) {
        try {
          return _parseTask(body);
        } on Object {
          return null; // 2xx stands even if the echo doesn't parse.
        }
      }
    }
    return null;
  }, kind: SkifluxErrorKind.taskSubmission);

  static PlatformTask _parseTask(Map<String, dynamic> json) {
    // Harden against partial payloads (docs omit fields the OpenAPI requires).
    final normalized = Map<String, dynamic>.from(json);
    normalized.putIfAbsent('action_type', () => json['trigger_type'] ?? '');
    normalized.putIfAbsent('trigger_type', () => json['action_type'] ?? '');
    normalized.putIfAbsent('metadata', () => <String, dynamic>{});
    normalized.putIfAbsent('icon', () => 'star');
    // Spec marks `icon` nullable while the model requires a String.
    normalized['icon'] ??= 'star';
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
