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

// Figma: **Profile Flow 12** (`1256:24572`) — Saved Videos. Search field +
// saved rows with a filled brand bookmark trailing; tapping the bookmark
// un-saves (removes) the row.
//
// Backed by `GET /me/saved`; the bookmark posts `POST /episodes/save`, a
// toggle. Nothing is seeded.

class SavedVideosScreen extends ConsumerStatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  ConsumerState<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends ConsumerState<SavedVideosScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedEpisodesProvider);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Saved Videos',
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
              child: switch (saved) {
                AsyncLoading() => const LibraryListSkeleton(),
                AsyncError(:final error) => LoadFailure(
                  error: error,
                  title: "We couldn't load your saved videos",
                  onRetry: () =>
                      ref.read(savedEpisodesProvider.notifier).refresh(),
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
          RemixIcons.bookmark_fill,
          size: SkifluxEmptyState.iconSize,
          color: SkifluxColors.contentBrand,
        ),
        title: query.isEmpty ? 'No saved videos' : 'No matches',
        message: query.isEmpty
            ? 'Videos you save will show up here.'
            : 'No saved video matches “$_query”.',
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
          onPressed: () => _unsave(visible[i]),
          icon: const Icon(
            RemixIcons.bookmark_fill,
            size: SkifluxIcons.sizeM,
            color: SkifluxColors.contentBrand,
          ),
        ),
      ),
    );
  }

  Future<void> _unsave(LibraryEpisode episode) async {
    try {
      await ref.read(savedEpisodesProvider.notifier).unsave(episode);
      if (mounted) SkifluxToast.info(context, 'Removed from saved videos');
    } catch (error) {
      if (!mounted) return;
      SkifluxToast.error(
        context,
        ref.read(errorHandlerProvider).classify(error).message,
      );
    }
  }
}
