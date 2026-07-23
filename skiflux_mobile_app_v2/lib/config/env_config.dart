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

  /// Base URL for backend REST/GraphQL API integration.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dev.skiflux.com',
  );

  /// Feature flag enabling or disabling telemetry analytics.
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';
  static bool get isCi => environment == 'ci';

  /// Validates environment configuration upon initialization.
  /// Logs a warning in debug mode if critical keys are missing.
  static void validate() {
    if (kDebugMode) {
      if (sentryDsn.isEmpty) {
        debugPrint(
          '[EnvConfig Warning] SENTRY_DSN is empty. Run Flutter with '
          '--dart-define-from-file=config/env/dev.json to supply secrets.',
        );
      } else {
        debugPrint(
          '[EnvConfig] Environment initialized ($environment). Sentry DSN active.',
        );
      }
    }
  }
}
