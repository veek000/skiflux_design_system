/// In-app payment checkout.
///
/// The gateway's hosted page (Paystack, Stripe) is shown in a WebView the app
/// can watch, instead of being handed to the system browser. Two things follow
/// from that:
///
///  * **The payment verifies itself.** The browser hand-off had no way back —
///    the user paid, switched apps, and had to remember to return and tap
///    "I've paid" before anything happened. Here the app sees the gateway
///    reach its redirect URL and pops with [CheckoutOutcome.completed], so the
///    caller can call `verify` immediately.
///  * **Card data never touches our UI.** The page is the gateway's own, on the
///    gateway's origin. This screen only observes navigation; it does not read
///    the form, and there is no PAN/CVV field anywhere in the app.
///
/// A WebView hides the address bar, so the origin is shown in the nav bar
/// subtitle — the user can still see who they are paying before they type a
/// card number. That is the trust signal the browser would have given them.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../sheets/confirm_sheet.dart';

/// How the checkout screen ended.
enum CheckoutOutcome {
  /// The gateway reached its success/redirect URL. The payment still has to be
  /// verified server-side — this only means "stop waiting and go ask".
  completed,

  /// The user backed out, or the page failed to load. Nothing is assumed about
  /// whether money moved; the caller should still let them verify by hand.
  abandoned,
}

/// Opens [checkoutUrl] and resolves once the flow ends.
///
/// Completion is navigation away from the gateway to somewhere that is
/// recognisably ours. Three independent signals, because which one fires
/// depends on whether the backend honoured the `redirect_url` we sent:
///
///  * [redirectUrlPrefix] — the return URL the app asked for
///    ([EnvConfig.paymentReturnUrl]). The normal case.
///  * [txRef] — our own transaction reference appearing in the URL. Per
///    `payment-flows.md` the gateway appends `?status=…&tx_ref=skf-topup-…`
///    to whatever return URL it was given, so this catches the case where the
///    backend substituted its own `PAYMENT_REDIRECT_URL` and the landing page
///    is somewhere the app has never heard of.
///  * [returnHost] — the API origin's host, if the backend returns to itself.
///
/// With none of them the screen cannot self-detect completion and relies on
/// the user closing it — the pre-WebView behaviour.
Future<CheckoutOutcome> showCheckout(
  BuildContext context, {
  required Uri checkoutUrl,
  String? redirectUrlPrefix,
  String? txRef,
  String? returnHost,
  String title = 'Complete payment',
}) async {
  final outcome = await Navigator.of(context).push<CheckoutOutcome>(
    MaterialPageRoute<CheckoutOutcome>(
      fullscreenDialog: true,
      builder: (_) => CheckoutScreen(
        checkoutUrl: checkoutUrl,
        redirectUrlPrefix: redirectUrlPrefix,
        txRef: txRef,
        returnHost: returnHost,
        title: title,
      ),
    ),
  );
  return outcome ?? CheckoutOutcome.abandoned;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.checkoutUrl,
    this.redirectUrlPrefix,
    this.txRef,
    this.returnHost,
    this.title = 'Complete payment',
  });

  final Uri checkoutUrl;
  final String? redirectUrlPrefix;

  /// Our transaction reference (`skf-topup-…` / `skf-card-…`). The gateway
  /// appends it to the return URL, so seeing it in a URL means the flow is
  /// over wherever it landed.
  final String? txRef;

  /// Host that means "the gateway handed control back to us" — the API origin.
  final String? returnHost;

  final String title;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final WebViewController _controller;

  var _loading = true;
  var _failed = false;

  /// Origin of the page currently shown, e.g. `checkout.paystack.com`. Stands
  /// in for the address bar the WebView doesn't have.
  late String _origin = widget.checkoutUrl.host;

  /// Guards against popping twice — `onNavigationRequest` and `onPageFinished`
  /// can both see the redirect.
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Debug builds narrate the whole hop chain, because the one thing
            // nobody can answer from the spec is what the gateway actually
            // returns to: `redirect_url` is `nullable: true` on both
            // `TopupInitiateRequest` (`:13438`) and `AddCardRequest`
            // (`:7977`), so the app omits it and the backend's own registered
            // URL is used — whatever that is. Run a top-up in a debug build
            // and read the final host off `flutter logs`. If it isn't the API
            // host, that host is what `TOPUP_REDIRECT_URL` needs to be.
            _trace('navigate', request.url);
            if (_isRedirect(request.url)) {
              _finish(CheckoutOutcome.completed);
              // Don't render the redirect target — it is our own callback URL,
              // not a page the user needs to see.
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _failed = false;
              _origin = Uri.tryParse(url)?.host ?? _origin;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() => _loading = false);
            if (_isRedirect(url)) _finish(CheckoutOutcome.completed);
          },
          onWebResourceError: (error) {
            // Sub-resource failures (an analytics script, a font) are not the
            // checkout failing — only a failed main-frame load is.
            if (!error.isForMainFrame!) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
            });
          },
        ),
      )
      ..loadRequest(widget.checkoutUrl);
  }

  /// Debug-only breadcrumb. Never in release: a checkout URL can carry a
  /// reference, an email, and in some gateway flows a one-time token.
  void _trace(String stage, String url) {
    if (!kDebugMode) return;
    final uri = Uri.tryParse(url);
    // Host + path only — the query is where the sensitive parts live, and the
    // host is the whole question being answered here.
    debugPrint(
      'Checkout[$stage]: ${uri?.host ?? url}${uri?.path ?? ''} '
      '(return host: ${widget.returnHost ?? '—'}, '
      'match: ${_isRedirect(url)})',
    );
  }

  bool _isRedirect(String url) {
    final prefix = widget.redirectUrlPrefix;
    if (prefix != null && prefix.isNotEmpty && url.startsWith(prefix)) {
      return true;
    }
    // `…?status=success&tx_ref=skf-topup-aabbccddee`. Checked against the
    // query only: the reference cannot appear there before the gateway puts
    // it there, whereas a substring match on the whole URL could in principle
    // hit a path segment on the gateway's own pages.
    final txRef = widget.txRef;
    if (txRef != null && txRef.isNotEmpty) {
      final query = Uri.tryParse(url)?.query ?? '';
      if (query.contains(txRef)) return true;
    }
    final host = widget.returnHost;
    if (host == null || host.isEmpty) return false;
    // The checkout page itself can be served from our origin in some gateway
    // setups; only a *return* after leaving it counts.
    if (host == widget.checkoutUrl.host) return false;
    return Uri.tryParse(url)?.host == host;
  }

  void _finish(CheckoutOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(outcome);
  }

  /// Leaving mid-payment is easy to do by accident and expensive to get wrong,
  /// so it asks — unless the page never loaded, where there is nothing to lose.
  Future<void> _confirmClose() async {
    if (_failed) {
      _finish(CheckoutOutcome.abandoned);
      return;
    }
    final leave = await showConfirmSheet(
      context,
      title: 'Leave payment?',
      message: "Your payment isn't finished. If you leave now it won't go "
          'through.',
      confirmLabel: 'Leave',
      cancelLabel: 'Keep paying',
    );
    if (leave == true) _finish(CheckoutOutcome.abandoned);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: SkifluxColors.backgroundPrimary,
        appBar: SkifluxTopNavBar(
          label: widget.title,
          labelStyle: SkifluxTypography.headingH8Bold,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(RemixIcons.close_line),
            onPressed: _confirmClose,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _OriginBar(host: _origin),
              Expanded(
                child: _failed
                    ? _FailedState(
                        onRetry: () {
                          setState(() {
                            _failed = false;
                            _loading = true;
                          });
                          _controller.loadRequest(widget.checkoutUrl);
                        },
                      )
                    : Stack(
                        children: [
                          WebViewWidget(controller: _controller),
                          if (_loading)
                            const ColoredBox(
                              color: SkifluxColors.backgroundPrimary,
                              child: Center(child: SkifluxSpinner()),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for the browser's address bar: a padlock and the host the user is
/// actually on. Without it a WebView asks for card details from an unnamed
/// page, which is exactly what a phishing screen looks like.
class _OriginBar extends StatelessWidget {
  const _OriginBar({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceL,
        vertical: SkifluxSpacing.spaceS,
      ),
      decoration: const BoxDecoration(
        color: SkifluxColors.backgroundHover,
        border: Border(
          bottom: BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            RemixIcons.lock_2_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentPositive,
          ),
          const SizedBox(width: SkifluxSpacing.spaceXs),
          Flexible(
            child: Text(
              host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkifluxTypography.bodyP11Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SkifluxSpacing.space2xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkifluxEmptyState(
            icon: Icon(
              RemixIcons.wifi_off_line,
              size: SkifluxEmptyState.iconSize,
              color: SkifluxColors.contentBrand,
            ),
            title: "We couldn't open the payment page",
            message: 'Check your connection and try again. Nothing has been '
                'charged.',
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxButton(
            label: 'Try again',
            expanded: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
