import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import 'data/library_episode.dart';
import 'library_episode_player.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 13** (`1256:24465`) — Downloads. Nav with "Clear
// all" (negative), search field, "8 videos · 1.2 GB used" storage line,
// download rows ("112 MB · SD 480p") with a red trash trailing control.
//
// There is no offline download pipeline and no download endpoint, so this
// screen starts empty and shows its empty state. It is wired end to end
// against [LibraryEpisode] so that the day downloads exist, only the source
// of `_downloads` has to change.

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _query = '';

  // TODO(backend, blocking): no offline download pipeline or endpoint exists, so this list is always empty — expects: local download store fed by a per-episode download URL + file size + quality label
  final List<LibraryEpisode> _downloads = [];

  /// Until files are really on disk there is nothing to measure, so the
  /// storage line is derived from what the rows claim rather than invented.
  static const int _mbPerVideo = 112;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _downloads
        : _downloads.where((e) => e.title.toLowerCase().contains(query))
              .toList();
    final totalMb = _downloads.length * _mbPerVideo;
    final usedLabel = totalMb >= 1000
        ? '${(totalMb / 1000).toStringAsFixed(1)} GB'
        : '$totalMb MB';

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
        trailing: TextButton(
          onPressed: _downloads.isEmpty ? null : _confirmClearAll,
          child: Text(
            'Clear all',
            style: SkifluxTypography.uiButtonMedium.copyWith(
              color: SkifluxColors.contentNegative,
            ),
          ),
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
            if (_downloads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  0,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                ),
                child: Text(
                  '${_downloads.length} videos · $usedLabel used',
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
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
                      itemBuilder: (_, i) => LibraryEpisodeRow(
                        episode: visible[i],
                        statusLine: '$_mbPerVideo MB · SD 480p',
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _confirmDelete(visible[i]),
                          icon: const Icon(
                            RemixIcons.delete_bin_fill,
                            size: SkifluxIcons.sizeM,
                            color: SkifluxColors.contentNegative,
                          ),
                        ),
                        onTap: () =>
                            showLibraryEpisodePlayer(context, visible[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm → delete one download → success toast.
  Future<void> _confirmDelete(LibraryEpisode episode) async {
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
    setState(() => _downloads.remove(episode));
    SkifluxToast.success(context, 'Download deleted');
  }

  /// Confirm → clear every download → success toast.
  Future<void> _confirmClearAll() async {
    final count = _downloads.length;
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
    setState(_downloads.clear);
    SkifluxToast.success(context, 'All downloads cleared');
  }
}
