import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';

// Figma: **Profile Flow 04** (`1256:25294`) — Liked Videos. Search field over
// a list of liked-episode rows: 98px thumbnail (EP + duration pills), 2-line
// title, creator avatar + name, views, red filled heart trailing. Tapping the
// heart un-likes (removes) the row; tapping the row opens the episode player.

class LikedVideosScreen extends ConsumerStatefulWidget {
  const LikedVideosScreen({super.key});

  @override
  ConsumerState<LikedVideosScreen> createState() => _LikedVideosScreenState();
}

class _LikedVideosScreenState extends ConsumerState<LikedVideosScreen> {
  String _query = '';

  /// Session-local demo "liked" set: first five feed episodes; un-liking
  /// removes locally (no store — likes aren't modeled app-wide yet).
  // TODO(backend, blocking): replace session-local liked list with real per-user liked videos fetched from backend — expects: List<{epNumber: int, title: String, creatorUsername: String, duration: String, views: String, postedAgo: String, isNew: bool, postedToday: bool, watchProgress: double}>
  List<SubscriptionEpisode>? _liked;

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider);
    _liked ??= subs.feed().take(5).toList();
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _liked!
        : _liked!
            .where((e) => e.title.toLowerCase().contains(query))
            .toList();

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
                      itemBuilder: (_, i) => _LikedRow(
                        episode: visible[i],
                        onOpen: () =>
                            showEpisodePlayerModal(context, visible[i]),
                        onUnlike: () => setState(
                          () => _liked!.remove(visible[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when there are no liked videos (or none match the search).
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
              RemixIcons.heart_3_fill,
              size: 48,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Text(
            'No liked videos',
            style: SkifluxTypography.headingH7Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'Videos you like will show up here.',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One liked-episode row (`1256:25302`): thumbnail + title/creator/views +
/// red heart.
class _LikedRow extends ConsumerWidget {
  const _LikedRow({
    required this.episode,
    required this.onOpen,
    required this.onUnlike,
  });

  final SubscriptionEpisode episode;
  final VoidCallback onOpen;
  final VoidCallback onUnlike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(subscriptionsProvider).creatorOf(episode);
    return InkWell(
      onTap: onOpen,
      borderRadius: SkifluxRadii.borderL,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(),
          const SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Row(
                  children: [
                    SkifluxAvatar(
                      style: SkifluxAvatarStyle.initial,
                      size: SkifluxSpacing.spaceL,
                      initials: creator.initials,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Flexible(
                      child: Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SkifluxTypography.bodyP11Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  '${episode.views} views',
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: onUnlike,
            icon: const Icon(
              RemixIcons.heart_3_fill,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentNegative,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // TODO(backend, blocking): replace local placeholder asset with real CDN/backend episode thumbnail URL — expects: String (network URL)
            Image.asset(
              'assets/home_video_cover.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: SkifluxColors.magenta900),
            ),
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: _pill(
                episode.epTag,
                background: SkifluxColors.contentBrand,
              ),
            ),
            Positioned(
              bottom: SkifluxSpacing.spaceS,
              right: SkifluxSpacing.spaceS,
              child: _pill(
                episode.duration,
                background: SkifluxColors.overlay50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, {required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.space2xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        label,
        style: SkifluxTypography.bodyP11Semibold.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
      ),
    );
  }
}
