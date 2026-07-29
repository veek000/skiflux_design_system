import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/home/data/home_feed_store.dart';

void main() {
  test('the feed is empty until the backend answers', () {
    // There used to be a seven-card sample feed here, playing stock clips
    // under invented creator names. It was indistinguishable from real
    // recommendations, so a signed-out or offline user watched, liked and
    // subscribed against episodes that do not exist.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(homeFeedItemsProvider), isEmpty);
  });

  test('HomeFeedItem only claims a playable video when it has a stream', () {
    const withStream = HomeFeedItem(
      type: FeedContentType.video,
      epTag: 'EP 01',
      title: 'Colour systems',
      description: 'Palettes that survive both themes.',
      coverAsset: '',
      videoUrl: 'https://cdn.skiflux.test/ep01.m3u8',
      creatorName: 'Amara',
      creatorUsername: 'amara',
      creatorInitials: 'A',
    );
    const awaitingStream = HomeFeedItem(
      type: FeedContentType.video,
      epTag: 'EP 02',
      title: 'Motion studies',
      description: 'Easing curves that feel human.',
      coverAsset: '',
      creatorName: 'Lola',
      creatorUsername: 'lola',
      creatorInitials: 'L',
    );

    expect(withStream.hasPlayableVideo, isTrue);
    // A video item whose `video_url` the API omitted must not reach
    // `VideoPlayerController` — that is the crash the seed used to mask.
    expect(awaitingStream.hasPlayableVideo, isFalse);
  });

  group('videoProgressFraction', () {
    test('returns 0 for zero duration', () {
      expect(
        videoProgressFraction(const Duration(seconds: 5), Duration.zero),
        0,
      );
    });

    test('returns position/duration clamped to 0–1', () {
      expect(
        videoProgressFraction(
          const Duration(seconds: 5),
          const Duration(seconds: 10),
        ),
        0.5,
      );
      expect(
        videoProgressFraction(
          const Duration(seconds: 12),
          const Duration(seconds: 10),
        ),
        1.0,
      );
      expect(
        videoProgressFraction(Duration.zero, const Duration(seconds: 10)),
        0,
      );
    });
  });
}
