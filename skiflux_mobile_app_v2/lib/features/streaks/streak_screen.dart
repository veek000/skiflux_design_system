import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import 'data/streaks_store.dart';
import 'milestone_sheet.dart';
import 'week_picker_sheet.dart';

// Figma: **Streak Flow** section (`3092:14400`) — Streak Screens 01–04.
// Screen 01 (`2231:11212`) = broken streak (0, missed days), 02
// (`2217:11294`) = active streak 5, 03 (`2259:12919`) = streak 7, 04
// (`2259:13122`) = 03 + milestone sheet. One parameterized screen renders
// all variants from [StreaksStore]; the demo data matches 03/04 so the
// milestone celebration is reachable.

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  /// Week shown in the tracker card; switchable via the date-range pill.
  StreakWeek _week = StreaksStore.currentWeek;

  @override
  void initState() {
    super.initState();
    // Screen 04: the milestone sheet opens over the screen when a
    // milestone was just reached (once per session for the demo).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && StreaksStore.consumeCelebration()) {
        showMilestoneSheet(context);
      }
    });
  }

  Future<void> _pickWeek() async {
    final picked = await showWeekPickerSheet(context, selected: _week);
    if (picked != null && mounted) setState(() => _week = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Streaks',
        // Figma: screen title uses Heading Style/Heading H8 Bold.
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 24px spacer mirrors the leading icon to keep the title centered.
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          const _StreakHero(),
          const SizedBox(height: SkifluxSpacing.spaceL),
          _ThisWeekCard(week: _week, onPickWeek: _pickWeek),
          const SizedBox(height: SkifluxSpacing.spaceL),
          const _StatCards(),
        ],
      ),
      bottomNavigationBar: _stickyShareButton(context),
    );
  }

  /// Sticky Button (`2231:11198`): white background, primary L "Share".
  Widget _stickyShareButton(BuildContext context) {
    return Material(
      color: SkifluxColors.surfaceL3,
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
            label: 'Share',
            expanded: true,
            onPressed: () => showShareSheet(context),
          ),
        ),
      ),
    );
  }
}

// ── Hero: flame · count · pending-task pill ──────────────────────────

class _StreakHero extends StatelessWidget {
  const _StreakHero();

  /// Figma `2224:11556` hero palette (primitive Orange ramp — the streak
  /// flow is orange-accented by design, like the My Profile streak pill).
  static const Color _count = SkifluxColors.orange500;

  @override
  Widget build(BuildContext context) {
    const active = StreaksStore.streak > 0;
    return Column(
      children: [
        const SkifluxFlame(active: active),
        const SizedBox(height: SkifluxSpacing.spaceM),
        Text(
          '${StreaksStore.streak}',
          textAlign: TextAlign.center,
          // Figma: H1 ExtraBold 72 with line-height 1 (leading-none);
          // inactive count (streak 0) goes disabled-grey like the flame.
          style: SkifluxTypography.headingH1.copyWith(
            color: active ? _count : SkifluxColors.contentDisabled,
            height: 1,
          ),
        ),
        Text(
          'Days in a row',
          textAlign: TextAlign.center,
          style: SkifluxTypography.bodyP7Regular.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceM),
        const _PendingTaskPill(),
      ],
    );
  }
}

/// Pending Task notification (`2224:11562`): orange pill, 32px fire
/// avatar, Creato Bold 14 message.
class _PendingTaskPill extends StatelessWidget {
  const _PendingTaskPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceS,
        SkifluxSpacing.spaceS,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceS,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.orange100,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        children: [
          Container(
            width: SkifluxUnit.u32,
            height: SkifluxUnit.u32,
            decoration: const BoxDecoration(
              color: SkifluxColors.orange400,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              RemixIcons.fire_fill,
              size: SkifluxUnit.u20,
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'Keep learning daily to maintain your streak and earn more XP',
              style: SkifluxTypography.uiButtonMedium.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── This Week card ───────────────────────────────────────────────────

/// `2226:11596`: grey card with header row (title + white date pill) and
/// the 7-day tracker for [week].
class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard({required this.week, required this.onPickWeek});

  final StreakWeek week;
  final VoidCallback onPickWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                week.isCurrent ? 'This Week' : 'Past Week',
                style: SkifluxTypography.uiButtonLarge.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
              _WeekPill(label: week.label, onTap: onPickWeek),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Row(
            children: [
              for (final day in week.days)
                Expanded(child: _DayCell(day: day)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date-range pill (`2259:13092`): white pill, calendar icon, Creato Bold
/// 12 label, down chevron. Tapping opens the week-picker sheet.
class _WeekPill extends StatelessWidget {
  const _WeekPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        borderRadius: SkifluxRadii.borderPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SkifluxSpacing.spaceS,
            SkifluxSpacing.spaceXs,
            SkifluxSpacing.spaceXs,
            SkifluxSpacing.spaceXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                RemixIcons.calendar_2_fill,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentPrimary,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceXs,
                ),
                child: Text(
                  label,
                  style: SkifluxTypography.uiButtonSmall.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
              ),
              const Icon(
                RemixIcons.arrow_down_s_line,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One day column (`2226:11600`…): Creato Bold 10 weekday label over a
/// 40px state circle.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day});

  final StreakDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day.label,
          style: SkifluxTypography.uiBadgeTagSmall.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Container(
          width: SkifluxUnit.u40,
          height: SkifluxUnit.u40,
          decoration: BoxDecoration(
            color: _background,
            shape: BoxShape.circle,
          ),
          child: Center(child: _content),
        ),
      ],
    );
  }

  Color get _background => switch (day.state) {
        StreakDayState.completed => SkifluxColors.orange500,
        StreakDayState.missed => SkifluxColors.backgroundNegativeSubtle,
        StreakDayState.today => SkifluxColors.orange200,
        StreakDayState.future => SkifluxColors.backgroundPressed,
      };

  Widget get _content => switch (day.state) {
        // Figma icon size inside the 40px circle: 26.67 (40 × ⅔).
        StreakDayState.completed => const Icon(
            RemixIcons.check_fill,
            size: 26.67,
            color: SkifluxColors.contentPrimaryInverse,
          ),
        StreakDayState.missed => const Icon(
            RemixIcons.close_fill,
            size: 26.67,
            color: SkifluxColors.contentNegative,
          ),
        StreakDayState.today => Text(
            '${day.number}',
            style: SkifluxTypography.headingH9Bold.copyWith(
              color: SkifluxColors.orange600,
            ),
          ),
        StreakDayState.future => Text(
            '${day.number}',
            style: SkifluxTypography.headingH9Bold.copyWith(
              color: SkifluxColors.contentDisabled,
            ),
          ),
      };
}

// ── Stat cards ───────────────────────────────────────────────────────

/// `2226:11888`: Best Streak (notice-subtle → notice gradient, trophy) and
/// XP Earned (brand-opacity-50 → brand gradient, flashlight).
class _StatCards extends StatelessWidget {
  const _StatCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${StreaksStore.bestStreak}',
            label: 'Best Streak',
            gradient: [
              SkifluxColors.backgroundNoticeSubtle,
              SkifluxColors.backgroundNotice,
            ],
            icon: RemixIcons.trophy_fill,
            // Figma icon fill: Yellow/700.
            iconColor: SkifluxColors.contentNoticeBold,
          ),
        ),
        SizedBox(width: SkifluxSpacing.spaceL),
        Expanded(
          child: _StatCard(
            value: '${StreaksStore.xpEarned}',
            label: 'XP Earned',
            gradient: [
              SkifluxColors.backgroundBrandOpacity50,
              SkifluxColors.backgroundBrand,
            ],
            icon: RemixIcons.flashlight_fill,
            // Figma icon fill: Brand/700.
            iconColor: SkifluxColors.brand700,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.gradient,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderX,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
        child: Stack(
          children: [
            // 64px icon hanging off the bottom-right corner, clipped.
            Positioned(
              right: -3.5,
              top: 37,
              child: Icon(icon, size: SkifluxUnit.u64, color: iconColor),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: SkifluxTypography.headingH6ExtraBold.copyWith(
                      color: SkifluxColors.black,
                    ),
                  ),
                  Text(
                    label,
                    style: SkifluxTypography.bodyP8Regular.copyWith(
                      color: SkifluxColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
