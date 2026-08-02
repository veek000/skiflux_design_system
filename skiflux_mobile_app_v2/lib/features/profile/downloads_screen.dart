import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/clear_all_action.dart';
import 'library_episode_player.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 13** (`1256:24465`) — Downloads. Nav with "Clear
// all" (negative), search field, storage line, download rows with a red trash
// trailing control.
//
// Every figure here is now read from disk: the storage line sums real file
// sizes and each row shows its own. It used to multiply the row count by a
// hardcoded 112 MB and print "SD 480p" on every row — a resolution nothing
// had chosen, for files that did not exist.

import 'data/downloads_store.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsProvider);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? downloads
        : downloads
              .where((d) => d.episode.title.toLowerCase().contains(query))
              .toList();
    // Summed from the files themselves. This was `count × 112 MB`, so the
    // storage line was a fiction that happened to look plausible.
    final usedLabel = formatBytes(
      ref.read(downloadsProvider.notifier).totalBytes,
    );

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Downloads',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: ClearAllAction(
          onPressed: downloads.isEmpty ? null : _confirmClearAll,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxSearchField(
                onChanged: (value) => setState(() => _query = value),
                onCleared: () => setState(() => _query = ''),
              ),
            ),
            if (downloads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  0,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                ),
                child: Text(
                  '${downloads.length} videos · $usedLabel used',
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ),
            Expanded(
              // Sits under the search field, not centred in the space below
              // it: [SkifluxEmptyState] already carries its own 48px of
              // vertical padding, and adding a [Center] on top pushed the
              // whole thing to the middle of the screen — well below where
              // Watch History puts the identical state.
              child: visible.isEmpty
                  // `Align` and not a bare child: this screen's Column is
                  // `crossAxisAlignment: start`, so the empty state was given
                  // a loose width constraint, sized to its own text and sat
                  // against the left edge. Top-centre puts it where Watch
                  // History has it — same height on the screen, centred.
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: SkifluxEmptyState(
                        icon: const Icon(
                          RemixIcons.download_fill,
                          size: SkifluxEmptyState.iconSize,
                          color: SkifluxColors.contentBrand,
                        ),
                        title: query.isEmpty ? 'No downloads' : 'No matches',
                        message: query.isEmpty
                            ? 'Downloaded episodes will show up here.'
                            : 'No download matches “$_query”.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        SkifluxSpacing.spaceL,
                        0,
                        SkifluxSpacing.spaceL,
                        SkifluxSpacing.spaceL,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: SkifluxSpacing.spaceL),
                      itemBuilder: (_, i) {
                        final d = visible[i];
                        return LibraryEpisodeRow(
                          episode: d.episode,
                          // The real size on disk. The resolution used to be
                          // printed as "SD 480p" on every row; the backend
                          // serves one rendition and never says which, so
                          // naming one was a guess.
                          statusLine: switch (d.state) {
                            DownloadState.downloading =>
                              'Downloading ${(d.progress * 100).round()}%',
                            DownloadState.failed =>
                              d.error ?? 'Download failed',
                            DownloadState.complete => d.sizeLabel,
                          },
                          trailing: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _confirmDelete(d),
                            icon: const Icon(
                              RemixIcons.delete_bin_fill,
                              size: SkifluxIcons.sizeM,
                              color: SkifluxColors.contentNegative,
                            ),
                          ),
                          // Only a finished file can play.
                          onTap: d.isComplete
                              ? () => showLibraryEpisodePlayer(
                                  context,
                                  d.episode,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(DownloadedEpisode download) async {
    final episode = download.episode;
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete this download?',
      message:
          '${episode.epTag} · ${episode.title} will be removed from '
          'your device. You can download it again anytime.',
      confirmLabel: 'Delete Download',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !mounted) return;
    // Awaited: this deletes a real file now, so the toast should follow the
    // deletion rather than race it.
    await ref.read(downloadsProvider.notifier).remove(episode.id);
    if (!mounted) return;
    SkifluxToast.success(context, 'Download deleted');
  }

  Future<void> _confirmClearAll() async {
    final count = ref.read(downloadsProvider).length;
    final confirmed = await showConfirmSheet(
      context,
      title: 'Clear all downloads?',
      message:
          'All $count downloaded videos will be removed from your '
          'device. You can download them again anytime.',
      confirmLabel: 'Clear All Downloads',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(downloadsProvider.notifier).clearAll();
    if (!mounted) return;
    SkifluxToast.success(context, 'All downloads cleared');
  }
}
