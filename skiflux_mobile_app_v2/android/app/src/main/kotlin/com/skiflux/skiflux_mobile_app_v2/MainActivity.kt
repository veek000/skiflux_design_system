package com.skiflux.skiflux_mobile_app_v2

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity rather than FlutterActivity: local_auth shows the
// biometric prompt as a fragment and has no host without it.
class MainActivity : FlutterFragmentActivity()
