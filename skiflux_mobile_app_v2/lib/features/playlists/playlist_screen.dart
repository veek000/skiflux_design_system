import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/playlist_deck.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import '../profile/profile_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/playlists_store.dart';
import 'playlist_description_sheet.dart';
import 'playlist_episode_row.dart';

/// Figma: **Home & In-app Flow 05** (`198:14183`) — playlist detail page.
///
/// Top nav (back + share, no title), stacked-deck cover, title + hashtags,
/// creator pill row, 2-line description + "View Full Description", Play all
/// + bookmark/download circles, then the episode list.
class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pl = ref.watch(playlistsProvider).defaultPlaylist;
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        // Figma 198:14248 — nav carries only the back + share icons.
        showLabel: false,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.share_forward_fill),
          onPressed: () => showShareSheet(context),
        ),
      ),
      body: SafeArea(
        top: false,
        // The header is one item, not fourteen. It used to be spread across
        // an index ladder in this builder, which is how the episodes below it
        // ended up with no gap between them: every spacer was written by hand
        // and the ones between the rows were simply never written.
        child: ListView.builder(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          itemCount: 1 + pl.episodes.length,
          itemBuilder: (context, index) {
            if (index == 0) return _PlaylistHeader(playlist: pl);
            final ep = pl.episodes[index - 1];
            return Padding(
              // Between the rows only — the header already sets its own gap.
              padding: const EdgeInsets.only(top: SkifluxSpacing.spaceL),
              child: PlaylistEpisodeRow(
                episode: ep,
                onTap: () =>
                    openPlaylistEpisode(context, ep, pl, showViewPlaylist: false),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Everything above the episode list: cover deck, title + hashtags, creator
/// pill, the clamped description and its expander, then the actions row.
///
/// No trailing gap — the first episode row supplies it, the same as every row
/// after it, so the list's rhythm is set in one place.
class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlaylistDeck(
          height: 150,
          episodeCount: playlist.episodeCount,
          backWidthFactor: 0.9336,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          playlist.title,
          style: SkifluxTypography.headingH9Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        // TODO(backend, minor): playlist hashtags are not in the payload —
        // expects: a `tags` array on the playlist so these stop being fixed
        Text(
          '#UIDesign #Figma',
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _CreatorPillRow(playlist: playlist),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          playlist.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SkifluxTypography.bodyP10Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () =>
                showPlaylistDescriptionSheet(context, playlist: playlist),
            child: Text(
              'View Full Description',
              style: SkifluxTypography.uiButtonSmall.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        _ActionsRow(playlist: playlist),
      ],
    );
  }
}

/// Opens the episode player modal for [ep], or the unlock sheet when locked.
///
/// [showViewPlaylist] — false when launched from the playlist page itself
/// (no self-link); the EP-chip menu sheet keeps the default true.
Future<void> openPlaylistEpisode(
  BuildContext context,
  PlaylistEpisode ep,
  Playlist pl, {
  bool showViewPlaylist = true,
}) async {
  if (ep.isLocked) {
    await showEpisodeUnlockSheet(context, episodeId: ep.id);
    return;
  }
  final sub = SubscriptionEpisode(
    epNumber: ep.number,
    title: ep.title,
    creatorUsername: pl.creatorUsername,
    duration: ep.duration,
    views: '22k',
    postedAgo: '5 hrs ago',
    watchProgress: ep.state == PlaylistEpisodeState.completed ? 1 : 0.15,
  );
  if (!context.mounted) return;
  await showEpisodePlayerModal(
    context,
    sub,
    showViewPlaylist: showViewPlaylist,
  );
}

/// Figma `198:14203` — full-width `Background/Hover` pill: 48px avatar,
/// name (H9 semibold) over handle (Creato Bold 10 tertiary), trailing
/// chevron circle. Tapping visits the creator profile.
class _CreatorPillRow extends StatelessWidget {
  const _CreatorPillRow({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderX,
      child: InkWell(
        borderRadius: SkifluxRadii.borderX,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: Row(
          children: [
            SkifluxAvatar(
              style: SkifluxAvatarStyle.initial,
              size: SkifluxUnit.u48,
              initials: playlist.creatorName[0],
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.creatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.headingH9Semibold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  Text(
                    '@${playlist.creatorUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              child: Icon(
                RemixIcons.arrow_right_s_line,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `198:14215` — expanded "Play all" primary pill + 32px grey circles
/// for bookmark and download.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SkifluxButton(
            label: 'Play all',
            size: SkifluxButtonSize.s,
            expanded: true,
            onPressed: () {
              // First playable episode (completed/unlocked) starts the run.
              final first = playlist.episodes
                  .where((e) => e.isUnlocked)
                  .firstOrNull;
              if (first != null) {
                openPlaylistEpisode(
                  context,
                  first,
                  playlist,
                  showViewPlaylist: false,
                );
              }
            },
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        _CircleAction(
          icon: RemixIcons.bookmark_fill,
          onTap: () => SkifluxToast.success(context, 'Playlist saved'),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        _CircleAction(
          icon: RemixIcons.download_fill,
          onTap: () => SkifluxToast.info(context, 'Downloads are coming soon'),
        ),
      ],
    );
  }
}

/// 32px `Background/Hover` circle with a 16px icon (198:14217 / 198:14219).
class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundHover,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: SkifluxUnit.u32,
          height: SkifluxUnit.u32,
          child: Center(
            child: Icon(
              icon,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
