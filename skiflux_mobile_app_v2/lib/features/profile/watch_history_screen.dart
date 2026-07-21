import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 15** (`1256:24224`) — Watch History. Nav with "Clear
// all" (negative), search field, Today / Yesterday sections of watched rows
// ("72% watched · Today, 9:20 AM" / "Completed · Yesterday, 4:12 PM"), each
// with a vertical more glyph → the row More Menu sheet (**Profile Flow 14**
// `1256:24327`: Remove from watch history / Downloads / Save Video /
// Share Video).

/// One watch-history entry: an episode + when/how far it was watched.
class _HistoryEntry {
  _HistoryEntry(this.episode, {required this.today, required this.progress});

  final SubscriptionEpisode episode;
  final bool today;

  /// 0–1; 1 renders as "Completed".
  final double progress;

  String get statusLine {
    final watched = progress >= 1
        ? 'Completed'
        : '${(progress * 100).round()}% watched';
    final when = today ? 'Today, 9:20 AM' : 'Yesterday, 4:12 PM';
    return '$watched · $when';
  }
}

class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  ConsumerState<WatchHistoryScreen> createState() =>
      _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  String _query = '';

  /// Session-local demo history (no app-wide history model yet): first four
  /// feed episodes — two Today (in progress), two Yesterday (completed).
  List<_HistoryEntry>? _entries;

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider);
    _entries ??= [
      for (final (i, ep) in subs.feed().take(4).indexed)
        _HistoryEntry(ep, today: i < 2, progress: i < 2 ? 0.72 : 1),
    ];
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _entries!
        : _entries!
            .where((e) => e.episode.title.toLowerCase().contains(query))
            .toList();
    final today = visible.where((e) => e.today).toList();
    final yesterday = visible.where((e) => !e.today).toList();

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Watch History',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // "Clear all" in negative red (1256:24238).
        trailing: TextButton(
          onPressed: _entries!.isEmpty
              ? null
              : () => setState(() => _entries = []),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxSearchField(
                onChanged: (value) => setState(() => _query = value),
                onCleared: () => setState(() => _query = ''),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        SkifluxSpacing.spaceL,
                        0,
                        SkifluxSpacing.spaceL,
                        SkifluxSpacing.spaceL,
                      ),
                      children: [
                        if (today.isNotEmpty) ...[
                          _sectionLabel('Today'),
                          const SizedBox(height: SkifluxSpacing.spaceS),
                          ..._rows(today),
                        ],
                        if (yesterday.isNotEmpty) ...[
                          _sectionLabel('Yesterday'),
                          const SizedBox(height: SkifluxSpacing.spaceS),
                          ..._rows(yesterday),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(List<_HistoryEntry> entries) {
    return [
      for (final entry in entries) ...[
        LibraryEpisodeRow(
          episode: entry.episode,
          statusLine: entry.statusLine,
          trailing: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openRowMenu(entry),
            icon: const Icon(
              RemixIcons.more_2_fill,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentTertiary,
            ),
          ),
          onTap: () => showEpisodePlayerModal(context, entry.episode),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
      ],
    ];
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceXs),
      child: Text(
        label,
        style: SkifluxTypography.uiButtonMedium.copyWith(
          color: SkifluxColors.contentTertiary,
        ),
      ),
    );
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
              RemixIcons.history_fill,
              size: 48,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Text(
            'No watch history',
            style: SkifluxTypography.headingH7Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'Episodes you watch will show up here.',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRowMenu(_HistoryEntry entry) async {
    final action = await showWatchHistoryMenuSheet(context);
    if (!mounted || action == null) return;
    switch (action) {
      case WatchHistoryMenuAction.remove:
        setState(() => _entries!.remove(entry));
        SkifluxToast.info(context, 'Removed from watch history');
      case WatchHistoryMenuAction.download:
        SkifluxToast.info(context, 'Episode queued for download');
      case WatchHistoryMenuAction.save:
        SkifluxToast.success(context, 'Saved to your videos');
      case WatchHistoryMenuAction.share:
        await showShareSheet(context);
    }
  }
}

/// Row actions from the Watch History More Menu (`1256:24327`).
enum WatchHistoryMenuAction { remove, download, save, share }

Future<WatchHistoryMenuAction?> showWatchHistoryMenuSheet(
  BuildContext context,
) {
  return showSkifluxSheet<WatchHistoryMenuAction>(
    context: context,
    builder: (_) => const _WatchHistoryMenuSheet(),
  );
}

class _WatchHistoryMenuSheet extends StatelessWidget {
  const _WatchHistoryMenuSheet();

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'More Menu',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          _row(
            context,
            icon: RemixIcons.delete_bin_fill,
            label: 'Remove from watch history',
            action: WatchHistoryMenuAction.remove,
          ),
          _row(
            context,
            icon: RemixIcons.download_fill,
            label: 'Downloads',
            action: WatchHistoryMenuAction.download,
          ),
          _row(
            context,
            icon: RemixIcons.bookmark_fill,
            label: 'Save Video',
            action: WatchHistoryMenuAction.save,
          ),
          _row(
            context,
            icon: RemixIcons.share_forward_fill,
            label: 'Share Video',
            action: WatchHistoryMenuAction.share,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required WatchHistoryMenuAction action,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(action),
      child: SizedBox(
        height: SkifluxUnit.u48,
        child: Row(
          children: [
            Icon(
              icon,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentPrimary,
            ),
            const SizedBox(width: SkifluxSpacing.spaceL),
            Expanded(
              child: Text(
                label,
                style: SkifluxTypography.uiButtonLarge.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
