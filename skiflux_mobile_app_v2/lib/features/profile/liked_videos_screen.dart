import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_handler.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';
import 'data/library_episode.dart';
import 'data/library_store.dart';
import 'library_episode_player.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 04** (`1256:25294`) — Liked Videos. Search field over
// a list of liked-episode rows: 98px thumbnail (EP + duration pills), 2-line
// title, creator avatar + name, views, red filled heart trailing. Tapping the
// heart un-likes (removes) the row; tapping the row opens the episode player.
//
// Backed by `GET /me/liked`; the heart posts `POST /episodes/like`, which is a
// toggle. Nothing is seeded — an empty list means the user has liked nothing.

class LikedVideosScreen extends ConsumerStatefulWidget {
  const LikedVideosScreen({super.key});

  @override
  ConsumerState<LikedVideosScreen> createState() => _LikedVideosScreenState();
}

class _LikedVideosScreenState extends ConsumerState<LikedVideosScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final liked = ref.watch(likedEpisodesProvider);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Liked Videos',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxSearchField(
                onChanged: (value) => setState(() => _query = value),
                onCleared: () => setState(() => _query = ''),
              ),
            ),
            Expanded(
              child: switch (liked) {
                AsyncLoading() => const LibraryListSkeleton(),
                AsyncError(:final error) => LoadFailure(
                  error: error,
                  title: "We couldn't load your liked videos",
                  onRetry: () =>
                      ref.read(likedEpisodesProvider.notifier).refresh(),
                ),
                AsyncData(:final value) => _list(value),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<LibraryEpisode> episodes) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? episodes
        : episodes
              .where((e) => e.title.toLowerCase().contains(query))
              .toList();
    if (visible.isEmpty) {
      return SkifluxEmptyState(
        icon: const Icon(
          RemixIcons.heart_3_fill,
          size: SkifluxEmptyState.iconSize,
          color: SkifluxColors.contentBrand,
        ),
        title: query.isEmpty ? 'No liked videos' : 'No matches',
        message: query.isEmpty
            ? 'Videos you like will show up here.'
            : 'No liked video matches “$_query”.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        0,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceL),
      itemBuilder: (_, i) => LibraryEpisodeRow(
        episode: visible[i],
        statusLine: '${visible[i].viewsLabel} views',
        onTap: () => showLibraryEpisodePlayer(context, visible[i]),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => _unlike(visible[i]),
          icon: const Icon(
            RemixIcons.heart_3_fill,
            size: SkifluxIcons.sizeM,
            color: SkifluxColors.contentNegative,
          ),
        ),
      ),
    );
  }

  Future<void> _unlike(LibraryEpisode episode) async {
    try {
      await ref.read(likedEpisodesProvider.notifier).unlike(episode);
      if (mounted) SkifluxToast.info(context, 'Removed from liked videos');
    } catch (error) {
      // The row is already back — say why it came back.
      if (!mounted) return;
      SkifluxToast.error(
        context,
        ref.read(errorHandlerProvider).classify(error).message,
      );
    }
  }
}
