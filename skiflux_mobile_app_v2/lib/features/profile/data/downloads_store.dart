import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_episode.dart';

/// Store for managing offline downloaded episodes.
class DownloadsNotifier extends Notifier<List<LibraryEpisode>> {
  @override
  List<LibraryEpisode> build() => [];

  void addDownload(LibraryEpisode episode) {
    if (!state.any((e) => e.id == episode.id)) {
      state = [...state, episode];
    }
  }

  void removeDownload(String episodeId) {
    state = state.where((e) => e.id != episodeId).toList();
  }

  void clearAll() {
    state = [];
  }
}

final downloadsProvider = NotifierProvider<DownloadsNotifier, List<LibraryEpisode>>(
  DownloadsNotifier.new,
);
