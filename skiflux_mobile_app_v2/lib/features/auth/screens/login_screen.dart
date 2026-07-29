/// Figma: **Login** — `24:188`, `24:1497`, `24:4068`.
///
/// The three frames are one screen in three states, not three screens: `24:188`
/// is the resting form, `24:1497` puts the `Content/Negative` 2px border and an
/// "Incorrect password" caption on the password field, and `24:4068` does the
/// same to the email field with "No account found with this email". The state is
/// driven by the error string [AuthFlowNotifier.signIn] already returns, so a
/// single widget covers all three.
///
/// Copy note: Figma labels the divider "or sign up with" on all three *login*
/// frames — the string was carried over from the sign-up frame it was copied
/// from. "or sign in with" is rendered instead; see [_dividerLabel].
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'auth_chrome.dart';

/// Figma's divider reads "or sign up with" on a sign-in surface — an authoring
/// slip inherited from `23:1912`. Corrected here, consistent with the other
/// copy slips in this flow that are deliberately not propagated.
const _dividerLabel = 'or sign in with';

/// The captions Figma prints on `24:4068` and `24:1497`. [AuthFlowNotifier]
/// produces these exact strings, so the screen matches on them to decide which
/// field wears the error treatment rather than carrying a second enum.
const _emailErrorPrefix = 'No account';
const _passwordError = 'Incorrect password';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.error,
    required this.onSubmit,
    required this.onForgot,
    required this.onSignUp,
    required this.onBack,
    this.submitting = false,
    this.onGoogle,
    this.onApple,
  });

  /// The failure from the last submit, or null on the resting `24:188` state.
  final String? error;

  /// True while login is in flight — disables the CTA.
  final bool submitting;

  /// Social sign-in. Null when that provider is unavailable on this build or
  /// platform, which also drops the divider above the row.
  final Future<void> Function()? onGoogle;
  final Future<void> Function()? onApple;

  final void Function(String email, String password) onSubmit;
  final VoidCallback onForgot;
  final VoidCallback onSignUp;
  final VoidCallback onBack;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  var _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailFailed => widget.error?.startsWith(_emailErrorPrefix) ?? false;
  bool get _passwordFailed => widget.error == _passwordError;

  /// A failure that belongs to neither input — the transport ones, above all.
  ///
  /// Figma only drew the two field states, so before this the "couldn't
  /// connect" string [AuthFlowNotifier.signIn] returns matched neither getter
  /// and was dropped on the floor: the CTA greyed out, came back, and the
  /// screen said nothing. It gets the same banner the sign-up and OTP frames
  /// use for their server-side rejections.
  String? get _generalError {
    final error = widget.error;
    if (error == null || _emailFailed || _passwordFailed) return null;
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final social = AuthSocialRow(
      onGoogle: widget.onGoogle,
      onApple: widget.onApple,
    );
    return AuthScaffold(
      onBack: widget.onBack,
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          const AuthHeading(
            title: 'Welcome Back',
            subtitle: 'Ready to pick up where you left off?',
          ),
          if (_generalError case final message?) ...[
            const SizedBox(height: SkifluxSpacing.spaceL),
            AuthErrorBanner(message: message),
          ],
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _email,
            label: 'Email Address',
            hintText: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            hasError: _emailFailed,
            caption: _emailFailed ? widget.error : null,
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _password,
            label: 'Password',
            hintText: 'Enter password',
            obscureText: !_showPassword,
            hasError: _passwordFailed,
            caption: _passwordFailed ? widget.error : null,
            trailingIcon: AuthRevealToggle(
              revealed: _showPassword,
              onTap: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          // Figma right-aligns this on its own row rather than hanging it off
          // the password field's caption slot, which the error state occupies.
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.onForgot,
              child: Text(
                'Forgot password?',
                style: SkifluxTypography.uiInputLabel.copyWith(
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ),
          ),
        ],
      ),
      footer: Column(
        children: [
          SkifluxButton(
            label: 'Sign in',
            expanded: true,
            loading: widget.submitting,
            onPressed: widget.submitting
                ? null
                : () => widget.onSubmit(_email.text, _password.text),
          ),
          if (social.hasProvider) ...[
            const SizedBox(height: SkifluxSpacing.spaceL),
            const AuthOrDivider(label: _dividerLabel),
            const SizedBox(height: SkifluxSpacing.spaceL),
            social,
          ],
          const SizedBox(height: SkifluxSpacing.spaceL),
          AuthFooterPrompt(
            prefix: 'Don’t have an account?',
            action: 'Sign up',
            onTap: widget.onSignUp,
          ),
        ],
      ),
    );
  }
}
