import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/widgets/load_failure.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import 'data/playlists_store.dart';
import 'data/season_providers.dart';
import 'playlist_episode_row.dart';
import 'playlist_screen.dart';

/// Figma: **Other Video Player Flow 07** (`1256:27214`) — the season picker,
/// opened from the EP chip above an episode title.
///
/// Header: season title (H7 Bold) over "Creator • N Episodes" + close circle.
/// Body: the same 128×98-thumb rows as the playlist detail page, each showing
/// the server's own lock state — locked rows blurred with a coin price,
/// unlocked and completed rows plain. The episode currently playing renders
/// highlighted (`1256:27298`, brand100 fill + "Playing EP 0X", no trailing
/// control) and is listed alongside its siblings rather than omitted.
///
/// [onOpenInFeed] is the whole "inline in home, modal elsewhere" rule. Home
/// passes a callback and the picked episode becomes a page of the feed the
/// user is already scrolling; every other surface passes null and gets the
/// player modal, because there is no feed behind them to scroll.
Future<void> showSeasonSheet(
  BuildContext context, {
  required SeasonArg season,
  String? playingEpisodeId,
  double? playingProgress,
  ValueChanged<PlaylistEpisode>? onOpenInFeed,
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _SeasonSheet(
      season: season,
      playingEpisodeId: playingEpisodeId,
      playingProgress: playingProgress,
      onOpenInFeed: onOpenInFeed,
    ),
  );
}

class _SeasonSheet extends ConsumerWidget {
  const _SeasonSheet({
    required this.season,
    this.playingEpisodeId,
    this.playingProgress,
    this.onOpenInFeed,
  });

  final SeasonArg season;
  final String? playingEpisodeId;

  /// Elapsed fraction of the episode playing behind this sheet, 0–1, or null
  /// when the caller has no clock to read. The sheet is a modal over a player
  /// it does not own, so it cannot derive this itself — and inventing a value
  /// is what the previous hardcoded `0.71` did.
  final double? playingProgress;

  final ValueChanged<PlaylistEpisode>? onOpenInFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seasonProvider(season));
    final loaded = async.value;

    // The header uses what the caller already knew so the title doesn't pop in
    // after the episodes land.
    final title = loaded?.title ?? season.title ?? 'Playlist';
    final subtitle = loaded?.metaLine ?? _hintMeta();

    return SkifluxSheetShell(
      title: title,
      subtitle: subtitle,
      child: switch (async) {
        AsyncLoading() => const Padding(
          padding: EdgeInsets.all(SkifluxSpacing.spaceL),
          child: PlaylistLoadingList(),
        ),
        AsyncError(:final error) => Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          child: LoadFailure(
            error: error,
            title: "We couldn't load this season",
            onRetry: () => ref.read(seasonProvider(season).notifier).retry(),
          ),
        ),
        AsyncValue(:final value?) when value.episodes.isEmpty =>
          const Padding(
            padding: EdgeInsets.all(SkifluxSpacing.spaceL),
            child: SkifluxEmptyState(
              icon: Icon(
                RemixIcons.play_list_2_fill,
                size: SkifluxEmptyState.iconSize,
                color: SkifluxColors.contentBrand,
              ),
              title: 'No episodes yet',
              message: 'This season has nothing published so far.',
            ),
          ),
        AsyncValue(:final value?) => _EpisodeList(
          playlist: value,
          playingEpisodeId: playingEpisodeId,
          playingProgress: playingProgress,
          onOpenInFeed: onOpenInFeed,
        ),
      },
    );
  }

  /// "N Episodes" from the navigating screen's hint, or nothing.
  String _hintMeta() {
    final count = season.episodeCount;
    final name = season.creatorName;
    final parts = <String>[
      if (name != null && name.isNotEmpty) name,
      if (count != null && count > 0) '$count Episodes',
    ];
    return parts.join(' · ');
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({
    required this.playlist,
    this.playingEpisodeId,
    this.playingProgress,
    this.onOpenInFeed,
  });

  final Playlist playlist;
  final String? playingEpisodeId;
  final double? playingProgress;
  final ValueChanged<PlaylistEpisode>? onOpenInFeed;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      // Sheet drags down only when this list is scrolled to its top.
      controller: ModalScrollController.of(context),
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      itemCount: playlist.episodes.length,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceL),
      itemBuilder: (context, i) {
        final ep = playlist.episodes[i];
        // Matched on id: the EP *number* only identifies an episode within its
        // own season, so scraping a digit out of the chip highlighted the
        // wrong row as soon as two seasons were in play.
        final playing = playingEpisodeId != null && ep.id == playingEpisodeId;
        return PlaylistEpisodeRow(
          episode: ep,
          playing: playing,
          progress: playing ? playingProgress : null,
          onTap: playing ? null : () => _onEpisodeTap(context, ep),
        );
      },
    );
  }

  Future<void> _onEpisodeTap(BuildContext context, PlaylistEpisode ep) async {
    if (ep.isLocked) {
      // Resolvable because `seasonProvider` cached this season on the way in.
      await showEpisodeUnlockSheet(context, episodeId: ep.id);
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final openInFeed = onOpenInFeed;
    if (openInFeed != null) {
      openInFeed(ep);
      return;
    }
    if (!context.mounted) return;
    await openPlaylistEpisode(context, ep, playlist);
  }
}
