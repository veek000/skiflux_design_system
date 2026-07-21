import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import 'data/playlists_store.dart';
import 'playlist_episode_row.dart';
import 'playlist_screen.dart';

/// Figma: **Other Video Player Flow 07** (`1256:27214`) — playlist picker
/// over the player, opened from the EP chip on the video card.
///
/// Header: playlist title (H7 Bold) over "Creator • N Episodes" + close
/// circle. Body: the same 128×98-thumb episode rows as the playlist detail
/// page; the episode currently playing renders highlighted (`1256:27298`,
/// brand100 fill + "Playing EP 0X" status, no trailing control).
Future<void> showPlaylistMenuSheet(
  BuildContext context, {
  int? playingEpisodeNumber,
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _PlaylistMenuSheet(
      playingEpisodeNumber: playingEpisodeNumber,
    ),
  );
}

class _PlaylistMenuSheet extends ConsumerWidget {
  const _PlaylistMenuSheet({this.playingEpisodeNumber});

  final int? playingEpisodeNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pl = ref.watch(playlistsProvider).defaultPlaylist;
    return SkifluxSheetShell(
      title: pl.title,
      subtitle: pl.metaLine,
      child: ListView.separated(
        shrinkWrap: true,
        // Sheet drags down only when this list is scrolled to its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        itemCount: pl.episodes.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: SkifluxSpacing.spaceL),
        itemBuilder: (context, i) {
          final ep = pl.episodes[i];
          final playing = ep.number == playingEpisodeNumber;
          return PlaylistEpisodeRow(
            episode: ep,
            playing: playing,
            onTap: playing ? null : () => _onEpisodeTap(context, ep, pl),
          );
        },
      ),
    );
  }

  Future<void> _onEpisodeTap(
    BuildContext context,
    PlaylistEpisode ep,
    Playlist pl,
  ) async {
    if (ep.isLocked) {
      await showEpisodeUnlockSheet(context, episodeId: ep.id);
      return;
    }
    // Swap to the picked episode: close the picker, open its player.
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await openPlaylistEpisode(context, ep, pl);
  }
}
