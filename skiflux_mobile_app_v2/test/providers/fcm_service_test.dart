import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux_mobile_app_v2/shared/notifications/fcm_service.dart';
import 'package:skiflux_mobile_app_v2/shared/toast/skiflux_toast.dart';

/// Stands in for the Firebase Messaging plugin, which has no implementation
/// under the test binding. Mirrors `_FakeBiometrics` in auth_flow_test.
class FakeFcmService extends FcmService {
  FakeFcmService({
    this.grantPermission = true,
    this.token = 'fake-fcm-token',
  });

  final bool grantPermission;
  final String? token;

  final List<String> displayed = <String>[];
  var permissionCalls = 0;
  var tokenCalls = 0;
  var attachCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionCalls += 1;
    permissionGranted = grantPermission;
    return grantPermission;
  }

  @override
  Future<String?> getToken() async {
    tokenCalls += 1;
    lastToken = token;
    return token;
  }

  @override
  Future<void> attachListeners() async {
    attachCalls += 1;
  }

  @override
  void deliverForegroundCopy({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) {
    displayed.add(body);
    onForegroundDisplay?.call(title: title, body: body, data: data);
  }
}

void main() {
  group('FcmService (fake / provider override)', () {
    test('permission granted returns true and records state', () async {
      final fake = FakeFcmService(grantPermission: true);
      final container = ProviderContainer(
        overrides: [fcmServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final granted =
          await container.read(fcmServiceProvider).requestPermission();

      expect(granted, isTrue);
      expect(fake.permissionGranted, isTrue);
      expect(fake.permissionCalls, 1);
    });

    test('permission denied returns false and records state', () async {
      final fake = FakeFcmService(grantPermission: false);
      final container = ProviderContainer(
        overrides: [fcmServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final granted =
          await container.read(fcmServiceProvider).requestPermission();

      expect(granted, isFalse);
      expect(fake.permissionGranted, isFalse);
      expect(fake.permissionCalls, 1);
    });

    test('token unavailable degrades to null without throwing', () async {
      final fake = FakeFcmService(token: null);
      final container = ProviderContainer(
        overrides: [fcmServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final token = await container.read(fcmServiceProvider).getToken();

      expect(token, isNull);
      expect(fake.lastToken, isNull);
      expect(fake.tokenCalls, 1);
    });

    test('token available is returned and cached on lastToken', () async {
      final fake = FakeFcmService(token: 'abc-123');
      final container = ProviderContainer(
        overrides: [fcmServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final token = await container.read(fcmServiceProvider).getToken();

      expect(token, 'abc-123');
      expect(fake.lastToken, 'abc-123');
    });

    test('foreground message invokes onForegroundDisplay callback', () async {
      final fake = FakeFcmService();
      final seen = <String>[];
      fake.onForegroundDisplay = ({required title, required body, data = const {}}) {
        seen.add('$title|$body');
      };

      fake.deliverForegroundCopy(
        title: 'New episode',
        body: 'New episode unlocked',
      );

      expect(fake.displayed, ['New episode unlocked']);
      expect(seen, ['New episode|New episode unlocked']);
    });

    testWidgets(
      'toast message surfaces via SkifluxToast.info',
      (tester) async {
        final fake = FakeFcmService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [fcmServiceProvider.overrideWithValue(fake)],
            child: MaterialApp(
              theme: SkifluxAppTheme.light,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    // Wire the same path the app shell uses.
                    fake.onForegroundDisplay =
                        ({required title, required body, data = const {}}) {
                      SkifluxToast.info(context, body);
                    };
                    return const Text('host');
                  },
                ),
              ),
            ),
          ),
        );

        fake.deliverForegroundCopy(
          title: 'Download',
          body: 'Download complete',
        );
        await tester.pump();

        expect(find.text('Download complete'), findsOneWidget);
        // Info toast uses the information icon from the toast helper.
        expect(find.byIcon(RemixIcons.information_fill), findsOneWidget);
      },
    );
  });
}
