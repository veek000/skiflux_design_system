import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/toast/skiflux_toast.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'library_episode_row.dart';

// Figma: **Profile Flow 12** (`1256:24572`) — Saved Videos. Search field +
// saved rows ("Saved 2 days ago") with a filled brand bookmark trailing;
// tapping the bookmark un-saves (removes) the row.

class SavedVideosScreen extends ConsumerStatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  ConsumerState<SavedVideosScreen> createState() =>
      _SavedVideosScreenState();
}

class _SavedVideosScreenState extends ConsumerState<SavedVideosScreen> {
  String _query = '';

  /// Session-local demo saved set (no app-wide save model yet).
  List<SubscriptionEpisode>? _saved;

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider);
    _saved ??= subs.feed().take(5).toList();
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _saved!
        : _saved!
            .where((e) => e.title.toLowerCase().contains(query))
            .toList();

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
                        statusLine: 'Saved 2 days ago',
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() => _saved!.remove(visible[i]));
                            SkifluxToast.info(
                              context,
                              'Removed from saved videos',
                            );
                          },
                          icon: const Icon(
                            RemixIcons.bookmark_fill,
                            size: SkifluxIcons.sizeM,
                            color: SkifluxColors.contentBrand,
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
              RemixIcons.bookmark_fill,
              size: 48,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Text(
            'No saved videos',
            style: SkifluxTypography.headingH7Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'Videos you save will show up here.',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
