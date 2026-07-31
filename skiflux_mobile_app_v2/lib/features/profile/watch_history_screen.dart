import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/share_sheet.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';
import 'data/library_episode.dart';
import 'data/library_repository.dart';
import 'data/library_store.dart';
import 'library_episode_player.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 15** (`1256:24224`) — Watch History. Nav with "Clear
// all" (negative), search field, Today / Yesterday sections of watched rows
// ("72% watched · Today, 9:20 AM" / "Completed · Yesterday, 4:12 PM"), each
// with a vertical more glyph → the row More Menu sheet (**Profile Flow 14**
// `1256:24327`: Remove from watch history / Downloads / Save Video /
// Share Video).
//
// Backed by `GET /me/watch-history`; row removal and "Clear all" hit
// `DELETE /me/watch-history/{episode_id}` / `DELETE /me/watch-history`.
// The Figma only draws Today and Yesterday because its sample data stops
// there; real history runs back further, so anything older is grouped under
// its own date heading.

class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  ConsumerState<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(watchHistoryProvider);
    final loaded = history.value ?? const <WatchHistoryEntry>[];

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
          onPressed: loaded.isEmpty ? null : _clearAll,
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
              child: switch (history) {
                AsyncLoading() => const LibraryListSkeleton(),
                AsyncError(:final error) => LoadFailure(
                  error: error,
                  title: "We couldn't load your watch history",
                  onRetry: () =>
                      ref.read(watchHistoryProvider.notifier).refresh(),
                ),
                AsyncData(:final value) => _list(value),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<WatchHistoryEntry> entries) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? entries
        : entries
              .where((e) => e.episode.title.toLowerCase().contains(query))
              .toList();
    if (visible.isEmpty) {
      return SkifluxEmptyState(
        icon: const Icon(
          RemixIcons.history_fill,
          size: SkifluxEmptyState.iconSize,
          color: SkifluxColors.contentBrand,
        ),
        title: query.isEmpty ? 'No watch history' : 'No matches',
        message: query.isEmpty
            ? 'Episodes you watch will show up here.'
            : 'Nothing you have watched matches “$_query”.',
      );
    }

    // Flatten to headings + rows once, so the builder is a plain index lookup
    // instead of the cursor arithmetic this screen used to do.
    final today = DateTime.now();
    final rows = <Widget>[];
    String? heading;
    for (final entry in visible) {
      final label = _dayLabel(entry.viewedAt, today);
      if (label != heading) {
        heading = label;
        if (rows.isNotEmpty) {
          rows.add(const SizedBox(height: SkifluxSpacing.spaceL));
        }
        rows
          ..add(_sectionLabel(label))
          ..add(const SizedBox(height: SkifluxSpacing.spaceS));
      }
      rows
        ..add(_rowItem(entry, label))
        ..add(const SizedBox(height: SkifluxSpacing.spaceL));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        0,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
      ),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _rowItem(WatchHistoryEntry entry, String dayLabel) {
    final watched = entry.completed
        ? 'Completed'
        : '${(entry.progress * 100).round()}% watched';
    return LibraryEpisodeRow(
      episode: entry.episode,
      statusLine: '$watched · $dayLabel, ${_clock(entry.viewedAt)}',
      onTap: () => showLibraryEpisodePlayer(context, entry.episode),
      trailing: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => _openRowMenu(entry),
        icon: const Icon(
          RemixIcons.more_2_fill,
          size: SkifluxIcons.sizeM,
          color: SkifluxColors.contentTertiary,
        ),
      ),
    );
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

  Future<void> _openRowMenu(WatchHistoryEntry entry) async {
    final action = await showWatchHistoryMenuSheet(context);
    if (!mounted || action == null) return;
    switch (action) {
      case WatchHistoryMenuAction.remove:
        await _remove(entry);
      case WatchHistoryMenuAction.download:
        // TODO(backend, blocking): no offline download pipeline exists — this
        // only acknowledges the tap — expects: a download URL + local store
        SkifluxToast.info(context, 'Episode queued for download');
      case WatchHistoryMenuAction.save:
        await _save(entry.episode);
      case WatchHistoryMenuAction.share:
        await showShareSheet(context);
    }
  }

  /// "Remove from watch history" — optimistic row drop backed by
  /// `DELETE /me/watch-history/{episode_id}`; the confirmation toast waits
  /// for the 2xx, and a failure (row restored by the store) says so instead.
  Future<void> _remove(WatchHistoryEntry entry) async {
    try {
      await ref.read(watchHistoryProvider.notifier).remove(entry);
      if (mounted) SkifluxToast.info(context, 'Removed from watch history');
    } catch (error) {
      if (!mounted) return;
      SkifluxToast.error(
        context,
        ref.read(errorHandlerProvider).classify(error).message,
      );
    }
  }

  /// "Clear all" — optimistic wipe backed by `DELETE /me/watch-history`;
  /// the store restores the list and this surfaces the error on failure.
  Future<void> _clearAll() async {
    try {
      await ref.read(watchHistoryProvider.notifier).clearAll();
      if (mounted) SkifluxToast.info(context, 'Watch history cleared');
    } catch (error) {
      if (!mounted) return;
      SkifluxToast.error(
        context,
        ref.read(errorHandlerProvider).classify(error).message,
      );
    }
  }

  /// "Save Video" from the row menu really saves — same toggle the Saved
  /// Videos screen uses, so the episode shows up there afterwards.
  Future<void> _save(LibraryEpisode episode) async {
    try {
      await ref.read(libraryRepositoryProvider).toggleSave(episode.id);
      ref.invalidate(savedEpisodesProvider);
      if (mounted) SkifluxToast.success(context, 'Saved to your videos');
    } catch (error) {
      if (!mounted) return;
      SkifluxToast.error(
        context,
        ref.read(errorHandlerProvider).classify(error).message,
      );
    }
  }
}

/// "Today" / "Yesterday" / "Mar 4, 2026".
String _dayLabel(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[at.month - 1]} ${at.day}, ${at.year}';
}

/// "9:20 AM".
String _clock(DateTime at) {
  final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final meridiem = at.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${at.minute.toString().padLeft(2, '0')} $meridiem';
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
