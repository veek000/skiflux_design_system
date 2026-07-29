/// Returning-user biometric login (`198:16415` Face ID, `70:4453` fingerprint).
///
/// Shown when settings have biometric login **enabled** and the device can
/// offer biometrics — it is the login screen itself, not a step after password.
/// "Login with Password" is the fallback. Figma draws the two frames identically
/// apart from the glyph; modality comes from [BiometricMode].
///
/// Verification is entirely on-device. The spec has no biometric
/// session-exchange endpoint by design — `POST /me/biometrics/toggle` stores a
/// preference and nothing more — so a successful prompt authorises reuse of the
/// token pair already in the keychain rather than minting a new one. The router
/// therefore checks a session actually exists before entering the app; see
/// `auth_flow.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../data/biometric_store.dart';
import 'auth_chrome.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onPassword,
    required this.onSwitchAccount,
    this.mode,
  });

  final String email;

  /// Called once the platform prompt reports success.
  final VoidCallback onVerified;

  /// "Login with Password" — same account, type the password instead.
  final VoidCallback onPassword;

  /// "Switch accounts" — a different account entirely.
  final VoidCallback onSwitchAccount;

  /// Forces a modality instead of asking the device. Only the Face ID stage
  /// sets this; the normal entry point detects.
  final BiometricMode? mode;

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  /// The avatar Figma draws at 60; `Unit/56` and `Unit/64` bracket it and the
  /// larger reads closer to the frame against the 98px hero below it.
  static const _avatar = SkifluxUnit.u64;

  bool _busy = false;

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(biometricAuthenticatorProvider).authenticate();
      if (!mounted) return;
      if (ok) {
        widget.onVerified();
        return;
      }
      // A plain "no match" is not an error — the system sheet has already said
      // so — but the frame would otherwise look inert after the tap.
      SkifluxToast.info(
        context,
        'Not recognised. Try again or use your password.',
      );
    } on LocalAuthException catch (error, stackTrace) {
      if (!mounted) return;
      switch (error.code) {
        // The user backed out or the system took the sheet away. Nothing to
        // say; the frame is still there to try again.
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          break;
        // They asked for the passcode path, which here is the password screen.
        case LocalAuthExceptionCode.userRequestedFallback:
          widget.onPassword();
        // Nothing on this screen can ever succeed in these states, so hand
        // straight back to the password form rather than leaving the user on
        // a frame whose only button always fails. The gate is normally
        // skipped before it is ever shown (see `_gateOnBiometrics`); this
        // catches enrolment being removed in between that check and the tap.
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          SkifluxToast.info(
            context,
            'Biometrics are not set up on this device. Use your password instead.',
          );
          widget.onPassword();
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          SkifluxToast.info(
            context,
            'Too many attempts. Use your password instead.',
          );
        case _:
          await ErrorDisplay.show(
            context,
            ref,
            error,
            stackTrace: stackTrace,
            onRetry: _verify,
          );
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      await ErrorDisplay.show(
        context,
        ref,
        error,
        stackTrace: stackTrace,
        onRetry: _verify,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Not Veek?" — Figma greets the account holder by name, and the only name
  /// this flow has is the address it just signed in with.
  String get _displayName {
    final local = widget.email.split('@').first.trim();
    if (local.isEmpty) return widget.email;
    return local[0].toUpperCase() + local.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // The fingerprint frame is drawn while detection is pending: it is the
    // more common of the two, and the wrong glyph for a moment beats an empty
    // hero disc.
    final mode =
        widget.mode ??
        ref.watch(biometricModeProvider).value ??
        BiometricMode.fingerprint;

    return AuthScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
              vertical: SkifluxSpacing.spaceS,
            ),
            child: Column(
              children: [
                Container(
                  width: _avatar,
                  height: _avatar,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SkifluxColors.backgroundSelected,
                  ),
                  // The spec's only avatar source is `GET /me`, which needs the
                  // session this screen is unlocking. Resolves when the profile
                  // cache lands (Tier 1 #39), not from an auth endpoint.
                  // TODO(backend, minor): draw the account's avatar from the cached profile — expects: {avatar} on GET /api/v1/me
                  child: const Icon(
                    RemixIcons.user_fill,
                    size: SkifluxIcons.sizeL,
                    color: SkifluxColors.contentBrand,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  'Welcome Back',
                  // Figma sets this at an untokenised 28; `Heading H6 Bold`
                  // (32) is the design system's nearest step up.
                  style: SkifluxTypography.headingH6Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                AuthEmailPill(email: widget.email),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceL,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthHeroCircle(
                      icon: mode == BiometricMode.face
                          ? RemixIcons.body_scan_fill
                          : RemixIcons.fingerprint_fill,
                      background: SkifluxColors.backgroundSelected,
                      foreground: SkifluxColors.contentBrand,
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceXs),
                    Text(
                      'Click the button to verify that it’s you',
                      textAlign: TextAlign.center,
                      // Figma caption ≈ 12px → bodyP10Regular (not hardcoded 10).
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    SkifluxButton(
                      label: 'Verify Identity',
                      expanded: true,
                      onPressed: _busy ? null : _verify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkifluxButton(
            label: 'Login with Password',
            type: SkifluxButtonType.secondary,
            expanded: true,
            onPressed: widget.onPassword,
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          AuthFooterPrompt(
            prefix: 'Not $_displayName?',
            action: 'Switch accounts',
            actionStyleLarge: true,
            onTap: widget.onSwitchAccount,
          ),
        ],
      ),
    );
  }
}
