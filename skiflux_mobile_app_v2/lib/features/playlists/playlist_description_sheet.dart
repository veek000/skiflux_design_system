import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/playlists_store.dart';

// Description modal opened from playlist detail "View Full Description".

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          0,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playlist.title,
              style: SkifluxTypography.headingH9Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              playlist.description,
              style: SkifluxTypography.bodyP9Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              playlist.detailMeta,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
