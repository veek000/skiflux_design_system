/// Report-a-comment category picker.
///
/// `POST /comments/{id}/report/` takes a **required** `category` from the
/// spec's `ReportCommentCategoryEnum` (`SkiFlux_API.yaml:12023`), so the report
/// cannot be fired from a bare thumb-down — the user has to say what is wrong.
/// This sheet asks, and returns the picked category for the caller to post.
///
/// Rows follow the playback-speed picker: 48px tap targets, label left, and no
/// pre-selected default — a report is deliberate.
library;

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../data/comments_repository.dart';

/// Shows the six spec categories and resolves to the chosen one, or null if the
/// sheet was dismissed without picking (backdrop tap, drag-down, close).
Future<ReportCommentCategory?> showReportCommentSheet(BuildContext context) {
  return showSkifluxSheet<ReportCommentCategory>(
    context: context,
    builder: (_) => const _ReportCommentSheet(),
  );
}

class _ReportCommentSheet extends StatelessWidget {
  const _ReportCommentSheet();

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Report comment',
      subtitle: 'Tell us what is wrong with it. Our team reviews every report.',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only once the list is scrolled to its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceS,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
        ),
        children: [
          for (final category in ReportCommentCategory.values)
            InkWell(
              onTap: () => Navigator.of(context).pop(category),
              child: SizedBox(
                height: SkifluxUnit.u48,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: SkifluxTypography.uiButtonLarge.copyWith(
                          color: SkifluxColors.contentPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      RemixIcons.arrow_right_s_line,
                      size: SkifluxIcons.sizeM,
                      color: SkifluxColors.contentDisabled,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
