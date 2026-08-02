/// What a share actually carries.
///
/// The share sheet used to be a custom row of eight branded circles, every one
/// of which closed the sheet and did nothing else. It now hands off to the OS
/// sheet — which means the app has to decide what text goes with it, and in
/// particular whether a media URL is safe to hand another app.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/sheets/share_sheet.dart';

void main() {
  group('shareableMediaUrl', () {
    test('passes through a clean CDN URL', () {
      expect(
        shareableMediaUrl('https://cdn.skiflux.com/ep/123.mp4'),
        'https://cdn.skiflux.com/ep/123.mp4',
      );
    });

    test('withholds a pre-signed URL', () {
      // The query string *is* the credential and it expires. Sharing one puts
      // a short-lived access token in someone's chat history and hands them a
      // link that is already dead by the time they open it.
      expect(
        shareableMediaUrl(
          'https://s3.amazonaws.com/skiflux/ep/123.mp4'
          '?X-Amz-Signature=abc123&X-Amz-Expires=900',
        ),
        isNull,
      );
    });

    test('withholds a URL carrying credentials in its authority', () {
      expect(
        shareableMediaUrl('https://user:secret@cdn.skiflux.com/ep/123.mp4'),
        isNull,
      );
    });

    test('null, blank and unparseable inputs yield null', () {
      expect(shareableMediaUrl(null), isNull);
      expect(shareableMediaUrl(''), isNull);
      expect(shareableMediaUrl('   '), isNull);
      // No scheme — a bare path is not something another app can open.
      expect(shareableMediaUrl('/ep/123.mp4'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(
        shareableMediaUrl('  https://cdn.skiflux.com/a.mp4  '),
        'https://cdn.skiflux.com/a.mp4',
      );
    });
  });
}
