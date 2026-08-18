import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/profile/data/hls_offline_downloader.dart';

void main() {
  group('isHlsUrl', () {
    test('detects m3u8 paths', () {
      expect(isHlsUrl('https://cdn.example/ep1.m3u8'), isTrue);
      expect(isHlsUrl('https://cdn.example/ep1.m3u8?token=1'), isTrue);
      expect(isHlsUrl('https://cdn.example/ep1.mp4'), isFalse);
      expect(isHlsUrl('https://cdn.example/ep1'), isFalse);
    });
  });
}

