/// App-wide "are we reachable?" state, driven by the app's own traffic.
///
/// A timed toast is the wrong shape for a connection failure: it disappears
/// after 3.5s whether or not the problem is over, and it says nothing when the
/// network comes back. TikTok, Instagram and X all use the same pattern
/// instead — a **thin persistent bar** pinned under the status bar that stays
/// up for exactly as long as the device is offline and removes itself the
/// moment traffic flows again. That is what this drives; see
/// `connectivity_banner.dart` for the bar.
///
/// It deliberately has **no platform connectivity plugin** behind it. What the
/// user cares about is whether *this app's requests* work, and the OS's answer
/// famously disagrees with that: captive-portal Wi-Fi reports "connected", a
/// backend that is down reports nothing at all. So the source of truth is the
/// traffic itself — every response flips it online, every transport failure
/// flips it offline — plus a probe that keeps asking while offline so the bar
/// can retire itself without the user tapping anything.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env_config.dart';
import '../error_handling/error_handler.dart';
import 'api_exception.dart';

/// What the banner should be showing.
enum ConnectivityStatus {
  /// Reachable, or not yet known to be otherwise. Nothing is shown.
  online,

  /// A request failed at the transport layer. The bar is up and stays up.
  offline,

  /// Just came back. Shown briefly in the positive colour so the recovery is
  /// acknowledged rather than the bar merely vanishing.
  restored,
}

/// Tracks reachability from request outcomes and a while-offline probe.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  static const _defaultProbeSchedule = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  /// How long the green "Back online" bar lingers before it retires itself.
  ///
  /// A getter, like [probeSchedule], so a test can compress it — the app has
  /// no `fake_async` dependency and a two-second wait per case is not worth
  /// adding one for.
  Duration get restoredDuration => const Duration(seconds: 2);

  /// Probe delays, one per consecutive failure, then the last repeats. Starts
  /// quick because most outages are a lift or a tunnel, then backs off so a
  /// genuinely dead backend is not hammered from every installed device.
  List<Duration> get probeSchedule => _defaultProbeSchedule;

  Timer? _timer;
  int _attempt = 0;

  @override
  ConnectivityStatus build() {
    ref.onDispose(_cancelTimer);
    return ConnectivityStatus.online;
  }

  /// Only the two transport kinds count. A 401 or a 500 means the network is
  /// fine and something else is wrong, and showing "No internet connection"
  /// over a backend fault sends the user to reboot their router for nothing.
  static bool isTransportFailure(SkifluxErrorKind kind) =>
      kind == SkifluxErrorKind.noConnection ||
      kind == SkifluxErrorKind.networkTimeout;

  /// Reports a failed request. Ignored unless it failed at the transport layer.
  void reportFailure(SkifluxErrorKind kind) {
    if (!isTransportFailure(kind)) return;
    if (state == ConnectivityStatus.offline) return;
    state = ConnectivityStatus.offline;
    _attempt = 0;
    _scheduleProbe();
  }

  /// Reports that *something* reached the server — including an error status.
  /// A 404 is proof of a working connection just as much as a 200 is.
  void reportReachable() {
    _cancelTimer();
    switch (state) {
      case ConnectivityStatus.offline:
        state = ConnectivityStatus.restored;
        _timer = Timer(restoredDuration, () {
          if (state == ConnectivityStatus.restored) {
            state = ConnectivityStatus.online;
          }
        });
      case ConnectivityStatus.restored:
      // Already counting down; leave the timer alone.
      case ConnectivityStatus.online:
        break;
    }
  }

  void _scheduleProbe() {
    _cancelTimer();
    final delay = probeSchedule[_attempt.clamp(0, probeSchedule.length - 1)];
    _timer = Timer(delay, () => unawaited(_probe()));
  }

  Future<void> _probe() async {
    if (state != ConnectivityStatus.offline) return;
    if (await probeReachable()) {
      reportReachable();
      return;
    }
    _attempt++;
    if (state == ConnectivityStatus.offline) _scheduleProbe();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// One cheap round trip to the API origin.
  ///
  /// Its own bare [Dio]: routing this through `apiClientProvider` would send
  /// the probe's own failure back through [reportFailure] and attach an auth
  /// header to a request that needs none.
  ///
  /// Overridden in tests — there is no server under `flutter test`.
  Future<bool> probeReachable() async {
    // A build with no `API_BASE_URL` has no origin to probe. Answering "up"
    // would clear an offline bar the requests are still failing behind; the
    // honest answer is that nothing is reachable, and `EnvConfig.validate`
    // has already said why at startup.
    if (!EnvConfig.isApiBaseUrlConfigured) return false;
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        // Every status is a pass: the question is whether bytes came back at
        // all, not whether the origin likes this path.
        validateStatus: (_) => true,
      ),
    );
    try {
      await dio.head<void>('/');
      return true;
    } on DioException catch (error) {
      // Same reasoning: a response of any kind means the link is up.
      return error.response != null;
    } on Object {
      return false;
    } finally {
      dio.close(force: true);
    }
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
      ConnectivityNotifier.new,
    );

/// Feeds [ConnectivityNotifier] from every request the app makes.
///
/// An interceptor rather than a call in each repository: reachability is a
/// property of the transport, and one repository forgetting to report would
/// leave the bar stuck up after the network returned.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._notifier);

  final ConnectivityNotifier Function() _notifier;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _notifier().reportReachable();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A response object means the server answered, however unhappily.
    if (err.response != null) {
      _notifier().reportReachable();
    } else if (err.type != DioExceptionType.cancel &&
        err.type != DioExceptionType.badCertificate) {
      // badCertificate is excluded on purpose: [ApiException] files it under
      // noConnection for copy purposes, but a rejected certificate means the
      // link is working and something is tampering with it. "No internet
      // connection" would be a lie, and one the user cannot act on.
      _notifier().reportFailure(ApiException.fromDio(err).kind);
    }
    handler.next(err);
  }
}
