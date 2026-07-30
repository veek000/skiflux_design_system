/// Device biometrics behind the post-sign-in gate (`198:16415`, `70:4453`).
///
/// The platform plugin is wrapped rather than used directly so the screen has
/// one narrow surface to talk to — which modality to draw, and one call that
/// runs the prompt — and so a fake can be substituted in tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Which challenge the device offers, and therefore which of the two Figma
/// frames is drawn.
enum BiometricMode { face, fingerprint }

class BiometricAuthenticator {
  const BiometricAuthenticator(this._plugin);

  final LocalAuthentication _plugin;

  /// Shown in the system prompt. Matches the caption on the frame.
  static const _reason = 'Verify that it’s you to get back into Skiflux';

  /// The modality to draw, or null when the device cannot offer biometrics —
  /// no hardware, or nothing enrolled.
  ///
  /// Android commonly reports only [BiometricType.strong] / [BiometricType.weak]
  /// with no modality detail, so anything that is not explicitly a face falls
  /// back to the fingerprint frame. iOS reports [BiometricType.face] on Face ID
  /// devices, which is what makes them show the Face ID frame only.
  /// Never throws: a platform that refuses to answer (or has no plugin
  /// registered at all) is reported as "cannot offer biometrics" rather than
  /// as an error. Callers use this to decide whether to *show* the gate, so a
  /// thrown exception here would otherwise be able to lock a user out of
  /// sign-in over a question that was never answerable.
  Future<BiometricMode?> availableMode() async {
    try {
      final isSupported = await _plugin.isDeviceSupported() || await _plugin.canCheckBiometrics;
      if (!isSupported) return null;
      final enrolled = await _plugin.getAvailableBiometrics();
      if (enrolled.contains(BiometricType.face)) {
        return BiometricMode.face;
      }
      return BiometricMode.fingerprint;
    } catch (_) {
      return BiometricMode.fingerprint;
    }
  }

  /// Runs the platform prompt.
  ///
  /// Returns false when the user simply fails or dismisses the challenge —
  /// that is not an error and the frame just stays put. Anything the user
  /// should be told about arrives as a [LocalAuthException] instead.
  Future<bool> authenticate() => _plugin.authenticate(
    localizedReason: _reason,
    biometricOnly: true,
    // Retry on foregrounding rather than failing outright: the system
    // sheet can be interrupted by a notification or an incoming call.
    persistAcrossBackgrounding: true,
  );
}

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>((ref) {
  return BiometricAuthenticator(LocalAuthentication());
});

/// Resolved once per screen mount; the frame draws the fingerprint variant
/// while this is pending, since that is the more common of the two.
final biometricModeProvider = FutureProvider<BiometricMode?>((ref) {
  return ref.watch(biometricAuthenticatorProvider).availableMode();
});
