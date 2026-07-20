import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/tasks_store.dart';
import 'quiz_assessment_screen.dart';
import 'task_shared_widgets.dart';

// Figma: Task flow 08 (`1256:14443`) — quiz intro / "Before you start".

class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(tasksProvider).byId(taskId);
    final quiz = task?.quiz;

    if (task == null || quiz == null) {
      return Scaffold(
        appBar: SkifluxTopNavBar(
          label: 'Task Details',
          labelStyle: SkifluxTypography.headingH8Bold,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(RemixIcons.arrow_left_s_line),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Quiz not found')),
      );
    }

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Task Details',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                Text(
                  task.title,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                TaskRewardPill(coins: task.coins, xp: task.xp),
                const SizedBox(height: SkifluxSpacing.spaceL),
                TaskEpisodeRow(
                  title: task.episodeTitle,
                  subtitle: task.episodeSubtitle,
                  onTap: () => openTaskEpisode(context, ref, task),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                  decoration: BoxDecoration(
                    borderRadius: SkifluxRadii.borderL,
                    border: Border.all(
                      color: SkifluxColors.contentSecondaryInverse,
                      width: SkifluxBorderWidth.xs,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you start',
                        style: SkifluxTypography.headingH10Bold.copyWith(
                          color: SkifluxColors.contentSecondary,
                        ),
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      Text(
                        quiz.introBody,
                        style: SkifluxTypography.bodyP10Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceM),
                      _InfoRow(
                        icon: RemixIcons.file_list_3_fill,
                        text:
                            '${quiz.questionCount} Questions multiple choice format.',
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      _InfoRow(
                        icon: RemixIcons.time_fill,
                        text:
                            'Takes roughly ${quiz.minutes} minutes to complete.',
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      _InfoRow(
                        icon: RemixIcons.checkbox_circle_fill,
                        text:
                            'You must score ${quiz.passPercent}% to pass and earn coins.',
                      ),
                    ],
                  ),
                ),
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
                  SkifluxSpacing.spaceL,
                ),
                child: SkifluxButton(
                  label: 'Take Assessment',
                  expanded: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            QuizAssessmentScreen(taskId: taskId),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SkifluxColors.contentBrand),
        const SizedBox(width: SkifluxSpacing.spaceS),
        Expanded(
          child: Text(
            text,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
