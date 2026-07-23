/// Demo data for the Tasks tab (Figma **Task Flow** `1256:12977`).
/// Session-local Riverpod notifier — no persistence, matching other stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Enums ────────────────────────────────────────────────────────────

enum TaskCategory { learning, mission, marketplace }

/// Learning-task lifecycle (Figma status chips on TF15).
enum LearningTaskStatus {
  completed,
  pending,
  inReview,
  actionNeeded,
}

/// How a learning task is completed.
enum LearningTaskKind { submission, quiz }

// ── Models ───────────────────────────────────────────────────────────

class LearningTask {
  LearningTask({
    required this.id,
    required this.title,
    required this.description,
    required this.episodeLabel,
    required this.episodeTitle,
    required this.episodeSubtitle,
    required this.status,
    required this.kind,
    required this.coins,
    required this.xp,
    this.feedback,
    this.briefIntro,
    this.briefBullets = const [],
    this.quiz,
  });

  final String id;
  final String title;
  final String description;
  final String episodeLabel;
  final String episodeTitle;
  final String episodeSubtitle;
  LearningTaskStatus status;
  final LearningTaskKind kind;
  final int coins;
  final int xp;

  /// Reviewer note — shown on Action Needed cards.
  String? feedback;

  /// Submission detail: intro paragraph under "The Brief".
  final String? briefIntro;

  /// Submission detail: checklist bullets.
  final List<String> briefBullets;

  /// Quiz payload when [kind] is quiz.
  final QuizData? quiz;

  /// Last quiz attempt answers (index per question) — powers View Result.
  List<int?>? quizAnswers;

  /// Correct count from the last quiz attempt.
  int? quizCorrect;

  String get statusLabel => switch (status) {
        LearningTaskStatus.completed => 'Completed',
        LearningTaskStatus.pending => 'Pending',
        LearningTaskStatus.inReview => 'In Review',
        LearningTaskStatus.actionNeeded => 'Action Needed',
      };

  /// Primary CTA on the list card.
  String get actionLabel => switch (status) {
        LearningTaskStatus.completed => 'View Result',
        LearningTaskStatus.pending => 'Start Task',
        LearningTaskStatus.inReview => 'Awaiting Review',
        LearningTaskStatus.actionNeeded => 'Fix & Resubmit',
      };

  bool get actionEnabled =>
      status != LearningTaskStatus.inReview &&
      status != LearningTaskStatus.completed;
}

class MissionTask {
  MissionTask({
    required this.id,
    required this.title,
    required this.description,
    required this.coins,
    required this.actionLabel,
    required this.iconKey,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final int coins;
  final String actionLabel;

  /// Key resolved to Remix in the UI (instagram, twitter/x, …).
  final String iconKey;
  bool completed;
}

class QuizData {
  const QuizData({
    required this.introBody,
    required this.questionCount,
    required this.minutes,
    required this.passPercent,
    required this.rewardCoins,
    required this.rewardXp,
    required this.questions,
    required this.timerSeconds,
  });

  final String introBody;
  final int questionCount;
  final int minutes;
  final int passPercent;
  final int rewardCoins;
  final int rewardXp;
  final List<QuizQuestion> questions;
  final int timerSeconds;
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class UploadedFileInfo {
  const UploadedFileInfo({
    required this.name,
    required this.extensionLabel,
    required this.sizeLabel,
    this.path,
  });

  final String name;
  final String extensionLabel;
  final String sizeLabel;
  final String? path;
}

// ── State + Notifier ─────────────────────────────────────────────────

/// Snapshot of learning + mission demo lists.
class TasksState {
  TasksState({
    required this.learning,
    required this.missions,
  });

  final List<LearningTask> learning;
  final List<MissionTask> missions;

  List<LearningTask> learningFiltered(LearningTaskStatus? status) {
    if (status == null) return List.unmodifiable(learning);
    // "Revision" filter maps to Action Needed in the product language.
    return learning.where((t) => t.status == status).toList(growable: false);
  }

  int countFor(LearningTaskStatus? status) {
    if (status == null) return learning.length;
    return learning.where((t) => t.status == status).length;
  }

  LearningTask? byId(String id) {
    for (final t in learning) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Riverpod choice: [NotifierProvider] — learning/mission status mutate
/// via markInReview / markCompleted / recordQuizResult / completeMission
/// (was ChangeNotifier singleton). Single provider keeps learning +
/// missions in one session snapshot (list filters stay local UI state).
// TODO(backend, blocking): replace static seeded learning tasks and missions with real per-user task catalog from backend, including submission persistence and quiz answer recording — expects: {learning: List<{id: String, title: String, description: String, episodeLabel: String, episodeTitle: String, episodeSubtitle: String, status: LearningTaskStatus, kind: LearningTaskKind, coins: int, xp: int, feedback: String?, briefIntro: String?, briefBullets: List<String>, quiz: QuizData?, quizAnswers: List<int?>?, quizCorrect: int?}>, missions: List<{id: String, title: String, description: String, coins: int, actionLabel: String, iconKey: String, completed: bool}>}
class TasksNotifier extends Notifier<TasksState> {
  @override
  TasksState build() {
    return TasksState(
      learning: _seedLearning(),
      missions: _seedMissions(),
    );
  }

  void markInReview(String id) {
    final t = state.byId(id);
    if (t == null) return;
    t.status = LearningTaskStatus.inReview;
    t.feedback = null;
    state = TasksState(
      learning: List<LearningTask>.of(state.learning),
      missions: state.missions,
    );
  }

  void markCompleted(String id) {
    final t = state.byId(id);
    if (t == null) return;
    t.status = LearningTaskStatus.completed;
    state = TasksState(
      learning: List<LearningTask>.of(state.learning),
      missions: state.missions,
    );
  }

  /// Persist quiz answers + score and mark the task completed when passed.
  void recordQuizResult({
    required String id,
    required List<int?> answers,
    required int correct,
    required bool passed,
  }) {
    final t = state.byId(id);
    if (t == null) return;
    t.quizAnswers = List<int?>.from(answers);
    t.quizCorrect = correct;
    if (passed) t.status = LearningTaskStatus.completed;
    state = TasksState(
      learning: List<LearningTask>.of(state.learning),
      missions: state.missions,
    );
  }

  void completeMission(String id) {
    for (final m in state.missions) {
      if (m.id == id && !m.completed) {
        m.completed = true;
        state = TasksState(
          learning: state.learning,
          missions: List<MissionTask>.of(state.missions),
        );
        return;
      }
    }
  }

  // ── Seeds ────────────────────────────────────────────────────────

  static List<LearningTask> _seedLearning() {
    const briefIntro =
        "You're designing the hero section for FlowBase — a fictional "
        'project management SaaS. Using the design token system from EP 06, '
        'build a clean, scalable hero section.';
    const briefBullets = [
      'Headline, subheadline, and a primary CTA button.',
      'At least one visual element (illustration or mockup).',
      'All colours and text must reference token values — no hardcoded styles.',
      '1440px desktop frame size.',
    ];

    const quiz = QuizData(
      introBody:
          'This assessment tests your knowledge from Episode 05. It is '
          'auto-graded and you will receive your results immediately.',
      questionCount: 3,
      minutes: 2,
      passPercent: 100,
      rewardCoins: 20,
      rewardXp: 50,
      timerSeconds: 6 * 60,
      questions: [
        QuizQuestion(
          prompt:
              'What is the primary purpose of a Design System in a product?',
          options: [
            'To make the app look more expensive',
            'To ensure consistency and speed up design & development',
            'To replace the need for a designer',
            'To increase the final file size',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          prompt: "What does a 'Design Token' represent in an architecture?",
          options: [
            'A specific, named value like a hex code',
            'A complex UI component',
            'The license fee for using Figma',
            'Introduction to UI Design Thinking',
          ],
          correctIndex: 0,
        ),
        QuizQuestion(
          prompt:
              'In a scalable UI architecture, what is the best practice '
              'for button padding?',
          options: [
            'Use random pixel values visually',
            'Hardcode margins in the CSS for every button',
            'Use spacing tokens from the design system',
            'Introduction to UI Design Thinking',
          ],
          correctIndex: 2,
        ),
      ],
    );

    // First card (Figma TF15): completed submission — View Result → result
    // screen (not task details).
    final completedSubmission = LearningTask(
      id: 'learn-1',
      title: 'Design a hero section',
      description:
          'Submit a Figma file or screenshot · reviewed within 24hrs',
      episodeLabel: 'EP 06 — Design Systems',
      episodeTitle: 'Introduction to UI Design Thinking',
      episodeSubtitle: 'Episode 1',
      status: LearningTaskStatus.completed,
      kind: LearningTaskKind.submission,
      coins: 25,
      xp: 25,
      briefIntro: briefIntro,
      briefBullets: briefBullets,
    );

    // Completed quiz with a perfect run — View Result → TF01.
    final completedQuiz = LearningTask(
      id: 'learn-1b',
      title: 'Grid & Spacing Quiz',
      description: '3 multiple-choice questions · must score 100% to pass',
      episodeLabel: 'EP 05 — Layout Foundations',
      episodeTitle: 'Introduction to UI Design Thinking',
      episodeSubtitle: 'Episode 1',
      status: LearningTaskStatus.completed,
      kind: LearningTaskKind.quiz,
      coins: 25,
      xp: 25,
      quiz: quiz,
    )
      ..quizAnswers = const [1, 0, 2]
      ..quizCorrect = 3;

    return [
      completedSubmission,
      LearningTask(
        id: 'learn-2',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.pending,
        kind: LearningTaskKind.submission,
        coins: 25,
        xp: 25,
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
      completedQuiz,
      LearningTask(
        id: 'learn-3',
        title: 'Grid & Spacing Quiz',
        description:
            '3 multiple-choice questions · must score 100% to pass',
        episodeLabel: 'EP 05 — Layout Foundations',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.pending,
        kind: LearningTaskKind.quiz,
        coins: 25,
        xp: 25,
        quiz: quiz,
      ),
      LearningTask(
        id: 'learn-4',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.inReview,
        kind: LearningTaskKind.submission,
        coins: 25,
        xp: 25,
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
      LearningTask(
        id: 'learn-5',
        title: 'Design a hero section',
        description:
            'Submit a Figma file or screenshot · reviewed within 24hrs',
        episodeLabel: 'EP 06 — Design Systems',
        episodeTitle: 'Introduction to UI Design Thinking',
        episodeSubtitle: 'Episode 1',
        status: LearningTaskStatus.actionNeeded,
        kind: LearningTaskKind.submission,
        coins: 25,
        xp: 25,
        feedback:
            'Contrast on secondary buttons is too low for WCAG compliance. '
            'Please adjust and re-submit.',
        briefIntro: briefIntro,
        briefBullets: briefBullets,
      ),
    ];
  }

  static List<MissionTask> _seedMissions() {
    return [
      MissionTask(
        id: 'm-ig',
        title: 'Follow Instagram',
        description:
            'Join our visual community for design inspiration and creator highlights',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'instagram',
      ),
      MissionTask(
        id: 'm-x',
        title: 'Follow X',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'twitter',
      ),
      MissionTask(
        id: 'm-fb',
        title: 'Follow Facebook',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'facebook',
      ),
      MissionTask(
        id: 'm-li',
        title: 'Follow LinkedIn',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'linkedin',
      ),
      MissionTask(
        id: 'm-tt',
        title: 'Follow TikTok',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'tiktok',
      ),
      MissionTask(
        id: 'm-tg',
        title: 'Join Telegram Community',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 7,
        actionLabel: 'Join',
        iconKey: 'telegram',
      ),
      MissionTask(
        id: 'm-wa',
        title: 'Join WhatsApp Community',
        description:
            'Stay updated with the latest creator episodes and platform news.',
        coins: 7,
        actionLabel: 'Join',
        iconKey: 'whatsapp',
      ),
      MissionTask(
        id: 'm-creator',
        title: 'Follow First Creator',
        description: 'Spend 10 minutes watching learning episodes',
        coins: 5,
        actionLabel: 'Follow',
        iconKey: 'user',
      ),
      MissionTask(
        id: 'm-rate',
        title: 'Rate the App',
        description: 'Thank you for rating Skiflux on the App Store!',
        coins: 5,
        actionLabel: 'Rate',
        iconKey: 'star',
      ),
      MissionTask(
        id: 'm-photo',
        title: 'Upload Profile Picture',
        description:
            'Never miss a new creator announcement, platform tutorial, or update.',
        coins: 25,
        actionLabel: 'Upload',
        iconKey: 'image',
      ),
    ];
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);
