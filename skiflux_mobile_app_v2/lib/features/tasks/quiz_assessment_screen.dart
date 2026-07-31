import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import 'data/episode_tasks_repository.dart';
import 'data/tasks_store.dart';
import 'quiz_result_screen.dart';

// Figma: Task flow 07–03 — Assessment; Review frame `1256:14533`.

class QuizAssessmentScreen extends ConsumerStatefulWidget {
  const QuizAssessmentScreen({
    super.key,
    required this.taskId,
    this.reviewMode = false,
    this.priorAnswers,
  });

  final String taskId;
  final bool reviewMode;
  final List<int?>? priorAnswers;

  @override
  ConsumerState<QuizAssessmentScreen> createState() =>
      _QuizAssessmentScreenState();
}

class _QuizAssessmentScreenState extends ConsumerState<QuizAssessmentScreen> {
  LearningTask? _task;
  QuizData? _quiz;

  int _index = 0;
  late List<int?> _answers;
  Timer? _timer;
  late int _remaining;
  bool _submitting = false;

  /// For `time_taken_seconds` on the wire submission.
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ConsumerState allows [ref] in initState (Riverpod 2+).
    _task = ref.read(tasksProvider).byId(widget.taskId);
    _quiz = _task?.quiz;
    final q = _quiz;
    _answers = widget.priorAnswers != null
        ? List<int?>.from(widget.priorAnswers!)
        : List<int?>.filled(q?.questions.length ?? 0, null);
    _remaining = q?.timerSeconds ?? 0;
    // Live quizzes may declare no time limit (timerSeconds 0) — running the
    // countdown then would auto-submit an untouched quiz after one tick.
    if (!widget.reviewMode && q != null && q.timerSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remaining <= 0) {
          _timer?.cancel();
          _finish();
          return;
        }
        setState(() => _remaining--);
      });
    }

    // Content failed to load — task/quiz missing from the session catalog.
    if (_task == null || _quiz == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ErrorDisplay.show(
          context,
          ref,
          const SkifluxFailure(SkifluxErrorKind.contentLoadFailed),
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _select(int option) {
    if (widget.reviewMode) return;
    setState(() => _answers[_index] = option);
  }

  void _next() {
    final quiz = _quiz;
    if (quiz == null) return;
    if (_index < quiz.questions.length - 1) {
      setState(() => _index++);
      return;
    }
    if (widget.reviewMode) {
      Navigator.of(context).pop();
      return;
    }
    _finish();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    _timer?.cancel();
    final quiz = _quiz;
    if (quiz == null || !mounted) return;

    try {
      var correct = 0;
      for (var i = 0; i < quiz.questions.length; i++) {
        if (_answers[i] == quiz.questions[i].correctIndex) correct++;
      }
      // Grade against the creator's threshold (integer math — no float
      // rounding): the spec exposes `correct_answer` per question, which is
      // what sanctions client-side grading for the instant result.
      final total = quiz.questions.length;
      final passed = correct * 100 >= quiz.passPercent * total;

      final task = ref.read(tasksProvider).byId(widget.taskId);
      // Store returns silently if the task vanished — treat that as a
      // submission failure so the user is not left without feedback.
      if (task == null) {
        throw const SkifluxFailure(SkifluxErrorKind.quizSubmission);
      }

      // Live quizzes record the attempt on the backend BEFORE any result UI:
      // `POST /episodes/task/submit` with answers keyed by question UUID.
      // A failed write shows the quiz-submission modal and stays here — the
      // picked answers survive for a retry. (When the payload carried no
      // question ids — a spec gap — the result stays client-graded.)
      final episodeId = task.episodeId;
      if (task.fromBackend && episodeId != null) {
        final ids = [for (final q in quiz.questions) q.id];
        final canSubmit = ids.isNotEmpty &&
            ids.every((id) => id != null && id.isNotEmpty);
        if (canSubmit) {
          setState(() => _submitting = true);
          try {
            final answers = <String, String>{
              for (var i = 0; i < quiz.questions.length; i++)
                if (_answers[i] != null && _answers[i]! >= 0 && _answers[i]! < 4)
                  ids[i]!: String.fromCharCode(65 + _answers[i]!),
            };
            await ref.read(episodeTasksRepositoryProvider).submitAssessment(
              episodeId: episodeId,
              answers: answers,
              timeTakenSeconds: DateTime.now()
                  .difference(_openedAt)
                  .inSeconds,
            );
          } finally {
            if (mounted) setState(() => _submitting = false);
          }
        }
      }

      ref
          .read(tasksProvider.notifier)
          .recordQuizResult(
            id: widget.taskId,
            answers: _answers,
            correct: correct,
            passed: passed,
          );

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            taskId: widget.taskId,
            correct: correct,
            total: total,
            answers: _answers,
            passed: passed,
          ),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(
        context,
        ref,
        e is SkifluxFailure
            ? e
            : SkifluxFailure(SkifluxErrorKind.quizSubmission, cause: e),
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final quiz = _quiz;
    if (task == null || quiz == null) {
      return const Scaffold(body: Center(child: Text('Quiz not found')));
    }

    final q = quiz.questions[_index];
    final selected = _answers[_index];
    final isLast = _index == quiz.questions.length - 1;
    // Progress: completed fraction of questions (Figma 100/361 ≈ q1 of 3).
    final progress = (_index + 1) / quiz.questions.length;

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        // Figma Review frame title is "Review".
        label: widget.reviewMode ? 'Review' : 'Assessment',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Figma still shows the timer chip on Review; untimed live quizzes
        // (no time limit) drop it rather than counting down from 00:00.
        trailing: widget.reviewMode || quiz.timerSeconds > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: SkifluxColors.backgroundDisabled,
                  borderRadius: SkifluxRadii.borderPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      RemixIcons.timer_fill,
                      size: 16,
                      color: SkifluxColors.contentSecondary,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Text(
                      widget.reviewMode ? '05:59' : _timerLabel,
                      style: SkifluxTypography.uiButtonSmall.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: ClipRRect(
              borderRadius: SkifluxRadii.borderPill,
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: SkifluxColors.backgroundSelected),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: const ColoredBox(
                        color: SkifluxColors.contentBrand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                Text(
                  'QUESTION ${_index + 1} OF ${quiz.questions.length}',
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: SkifluxColors.contentDisabled,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                Text(
                  q.prompt,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                for (var i = 0; i < q.options.length; i++) ...[
                  _OptionCard(
                    letter: String.fromCharCode(65 + i),
                    label: q.options[i],
                    selected: selected == i,
                    reviewMode: widget.reviewMode,
                    isCorrect: i == q.correctIndex,
                    isWrongPick:
                        widget.reviewMode &&
                        selected == i &&
                        i != q.correctIndex,
                    onTap: () => _select(i),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                ],
              ],
            ),
          ),
          Material(
            color: SkifluxColors.backgroundPrimary,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceS,
                ),
                child: SkifluxButton(
                  label: widget.reviewMode
                      ? (isLast ? 'Done' : 'Next Question')
                      : (isLast ? 'Submit' : 'Next Question'),
                  expanded: true,
                  loading: _submitting,
                  onPressed: widget.reviewMode
                      ? _next
                      : (selected == null || _submitting ? null : _next),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma option rows (`1256:14544` correct / `1256:14562` wrong / default).
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.letter,
    required this.label,
    required this.selected,
    required this.reviewMode,
    required this.isCorrect,
    required this.isWrongPick,
    required this.onTap,
  });

  final String letter;
  final String label;
  final bool selected;
  final bool reviewMode;
  final bool isCorrect;
  final bool isWrongPick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Defaults — idle option (border tertiary, pressed grey letter chip).
    Color bg = SkifluxColors.backgroundPrimary;
    Color border = SkifluxColors.borderTertiary;
    Color circleBg = SkifluxColors.backgroundPressed;
    Color circleFg = SkifluxColors.contentPrimary;
    Color textColor = SkifluxColors.contentTertiary;

    if (reviewMode) {
      if (isCorrect) {
        // Correct answer — always highlighted green (even if not picked).
        bg = SkifluxColors.backgroundPositiveSubtle;
        border = SkifluxColors.contentPositiveBold;
        circleBg = SkifluxColors.contentPositive;
        circleFg = SkifluxColors.contentPrimaryInverse;
      } else if (isWrongPick) {
        // User's wrong pick — red.
        bg = SkifluxColors.backgroundNegativeSubtle;
        border = SkifluxColors.contentNegativeBold;
        circleBg = SkifluxColors.backgroundNegative;
        circleFg = SkifluxColors.contentPrimaryInverse;
      }
    } else if (selected) {
      bg = SkifluxColors.backgroundSelected;
      border = SkifluxColors.contentBrand;
      circleBg = SkifluxColors.backgroundBrand;
      circleFg = SkifluxColors.contentPrimaryInverse;
      textColor = SkifluxColors.contentPrimary;
    }

    return Material(
      color: bg,
      borderRadius: SkifluxRadii.borderX,
      child: InkWell(
        onTap: reviewMode ? null : onTap,
        borderRadius: SkifluxRadii.borderX,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            SkifluxSpacing.spaceS,
            SkifluxSpacing.spaceS,
            SkifluxSpacing.spaceL,
            SkifluxSpacing.spaceS,
          ),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderX,
            border: Border.all(color: border, width: SkifluxBorderWidth.xs),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: circleFg,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                child: Text(
                  label,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
