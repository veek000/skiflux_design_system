import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Figma: **Onboarding Screen** — `224:3286`, `224:3332`, `224:3450`.
///
/// Three swipeable pages on a white surface: a 3-segment progress bar pinned
/// to the top, a centred illustration, then a heading/subheading pair sitting
/// directly above the "Create an account" / "Login" pair and the legal line.
///
/// The three frames differ only in artwork and copy, so they are one screen
/// driven by a [PageView] rather than three router stages — the buttons and
/// the legal line are identical across all three and stay put while the page
/// content slides.
///
/// Artwork note: the three `assets/illustrations/onboarding_*.svg` exports were
/// post-processed after being copied out of the design folder. Illustration 3
/// embedded a 1010×1010 base64 avatar (849 KB) that renders at ~48 logical px,
/// downscaled to 160×160; and Figma emitted a `<foreignObject>` holding an
/// empty backdrop-blur div, which `flutter_svg` cannot parse — it logged
/// "unhandled element" on every build and carried no geometry, so it was
/// stripped along with its now-unreferenced `bgblur_*` clip path. Net: 1.2 MB
/// → 85 KB. **Re-run both steps after any re-export from Figma.**
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCreateAccount,
    required this.onLogin,
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.surfaceL3,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (`224:3460`) — one segment per page, filled up to
            // and including the current one.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceL,
                vertical: SkifluxSpacing.spaceS,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _pages.length; i++) ...[
                    if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
                    Expanded(
                      child: Container(
                        height: SkifluxUnit.u4,
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? SkifluxColors.backgroundBrand
                              : SkifluxColors.backgroundSelected,
                          borderRadius: SkifluxRadii.borderS,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),
            // Sticky footer (`1269:31220`) — identical on all three frames.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SkifluxSpacing.spaceL,
                SkifluxSpacing.spaceL,
                SkifluxSpacing.spaceL,
                SkifluxSpacing.spaceS,
              ),
              child: Column(
                children: [
                  SkifluxButton(
                    label: 'Create an account',
                    expanded: true,
                    onPressed: widget.onCreateAccount,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxButton(
                    label: 'Login',
                    expanded: true,
                    type: SkifluxButtonType.secondary,
                    onPressed: widget.onLogin,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _LegalLine(
                    onTerms: widget.onTerms,
                    onPrivacy: widget.onPrivacy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One onboarding page: artwork above, copy below. Both scroll together when
/// the user swipes.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // Frame `224:3464` — the artwork sits in a 25/64 inset; 25 has no
          // token, so it rounds to Space/XL.
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceXl,
              vertical: SkifluxSpacing.space6xl,
            ),
            // One shared scale for all three pages. A plain `BoxFit.contain`
            // per illustration would size each to *its own* bounds, and the
            // exports differ (263×261, 329×347, 332×288) — the near-square
            // first one got upscaled ~1.3× more than the others and read as
            // oversized. Fitting the common [_artboard] instead and drawing
            // each SVG at natural size inside it reproduces Figma, where all
            // three sit unscaled in an identically sized frame.
            child: FittedBox(
              child: SizedBox(
                width: _artboard.width,
                height: _artboard.height,
                child: Center(
                  child: SvgPicture.asset(
                    page.asset,
                    width: page.size.width,
                    height: page.size.height,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceL,
          ),
          child: Text(
            page.title,
            textAlign: TextAlign.center,
            style: SkifluxTypography.headingH6Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Padding(
          // Subheading is inset a further 32 either side (`1269:32075`).
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceL + SkifluxSpacing.space2xl,
          ),
          child: Text(
            page.description,
            textAlign: TextAlign.center,
            // Subheading should read more prominently than caption copy.
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `1349:32843` — disabled-grey base copy with tertiary, semibold,
/// underlined links to the two legal documents.
class _LegalLine extends StatelessWidget {
  const _LegalLine({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    // Fine-print / caption role — bodyP11 (10) not bodyP9 (14).
    final linkStyle = SkifluxTypography.bodyP11Semibold.copyWith(
      color: SkifluxColors.contentTertiary,
      decoration: TextDecoration.underline,
      decorationColor: SkifluxColors.contentTertiary,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: SkifluxTypography.bodyP11Regular.copyWith(
          color: SkifluxColors.contentDisabled,
        ),
        children: [
          const TextSpan(text: 'By continuing, you agree to Skiflux’s '),
          TextSpan(
            text: 'Terms of use',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onTerms,
          ),
          const TextSpan(text: ' and confirm that you have read '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacy,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.asset,
    required this.size,
    required this.title,
    required this.description,
  });

  final String asset;

  /// The export's own `viewBox`, so every page can be drawn unscaled inside
  /// the shared [_artboard].
  final Size size;
  final String title;
  final String description;
}

/// Union of the three illustrations' natural sizes — the shared box that gets
/// fitted to the page, giving all three the same effective scale.
const _artboard = Size(332, 347);

const _pages = <_OnboardingPageData>[
  _OnboardingPageData(
    asset: 'assets/illustrations/onboarding_1.svg',
    size: Size(263, 261),
    title: 'Your CV is officially dead.',
    description:
        'Nobody cares about your certificates. They care about what you '
        'can execute.',
  ),
  _OnboardingPageData(
    asset: 'assets/illustrations/onboarding_2.svg',
    size: Size(329, 347),
    title: 'Build a portfolio that actually pays.',
    description:
        'Execute real-world tasks. Get your skills verified. Build '
        'undeniable proof of work.',
  ),
  _OnboardingPageData(
    asset: 'assets/illustrations/onboarding_3.svg',
    size: Size(332, 288),
    title: 'Learn it. Prove it. Earn it.',
    description:
        'Move from passive learning to active earning. The Skiflux '
        'ecosystem is ready for you.',
  ),
];
