import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/streaks_store.dart';

// Week picker for the Streaks screen's date-range pill. No Figma frame
// exists for this modal (the pill is static in all four streak screens),
// so it composes existing patterns: SkifluxSheetShell + a hand-rolled
// month grid styled like the This-Week day cells. Tapping any date
// selects its whole Sun–Sat week (start → end); weeks without tracked
// history are disabled.
//
// Sheet consumption: reads [streaksProvider] for [StreaksState.weekContaining]
// only — selection/month paging stay local to the sheet.

/// Shows the picker and resolves with the chosen week, or null when
/// dismissed. [selected] is the currently shown week.
Future<StreakWeek?> showWeekPickerSheet(
  BuildContext context, {
  required StreakWeek selected,
}) {
  return showSkifluxSheet<StreakWeek>(
    context: context,
    builder: (_) => _WeekPickerSheet(selected: selected),
  );
}

class _WeekPickerSheet extends ConsumerStatefulWidget {
  const _WeekPickerSheet({required this.selected});

  final StreakWeek selected;

  @override
  ConsumerState<_WeekPickerSheet> createState() => _WeekPickerSheetState();
}

class _WeekPickerSheetState extends ConsumerState<_WeekPickerSheet> {
  late StreakWeek _selected = widget.selected;

  /// First day of the month currently shown in the grid.
  late DateTime _month = DateTime(_selected.start.year, _selected.start.month);

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final streaks = ref.watch(streaksProvider);

    return SkifluxSheetShell(
      title: 'Select Week',
      child: SingleChildScrollView(
        // Sheet drags down only when scrolled to the top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _monthHeader(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _weekdayLabels(),
            const SizedBox(height: SkifluxSpacing.spaceS),
            ..._weekRows(streaks),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Apply',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }

  /// "May 2029" between back/forward month chevrons.
  Widget _monthHeader() {
    return Row(
      children: [
        _monthChevron(RemixIcons.arrow_left_s_line, -1),
        Expanded(
          child: Text(
            '${_monthNames[_month.month - 1]} ${_month.year}',
            textAlign: TextAlign.center,
            style: SkifluxTypography.headingH9Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
        _monthChevron(RemixIcons.arrow_right_s_line, 1),
      ],
    );
  }

  Widget _monthChevron(IconData icon, int delta) {
    return Material(
      color: SkifluxColors.backgroundHover,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() {
          _month = DateTime(_month.year, _month.month + delta);
        }),
        child: Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
          child: Icon(
            icon,
            size: SkifluxIcons.sizeM,
            color: SkifluxColors.contentPrimary,
          ),
        ),
      ),
    );
  }

  Widget _weekdayLabels() {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
      ],
    );
  }

  /// Sun-first rows from the Sunday on/before the 1st through the week
  /// containing the month's last day.
  List<Widget> _weekRows(StreaksState streaks) {
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    // DateTime.weekday: Mon=1 … Sun=7 → Sun-first offset is weekday % 7.
    var cursor = first.subtract(Duration(days: first.weekday % 7));
    final rows = <Widget>[];
    while (!cursor.isAfter(last)) {
      rows.add(
        _WeekRow(
          sunday: cursor,
          month: _month.month,
          selected: _selected,
          weekContaining: streaks.weekContaining,
          onSelect: (week) => setState(() => _selected = week),
        ),
      );
      cursor = cursor.add(const Duration(days: 7));
    }
    return rows;
  }
}

/// One Sun–Sat row. Tappable as a whole — any date selects its week —
/// when the week has tracked data; the selected week renders as a
/// brand-tinted pill spanning the row.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.sunday,
    required this.month,
    required this.selected,
    required this.weekContaining,
    required this.onSelect,
  });

  final DateTime sunday;
  final int month;
  final StreakWeek selected;
  final StreakWeek? Function(DateTime day) weekContaining;
  final ValueChanged<StreakWeek> onSelect;

  @override
  Widget build(BuildContext context) {
    final week = weekContaining(sunday);
    final isSelected =
        week != null && StreakWeek.sameDay(week.start, selected.start);
    return Padding(
      padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceXs),
      child: Material(
        color: isSelected
            ? SkifluxColors.backgroundSelected
            : Colors.transparent,
        borderRadius: SkifluxRadii.borderPill,
        child: InkWell(
          borderRadius: SkifluxRadii.borderPill,
          onTap: week == null ? null : () => onSelect(week),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _dayCell(
                    sunday.add(Duration(days: i)),
                    tracked: week != null,
                    isSelected: isSelected,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(
    DateTime date, {
    required bool tracked,
    required bool isSelected,
  }) {
    final inMonth = date.month == month;
    final Color color;
    if (!tracked) {
      // Untracked → disabled; adjacent-month dates fade further back.
      color = inMonth
          ? SkifluxColors.contentDisabled
          : SkifluxColors.contentTertiaryInverse;
    } else if (isSelected) {
      color = SkifluxColors.contentBrand;
    } else {
      color = SkifluxColors.contentPrimary;
    }
    return SizedBox(
      height: SkifluxUnit.u40,
      child: Center(
        child: Text(
          '${date.day}',
          style:
              (isSelected
                      ? SkifluxTypography.bodyP9Semibold
                      : SkifluxTypography.bodyP9Regular)
                  .copyWith(color: color),
        ),
      ),
    );
  }
}
