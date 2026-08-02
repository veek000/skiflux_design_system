/// A file or link attached to an episode — the More Menu's "Episode
/// Resources" sheet.
///
/// Parsed from `Episode.resources`, which the viewer-facing payload carries
/// inline (`SkiFlux_API.yaml:9518`). There is a `GET
/// /episodes/{id}/resources/` too, but it sits under **Studio** with
/// `adminBearerAuth` and returns resources "owned by the creator" — it is the
/// authoring endpoint, not a viewer one, so the inline array is the right
/// source here.
///
/// The sheet used to render four hardcoded rows — `design_tokens.fig`,
/// `component_kit.zip`, `episode_notes.pdf`, `color_styles.xlsx` — on every
/// episode in the app, downloadable by nobody.
library;

import 'package:flutter/widgets.dart' show IconData;
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// `ResourceTypeEnum`: a resource is either an uploaded file or an outbound
/// link, and the two behave differently — one downloads, one opens.
enum EpisodeResourceKind { file, link }

class EpisodeResource {
  const EpisodeResource({
    required this.id,
    required this.kind,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.linkLabel,
    this.linkUrl,
    this.order = 0,
  });

  /// Spec `EpisodeResource`.
  static EpisodeResource? fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    if (id == null) return null;

    // `is_file` / `is_link` are readOnly booleans the server derives; prefer
    // them over `resource_type` when present, and fall back to whichever URL
    // actually arrived.
    final EpisodeResourceKind kind;
    if (json['is_link'] == true) {
      kind = EpisodeResourceKind.link;
    } else if (json['is_file'] == true) {
      kind = EpisodeResourceKind.file;
    } else if (_string(json['resource_type']) == 'link') {
      kind = EpisodeResourceKind.link;
    } else if (_string(json['link_url']) != null) {
      kind = EpisodeResourceKind.link;
    } else {
      kind = EpisodeResourceKind.file;
    }

    return EpisodeResource(
      id: id,
      kind: kind,
      fileName: _string(json['file_name']),
      fileUrl: _string(json['file_url']),
      fileType: _string(json['file_type']),
      fileSize: json['file_size'] is int ? json['file_size'] as int : null,
      linkLabel: _string(json['link_label']),
      linkUrl: _string(json['link_url']),
      order: json['order'] is int ? json['order'] as int : 0,
    );
  }

  final String id;
  final EpisodeResourceKind kind;

  final String? fileName;
  final String? fileUrl;

  /// `FileTypeEnum` wire value: pdf / figma / zip / image / doc / xlsx / csv /
  /// other. Nullable and may be blank — the spec allows `BlankEnum`.
  final String? fileType;

  /// Size in bytes.
  final int? fileSize;

  final String? linkLabel;
  final String? linkUrl;

  final int order;

  bool get isLink => kind == EpisodeResourceKind.link;

  /// Whether this row has somewhere to go. A resource with neither URL is not
  /// actionable and is filtered out rather than rendered as a dead row.
  bool get isUsable => (isLink ? linkUrl : fileUrl)?.isNotEmpty ?? false;

  /// The URL to open or download.
  String? get url => isLink ? linkUrl : fileUrl;

  /// What the row is called. Falls back through the fields the payload might
  /// actually have filled, and finally to the URL's own last path segment —
  /// anything rather than a blank row.
  String get displayName {
    for (final candidate in [linkLabel, fileName]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    final path = Uri.tryParse(url ?? '')?.pathSegments;
    if (path != null && path.isNotEmpty && path.last.isNotEmpty) {
      return path.last;
    }
    return isLink ? 'External link' : 'Attachment';
  }

  /// "PDF · 890 KB", "Link", or just the type when no size was sent. Built only
  /// from what the payload carried — an absent size prints nothing rather than
  /// a guess.
  String get metaLabel {
    if (isLink) {
      final host = Uri.tryParse(linkUrl ?? '')?.host;
      return (host != null && host.isNotEmpty) ? host : 'External link';
    }
    final parts = <String>[
      if (fileType != null && fileType!.isNotEmpty) fileType!.toUpperCase(),
      if (fileSize != null && fileSize! > 0) _size(fileSize!),
    ];
    return parts.isEmpty ? 'File' : parts.join(' · ');
  }

  /// Glyph per `FileTypeEnum`, with a link arrow for the link kind.
  IconData get icon {
    if (isLink) return RemixIcons.external_link_line;
    return switch (fileType) {
      'pdf' => RemixIcons.file_pdf_fill,
      'figma' => RemixIcons.file_3_fill,
      'zip' => RemixIcons.file_zip_fill,
      'image' => RemixIcons.image_fill,
      'doc' => RemixIcons.file_word_fill,
      'xlsx' || 'csv' => RemixIcons.file_excel_fill,
      _ => RemixIcons.file_3_fill,
    };
  }

  static String _size(int bytes) {
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000 * 1000) return '${(bytes / 1000).round()} KB';
    if (bytes < 1000 * 1000 * 1000) {
      return '${(bytes / (1000 * 1000)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1000 * 1000 * 1000)).toStringAsFixed(1)} GB';
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Parse `Episode.resources`, keeping only rows that can actually be opened,
/// in the server's display order.
List<EpisodeResource> parseEpisodeResources(Object? raw) {
  if (raw is! List) return const [];
  final parsed = <EpisodeResource>[
    for (final entry in raw)
      if (entry is Map)
        ?EpisodeResource.fromJson(Map<String, dynamic>.from(entry)),
  ].where((r) => r.isUsable).toList()..sort((a, b) => a.order.compareTo(b.order));
  return List.unmodifiable(parsed);
}
