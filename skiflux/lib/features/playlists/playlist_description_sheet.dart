import 'package:flutter/material.dart';

import '../../shared/sheets/description_sheet.dart';
import 'data/playlists_store.dart';

/// Figma: **Home & In-app Flow 04** (`827:35820`) — description modal opened
/// from the playlist detail "View Full Description" link.
///
/// Thin wrapper over [showDescriptionSheet] so playlist call sites stay
/// playlist-shaped; body presentation is shared with the home feed card.
Future<void> showPlaylistDescriptionSheet(
  BuildContext context, {
  required Playlist playlist,
}) {
  return showDescriptionSheet(
    context,
    description: playlist.description,
  );
}
