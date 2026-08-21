// /// The episode player the library screens open — Liked, Saved, Watch History.
// ///
// /// Same shell as the subscriptions player modal (`1256:29748`), but it takes a
// /// [LibraryEpisode] straight from the API, so it plays the episode's real
// /// `video_url` rather than resolving a creator out of a local store.
// library;
//
// import 'package:flutter/material.dart';
// import 'package:skiflux_design_system/skiflux_design_system.dart';
//
// import '../../shared/sheets/skiflux_sheet.dart';
// import '../../shared/widgets/video_feed_card.dart';
// import 'data/library_episode.dart';
//
// Future<void> showLibraryEpisodePlayer(
//   BuildContext context,
//   LibraryEpisode episode,
// ) {
//   return showSkifluxSheet<void>(
//     context: context,
//     builder: (_) => _LibraryEpisodePlayerSheet(episode: episode),
//   );
// }
//
// class _LibraryEpisodePlayerSheet extends StatelessWidget {
//   const _LibraryEpisodePlayerSheet({required this.episode});
//
//   final LibraryEpisode episode;
//
//   @override
//   Widget build(BuildContext context) {
//     final media = MediaQuery.of(context);
//     return Material(
//       color: SkifluxColors.backgroundPrimary,
//       borderRadius: const BorderRadius.vertical(
//         top: Radius.circular(SkifluxRadii.x),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: SizedBox(
//         height: media.size.height - media.padding.top - SkifluxUnit.u48,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(
//                 SkifluxSpacing.spaceL,
//                 SkifluxSpacing.spaceL,
//                 SkifluxSpacing.spaceL,
//                 SkifluxSpacing.spaceS,
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           episode.title,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: SkifluxTypography.headingH9Bold.copyWith(
//                             color: SkifluxColors.contentPrimary,
//                           ),
//                         ),
//                         const SizedBox(height: SkifluxSpacing.space2xs),
//                         Text(
//                           episode.creatorName,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: SkifluxTypography.bodyP10Regular.copyWith(
//                             color: SkifluxColors.contentTertiary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SkifluxSheetCloseButton(),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(
//                   SkifluxSpacing.spaceL,
//                   0,
//                   SkifluxSpacing.spaceL,
//                   SkifluxSpacing.spaceL + media.padding.bottom,
//                 ),
//                 child: VideoFeedCard(
//                   pauseWhenRouteCovered: false,
//                   item: episode.toFeedItem(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


/// The episode player the library screens open — Liked, Saved, Watch History.
///
/// Same shell as the subscriptions player modal (`1256:29748`), but it takes a
/// [LibraryEpisode] straight from the API, so it plays the episode's real
/// `video_url`.
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/widgets/video_feed_card.dart';
import 'data/library_episode.dart';

Future<void> showLibraryEpisodePlayer(
    BuildContext context,
    LibraryEpisode episode,
    ) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => _LibraryEpisodePlayerSheet(episode: episode),
  );
}

class _LibraryEpisodePlayerSheet extends StatelessWidget {
  const _LibraryEpisodePlayerSheet({
    required this.episode,
  });

  final LibraryEpisode episode;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SkifluxRadii.x),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: media.size.height -
            media.padding.top -
            SkifluxUnit.u48,
        child: Column(
          children: [
            _LibraryEpisodePlayerHeader(
              episode: episode,
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  0,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL +
                      media.padding.bottom,
                ),
                child: VideoFeedCard(
                  pauseWhenRouteCovered: false,
                  item: episode.toFeedItem(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same header treatment as the subscriptions episode player:
/// title on the left and close circle on the right.
class _LibraryEpisodePlayerHeader extends StatelessWidget {
  const _LibraryEpisodePlayerHeader({
    required this.episode,
  });

  final LibraryEpisode episode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),

                const SizedBox(
                  height: SkifluxSpacing.space2xs,
                ),

                Text(
                  episode.creatorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: SkifluxSpacing.spaceL,
          ),

          const SkifluxSheetCloseButton(),
        ],
      ),
    );
  }
}