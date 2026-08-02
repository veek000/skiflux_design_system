import 'package:flutter/foundation.dart';

/// Typed environment configuration loaded via compile-time environment variables
/// (`--dart-define` or `--dart-define-from-file=config/env/dev.json`).
class EnvConfig {
  EnvConfig._();

  /// Target environment: 'dev', 'staging', 'prod', or 'ci'.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// Sentry Data Source Name (DSN) URL for crash reporting.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Base URL for backend REST/GraphQL API integration. **Origin only** — the
  /// `/api/v1` prefix is appended once, in `api_client.dart`.
  ///
  /// Deliberately has **no default**. It used to fall back to
  /// `https://api-dev.skiflux.com`, a host that does not resolve, so any build
  /// that forgot `--dart-define-from-file` compiled in a dead address and every
  /// request died in DNS — surfacing to the user as "Couldn't connect. Check
  /// your internet and try again." on a perfectly good connection. An empty
  /// value fails loudly at startup instead (see [validate]), which
  /// names the actual problem rather than blaming the user's network.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Whether a backend origin was compiled into this build.
  static bool get isApiBaseUrlConfigured => apiBaseUrl.isNotEmpty;

  /// Optional override for the payment return URL. Normally empty — see
  /// [paymentReturnUrl].
  static const String topupRedirectUrl = String.fromEnvironment(
    'TOPUP_REDIRECT_URL',
  );

  /// The app's own landing page for a finished hosted checkout.
  ///
  /// Deliberately a URL that does not have to exist. `payment-flows.md` is
  /// explicit that `redirect_url` is "where the gateway sends the user
  /// afterwards (**your app page**)", and that the gateway appends the result:
  /// `redirect_url?status=success&tx_ref=skf-card-9f8e7d6c5b4a`. On the web
  /// that page would call `topup/verify`. In an app there is no page — the
  /// checkout WebView watches for navigation *to* this URL and closes before
  /// it ever loads, which is the standard mobile pattern and the reason the
  /// host need not resolve.
  ///
  /// This previously sent nothing at all, on the reading that the spec's
  /// `nullable: true` meant the backend owned the return. It does own a
  /// default (`PAYMENT_REDIRECT_URL` in its `.env`) — but that default is a
  /// *web* page on some other host, so the WebView had nothing it could
  /// recognise and the checkout could never hand back. Sending our own is what
  /// closes the loop.
  static String get paymentReturnUrl =>
      topupRedirectUrl.isNotEmpty ? topupRedirectUrl : _defaultReturnUrl;

  /// Not a real page. `skiflux.app` is the brand domain; the path exists only
  /// to be recognised.
  static const String _defaultReturnUrl =
      'https://skiflux.app/payments/return';

  /// Host of [apiBaseUrl], e.g. `api.skiflux.com`. Empty when no origin is
  /// configured. Used by the checkout WebView to recognise the backend's own
  /// return page without having to know its exact path.
  static String get apiHost => Uri.tryParse(apiBaseUrl)?.host ?? '';

  /// Feature flag enabling or disabling telemetry analytics.
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  /// The **Web** OAuth client ID from the backend's Google Cloud project.
  ///
  /// Counter-intuitively this is the Web client, not the Android one, on every
  /// platform: it is the audience the backend verifies the `id_token` against.
  /// Android's own client ID is matched by package name + signing certificate
  /// SHA-1 and is never named in code. Without this, `google_sign_in` returns
  /// an access token but a **null `idToken`**, and
  /// `POST /auth/social/mobile/google` has nothing to send.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// The iOS OAuth client ID from the same project. Required only on iOS, where
  /// the SDK also needs its reversed form registered as a URL scheme in
  /// `ios/Runner/Info.plist`.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Whether Google sign-in has enough configuration to produce an `id_token`.
  /// The button is hidden when false rather than failing on tap.
  static bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';
  static bool get isCi => environment == 'ci';

  /// Validates environment configuration upon initialization.
  ///
  /// A missing [apiBaseUrl] **throws in debug** rather than warning: the app
  /// cannot do anything useful without a backend, and the previous behaviour
  /// (a dead default host) turned a build-configuration mistake into a
  /// "check your internet" message that blamed the user's connection. A missing
  /// Sentry DSN only warns — crash reporting is not load-bearing.
  ///
  /// Release builds never throw. A store build with a missing define is a
  /// release-process failure, and crashing every launch is worse than degrading.
  static void validate() {
    if (!kDebugMode) return;
    if (!isApiBaseUrlConfigured) {
      throw StateError(
        'API_BASE_URL was not compiled into this build, so the app has no '
        'backend to call. Run with the env file:\n'
        '  flutter run --dart-define-from-file=config/env/dev.json\n'
        '  flutter build apk --debug '
        '--dart-define-from-file=config/env/dev.json',
      );
    }
    if (sentryDsn.isEmpty) {
      debugPrint(
        '[EnvConfig Warning] SENTRY_DSN is empty. Run Flutter with '
        '--dart-define-from-file=config/env/dev.json to supply secrets.',
      );
    } else {
      debugPrint(
        '[EnvConfig] Environment initialized ($environment). '
        'API $apiBaseUrl. Sentry DSN active.',
      );
    }
  }
}
