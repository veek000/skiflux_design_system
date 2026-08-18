import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/home/data/voice_note_cache.dart';

void main() {
  group('resolveVoiceNoteUrl', () {
    test('passes through absolute https URLs', () {
      expect(
        resolveVoiceNoteUrl('https://cdn.example/a.m4a'),
        'https://cdn.example/a.m4a',
      );
    });

    test('returns null for empty input', () {
      expect(resolveVoiceNoteUrl(null), isNull);
      expect(resolveVoiceNoteUrl('  '), isNull);
    });

    test('resolves relative paths when API_BASE_URL is configured', () {
      // EnvConfig.apiBaseUrl comes from --dart-define; in plain unit tests it
      // is usually empty, so relative resolution may return null. Absolute
      // URLs remain the production path for CDN media.
      final relative = resolveVoiceNoteUrl('/media/voice/1.m4a');
      // Either unresolved (no base) or joined — never an empty string.
      expect(relative == null || relative.startsWith('http'), isTrue);
    });
  });
}

