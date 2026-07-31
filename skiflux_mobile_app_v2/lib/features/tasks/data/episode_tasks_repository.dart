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
      options: Options(contentType: 'multipart/form-data'),
    );
  }, kind: SkifluxErrorKind.taskSubmission);

  /// Assessment answers — `{question_uuid: "A".."D"}` per
  /// `AssessmentSubmissionInputRequest`.
  Future<void> submitAssessment({
    required String episodeId,
    required Map<String, String> answers,
    int? timeTakenSeconds,
  }) => post<void>(
    submitPath,
    body: {
      'episode_id': episodeId,
      'assessment_submission': {
        'answers': answers,
        if (timeTakenSeconds != null && timeTakenSeconds >= 0)
          'time_taken_seconds': timeTakenSeconds,
      },
    },
    kind: SkifluxErrorKind.quizSubmission,
  );
}

final episodeTasksRepositoryProvider = Provider<EpisodeTasksRepository>(
  (ref) => EpisodeTasksRepository(ref.watch(apiClientProvider)),
);
