/// "Download this episode", from wherever it is offered.
///
/// There are three entry points — the feed's More Menu, the Watch History row
/// menu, and the same row menu on the profile tab — and until now only the
/// first ran a real download. The other two posted "Episode queued for
/// download" and did nothing at all: a toast describing a queue that did not
/// exist, over a pipeline that had been built and wired to one caller.
///
/// Shared so the three cannot drift again, and so the tray notification, the
/// Wi-Fi-only check and the error copy are the same wherever the user taps.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/toast/skiflux_toast.dart';
import 'downloads_store.dart';
import 'library_episode.dart';

/// Start downloading [episode], reporting progress through the toast, the
/// Downloads screen and the system tray.
///
/// Returns true when the file finished. Every failure path — no video URL, the
/// Wi-Fi-only preference, a dropped transfer — surfaces through
/// [ErrorDisplay] with its own copy rather than a generic message.
Future<bool> downloadEpisode(
  BuildContext context,
  WidgetRef ref,
  LibraryEpisode? episode,
) async {
  if (episode == null) {
    SkifluxToast.error(context, "This episode can't be downloaded yet");
    return false;
  }
  final downloads = ref.read(downloadsProvider.notifier);
  if (downloads.isDownloaded(episode.id)) {
    SkifluxToast.info(context, 'Already downloaded');
    return false;
  }
  // Nothing to fetch. Said before the transfer starts rather than after it
  // fails, because "this one has no file" is not the same as "it broke".
  if (episode.videoUrl == null || episode.videoUrl!.isEmpty) {
    SkifluxToast.error(context, "This episode has no video to download");
    return false;
  }

  SkifluxToast.info(context, 'Downloading ${episode.title}…');
  try {
    await downloads.download(episode);
    if (!context.mounted) return true;
    SkifluxToast.success(context, 'Downloaded ${episode.title}');
    return true;
  } catch (error, stackTrace) {
    if (!context.mounted) return false;
    // Covers the Wi-Fi-only block as well as a genuine transfer failure; each
    // has its own entry in the error table.
    await ErrorDisplay.show(context, ref, error, stackTrace: stackTrace);
    return false;
  }
}
