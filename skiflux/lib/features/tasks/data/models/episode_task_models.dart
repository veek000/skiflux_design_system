/// Wire models for the learning-task pipeline:
///
/// - `GET /episodes/watched/tasks` → [WatchedEpisodeTask]
///   (OpenAPI `WatchedEpisodeTaskItem`, inside a `WatchedEpisodeTaskList`
///   envelope of `{total_count, offset, limit, results}`)
/// - `GET /me/submissions` → [UserSubmission] (OpenAPI `UserSubmission`)
///
/// Hand-parsed rather than freezed — same defensive style as
/// `library_episode.dart` — because both payloads are new and several fields
/// the spec marks required are worth not trusting (e.g. `questions[].id` is
/// *omitted* by the spec's `AssessmentQuestion` even though the submit
/// endpoint keys answers by question UUID; it is parsed here when present).
library;

import 'package:decimal/decimal.dart';

/// One task attached to an episode the user has watched.
class WatchedEpisodeTask {
  const WatchedEpisodeTask({
    required this.id,
    required this.episodeId,
    required this.episodeTitle,
    required this.seasonId,
    required this.seasonTitle,
    required this.kind,
    required this.status,
    this.slaTimeLimitHours = 0,
    this.slaDeadline,
    this.taskBrief = '',
    this.acceptedProofTypes = const [],
    this.passScorePercent,
    this.questions = const [],
    this.timeLimitMinutes,
    this.maxAttempts,
    this.completionCriteria = const {},
    this.rewardHints = const {},
    this.viewedAt,
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;

  /// What `POST /episodes/task/submit` keys on (`episode_id`), not [id].
  final String episodeId;
  final String episodeTitle;
  final String seasonId;
  final String seasonTitle;

  /// `project_based` | `assessment` (OpenAPI `EpisodeTaskKindEnum`).
  final String kind;

  /// Free string in the spec; mapped onto the UI status defensively.
  final String status;

  final int slaTimeLimitHours;
  final DateTime? slaDeadline;
  final String taskBrief;

  /// Creator-defined proof types, e.g. `["link", "image", "video", "file"]`.
  final List<String> acceptedProofTypes;

  final int? passScorePercent;
  final List<WireAssessmentQuestion> questions;
  final int? timeLimitMinutes;
  final int? maxAttempts;

  /// Spec type is `{}` (anything); kept as a map so reward hints can be read
  /// opportunistically without inventing them when absent.
  final Map<String, dynamic> completionCriteria;

  /// Everywhere a coin/XP reward could plausibly arrive, flattened into one
  /// map for [LearningTask] to read.
  ///
  /// `WatchedEpisodeTaskItem` declares **no** reward fields — unlike
  /// `PlatformTaskUser`, which has `xp_reward` and `skillcoin_reward` — so
  /// there is nothing in the schema to bind to and the reward chips on every
  /// learning-task card stay hidden against a live backend. Rather than
  /// invent a number, this gathers the untyped `completion_criteria` blob, any
  /// `reward`/`rewards` object nested inside it, and any reward-shaped key
  /// sent at the top level of the row. The moment the backend sends one under
  /// any of those names the chips appear; until then they stay off.
  //
  // TODO(backend, blocking): learning tasks cannot show their reward because
  // the payload has none. Expects: `xp_reward: int` and
  // `skillcoin_reward: decimal-string` on WatchedEpisodeTaskItem and
  // EpisodeTask, matching PlatformTaskUser.
  final Map<String, dynamic> rewardHints;

  final DateTime? viewedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  bool get isAssessment => kind.toLowerCase().contains('assess');

  factory WatchedEpisodeTask.fromJson(Map<String, dynamic> json) {
    final criteria = json['completion_criteria'] is Map
        ? Map<String, dynamic>.from(json['completion_criteria'] as Map)
        : const <String, dynamic>{};
    return WatchedEpisodeTask(
      id: _string(json['id']) ?? '',
      episodeId: _string(json['episode_id']) ?? '',
      episodeTitle: _string(json['episode_title']) ?? 'Episode',
      seasonId: _string(json['season_id']) ?? '',
      seasonTitle: _string(json['season_title']) ?? '',
      kind: _string(json['kind']) ?? 'project_based',
      status: _string(json['status']) ?? '',
      slaTimeLimitHours: _int(json['sla_time_limit_hours']) ?? 0,
      slaDeadline: _date(json['sla_deadline']),
      taskBrief: _string(json['task_brief']) ?? '',
      acceptedProofTypes: _stringList(json['accepted_proof_types']),
      passScorePercent: _int(json['pass_score_percent']),
      questions: [
        if (json['questions'] is List)
          for (final q in json['questions'] as List)
            if (q is Map) WireAssessmentQuestion.fromJson(Map<String, dynamic>.from(q)),
      ],
      timeLimitMinutes: _int(json['time_limit_minutes']),
      maxAttempts: _int(json['max_attempts']),
      completionCriteria: criteria,
      rewardHints: _rewardHints(json, criteria),
      viewedAt: _date(json['viewed_at']),
      submittedAt: _date(json['submitted_at']),
      reviewedAt: _date(json['reviewed_at']),
    );
  }

  /// Collect reward-shaped values from the row, its `completion_criteria`, and
  /// any `reward` / `rewards` object nested one level inside either.
  ///
  /// Innermost wins, because a nested `{"reward": {"xp": 30}}` is a more
  /// deliberate statement than a stray top-level `xp`. Only scalar values are
  /// taken — a key holding a list or another map is not a reward.
  static Map<String, dynamic> _rewardHints(
    Map<String, dynamic> json,
    Map<String, dynamic> criteria,
  ) {
    final hints = <String, dynamic>{};

    void absorb(Map<String, dynamic> source) {
      for (final entry in source.entries) {
        if (!_rewardKeys.contains(entry.key)) continue;
        final value = entry.value;
        if (value is num || value is String) hints[entry.key] = value;
      }
      for (final key in const ['reward', 'rewards']) {
        final nested = source[key];
        if (nested is Map) {
          absorb(Map<String, dynamic>.from(nested));
        }
      }
    }

    absorb(json);
    absorb(criteria);
    return Map.unmodifiable(hints);
  }

  /// The names a coin or XP reward could arrive under. `PlatformTaskUser` uses
  /// `xp_reward` / `skillcoin_reward`; the rest are the shorter spellings a
  /// free-form `completion_criteria` blob is likely to use.
  static const Set<String> _rewardKeys = {
    'skillcoin_reward',
    'skillcoins',
    'coin_reward',
    'coins',
    'xp_reward',
    'xp',
  };
}

/// One multiple-choice question (OpenAPI `AssessmentQuestion`).
class WireAssessmentQuestion {
  const WireAssessmentQuestion({
    this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.order = 0,
  });

  /// Needed to submit answers (`{question_uuid: "A"}`), yet absent from the
  /// spec's `AssessmentQuestion` schema — a genuine spec gap. Parsed when the
  /// backend includes it; null blocks backend assessment submission.
  final String? id;

  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  /// `A` | `B` | `C` | `D` when present. Learner-facing
  /// `AssessmentQuestionResponse` **omits** this field (answer key stays on
  /// the server); local grading then falls back to the submission's
  /// `score_percent` / `passed`.
  final String correctAnswer;
  final int order;

  List<String> get options => [optionA, optionB, optionC, optionD];

  /// 0-based index of [correctAnswer]; -1 when the letter is unparseable.
  int get correctIndex {
    final letter = correctAnswer.trim().toUpperCase();
    if (letter.isEmpty) return -1;
    final index = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
    return index >= 0 && index <= 3 ? index : -1;
  }

  factory WireAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return WireAssessmentQuestion(
      id: _string(json['id']),
      questionText: _string(json['question_text']) ?? '',
      optionA: _string(json['option_a']) ?? '',
      optionB: _string(json['option_b']) ?? '',
      optionC: _string(json['option_c']) ?? '',
      optionD: _string(json['option_d']) ?? '',
      correctAnswer: _string(json['correct_answer']) ?? '',
      order: _int(json['order']) ?? 0,
    );
  }
}

/// One row of `GET /me/submissions` — project or assessment submission.
class UserSubmission {
  const UserSubmission({
    required this.id,
    required this.type,
    required this.episodeId,
    required this.episodeTitle,
    required this.seasonTitle,
    required this.skillworld,
    required this.taskId,
    required this.status,
    this.submissionText,
    this.submissionUrl,
    this.submissionFileUrl,
    this.proofType,
    this.cashbackAmount,
    this.rejectionReason,
    this.reviewedAt,
    this.createdAt,
    this.scorePercent,
    this.passed,
    this.attemptNumber,
    this.timeTakenSeconds,
    this.submittedAt,
    this.gradedAnswers = const {},
  });

  final String id;
  final String type;
  final String episodeId;
  final String episodeTitle;
  final String seasonTitle;
  final String skillworld;
  final String taskId;

  /// `pending | approved | rejected | passed | failed` per the endpoint's
  /// status filter documentation.
  final String status;

  final String? submissionText;
  final String? submissionUrl;
  final String? submissionFileUrl;
  final String? proofType;

  /// Money — decimal string on the wire, [Decimal] here, never double.
  final Decimal? cashbackAmount;

  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final int? scorePercent;
  final bool? passed;
  final int? attemptNumber;
  final int? timeTakenSeconds;
  final DateTime? submittedAt;

  /// Per-question graded answers from `UserSubmission.answers` (schema is an
  /// untyped blob). Powers Review Answers: selected letter + correct letter
  /// when the backend includes them after submit.
  final Map<String, GradedAnswer> gradedAnswers;

  /// Recency key for picking the latest submission per task.
  DateTime? get sortDate => submittedAt ?? createdAt;

  factory UserSubmission.fromJson(Map<String, dynamic> json) {
    final cashback = _string(json['cashback_amount']);
    return UserSubmission(
      id: _string(json['id']) ?? '',
      type: _string(json['type']) ?? '',
      episodeId: _string(json['episode_id']) ?? '',
      episodeTitle: _string(json['episode_title']) ?? '',
      seasonTitle: _string(json['season_title']) ?? '',
      skillworld: _string(json['skillworld']) ?? '',
      taskId: _string(json['task_id']) ?? '',
      status: _string(json['status']) ?? '',
      submissionText: _string(json['submission_text']),
      submissionUrl: _string(json['submission_url']),
      submissionFileUrl: _string(json['submission_file_url']),
      proofType: _string(json['proof_type']),
      cashbackAmount: cashback == null ? null : Decimal.tryParse(cashback),
      rejectionReason: _string(json['rejection_reason']),
      reviewedAt: _date(json['reviewed_at']),
      createdAt: _date(json['created_at']),
      scorePercent: _int(json['score_percent']),
      passed: json['passed'] is bool ? json['passed'] as bool : null,
      attemptNumber: _int(json['attempt_number']),
      timeTakenSeconds: _int(json['time_taken_seconds']),
      submittedAt: _date(json['submitted_at']),
      gradedAnswers: GradedAnswer.parseMap(json['answers']),
    );
  }
}

/// One question's graded result from a submission `answers` blob.
///
/// The OpenAPI field is untyped (`nullable: true` only). Backends commonly
/// send either `{questionId: "A"}` or
/// `{questionId: {selected/answer: "A", correct_answer/correct: "B"}}`.
class GradedAnswer {
  const GradedAnswer({this.selectedLetter, this.correctLetter});

  final String? selectedLetter;
  final String? correctLetter;

  int? get selectedIndex => letterToIndex(selectedLetter);
  int? get correctIndex => letterToIndex(correctLetter);

  static int? letterToIndex(String? letter) {
    if (letter == null || letter.isEmpty) return null;
    final trimmed = letter.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final index = trimmed.codeUnitAt(0) - 'A'.codeUnitAt(0);
    return index >= 0 && index <= 3 ? index : null;
  }

  static Map<String, GradedAnswer> parseMap(Object? raw) {
    final out = <String, GradedAnswer>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = entry.key.toString();
        final value = entry.value;
        if (value is String) {
          out[id] = GradedAnswer(selectedLetter: value);
        } else if (value is Map) {
          final m = Map<String, dynamic>.from(value);
          out[id] = GradedAnswer(
            selectedLetter: _string(
              m['answer'] ??
                  m['selected'] ??
                  m['selected_answer'] ??
                  m['choice'] ??
                  m['user_answer'],
            ),
            correctLetter: _string(
              m['correct_answer'] ??
                  m['correct'] ??
                  m['right_answer'] ??
                  m['answer_key'] ??
                  m['expected'],
            ),
          );
        }
      }
    } else if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final id = _string(
          m['question_id'] ?? m['id'] ?? m['question'] ?? m['uuid'],
        );
        if (id == null) continue;
        out[id] = GradedAnswer(
          selectedLetter: _string(
            m['answer'] ??
                m['selected'] ??
                m['selected_answer'] ??
                m['choice'] ??
                m['user_answer'],
          ),
          correctLetter: _string(
            m['correct_answer'] ??
                m['correct'] ??
                m['right_answer'] ??
                m['answer_key'] ??
                m['expected'],
          ),
        );
      }
    }
    return Map.unmodifiable(out);
  }
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry != null && entry.toString().trim().isNotEmpty)
        entry.toString().trim(),
  ];
}
