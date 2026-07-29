/// The offline bar's state machine.
///
/// What matters here is not that a failure raises the bar — it is that the bar
/// comes *down* again on its own, and that it never goes up for a failure the
/// user's network is not responsible for.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/connectivity_store.dart';

/// A notifier whose probe is scripted and whose delays are compressed —
/// `flutter test` has no server, and the real schedule runs to 15s a step.
class _ScriptedConnectivity extends ConnectivityNotifier {
  _ScriptedConnectivity(this.results, this.restoredDuration);

  /// One entry per probe, consumed in order; the last repeats.
  final List<bool> results;
  int probeCount = 0;

  @override
  List<Duration> get probeSchedule => const [
    Duration(milliseconds: 10),
    Duration(milliseconds: 20),
    Duration(milliseconds: 40),
  ];

  /// Per-instance: a test that has to *observe* the green bar needs a window
  /// wide enough that a loaded machine cannot step over it between the delay
  /// and the assertion, while the tests that only wait for it to retire want
  /// it short.
  @override
  final Duration restoredDuration;

  @override
  Future<bool> probeReachable() async {
    final result = results[probeCount.clamp(0, results.length - 1)];
    probeCount++;
    return result;
  }
}

/// The container plus the notifier instance, so a test can read `probeCount`.
({ProviderContainer container, _ScriptedConnectivity notifier}) build({
  List<bool> probes = const [false],
  Duration restored = const Duration(milliseconds: 30),
}) {
  final notifier = _ScriptedConnectivity(probes, restored);
  final container = ProviderContainer(
    overrides: [connectivityProvider.overrideWith(() => notifier)],
  );
  addTearDown(container.dispose);
  // Force construction so the notifier is attached before the first report.
  container.read(connectivityProvider);
  return (container: container, notifier: notifier);
}

/// Serves one canned outcome, so the interceptor can be driven through a real
/// [Dio] rather than by calling `onError` by hand — dio owns the handler
/// plumbing, and a hand-built handler is both protected API and a different
/// code path from the one that ships.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.outcome);

  /// Returns a body, or throws the [DioException] to simulate.
  final Future<ResponseBody> Function() outcome;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => outcome();

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ConnectivityNotifier', () {
    test('starts online and stays there until something fails', () {
      final env = build();
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.online,
      );
    });

    test('a transport failure raises the bar', () {
      final env = build();
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.offline,
      );
    });

    test('a timeout counts as offline', () {
      final env = build();
      env.notifier.reportFailure(SkifluxErrorKind.networkTimeout);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.offline,
      );
    });

    test('a backend fault does not', () {
      // "No internet connection" over a 500 sends the user to reboot a router
      // that is working perfectly.
      final env = build();
      for (final kind in [
        SkifluxErrorKind.authFailed,
        SkifluxErrorKind.sessionExpired,
        SkifluxErrorKind.unknown,
        SkifluxErrorKind.contentLoadFailed,
      ]) {
        env.notifier.reportFailure(kind);
        expect(
          env.container.read(connectivityProvider),
          ConnectivityStatus.online,
          reason: '$kind should not read as an offline device',
        );
      }
    });

    test('the probe lowers the bar without the user retrying', () async {
      // The whole point of a persistent bar: it has to retire itself.
      final env = build(probes: [false, false, true]);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(env.notifier.probeCount, greaterThanOrEqualTo(3));
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.online,
        reason: 'restored, then the green bar retires on its own',
      );
    });

    test('the recovery is acknowledged before it disappears', () async {
      // A two-second window, not the default 30ms: the probe fires at 10ms and
      // this samples at 20ms, so a compressed countdown would let a busy
      // machine skip straight past the green bar and fail on timing alone.
      final env = build(probes: [true], restored: const Duration(seconds: 2));
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.restored,
      );
    });

    test('real traffic beats the probe to it', () async {
      final env = build(probes: [false]);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);
      env.notifier.reportReachable();

      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.restored,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      // No probe fires once the app's own traffic has answered the question.
      expect(env.notifier.probeCount, 0);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.online,
      );
    });

    test('a screen retrying in a loop does not restart the countdown', () async {
      final env = build(probes: [true]);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(env.notifier.probeCount, 1);
    });

    test('probe delays back off instead of hammering a dead backend', () async {
      final env = build(probes: [false]);
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);

      // 10 + 20 + 40 + 40 + 40 = 150ms of schedule inside the window.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(env.notifier.probeCount, lessThanOrEqualTo(6));
      expect(env.notifier.probeCount, greaterThanOrEqualTo(3));
    });
  });

  group('ConnectivityInterceptor', () {
    /// A client wired exactly as `api_client.dart` wires it.
    ({ProviderContainer container, Dio dio}) client(
      Future<ResponseBody> Function() outcome,
    ) {
      final env = build();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.test/api/v1',
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      )..httpClientAdapter = _StubAdapter(outcome);
      dio.interceptors.add(ConnectivityInterceptor(() => env.notifier));
      env.notifier.reportFailure(SkifluxErrorKind.noConnection);
      return (container: env.container, dio: dio);
    }

    Future<void> call(Dio dio) async {
      try {
        await dio.get<dynamic>('/me');
      } on DioException {
        // Every case here is about the side effect, not the throw.
      }
    }

    ResponseBody body(int status) =>
        ResponseBody.fromString('{}', status, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });

    test('a successful response clears the bar', () async {
      final env = client(() async => body(200));
      await call(env.dio);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.restored,
      );
    });

    test('a 500 clears it too — the server answered', () async {
      final env = client(() async => body(500));
      await call(env.dio);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.restored,
      );
    });

    test('a connection error leaves it up', () async {
      final env = client(
        () async => throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/me'),
          reason: 'no route to host',
        ),
      );
      await call(env.dio);
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.offline,
      );
    });

    test('a cancelled request says nothing about the network', () async {
      final env = client(
        () async => throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: '/me'),
          reason: null,
        ),
      );
      await call(env.dio);
      // Still offline from the seeded failure — a cancel neither raises nor
      // lowers the bar.
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.offline,
      );
    });

    test('a rejected certificate is not an outage', () async {
      // The link is up; something is tampering with it. Telling the user to
      // check their internet is both wrong and unactionable — so a fresh
      // client must not raise the bar for one.
      final env = build();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = _StubAdapter(
          () async => throw DioException.badCertificate(
            requestOptions: RequestOptions(path: '/me'),
            error: 'self-signed',
          ),
        );
      dio.interceptors.add(ConnectivityInterceptor(() => env.notifier));

      try {
        await dio.get<dynamic>('/me');
      } on DioException {
        // Expected.
      }
      expect(
        env.container.read(connectivityProvider),
        ConnectivityStatus.online,
      );
    });
  });
}
