import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 13** (`1256:24465`) — Downloads. Nav with "Clear
// all" (negative), search field, "8 videos · 1.2 GB used" storage line,
// download rows ("112 MB · SD 480p") with a red trash trailing control.

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _query = '';

  /// Session-local demo downloads (no real download pipeline): first five
  /// feed episodes at 112 MB each.
  List<SubscriptionEpisode>? _downloads;

  static const int _mbPerVideo = 112;

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider);
    _downloads ??= subs.feed().take(5).toList();
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _downloads!
        : _downloads!
            .where((e) => e.title.toLowerCase().contains(query))
            .toList();
    final totalMb = _downloads!.length * _mbPerVideo;
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
          onPressed: _downloads!.isEmpty ? null : _confirmClearAll,
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
            if (_downloads!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  0,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                ),
                child: Text(
                  '${_downloads!.length} videos · $usedLabel used',
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        SkifluxSpacing.spaceL,
                        0,
                        SkifluxSpacing.spaceL,
                        SkifluxSpacing.spaceL,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
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
                            showEpisodePlayerModal(context, visible[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm → delete one download → success toast.
  Future<void> _confirmDelete(SubscriptionEpisode episode) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete this download?',
      message: '${episode.epTag} · ${episode.title} will be removed from '
          'your device. You can download it again anytime.',
      confirmLabel: 'Delete Download',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _downloads!.remove(episode));
    SkifluxToast.success(context, 'Download deleted');
  }

  /// Confirm → clear every download → success toast.
  Future<void> _confirmClearAll() async {
    final count = _downloads!.length;
    final confirmed = await showConfirmSheet(
      context,
      title: 'Clear all downloads?',
      message: 'All $count downloaded videos will be removed from your '
          'device. You can download them again anytime.',
      confirmLabel: 'Clear All Downloads',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _downloads = []);
    SkifluxToast.success(context, 'All downloads cleared');
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 98,
            height: 98,
            decoration: const BoxDecoration(
              color: SkifluxColors.brand100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              RemixIcons.download_fill,
              size: 48,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Text(
            'No downloads',
            style: SkifluxTypography.headingH7Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'Downloaded episodes will show up here.',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
