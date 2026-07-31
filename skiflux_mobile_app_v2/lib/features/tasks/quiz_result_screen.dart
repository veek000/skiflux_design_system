import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import 'data/skillcoin_display.dart';
import 'data/tasks_store.dart';
import 'quiz_assessment_screen.dart';

// Figma: Task flow 01 (`1256:14718`) — Assessment Passed / result.
// Rewards split card: `1256:14729` (border/secondary divider).

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    super.key,
    required this.taskId,
    required this.correct,
    required this.total,
    required this.answers,
    required this.passed,
  });

  final String taskId;
  final int correct;
  final int total;
  final List<int?> answers;
  final bool passed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(tasksProvider).byId(taskId);
    final quiz = task?.quiz;
    final isQuiz = task?.kind == LearningTaskKind.quiz && quiz != null;
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    // Rewards are whatever the task actually declared — no invented "+25"
    // fallback; the split card hides entirely when nothing was declared.
    final coins = isQuiz ? quiz.rewardCoins : (task?.coins ?? Decimal.zero);
    final coinsLabel = formatSkillcoin(coins);
    final xp = isQuiz ? quiz.rewardXp : (task?.xp ?? 0);
    final hasRewards = coins > Decimal.zero || xp > 0;
    final passPercent = quiz?.passPercent ?? 100;
    final title = isQuiz
        ? (passed ? 'Assessment Passed!' : 'Assessment Failed')
        : 'Task Completed!';
    final body = isQuiz
        ? (passed
              ? 'You scored $correct/$total ($percent%) on this assessment.'
              : 'You scored $correct/$total ($percent%). You need '
                    '$passPercent% to pass. Review the answers and try again.')
        : hasRewards
        ? 'Your submission was approved. Rewards have been added '
              'to your wallet.'
        : 'Your submission was approved.';

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.space6xl,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 98,
                      height: 98,
                      decoration: BoxDecoration(
                        color: passed
                            ? SkifluxColors.backgroundPositiveSubtle
                            : SkifluxColors.backgroundNegativeSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        passed ? RemixIcons.check_fill : RemixIcons.close_fill,
                        size: 48,
                        color: passed
                            ? SkifluxColors.contentPositive
                            : SkifluxColors.contentNegative,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceS),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: SkifluxTypography.headingH7Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceXs),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: SkifluxTypography.bodyP8Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                    if (passed && hasRewards) ...[
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      // Figma `1256:14729` — two equal columns + centered
                      // vertical stroke (Border/Secondary). Stack guarantees
                      // the 1px line paints at a fixed height.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: SkifluxSpacing.spaceL,
                        ),
                        decoration: BoxDecoration(
                          color: SkifluxColors.backgroundHover,
                          borderRadius: SkifluxRadii.borderL,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Earned',
                                        style: SkifluxTypography
                                            .uiBadgeTagMedium
                                            .copyWith(
                                              color:
                                                  SkifluxColors.contentTertiary,
                                            ),
                                      ),
                                      const SizedBox(
                                        height: SkifluxSpacing.spaceXs,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            RemixIcons.copper_coin_fill,
                                            size: 20,
                                            color: SkifluxColors.contentNotice,
                                          ),
                                          const SizedBox(
                                            width: SkifluxSpacing.spaceXs,
                                          ),
                                          Text(
                                            '+$coinsLabel',
                                            style: SkifluxTypography
                                                .headingH10Bold
                                                .copyWith(
                                                  color: SkifluxColors
                                                      .contentNotice,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Gained',
                                        style: SkifluxTypography
                                            .uiBadgeTagMedium
                                            .copyWith(
                                              color:
                                                  SkifluxColors.contentTertiary,
                                            ),
                                      ),
                                      const SizedBox(
                                        height: SkifluxSpacing.spaceXs,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            RemixIcons.flashlight_fill,
                                            size: 20,
                                            color: SkifluxColors.contentBrand,
                                          ),
                                          const SizedBox(
                                            width: SkifluxSpacing.spaceXs,
                                          ),
                                          Text(
                                            '+$xp XP',
                                            style: SkifluxTypography
                                                .headingH10Bold
                                                .copyWith(
                                                  color: SkifluxColors
                                                      .contentBrand,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Fixed-height dark stroke between columns.
                            IgnorePointer(
                              child: Container(
                                width: 1.5,
                                height: 40,
                                color: SkifluxColors.borderSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Material(
              color: SkifluxColors.backgroundPrimary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceS,
                ),
                child: Column(
                  children: [
                    if (isQuiz) ...[
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: SkifluxColors.backgroundPrimary,
                          borderRadius: SkifluxRadii.borderPill,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuizAssessmentScreen(
                                    taskId: taskId,
                                    reviewMode: true,
                                    priorAnswers: answers,
                                  ),
                                ),
                              );
                            },
                            borderRadius: SkifluxRadii.borderPill,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                SkifluxSpacing.spaceM,
                              ),
                              child: Center(
                                child: Text(
                                  'Review Answers',
                                  style: SkifluxTypography.uiButtonLarge
                                      .copyWith(
                                        color: SkifluxColors.contentBrand,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                    ],
                    if (passed) ...[
                      SkifluxButton(
                        label: 'Share Result',
                        type: SkifluxButtonType.secondary,
                        expanded: true,
                        leadingIcon: const Icon(RemixIcons.share_forward_fill),
                        // Same share modal as home / streaks (not OS sheet).
                        onPressed: () => showShareSheet(context),
                      ),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                    ],
                    SkifluxButton(
                      label: 'Back to Tasks',
                      expanded: true,
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
