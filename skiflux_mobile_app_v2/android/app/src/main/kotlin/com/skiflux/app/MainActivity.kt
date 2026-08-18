package com.skiflux.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity rather than FlutterActivity: local_auth shows the
// biometric prompt as a fragment and has no host without it.
class MainActivity : FlutterFragmentActivity()

