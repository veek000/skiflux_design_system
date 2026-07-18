import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import 'data/playlists_store.dart';
import 'playlist_screen.dart';

// Figma: playlist picker over the player — Other Video Player Flow 07
// (`1256:27214`): title, creator · N episodes, unlocked / locked rows.

Future<void> showPlaylistMenuSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _PlaylistMenuSheet(),
  );
}

class _PlaylistMenuSheet extends StatefulWidget {
  const _PlaylistMenuSheet();

  @override
  State<_PlaylistMenuSheet> createState() => _PlaylistMenuSheetState();
}

class _PlaylistMenuSheetState extends State<_PlaylistMenuSheet> {
  final _store = PlaylistsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pl = _store.defaultPlaylist;
    return SkifluxSheetShell(
      title: pl.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.spaceL,
              0,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceS,
            ),
            child: Text(
              pl.metaLine,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                SkifluxSpacing.spaceL,
                0,
                SkifluxSpacing.spaceL,
                SkifluxSpacing.spaceL,
              ),
              itemCount: pl.episodes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SkifluxSpacing.spaceS),
              itemBuilder: (context, i) {
                final ep = pl.episodes[i];
                return _EpisodeRow(
                  episode: ep,
                  onTap: () => _onEpisodeTap(context, ep),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.spaceL,
              0,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
            ),
            child: SkifluxButton(
              label: 'Open full playlist',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PlaylistScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onEpisodeTap(BuildContext context, PlaylistEpisode ep) async {
    if (ep.isLocked) {
      await showEpisodeUnlockSheet(context, episodeId: ep.id);
      return;
    }
    // Unlocked — dismiss menu; player already shows current EP in demo.
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing ${ep.epTag} · ${ep.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.onTap});

  final PlaylistEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = episode.isLocked;
    final statusLabel = switch (episode.state) {
      PlaylistEpisodeState.completed => 'Completed',
      PlaylistEpisodeState.unlocked => 'Unlocked',
      PlaylistEpisodeState.locked => 'Locked',
    };
    final statusColor = switch (episode.state) {
      PlaylistEpisodeState.completed => SkifluxColors.contentPositive,
      PlaylistEpisodeState.unlocked => SkifluxColors.contentNotice,
      PlaylistEpisodeState.locked => SkifluxColors.contentTertiary,
    };

    return Material(
      color: SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderL,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderL,
        child: Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          child: Row(
            children: [
              Container(
                width: SkifluxUnit.u40,
                height: SkifluxUnit.u40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: locked
                      ? SkifluxColors.backgroundPressed
                      : SkifluxColors.backgroundBrand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  locked
                      ? RemixIcons.lock_2_fill
                      : RemixIcons.play_circle_fill,
                  size: 20,
                  color: locked
                      ? SkifluxColors.contentTertiary
                      : SkifluxColors.contentPrimaryInverse,
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${episode.epTag} · ${episode.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.space2xs),
                    Row(
                      children: [
                        Text(
                          statusLabel,
                          style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                            color: statusColor,
                          ),
                        ),
                        Text(
                          ' · ${episode.duration}',
                          style: SkifluxTypography.bodyP11Regular.copyWith(
                            color: SkifluxColors.contentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (locked) ...[
                const Icon(
                  RemixIcons.copper_coin_fill,
                  size: 16,
                  color: SkifluxColors.contentNoticeBold,
                ),
                const SizedBox(width: SkifluxSpacing.space2xs),
                Text(
                  '${episode.coinCost}',
                  style: SkifluxTypography.uiButtonSmall.copyWith(
                    color: SkifluxColors.contentNoticeBold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
