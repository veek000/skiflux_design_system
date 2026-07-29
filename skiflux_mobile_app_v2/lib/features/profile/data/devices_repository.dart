import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// `POST /me/devices` — FCM/APNs token registration.
class DevicesRepository extends ApiRepository {
  const DevicesRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.unknown;

  /// Registers a push token. Never required for app function — failures are
  /// soft (caller should catch / ignore).
  Future<void> registerDevice({
    required String token,
    String? deviceId,
  }) async {
    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
        ? 'ios'
        : 'android';
    await post<void>(
      '/me/devices',
      body: {
        'token': token,
        'platform': platform,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
    );
  }
}

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (ref) => DevicesRepository(ref.watch(apiClientProvider)),
);
