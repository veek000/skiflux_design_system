/// Sharing — the device's own share sheet.
///
/// Figma draws a custom "Share to" row (**Home & In-app Flow 08**,
/// `198:13910`) with eight branded circles: Copy Link, WhatsApp, X, Message,
/// Telegram, Snapchat, Facebook, Instagram. That sheet was rendered here and
/// **every one of those eight buttons did nothing but close it** — no intent,
/// no clipboard, no link. It also promised targets the user may not have
/// installed, in an order that had nothing to do with what they actually use.
///
/// The OS sheet is the honest version of the same feature: it lists the apps
/// that are really on the device, ranks them by real usage, and handles Copy
/// Link itself. `share_plus` was already an approved dependency for exactly
/// this and had no call sites.
//
// TODO(backend, minor): there is no public web URL for an episode, creator or
// playlist, so shares carry the media URL (or nothing but a title) rather than
// a page anyone can open. Expects: a canonical `share_url` / `web_url` on
// Episode, PublicCreatorProfile and SeasonList — tracker #59.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Hand [text] to the platform share sheet.
///
/// [subject] becomes the email subject on the mail fallback and the chooser
/// title on Android. [origin] anchors the popover on iPad — pass the button's
/// own rect when there is one; without it iPadOS anchors to the screen centre.
///
/// Every call site awaits this, so nothing here throws: a device with no share
/// target (or a plugin that is unavailable, as under `flutter test`) is a
/// no-op, not a crash on top of a tap.
Future<void> showShareSheet(
  BuildContext context, {
  String? title,
  String? url,
  String? subject,
}) async {
  final body = _composeBody(title: title, url: url);
  if (body.isEmpty) return;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: body,
        subject: subject ?? title,
        sharePositionOrigin: _originOf(context),
      ),
    );
  } catch (error) {
    debugPrint('Share sheet unavailable: $error');
  }
}

/// Constructs a shareable web / deep link for Skiflux resources.
String buildSkifluxShareUrl(String type, String id) {
  return 'https://app.skiflux.com/$type/$id';
}

/// A media URL that is safe to hand to another app, or null.
///
/// Object-storage links are commonly pre-signed — the query string *is* the
/// credential, and it expires. Sharing one puts a short-lived access token in
/// someone's chat history and hands them a link that is broken by the time
/// they open it. So a URL with a query is treated as private and the share
/// goes out as text alone; a clean path-only URL is passed through.
String? shareableMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return null;
  if (uri.hasQuery || uri.userInfo.isNotEmpty) return null;
  return uri.toString();
}

/// "Episode title\nhttps://…" — whichever halves exist. A share with neither
/// is not sent at all rather than opening an empty chooser.
String _composeBody({String? title, String? url}) {
  final parts = <String>[
    if (title != null && title.trim().isNotEmpty) title.trim(),
    if (url != null && url.trim().isNotEmpty) url.trim(),
  ];
  return parts.join('\n');
}

/// The tapped widget's rect in global coordinates, for the iPad popover.
Rect? _originOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
