/// The forgot-password sub-flow (`198:12640`, `198:12946`, `198:13021`,
/// `24:490`).
///
/// The verify step (`198:12698`) is not here — it is pixel-identical to the
/// sign-up frame `24:4312`, so the router reuses [VerifyEmailScreen] with
/// reset callbacks instead of keeping a second copy.
///
/// Copy note: Figma's field helper reads "Use the email tied to your skilflux
/// account" — the misspelling is an authoring slip and is not propagated,
/// consistent with the rest of the flow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'auth_chrome.dart';

/// "Forgot your password?" (`198:12640`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onSend,
    required this.onBack,
    this.error,
    this.submitting = false,
  });

  /// `POST /auth/forgot-password` with the typed address. Returns false when
  /// the server rejected it, so the field can keep the error and the user can
  /// correct the address without leaving the screen.
  final Future<bool> Function(String email) onSend;
  final VoidCallback onBack;

  /// Failure from the last attempt, rendered under the field.
  final String? error;

  /// True while the request is in flight — disables the CTA so a second tap
  /// can't send two reset codes.
  final bool submitting;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.error != null;
    return AuthScaffold(
      onBack: widget.onBack,
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        // Vertical ListView defaults to CrossAxisAlignment.center — pin
        // children start so the hero disc left-aligns with the heading/field.
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AuthHeroCircle(
              icon: RemixIcons.lock_password_fill,
              background: SkifluxColors.backgroundSelected,
              foreground: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          const AuthHeading(
            title: 'Forgot your password?',
            subtitle:
                'Enter your email and we’ll send a reset link - expires in 30 minutes',
          ),
          // The hero/heading section and the field section each carry Space/L
          // padding in Figma, so the seam between them is two of them.
          const SizedBox(height: SkifluxSpacing.space2xl),
          SkifluxInputField(
            controller: _email,
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            hasError: failed,
            // The failure takes the caption slot; the helper returns once the
            // user edits the address.
            caption: failed
                ? widget.error
                : 'Use the email tied to your Skiflux account',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      footer: SkifluxButton(
        label: 'Send Reset Link',
        expanded: true,
        loading: widget.submitting,
        onPressed: widget.submitting
            ? null
            : () => unawaited(widget.onSend(_email.text)),
      ),
    );
  }
}

/// "Create a new password" (`198:12946` resting, `198:13021` filled) — one
/// screen whose strength meter, match caption and CTA react to what is typed.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.onSubmit,
    required this.onBack,
    this.error,
    this.submitting = false,
  });

  /// `POST /auth/reset-password` with both password fields. The email and OTP
  /// come from flow state, not from this screen — the reset code was collected
  /// on the previous frame.
  final Future<bool> Function(String password, String confirmPassword) onSubmit;
  final VoidCallback onBack;

  final String? error;
  final bool submitting;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  var _showPassword = false;
  var _showConfirm = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// One point per satisfied rule, one strength segment each. Figma draws only
  /// the resting and all-four-green states; the intermediate fills follow the
  /// same meter.
  int get _score {
    final value = _password.text;
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.contains(RegExp(r'[a-z]')) && value.contains(RegExp(r'[A-Z]'))) {
      score++;
    }
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  bool get _matches =>
      _confirm.text.isNotEmpty && _confirm.text == _password.text;

  /// The CTA enables on exactly the state `198:13021` draws it enabled in:
  /// a strong password, confirmed.
  bool get _valid => _score == 4 && _matches;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: widget.onBack,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        children: [
          const AuthHeading(
            title: 'Create a new password',
            subtitle: 'Choose something strong and secure',
          ),
          const SizedBox(height: SkifluxSpacing.spaceXl),
          SkifluxInputField(
            controller: _password,
            label: 'Create Password',
            hintText: 'Enter password',
            obscureText: !_showPassword,
            onChanged: (_) => setState(() {}),
            trailingIcon: AuthRevealToggle(
              revealed: _showPassword,
              onTap: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          _StrengthMeter(score: _score),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _confirm,
            label: 'Confirm Password',
            hintText: 'Re-enter password',
            obscureText: !_showConfirm,
            onChanged: (_) => setState(() {}),
            trailingIcon: AuthRevealToggle(
              revealed: _showConfirm,
              onTap: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          // Rendered outside the field's caption slot so it can wear
          // `Content/Positive` — the slot styles for error/neutral only.
          if (_matches) ...[
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              'Password match',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentPositive,
              ),
            ),
          ],
          // A server rejection — an expired reset OTP, or a password the
          // backend's validators refuse even though the local meter is happy.
          if (widget.error != null) ...[
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              widget.error!,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentNegative,
              ),
            ),
          ],
        ],
      ),
      footer: SkifluxButton(
        label: 'Reset Password',
        expanded: true,
        loading: widget.submitting,
        onPressed: _valid && !widget.submitting
            ? () => unawaited(widget.onSubmit(_password.text, _confirm.text))
            : null,
      ),
    );
  }
}

/// The four-segment strength bar with its caption (`198:10421` resting,
/// `198:10461` strong).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final strong = score == 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                child: Container(
                  height: SkifluxUnit.u4,
                  decoration: BoxDecoration(
                    color: i < score
                        ? SkifluxColors.backgroundPositive
                        : SkifluxColors.backgroundHover,
                    borderRadius: SkifluxRadii.borderS,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          strong ? 'Strong password' : 'Password strength',
          style: SkifluxTypography.uiBadgeTagMedium.copyWith(
            color: strong
                ? SkifluxColors.contentPositive
                : SkifluxColors.contentTertiary,
          ),
        ),
      ],
    );
  }
}

/// "Password updated!" (`24:490`) — the whole block, CTA included, sits in the
/// vertical centre of the frame rather than the CTA sticking to the bottom.
class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key, required this.onBackToSignIn});

  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      centerBody: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: AuthHeroCircle(
                icon: RemixIcons.check_fill,
                background: SkifluxColors.backgroundSelected,
                foreground: SkifluxColors.contentBrand,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            const AuthHeading(
              title: 'Password updated!',
              subtitle:
                  'Your password has been changed. Sign in to get back to work.',
              centered: true,
              subtitleStyleLarge: true,
            ),
            const SizedBox(height: SkifluxSpacing.spaceXl),
            SkifluxButton(
              label: 'Back to Sign in',
              expanded: true,
              onPressed: onBackToSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
