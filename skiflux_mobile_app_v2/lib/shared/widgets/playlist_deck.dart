import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Stacked playlist "deck" thumbnail — magenta200 back card peeking above a
/// magenta900 front card with an episode-count chip.
///
/// Figma sources (same construction at two sizes):
/// - Search playlist row `304:9583` (126×98, back card 90.25% wide)
/// - Playlist detail cover `198:14189` (361×150, back card 93.36% wide)
///
/// Geometry is fractional so both variants share one widget: back card is
/// horizontally centered at [backWidthFactor] × width and 87% of the height;
/// the front card is full-width, 96.3% of the height, bottom-anchored
/// (leaving the Figma ~3.7% top offset where the back card peeks out).
class PlaylistDeck extends StatelessWidget {
  const PlaylistDeck({
    super.key,
    this.width,
    required this.height,
    required this.episodeCount,
    this.backWidthFactor = 0.9025,
  });

  final double? width;
  final double height;
  final int episodeCount;

  /// 0.9025 for the search-row size (`304:9583`), 0.9336 for the full-width
  /// playlist-detail cover (`198:14190`).
  final double backWidthFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Back card — Figma radius 14.44 (non-token value from the file).
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              widthFactor: backWidthFactor,
              heightFactor: 0.87,
              child: Container(
                decoration: BoxDecoration(
                  color: SkifluxColors.magenta200,
                  borderRadius: BorderRadius.circular(14.44),
                ),
              ),
            ),
          ),
          // Front card with the episode-count chip bottom-right.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.963,
              child: Container(
                decoration: BoxDecoration(
                  color: SkifluxColors.magenta900,
                  borderRadius: SkifluxRadii.borderL,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SkifluxSpacing.spaceS,
                        vertical: SkifluxSpacing.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: SkifluxColors.backgroundPrimaryBrand,
                        borderRadius: SkifluxRadii.borderX,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            RemixIcons.menu_fold_line,
                            size: 12,
                            color: SkifluxColors.contentBrand,
                          ),
                          const SizedBox(width: SkifluxSpacing.spaceXs),
                          Text(
                            '$episodeCount',
                            style: SkifluxTypography.bodyP11Semibold.copyWith(
                              color: SkifluxColors.contentBrand,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
