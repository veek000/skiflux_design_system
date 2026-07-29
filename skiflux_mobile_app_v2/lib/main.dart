import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'config/env_config.dart';
import 'firebase_options.dart';
import 'shared/notifications/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.validate();

  // Firebase before Sentry appRunner so messaging + crash reporting both see
  // an initialized engine. Failure degrades to "notifications unavailable"
  // rather than blocking launch (throwaway project / missing native config
  // must never brick the app).
  await _initFirebase();

  if (EnvConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvConfig.sentryDsn;
        options.environment = EnvConfig.environment;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(const ProviderScope(child: SkifluxMobileAppV2())),
    );
  } else {
    runApp(const ProviderScope(child: SkifluxMobileAppV2()));
  }
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register the top-level background handler ASAP after init — before
    // runApp — so a message that arrives during the first frame is handled.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    debugPrint('Firebase.initializeApp failed (FCM unavailable): $e\n$st');
  }
}
