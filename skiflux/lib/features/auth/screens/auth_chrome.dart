/// Chrome shared by every frame in the auth flow.
///
/// Figma draws the sign-up (`23:1912`) and login (`24:188`) screens on the same
/// skeleton: a bare back chevron, a heading/subheading pair, and a
/// bottom-anchored footer holding a full-width CTA, an "or … with" divider, the
/// Google/Apple pair and a closing prompt. These widgets live here rather than
/// in either screen file so the two flows share one implementation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/connectivity_store.dart';

/// The frame every auth screen sits in: an optional back chevron and progress
/// bar on top, content in the middle, a sticky footer at the bottom
/// (`pt:16 pb:8 px:16`).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.body,
    this.footer,
    this.onBack,
    this.progress,
    this.centerBody = false,
  });

  final Widget body;
  final Widget? footer;

  /// Omitted on the frames Figma draws without a nav bar.
  final VoidCallback? onBack;

  /// 1-based index into the three account-setup steps, or null on frames with
  /// no progress bar — which is every login frame.
  final int? progress;

  /// Centres [body] in the space left over instead of top-aligning it.
  final bool centerBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.surfaceL3,
      body: SafeArea(
        child: Column(
          children: [
            if (onBack != null || progress != null)
              AuthNavBar(onBack: onBack, progress: progress),
            Expanded(
              child: centerBody
                  ? Center(child: SingleChildScrollView(child: body))
                  : body,
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceS,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Back chevron on the left with the account-setup progress bar optically
/// centred (`198:16123`). The login frames use the same bar with [progress]
/// null, which is Figma's `showLabel={false} showRightIcon={false}` variant.
///
/// `SkifluxTopNavBar` has no slot for a centred widget — only a label — so the
/// row is built here rather than bending the design-system component.
class AuthNavBar extends StatelessWidget {
  const AuthNavBar({super.key, required this.onBack, required this.progress});

  final VoidCallback? onBack;
  final int? progress;

  /// Total account-setup steps, from the three-segment bar in Figma.
  static const _steps = 3;

  /// One segment is 24×4 with `Radius/XS`; the pair is fixed by the component,
  /// not derived from the container.
  static const _segmentWidth = SkifluxSpacing.spaceXl;

  @override
  Widget build(BuildContext context) {
    final step = progress;
    return SizedBox(
      height: SkifluxUnit.u48,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceM,
        ),
        child: Row(
          children: [
            SizedBox(
              width: SkifluxIcons.sizeM,
              child: onBack == null
                  ? null
                  : GestureDetector(
                      onTap: onBack,
                      child: const Icon(
                        RemixIcons.arrow_left_s_line,
                        size: SkifluxIcons.sizeM,
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
            ),
            Expanded(
              child: step == null
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= _steps; i++) ...[
                          if (i > 1)
                            const SizedBox(width: SkifluxSpacing.spaceXs),
                          Container(
                            width: _segmentWidth,
                            height: SkifluxUnit.u4,
                            decoration: BoxDecoration(
                              color: i <= step
                                  ? SkifluxColors.contentBrand
                                  : SkifluxColors.contentBrandInactive,
                              borderRadius: SkifluxRadii.borderXs,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            // Balances the chevron so the progress bar stays optically centred.
            const SizedBox(width: SkifluxIcons.sizeM),
          ],
        ),
      ),
    );
  }
}

/// Heading + subheading pair. Figma authors the headings at `#090a0a` and the
/// subheadings at `#777` on the account-setup frames and on the `Content/*`
/// ramp elsewhere; the semantic tokens are used throughout so the flow stays
/// internally consistent and themeable.
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.centered = false,
    this.subtitleStyleLarge = false,
  });

  final String title;
  final String subtitle;
  final bool centered;

  /// The account-setup frames set the subheading in `Body p8 regular` (16);
  /// `23:1912`, `24:4312` and the login frames use `Body p9 regular` (14).
  final bool subtitleStyleLarge;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: align,
          style: SkifluxTypography.headingH7Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.space2xs),
        Text(
          subtitle,
          textAlign: align,
          style:
              (subtitleStyleLarge
                      ? SkifluxTypography.bodyP8Regular
                      : SkifluxTypography.bodyP9Regular)
                  .copyWith(color: SkifluxColors.contentTertiary),
        ),
      ],
    );
  }
}

/// The 98px tinted disc holding a 48px glyph, used as the hero mark on
/// `24:4312`, `3098:15817`, `2902:12537` and the biometric frames
/// (`198:16415`, `70:4453`).
class AuthHeroCircle extends StatelessWidget {
  const AuthHeroCircle({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  /// Diameter of the disc. Figma draws it at 98 on every frame that uses it,
  /// between `Unit/96` and `Unit/104`, so it is recorded here rather than
  /// rounded to either token.
  static const diameter = 98.0;

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Icon(icon, size: SkifluxSpacing.space4xl, color: foreground),
    );
  }
}

/// The address chip under "We sent a 6-digit code to" (`24:4312`) and under
/// "Welcome Back" on the biometric frames (`198:16415`, `70:4453`).
class AuthEmailPill extends StatelessWidget {
  const AuthEmailPill({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPrimaryBrand,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Text(
        email,
        style: SkifluxTypography.uiBadgeTagMedium.copyWith(
          color: SkifluxColors.contentBrand,
        ),
      ),
    );
  }
}

/// A server-side rejection on a frame Figma gave no error slot — the sign-up,
/// OTP and reset frames. Those designs only account for client-side problems
/// (mismatched passwords, a short one), which are caught before the request; a
/// taken address or a spent OTP can only be known after it, and still has to
/// land somewhere the user will read.
///
/// The sign-in frame has per-field error states in Figma (`24:4068`,
/// `24:1497`), so `login_screen.dart` paints the caption for the two failures
/// those frames cover — but it falls back to this banner for anything else. A
/// transport failure is neither a bad address nor a bad password, and matching
/// only the two field strings meant it rendered nowhere at all.
class AuthErrorBanner extends ConsumerWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The offline bar already owns this exact sentence, app-wide and for as
    // long as the condition lasts. Printing it a second time inside the form
    // told the user nothing new and read as two separate faults. Suppress the
    // duplicate, keep the bar: it is the one that knows when the problem ends.
    // Every other failure — a rejected credential, a server-side rejection —
    // is specific to this action and still belongs here.
    final offline =
        ref.watch(connectivityProvider) != ConnectivityStatus.online;
    if (offline && message == kNoConnectionMessage) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            RemixIcons.error_warning_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentNegative,
          ),
          const SizedBox(width: SkifluxSpacing.spaceXs),
          Expanded(
            child: Text(
              message,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentNegative,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The eye toggle in the password fields (`23:1912`, `24:188`).
class AuthRevealToggle extends StatelessWidget {
  const AuthRevealToggle({
    super.key,
    required this.revealed,
    required this.onTap,
  });

  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        revealed ? RemixIcons.eye_off_line : RemixIcons.eye_line,
        size: SkifluxIcons.sizeS,
        color: SkifluxColors.contentTertiary,
      ),
    );
  }
}

/// A label between two hairlines (`23:1912`).
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _Hairline()),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceS,
          ),
          child: Text(
            label,
            style: SkifluxTypography.uiNavItem.copyWith(
              color: SkifluxColors.contentDisabled,
            ),
          ),
        ),
        const Expanded(child: _Hairline()),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Container(
    height: SkifluxBorderWidth.xs,
    color: SkifluxColors.borderTertiary,
  );
}

/// The Google / Apple pair (`23:1912`).
///
/// Figma draws both on every frame and the flow passes both, so in the app both
/// are always there for the user to choose between; a provider that cannot
/// complete on this build answers the tap with a "coming soon" toast rather than
/// vanishing. A null callback still hides that button — the row keeps working
/// with one, and with neither it collapses so the caller's "or sign in with"
/// divider can go too.
class AuthSocialRow extends StatefulWidget {
  const AuthSocialRow({super.key, this.onGoogle, this.onApple});

  /// Runs the provider's flow and completes when it has settled either way.
  /// Both buttons disable while one is in flight.
  final Future<void> Function()? onGoogle;
  final Future<void> Function()? onApple;

  /// Whether either provider is offered — the caller uses this to drop the
  /// "or sign in with" divider along with the row.
  bool get hasProvider => onGoogle != null || onApple != null;

  @override
  State<AuthSocialRow> createState() => _AuthSocialRowState();
}

class _AuthSocialRowState extends State<AuthSocialRow> {
  /// The provider currently running, or null. Doubles as the busy flag so the
  /// spinner sits on the tapped button and not on both.
  String? _pending;

  Future<void> _run(String provider, Future<void> Function() action) async {
    if (_pending != null) return;
    setState(() => _pending = provider);
    try {
      await action();
    } finally {
      // The flow can outlive this row: a successful sign-in replaces the
      // screen while the future is still unwinding.
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (widget.onGoogle case final onGoogle?)
        Expanded(
          child: _SocialButton(
            asset: 'assets/brand/google.svg',
            provider: 'Google',
            busy: _pending == 'Google',
            onTap: _pending != null ? null : () => _run('Google', onGoogle),
          ),
        ),
      if (widget.onApple case final onApple?)
        Expanded(
          child: _SocialButton(
            asset: 'assets/brand/apple.svg',
            provider: 'Apple',
            busy: _pending == 'Apple',
            onTap: _pending != null ? null : () => _run('Apple', onApple),
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (index, button) in buttons.indexed) ...[
          if (index > 0) const SizedBox(width: SkifluxSpacing.spaceS),
          button,
        ],
      ],
    );
  }
}

/// An icon-only outlined pill. `SkifluxButton` requires a label and centres it
/// with horizontal padding, so these are built directly on the same tokens its
/// Secondary/Default variant uses: transparent fill, `Border/Tertiary`
/// hairline, `Radius/Pill`.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.asset,
    required this.provider,
    required this.busy,
    required this.onTap,
  });

  final String asset;
  final String provider;
  final bool busy;

  /// Null while any provider is in flight, which is what disables the pill.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Continue with $provider',
      child: Material(
      color: Colors.transparent,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        borderRadius: SkifluxRadii.borderPill,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: SkifluxUnit.u48),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: Border.all(
              color: SkifluxColors.borderTertiary,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Center(
            // Sized identically to the mark so the pill does not resize when
            // the flow starts.
            child: SizedBox(
              width: SkifluxIcons.sizeM,
              height: SkifluxIcons.sizeM,
              child: busy
                  ? const SkifluxSpinner(size: SkifluxSpinnerSize.s)
                  : SvgPicture.asset(asset),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// A centred "`<prompt> <action>`" line — "Already have an account? Sign in",
/// "Don't have an account? Sign up" and "Didn't get it? Resend Code" are the
/// same component in Figma.
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
    this.actionStyleLarge = false,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  /// The biometric frames set the action in `UI Button - Large` (16); the
  /// sign-up and login frames use `UI Button - Medium` (14).
  final bool actionStyleLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: SkifluxTypography.bodyP9Regular.copyWith(
            color: SkifluxColors.contentDisabled,
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style:
                (actionStyleLarge
                        ? SkifluxTypography.uiButtonLarge
                        : SkifluxTypography.uiButtonMedium)
                    .copyWith(color: SkifluxColors.contentBrand),
          ),
        ),
      ],
    );
  }
}
