import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/playlist_deck.dart';
import 'data/recent_searches_store.dart';
import 'data/search_index.dart';

/// Result + recent-row widgets shared by the search screens.
/// Figma: Search Flow section `294:6905` (flows 01–08).

/// Small brand chip used on thumbnails ("20:00", "EP 01", menu-fold "20").
/// Figma tags these "Outfit SemiBold 10" — an authoring slip; DM Sans is the
/// project body face (same call as the ComposeBar audit).
class _ThumbChip extends StatelessWidget {
  const _ThumbChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.brand100,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        label,
        style: SkifluxTypography.bodyP11Semibold.copyWith(
          color: SkifluxColors.brand500,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Figma `304:9537` — episode result row: 128×98 magenta thumb with a
/// duration chip, then EP tag + title + views.
class EpisodeResultCard extends StatelessWidget {
  const EpisodeResultCard({super.key, required this.episode, this.onTap});

  final EpisodeResult episode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 98,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail placeholder (demo data has no artwork).
            // TODO(backend, minor): replace brand-colored placeholder thumbnails with real episode/playlist cover artwork URLs from backend — expects: String (network URL)
            Container(
              width: 128,
              decoration: BoxDecoration(
                color: SkifluxColors.magenta900,
                borderRadius: SkifluxRadii.borderL,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: SkifluxSpacing.spaceM,
                    bottom: SkifluxSpacing.spaceM,
                    child: _ThumbChip(label: episode.duration),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ThumbChip(label: episode.epTag),
                        const SizedBox(height: SkifluxSpacing.spaceXs),
                        Text(
                          episode.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SkifluxTypography.headingH10Bold.copyWith(
                            color: SkifluxColors.contentPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      episode.views,
                      style: SkifluxTypography.bodyP11Regular.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `304:9568` — creator/user row: 40px avatar, name + handle, trailing
/// primary pill ("Follow" for creators, "View Profile" for users).
class PersonResultRow extends StatelessWidget {
  const PersonResultRow({
    super.key,
    required this.person,
    required this.actionLabel,
    this.onAction,
    this.onTap,
  });

  final PersonResult person;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
            decoration: const BoxDecoration(
              color: SkifluxColors.backgroundSelected,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              RemixIcons.user_fill,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  person.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          SkifluxButton(
            label: actionLabel,
            size: SkifluxButtonSize.s,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

/// Figma `304:9582` — playlist result row: stacked-card thumbnail (magenta200
/// back card peeking behind a magenta900 front card with an episode-count
/// chip), then title + "creator · N episodes".
class PlaylistResultCard extends StatelessWidget {
  /// [onTap] optional — when null, card still renders (parent may pass a
  /// navigator callback).
  const PlaylistResultCard({super.key, required this.playlist, this.onTap});

  final PlaylistResult playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 98,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stacked deck thumbnail — shared geometry (Figma 304:9583).
            PlaylistDeck(
              width: 126,
              height: 98,
              episodeCount: playlist.episodeCount,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    Text(
                      playlist.subtitle,
                      style: SkifluxTypography.bodyP11Regular.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `304:9438` — recent-search row: clock avatar, query + result
/// subtitle, trailing remove button.
class RecentSearchRow extends StatelessWidget {
  const RecentSearchRow({
    super.key,
    required this.entry,
    this.onTap,
    this.onRemove,
  });

  final RecentSearch entry;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
            decoration: const BoxDecoration(
              color: SkifluxColors.backgroundHover,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              RemixIcons.time_fill,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  entry.subtitle,
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
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(
              RemixIcons.close_fill,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `304:9532` — overview section header: tertiary heading + brand
/// "See all" trailing link. Also used for the "Recent" header ("Clear all").
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    this.onAction,
    this.titleStyle,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                titleStyle ??
                SkifluxTypography.headingH10Bold.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
          ),
        ),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: SkifluxUnit.u24,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceXs,
                ),
                child: Text(
                  actionLabel,
                  style: SkifluxTypography.uiButtonMedium.copyWith(
                    color: SkifluxColors.contentBrand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
