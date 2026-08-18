/// Generic "Description" bottom sheet — full body text under a standard
/// [SkifluxSheetShell] header.
///
/// Extracted so playlist and home feed share one presentation. Playlist keeps
/// [showPlaylistDescriptionSheet] as a thin wrapper for call-site clarity.
library;

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

/// Opens the shared description sheet with free-form [description] copy.
Future<void> showDescriptionSheet(
  BuildContext context, {
  required String description,
  String title = 'Description',
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _DescriptionSheet(title: title, description: description),
  );
}

class _DescriptionSheet extends StatelessWidget {
  const _DescriptionSheet({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: title,
      child: SingleChildScrollView(
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        // Sheet Column defaults to CrossAxisAlignment.center, so a Text that
        // only takes its intrinsic width reads as centered. Force full width
        // + start alignment to match Figma (left-aligned body copy).
        child: SizedBox(
          width: double.infinity,
          child: Text(
            description,
            textAlign: TextAlign.start,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
