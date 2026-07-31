/// Opens an external URL (payment checkout pages, mission links, store pages).
///
/// Backed by `url_launcher` (approved 2026-07-31) in external-application mode
/// so checkout pages open in the user's real browser — a payment gateway
/// inside a WebView would hide the address bar trust signals.
///
/// If the platform refuses to launch (no browser, restricted profile), the
/// original clipboard shim is the fallback: the link is copied and the user is
/// told to open it themselves, so external hand-offs never dead-end.
///
/// Call sites should treat a `true` return as "the hand-off was presented",
/// not "a browser is now open".
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../toast/skiflux_toast.dart';

Future<bool> openExternalUrl(BuildContext context, Uri url) async {
  try {
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return true;
  } on PlatformException {
    // Fall through to the clipboard fallback.
  }
  await Clipboard.setData(ClipboardData(text: url.toString()));
  if (context.mounted) {
    SkifluxToast.info(
      context,
      'Link copied — paste it in your browser to continue',
    );
  }
  return true;
}
