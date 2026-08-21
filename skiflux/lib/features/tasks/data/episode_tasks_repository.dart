/// Episode learning tasks — reads and submissions.
///
/// - `GET /episodes/watched/tasks` — tasks attached to episodes the user has
///   watched, with their current status (`WatchedEpisodeTaskList`).
/// - `GET /me/submissions` — the spec's "primary endpoint for mobile to
///   retrieve user submissions list"; hydrates statuses/feedback/scores.
/// - `POST /episodes/task/submit` — one endpoint, three request shapes:
///   JSON `{episode_id, project_submission}` for a link, flat multipart
///   (`episode_id`, `submission_file`, `submission_text`) for a file, and
///   JSON `{episode_id, assessment_submission}` for quiz answers keyed by
///   question UUID.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/episode_task_models.dart';

class EpisodeTasksRepository extends ApiRepository {
  const EpisodeTasksRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const submitPath = '/episodes/task/submit';

  /// `GET /episodes/watched/tasks` — the learning tab's source of truth.
  Future<List<WatchedEpisodeTask>> getWatchedTasks() => getList(
    '/episodes/watched/tasks',
    parse: WatchedEpisodeTask.fromJson,
  );

  /// `GET /me/submissions` — status filter values per the spec:
  /// `pending | approved | rejected | passed | failed`.
  Future<List<UserSubmission>> getMySubmissions({
    String? status,
    String? episodeId,
    int? pageSize,
  }) => getList(
    '/me/submissions',
    parse: UserSubmission.fromJson,
    query: {
      'status': ?status,
      'episode_id': ?episodeId,
      'page_size': ?pageSize,
    },
  );

  /// Project proof via hosted link — JSON body with nested
  /// `project_submission` (`ProjectSubmissionLinkRequest`).
  Future<void> submitProjectLink({
    required String episodeId,
    required String url,
    String? note,
  }) => post<void>(
    submitPath,
    body: {
      'episode_id': episodeId,
      'project_submission': {
        'submission_url': url,
        if (note != null && note.isNotEmpty) 'submission_text': note,
      },
    },
    kind: SkifluxErrorKind.taskSubmission,
  );

  /// Project proof via file upload — flat `multipart/form-data` fields per
  /// `SubmitTasksMultipartRequest` (`episode_id`, `submission_file`,
  /// optional `submission_text`).
  Future<void> submitProjectFile({
    required String episodeId,
    required String filePath,
    required String fileName,
    String? note,
  }) => guard(() async {
    final form = FormData.fromMap({
      'episode_id': episodeId,
      if (note != null && note.isNotEmpty) 'submission_text': note,
      'submission_file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });
    // Direct dio call: the base client pins JSON as the default content type
    // and [post] has no options hook; FormData must go out as multipart.
    await dio.post<dynamic>(
      submitPath,
      data: form,
      
    );
  }, kind: SkifluxErrorKind.taskSubmission);

  /// Assessment answers — `{question_uuid: "A".."D"}` per
  /// `AssessmentSubmissionInputRequest`.
  ///
  /// Returns the graded [UserSubmission] when the API echoes one (or after a
  /// follow-up `GET /me/submissions`). Learner-facing question payloads use
  /// `AssessmentQuestionResponse`, which **omits** `correct_answer`, so the
  /// client cannot grade locally and must use this result for the score UI.
  Future<UserSubmission?> submitAssessment({
    required String episodeId,
    required Map<String, String> answers,
    String? taskId,
    int? timeTakenSeconds,
  }) => guard(() async {
    final response = await dio.post<dynamic>(
      submitPath,
      data: {
        'episode_id': episodeId,
        'assessment_submission': {
          'answers': answers,
          if (timeTakenSeconds != null && timeTakenSeconds >= 0)
            'time_taken_seconds': timeTakenSeconds,
        },
      },
    );
    final echoed = _tryParseSubmission(response.data);
    if (echoed != null) return echoed;

    // Spec documents 200 with no body — pull the latest assessment row.
    return latestAssessmentSubmission(
      episodeId: episodeId,
      taskId: taskId,
    );
  }, kind: SkifluxErrorKind.quizSubmission);

  /// Newest assessment submission for [episodeId] (optionally [taskId]).
  Future<UserSubmission?> latestAssessmentSubmission({
    required String episodeId,
    String? taskId,
  }) async {
    final rows = await getMySubmissions(episodeId: episodeId, pageSize: 20);
    final matches = [
      for (final row in rows)
        if (_isAssessment(row) &&
            (taskId == null ||
                taskId.isEmpty ||
                row.taskId == taskId ||
                row.taskId.isEmpty))
          row,
    ];
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final ad = a.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return matches.first;
  }

  static bool _isAssessment(UserSubmission row) {
    final t = row.type.toLowerCase();
    return t.contains('assess') || t.contains('quiz') || t.contains('exam');
  }

  static UserSubmission? _tryParseSubmission(Object? data) {
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
      final inner = map['data'];
      if (inner is Map) map = Map<String, dynamic>.from(inner);
    }
    if (map == null || map.isEmpty) return null;
    if (map['id'] == null && map['status'] == null && map['score_percent'] == null) {
      return null;
    }
    try {
      return UserSubmission.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

final episodeTasksRepositoryProvider = Provider<EpisodeTasksRepository>(
  (ref) => EpisodeTasksRepository(ref.watch(apiClientProvider)),
);

