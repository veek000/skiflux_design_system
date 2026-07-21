import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/playlists_store.dart';

/// Figma: **Home & In-app Flow 04** (`827:35820`) — description modal opened
/// from the playlist detail "View Full Description" link. Header "Description"
/// + close circle, then the full description body (Body p11 regular,
/// Content/Tertiary). No title/meta repetition per the frame.
Future<void> showPlaylistDescriptionSheet(
  BuildContext context, {
  required Playlist playlist,
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _PlaylistDescriptionSheet(playlist: playlist),
  );
}

class _PlaylistDescriptionSheet extends StatelessWidget {
  const _PlaylistDescriptionSheet({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Description',
      child: SingleChildScrollView(
        // Sheet drags down only when scrolled to the top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          0,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
        ),
        child: Text(
          playlist.description,
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
      ),
    );
  }
}
