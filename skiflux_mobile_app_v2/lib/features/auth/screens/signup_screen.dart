/// Figma: **Sign up** — `23:1912`, `24:4312`, `3098:15817`, `198:16123`,
/// `198:16222`, `198:16142`, `2897:12161`, `2902:12537`.
///
/// Seven screens in one file because they are one flow and share a nav bar, a
/// sticky footer and a heading block; splitting them further would spread the
/// shared chrome across seven imports. Each screen is a public widget so
/// `auth_flow.dart` stays a thin router.
///
/// Copy note: Figma's subheading on `23:1912` misspells the brand as
/// "Skilflux" and the one on `3098:15817` is truncated mid-word at "You can n".
/// Neither slip is reproduced.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/toast/skiflux_toast.dart';
import '../../profile/data/skill_world_store.dart';
import 'auth_chrome.dart';

/// Diameter of the circular hero on the verify / verified / identity / welcome
/// frames — the same disc the biometric frames use, so the size lives with the
/// shared widget rather than being restated here.
const double _heroCircle = AuthHeroCircle.diameter;

/// Height of a Skillworld grid card (`2897:12161`). Off the token scale.
const double _worldCardHeight = 210;

/// The camera / edit badge on the avatar (`198:16123`). Figma authors this
/// group in fractional pixels — 3.267 border, 8.167 padding, 19.6 glyph — as a
/// by-product of scaling a larger symbol down; they are kept verbatim so the
/// badge matches the design at every density.
const double _avatarBadgeBorder = 3.267;
const double _avatarBadgePadding = 8.167;
const double _avatarBadgeIcon = 19.6;

// =============================================================================
// 1. Create your account (`23:1912`)
// =============================================================================

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onSubmit,
    required this.onSignIn,
    required this.onBack,
    this.error,
    this.submitting = false,
    this.onGoogle,
    this.onApple,
  });

  /// Registers the account. Named rather than positional because the spec's
  /// body has five fields and two of them are both passwords — positional would
  /// make swapping them a silent bug.
  final Future<bool> Function({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  })
  onSubmit;
  final VoidCallback onSignIn;
  final VoidCallback onBack;

  /// Social sign-up. The provider endpoints create the account on first use, so
  /// these are the same two calls the login screen makes. Null hides the
  /// provider — see [AuthSocialRow].
  final Future<void> Function()? onGoogle;
  final Future<void> Function()? onApple;

  /// Server-side rejection from the last attempt — "that email is already
  /// registered" and the like. Client-side problems (mismatch, short password)
  /// are caught by [_canSubmit] and never reach the network.
  final String? error;

  /// True while the signup request is in flight. The design system's button has
  /// no loading variant, so this disables the CTA — enough to stop a second tap
  /// creating a duplicate account or spending an OTP twice.
  final bool submitting;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  var _showPassword = false;
  var _showConfirm = false;

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Maps the typed password onto the Figma meter. Under 8 characters the
  /// component has a dedicated "too short" variant regardless of composition;
  /// past that, one bar per satisfied character class.
  SkifluxPasswordStrengthLevel get _strength {
    final value = _password.text;
    if (value.isEmpty) return SkifluxPasswordStrengthLevel.none;
    if (value.length < 8) return SkifluxPasswordStrengthLevel.tooShort;
    var score = 0;
    if (value.contains(RegExp('[a-z]'))) score++;
    if (value.contains(RegExp('[A-Z]'))) score++;
    if (value.contains(RegExp('[0-9]'))) score++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return switch (score) {
      <= 1 => SkifluxPasswordStrengthLevel.weak,
      2 => SkifluxPasswordStrengthLevel.fair,
      3 => SkifluxPasswordStrengthLevel.good,
      _ => SkifluxPasswordStrengthLevel.strong,
    };
  }

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty &&
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _password.text.length >= 8 &&
      _confirm.text == _password.text;

  /// Hands the form up. The keyboard is dismissed first so the error banner
  /// isn't hidden behind it when the address turns out to be taken.
  void _submit() {
    FocusScope.of(context).unfocus();
    unawaited(
      widget.onSubmit(
        email: _email.text,
        password: _password.text,
        passwordConfirm: _confirm.text,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mismatch =
        _confirm.text.isNotEmpty && _confirm.text != _password.text;
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
            title: 'Create your account',
            subtitle:
                'Join Skiflux and start building your verified '
                'portfolio today.',
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _email,
            label: 'Email Address',
            hintText: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SkifluxInputField(
                  controller: _firstName,
                  label: 'First Name',
                  hintText: 'First name',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                child: SkifluxInputField(
                  controller: _lastName,
                  label: 'Last Name',
                  hintText: 'Last name',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
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
          SkifluxPasswordStrength(level: _strength),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _confirm,
            label: 'Confirm Password',
            hintText: 'Re-enter password',
            obscureText: !_showConfirm,
            hasError: mismatch,
            caption: mismatch ? 'Passwords do not match' : null,
            onChanged: (_) => setState(() {}),
            trailingIcon: AuthRevealToggle(
              revealed: _showConfirm,
              onTap: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          // Server-side rejections — a duplicate address is the common one, and
          // it can only be known after the request. Figma has no error slot on
          // this frame, so it sits under the last field where the eye already is.
          if (widget.error != null) ...[
            const SizedBox(height: SkifluxSpacing.spaceL),
            AuthErrorBanner(message: widget.error!),
          ],
        ],
      ),
      footer: Column(
        children: [
          SkifluxButton(
            label: 'Create an account',
            expanded: true,
            loading: widget.submitting,
            onPressed: _canSubmit && !widget.submitting ? _submit : null,
          ),
          if (social.hasProvider) ...[
            const SizedBox(height: SkifluxSpacing.spaceL),
            const AuthOrDivider(label: 'or sign up with'),
            const SizedBox(height: SkifluxSpacing.spaceL),
            social,
          ],
          const SizedBox(height: SkifluxSpacing.spaceL),
          AuthFooterPrompt(
            prefix: 'Already have an account?',
            action: 'Sign in',
            onTap: widget.onSignIn,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. Verify your email (`24:4312`)
// =============================================================================

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onBack,
    /// Preferred: async verify that can fail and re-enable the boxes.
    this.onSubmit,
    /// Legacy void complete (still accepted if [onSubmit] is null).
    this.onComplete,
    this.onResend,
    this.error,
    this.submitting = false,
  });

  final String email;
  final VoidCallback onBack;

  /// `POST` verify with the six-digit code. Return false to allow retry.
  final Future<bool> Function(String otp)? onSubmit;

  final VoidCallback? onComplete;

  /// Re-issue the code (signup resend or reset forgot-password).
  final Future<bool> Function()? onResend;

  final String? error;
  final bool submitting;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  /// Figma renders the chip at 05:59 — one tick into a six-minute window.
  static const _window = Duration(minutes: 6);
  static const _digits = 6;

  final _controllers = List.generate(_digits, (_) => TextEditingController());
  final _focusNodes = List.generate(_digits, (_) => FocusNode());

  late Duration _remaining = _window;
  Timer? _ticker;

  /// Guards [_onDigitChanged] so editing an already-complete code cannot fire
  /// the transition a second time.
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _ticker?.cancel();
    setState(() => _remaining = _window);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= Duration.zero) {
        timer.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _clock {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Moves focus forward on entry and backward on delete so the six boxes
  /// behave as one field.
  ///
  /// Figma gives this frame no CTA — the sixth digit *is* the submit, so the
  /// transition is driven from here rather than from a footer button.
  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _digits - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_submitted || widget.submitting || _code.length != _digits) return;
    _submitted = true;
    FocusScope.of(context).unfocus();
    final submit = widget.onSubmit;
    if (submit != null) {
      unawaited(() async {
        final ok = await submit(_code);
        if (!mounted) return;
        if (!ok) {
          // Allow another attempt after a server rejection.
          setState(() => _submitted = false);
        }
      }());
      return;
    }
    widget.onComplete?.call();
  }

  void _resend() {
    _startTimer();
    _submitted = false;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    final resend = widget.onResend;
    if (resend != null) {
      unawaited(resend());
    }
    SkifluxToast.info(context, 'A new code is on its way.');
  }

  @override
  Widget build(BuildContext context) {
    // Figma splits the frame into two stacked blocks with different insets, so
    // the 24px between the address pill and the code label is the sum of the
    // first block's 16 bottom and the second's 8 top rather than a gap token.
    return AuthScaffold(
      onBack: widget.onBack,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // `24:4455` — the identity block. Left-aligned, not centred: Figma
          // sets `items-start`, so the avatar, heading and pill all hang off
          // the same 16px margin as the code boxes below.
          Padding(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeroCircle(
                  icon: RemixIcons.mail_fill,
                  background: SkifluxColors.brand100,
                  foreground: SkifluxColors.contentBrand,
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                const AuthHeading(
                  title: 'Verify your email',
                  subtitle: 'We sent a 6-digit code to',
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                AuthEmailPill(email: widget.email),
                if (widget.error != null) ...[
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  AuthErrorBanner(message: widget.error!),
                ],
              ],
            ),
          ),
          // `24:4326` — the code block.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
              vertical: SkifluxSpacing.spaceS,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enter the 6-digit code',
                      style: SkifluxTypography.uiInputLabel.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                    _TimerChip(label: _clock),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                Row(
                  children: [
                    for (var i = 0; i < _digits; i++) ...[
                      if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
                      Expanded(
                        child: _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (value) => _onDigitChanged(i, value),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                AuthFooterPrompt(
                  prefix: 'Didn’t get it?',
                  action: 'Resend Code',
                  onTap: _resend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Email Verified Successfully (`3098:15817`)
// =============================================================================

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      // This frame carries no nav bar — verification is done, there is nothing
      // to go back to.
      centerBody: true,
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthHeroCircle(
              icon: RemixIcons.check_fill,
              background: SkifluxColors.brand100,
              foreground: SkifluxColors.contentBrand,
            ),
            SizedBox(height: SkifluxSpacing.spaceL),
            AuthHeading(
              title: 'Email Verified Successfully',
              subtitle:
                  'Your email has been verified. You can now set up '
                  'your profile.',
              centered: true,
              subtitleStyleLarge: true,
            ),
          ],
        ),
      ),
      footer: SkifluxButton(
        label: 'Continue to Account Setup',
        expanded: true,
        onPressed: onContinue,
      ),
    );
  }
}

// =============================================================================
// 4. Claim your identity (`198:16123` default / `198:16222` filled)
// =============================================================================

class ClaimIdentityScreen extends StatefulWidget {
  const ClaimIdentityScreen({
    super.key,
    required this.username,
    required this.avatarPath,
    required this.onUsernameChanged,
    required this.onAvatarPicked,
    required this.onContinue,
    required this.onBack,
  });

  final String username;
  final String? avatarPath;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onAvatarPicked;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  State<ClaimIdentityScreen> createState() => _ClaimIdentityScreenState();
}

class _ClaimIdentityScreenState extends State<ClaimIdentityScreen> {
  late final _username = TextEditingController(text: widget.username);

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    // Single image only — `pickFiles` is multi-select by default in
    // file_picker 12, matching the submission screen's reasoning.
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (path == null) return;
    widget.onAvatarPicked(path);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: widget.onBack,
      progress: 1,
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          const AuthHeading(
            title: 'Claim your identity',
            subtitle: 'Set up your profile for the leaderboard.',
            subtitleStyleLarge: true,
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Center(
            child: _AvatarPicker(path: widget.avatarPath, onTap: _pickAvatar),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          SkifluxInputField(
            controller: _username,
            label: 'Username',
            hintText: '@yourname',
            onChanged: (value) {
              widget.onUsernameChanged(value);
              setState(() {});
            },
          ),
        ],
      ),
      footer: SkifluxButton(
        label: 'Continue',
        expanded: true,
        // Figma's default frame shows the CTA disabled; `SkifluxButton` renders
        // exactly that `Background/Brand Disabled` fill for a null callback.
        onPressed: _username.text.trim().isEmpty ? null : widget.onContinue,
      ),
    );
  }
}

// =============================================================================
// 5. What brings you here? (`198:16142`)
// =============================================================================

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const goals = <String>[
    'Build a verified portfolio',
    'Learn a new technical skill',
    'Earn income through tasks',
    'Network with creators',
  ];

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: onBack,
      progress: 2,
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          const AuthHeading(
            title: 'What brings you here?',
            subtitle:
                'Select what you want to achieve. We’ll tailor your '
                'experience.',
            subtitleStyleLarge: true,
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          for (final goal in goals) ...[
            if (goal != goals.first)
              const SizedBox(height: SkifluxSpacing.spaceS),
            _GoalRow(
              label: goal,
              selected: value == goal,
              onTap: () => onChanged(goal),
            ),
          ],
        ],
      ),
      footer: SkifluxButton(
        label: 'Continue',
        expanded: true,
        onPressed: value == null ? null : onContinue,
      ),
    );
  }
}

/// One option on `198:16142`. Selected swaps the fill to
/// `Background/Brand Opacity 50` and adds a `Border/Brand` hairline. The radio
/// is drawn inline rather than with `SkifluxRadio` because Figma uses a filled
/// disc with a check glyph here, not the design system's ring.
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SkifluxColors.backgroundBrandOpacity50
          : SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderPill,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            SkifluxSpacing.spaceXl,
            SkifluxSpacing.spaceL,
            SkifluxSpacing.spaceL,
            SkifluxSpacing.spaceL,
          ),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: selected
                ? Border.all(
                    color: SkifluxColors.borderBrand,
                    width: SkifluxBorderWidth.xs,
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: SkifluxTypography.headingH10Semibold.copyWith(
                    color: selected
                        ? SkifluxColors.contentBrand
                        : SkifluxColors.contentSecondary,
                  ),
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Container(
                width: SkifluxSpacing.spaceL,
                height: SkifluxSpacing.spaceL,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? SkifluxColors.backgroundBrand
                      : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(
                          color: SkifluxColors.borderSecondary,
                          width: SkifluxBorderWidth.s,
                        ),
                ),
                child: selected
                    ? const Icon(
                        RemixIcons.check_line,
                        size: SkifluxSpacing.spaceM,
                        color: SkifluxColors.contentPrimaryInverse,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 6. Choose your Skillworld (`2897:12161`)
// =============================================================================

class ChooseSkillworldScreen extends StatelessWidget {
  const ChooseSkillworldScreen({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: onBack,
      progress: 3,
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          const AuthHeading(
            title: 'Choose your Skillworld',
            subtitle:
                'Select the ecosystem you want to dive into first. You '
                'can change this later.',
            subtitleStyleLarge: true,
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: SkillWorld.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: SkifluxSpacing.spaceS,
              mainAxisSpacing: SkifluxSpacing.spaceS,
              mainAxisExtent: _worldCardHeight,
            ),
            itemBuilder: (context, index) {
              final world = SkillWorld.values[index];
              return _WorldCard(
                world: world,
                selected: value == world.label,
                onTap: () => onChanged(world.label),
              );
            },
          ),
        ],
      ),
      footer: SkifluxButton(
        label: 'Enter World',
        expanded: true,
        onPressed: value == null ? null : onContinue,
      ),
    );
  }
}

/// One card in the Skillworld grid. Figma captures every card unselected, so
/// the selected treatment is borrowed from the goal rows on `198:16142` —
/// `Background/Brand Opacity 50` plus a `Border/Brand` hairline — which is the
/// pair the rest of the flow already uses to mean "chosen".
class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  final SkillWorld world;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SkifluxColors.backgroundBrandOpacity50
          : SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderL,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderL,
            border: selected
                ? Border.all(
                    color: SkifluxColors.borderBrand,
                    width: SkifluxBorderWidth.xs,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SkifluxColors.backgroundPrimaryBrand,
                ),
                child: Icon(
                  world.icon,
                  size: SkifluxIcons.sizeL,
                  color: SkifluxColors.contentBrand,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    world.label,
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  Text(
                    world.skills,
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 7. Welcome to Skiflux (`2902:12537`)
// =============================================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  /// Vertical offset of the ray burst from the centre of the frame. Figma pins
  /// it to `calc(50% - 81.05px)`, so it sits behind the hero circle rather than
  /// behind the whole block.
  static const _burstOffset = -81.05;

  /// The burst artboard (`2902:12595`).
  static const _burstSize = 500.0;

  /// Width of the Figma frame the burst is drawn on. The artboard is wider than
  /// it, so the disc overhangs both edges by ~53px and only the top and bottom
  /// of the circle — where the per-ray gradient has faded to white — stay on
  /// screen. The overhang is kept as a *ratio* of the available width rather
  /// than a fixed 500 so it survives a wider device.
  static const _burstFrameWidth = 393.0;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      centerBody: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Same 32-ray motif as `assets/streaks/light_ray.svg`, exported
          // separately: the streak copy is a 393×96 crop filled flat white for
          // the milestone header, while this one is the full square with a
          // per-ray brand gradient at 20% opacity. `colorFilter` cannot
          // synthesise a multi-stop gradient, so both exports are kept.
          //
          // The disc has to be allowed *out* of the stack's width constraint.
          // Every ray tip sits on a circle of radius 250 inside the 500 square,
          // so shrinking the artboard to fit the screen brings that whole circle
          // into view and its edge reads as a rounded corner; overflowing the
          // constraint pushes the arc past the left and right edges instead,
          // which is what Figma draws.
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter =
                  constraints.maxWidth * (_burstSize / _burstFrameWidth);
              return SizedBox(
                height: diameter,
                child: Transform.translate(
                  offset: const Offset(0, _burstOffset),
                  child: OverflowBox(
                    minWidth: diameter,
                    maxWidth: diameter,
                    child: SvgPicture.asset(
                      'assets/illustrations/light_ray_burst.svg',
                      width: diameter,
                      height: diameter,
                    ),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthHeroCircle(
                  icon: RemixIcons.check_fill,
                  background: SkifluxColors.contentBrand,
                  foreground: SkifluxColors.contentPrimaryInverse,
                ),
                SizedBox(height: SkifluxSpacing.spaceS),
                AuthHeading(
                  title: 'Welcome to Skiflux',
                  subtitle: 'Your execution journey starts now.',
                  centered: true,
                  subtitleStyleLarge: true,
                ),
                SizedBox(height: SkifluxSpacing.spaceM),
                _RewardBanner(),
              ],
            ),
          ),
        ],
      ),
      footer: SkifluxButton(
        label: 'Start Learning',
        expanded: true,
        onPressed: onStart,
      ),
    );
  }
}

/// The "Task Toaster" reward card (`2902:12551`).
class _RewardBanner extends StatelessWidget {
  const _RewardBanner();

  /// Gradient stops — authored directly in Figma, not colour variables. The
  /// CSS declares a fourth stop at 130%, past the end of the box; it repeats
  /// the third colour, so dropping it is lossless.
  static const _colors = [
    Color(0xFFD946EF),
    Color(0xFF7C3AED),
    Color(0xFF3B82F6),
  ];
  static const _stops = [0.0319, 0.5392, 0.9197];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderX,
        // Figma authors the ramp at 107.977° — near-horizontal with a slight
        // downward tilt; the alignment pair expresses that in Flutter's
        // box-relative space.
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.3),
          end: Alignment(1, 0.3),
          colors: _colors,
          stops: _stops,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: SkifluxUnit.u48,
            height: SkifluxUnit.u48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SkifluxColors.backgroundPrimary,
            ),
            child: const Icon(
              RemixIcons.gift_fill,
              size: SkifluxIcons.sizeL,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Surprise Reward!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
                Text(
                  'You earned 100 Skillcoins for signing up.',
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentSecondaryInverse,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sign-up-only helpers
// =============================================================================

/// The countdown chip beside "Enter the 6-digit code" (`24:4312`).
class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceXs,
        SkifluxSpacing.spaceXs,
        SkifluxSpacing.spaceS,
        SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNoticeSubtle,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            RemixIcons.timer_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentNoticeBold,
          ),
          const SizedBox(width: SkifluxSpacing.spaceXs),
          Text(
            label,
            style: SkifluxTypography.uiBadgeTagMedium.copyWith(
              color: SkifluxColors.contentNoticeBold,
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the six code boxes. Built on a bare [TextField] rather than
/// `SkifluxInputField` — that component is a labelled, left-aligned form field,
/// while these are fixed-height single-character cells.
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SkifluxUnit.u48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: SkifluxTypography.headingH10Bold.copyWith(
          color: SkifluxColors.contentPrimary,
        ),
        cursorColor: SkifluxColors.borderFocus,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          // Figma parks an italic underscore in every empty cell.
          hintText: '_',
          hintStyle: SkifluxTypography.uiPlaceholderText.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
          enabledBorder: _border(
            SkifluxColors.borderSecondary,
            SkifluxBorderWidth.xs,
          ),
          focusedBorder: _border(
            SkifluxColors.borderFocus,
            SkifluxBorderWidth.m,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: SkifluxRadii.borderPill,
        borderSide: BorderSide(color: color, width: width),
      );
}

/// The avatar and its camera / edit badge (`198:16123` → `198:16222`). The
/// badge glyph is what changes between the two frames.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _heroCircle,
        height: _heroCircle,
        child: Stack(
          children: [
            Container(
              width: _heroCircle,
              height: _heroCircle,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SkifluxColors.backgroundSelected,
              ),
              child: imagePath == null
                  ? const Icon(
                      RemixIcons.user_fill,
                      // Figma scales the glyph to 39.2 inside the 98 circle —
                      // 40% of the diameter, kept as that ratio.
                      size: _heroCircle * 0.4,
                      color: SkifluxColors.contentBrand,
                    )
                  : Image.file(File(imagePath), fit: BoxFit.cover),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(_avatarBadgePadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SkifluxColors.contentBrand,
                  border: Border.all(
                    color: SkifluxColors.backgroundPrimary,
                    width: _avatarBadgeBorder,
                  ),
                ),
                child: Icon(
                  imagePath == null
                      ? RemixIcons.camera_line
                      : RemixIcons.edit_2_line,
                  size: _avatarBadgeIcon,
                  color: SkifluxColors.contentPrimaryInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
