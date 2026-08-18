import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/home/data/episode_resource.dart';

void main() {
  // `Episode.resources` is inline on the viewer payload and was never parsed,
  // so the More Menu offered an "Episode Resources" card on every episode and
  // it opened four hardcoded filenames.
  group('parseEpisodeResources', () {
    Map<String, dynamic> file({
      String id = 'r1',
      String? name = 'brief.pdf',
      String? url = 'https://cdn.example.com/files/brief.pdf',
      String? type = 'pdf',
      int? size = 890 * 1000,
      int order = 0,
    }) => {
      'id': id,
      'resource_type': 'file',
      'is_file': true,
      'is_link': false,
      'file_name': name,
      'file_url': url,
      'file_type': type,
      'file_size': size,
      'order': order,
    };

    test('an absent or empty array yields nothing', () {
      expect(parseEpisodeResources(null), isEmpty);
      expect(parseEpisodeResources(const []), isEmpty);
      // A non-list (a bad payload) must not throw.
      expect(parseEpisodeResources('nope'), isEmpty);
    });

    test('parses a file resource with its real name, type and size', () {
      final parsed = parseEpisodeResources([file()]);
      expect(parsed, hasLength(1));
      expect(parsed.single.displayName, 'brief.pdf');
      expect(parsed.single.metaLabel, 'PDF · 890 KB');
      expect(parsed.single.isLink, isFalse);
      expect(parsed.single.url, 'https://cdn.example.com/files/brief.pdf');
    });

    test('parses a link resource and shows its host', () {
      final parsed = parseEpisodeResources([
        {
          'id': 'r2',
          'resource_type': 'link',
          'is_file': false,
          'is_link': true,
          'link_label': 'Figma community file',
          'link_url': 'https://figma.com/community/file/123',
        },
      ]);
      expect(parsed.single.isLink, isTrue);
      expect(parsed.single.displayName, 'Figma community file');
      expect(parsed.single.metaLabel, 'figma.com');
    });

    test('drops rows with no usable URL', () {
      // A row that cannot be opened is a dead row; better absent than present
      // and inert — which is what the whole sheet used to be.
      final parsed = parseEpisodeResources([
        file(id: 'ok'),
        file(id: 'nourl', url: null),
        file(id: 'blank', url: ''),
      ]);
      expect(parsed.map((r) => r.id), ['ok']);
    });

    test('respects the server display order', () {
      final parsed = parseEpisodeResources([
        file(id: 'third', order: 3),
        file(id: 'first', order: 1),
        file(id: 'second', order: 2),
      ]);
      expect(parsed.map((r) => r.id), ['first', 'second', 'third']);
    });

    test('falls back to the URL filename when no name was sent', () {
      final parsed = parseEpisodeResources([
        file(name: null, url: 'https://cdn.example.com/a/kit.zip', type: null),
      ]);
      expect(parsed.single.displayName, 'kit.zip');
      // The size is still known, so it is still shown — only the missing type
      // drops out of the label.
      expect(parsed.single.metaLabel, '890 KB');
    });

    test('a file with neither type nor size gets the generic label', () {
      final parsed = parseEpisodeResources([file(type: null, size: null)]);
      expect(parsed.single.metaLabel, 'File');
    });

    test('infers the kind when is_file/is_link are missing', () {
      // The booleans are readOnly and may not be echoed by every serializer;
      // whichever URL arrived is then the deciding evidence.
      final parsed = parseEpisodeResources([
        {
          'id': 'r3',
          'link_url': 'https://example.com/read-me',
        },
      ]);
      expect(parsed.single.isLink, isTrue);
    });

    test('omits the size when the payload carried none', () {
      final parsed = parseEpisodeResources([file(size: null)]);
      // "PDF", not "PDF · 0 B" — an unknown size prints nothing.
      expect(parsed.single.metaLabel, 'PDF');
    });
  });
}

