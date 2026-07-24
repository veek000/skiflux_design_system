import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../home/home_screen.dart';
import 'data/auth_store.dart';

class AuthFlow extends ConsumerStatefulWidget {
  const AuthFlow({super.key});

  @override
  ConsumerState<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends ConsumerState<AuthFlow> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && ref.read(authFlowProvider).stage == AuthStage.splash) {
        ref.read(authFlowProvider.notifier).show(AuthStage.onboardingOne);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowProvider);
    final notifier = ref.read(authFlowProvider.notifier);
    return switch (state.stage) {
      AuthStage.splash => const _SplashScreen(),
      AuthStage.onboardingOne => _OnboardingScreen(
        page: 0,
        eyebrow: null,
        title: 'Your CV is officially dead.',
        description: 'Nobody cares about your certificates. They care about what you can execute.',
        onCreate: () => notifier.show(AuthStage.createAccount),
        onLogin: () => notifier.show(AuthStage.signIn),
        onAdvance: () => notifier.show(AuthStage.onboardingTwo),
      ),
      AuthStage.onboardingTwo => _OnboardingScreen(
        page: 1,
        eyebrow: r'$',
        title: 'Build a portfolio that actually pays.',
        description: 'Execute real-world tasks. Get your skills verified. Build undeniable proof of work.',
        onCreate: () => notifier.show(AuthStage.createAccount),
        onLogin: () => notifier.show(AuthStage.signIn),
        onAdvance: () => notifier.show(AuthStage.onboardingThree),
      ),
      AuthStage.onboardingThree => _OnboardingScreen(
        page: 2,
        eyebrow: 'Certified learner',
        title: 'Learn it. Prove it. Earn it.',
        description: 'Move from passive learning to active earning. The Skiflux ecosystem is ready for you.',
        onCreate: () => notifier.show(AuthStage.createAccount),
        onLogin: () => notifier.show(AuthStage.signIn),
        onAdvance: () {},
      ),
      AuthStage.createAccount => _CreateAccount(
        onSubmit: () => notifier.show(AuthStage.verifyEmail),
        onSignIn: () => notifier.show(AuthStage.signIn),
        onTerms: () => notifier.show(AuthStage.terms),
        onPrivacy: () => notifier.show(AuthStage.privacy),
      ),
      AuthStage.verifyEmail || AuthStage.verifyReset => _VerificationScreen(
        reset: state.stage == AuthStage.verifyReset,
        onComplete: () => notifier.show(state.stage == AuthStage.verifyReset
            ? AuthStage.resetPassword
            : AuthStage.emailVerified),
      ),
      AuthStage.emailVerified => _SuccessScreen(
        title: 'Email Verified Successfully',
        description: 'Your email has been verified. You can now set up your profile.',
        action: 'Continue',
        onAction: () => notifier.show(AuthStage.claimIdentity),
      ),
      AuthStage.signIn => _SignInScreen(
        error: state.signInError,
        onSubmit: notifier.signIn,
        onForgot: () => notifier.show(AuthStage.forgottenPassword),
        onSignUp: () => notifier.show(AuthStage.createAccount),
      ),
      AuthStage.forgottenPassword => _ForgotPassword(
        onSend: () => notifier.show(AuthStage.verifyReset),
      ),
      AuthStage.resetPassword => _ResetPassword(
        onSubmit: () => notifier.show(AuthStage.passwordUpdated),
      ),
      AuthStage.passwordUpdated => _SuccessScreen(
        title: 'Password updated!',
        description: 'Your password has been changed. Sign in to get back to work.',
        action: 'Back to Sign in',
        onAction: () => notifier.show(AuthStage.signIn),
      ),
      AuthStage.fingerprint || AuthStage.faceId => _BiometricScreen(
        face: state.stage == AuthStage.faceId,
        onVerify: () {
          ref.invalidate(authFlowProvider);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          );
        },
        onPassword: () => notifier.show(AuthStage.signIn),
        onSwitch: () => notifier.show(AuthStage.faceId),
      ),
      AuthStage.claimIdentity => _ClaimIdentity(
        value: state.username,
        onChanged: notifier.setUsername,
        onContinue: () => notifier.show(AuthStage.whatBringsYouHere),
      ),
      AuthStage.whatBringsYouHere => _GoalsScreen(
        value: state.goal,
        onChanged: notifier.setGoal,
        onContinue: () => notifier.show(AuthStage.chooseSkillworld),
      ),
      AuthStage.chooseSkillworld => _SkillworldScreen(
        value: state.skillworld,
        onChanged: notifier.setSkillworld,
        onContinue: () {
          ref.invalidate(authFlowProvider);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          );
        },
      ),
      AuthStage.terms => _LegalScreen(title: 'Terms of Use', onBack: () => notifier.show(AuthStage.createAccount)),
      AuthStage.privacy => _LegalScreen(title: 'Privacy Policy', onBack: () => notifier.show(AuthStage.createAccount)),
    };
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child, this.bottom});
  final Widget child;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SkifluxColors.backgroundPrimary,
    body: SafeArea(child: Column(children: [Expanded(child: child), if (bottom != null) bottom!])),
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const _AuthScaffold(
    child: Center(child: _BrandMark(size: 92)),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(color: SkifluxColors.backgroundBrand, shape: BoxShape.circle),
    child: Center(child: Text('S', style: SkifluxTypography.headingH6ExtraBold.copyWith(color: SkifluxColors.contentPrimaryInverse))),
  );
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({required this.page, required this.eyebrow, required this.title, required this.description, required this.onCreate, required this.onLogin, required this.onAdvance});
  final int page;
  final String? eyebrow;
  final String title;
  final String description;
  final VoidCallback onCreate;
  final VoidCallback onLogin;
  final VoidCallback onAdvance;
  @override
  Widget build(BuildContext context) => _AuthScaffold(
    bottom: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkifluxButton(
            label: 'Create an account',
            expanded: true,
            onPressed: onCreate,
          ),
          const SizedBox(height: 8),
          SkifluxButton(
            label: 'Login',
            expanded: true,
            type: SkifluxButtonType.secondary,
            onPressed: onLogin,
          ),
        ],
      ),
    ),
    child: GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) onAdvance();
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const _BrandMark(size: 72),
            const SizedBox(height: 36),
            if (eyebrow != null) _Pill(text: eyebrow!),
            const SizedBox(height: 12),
            Text(title, style: SkifluxTypography.headingH5ExtraBold),
            const SizedBox(height: 12),
            Text(
              description,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const Spacer(),
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: index == page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == page
                        ? SkifluxColors.contentBrand
                        : SkifluxColors.backgroundPressed,
                    borderRadius: SkifluxRadii.borderPill,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

class _CreateAccount extends StatelessWidget {
  const _CreateAccount({required this.onSubmit, required this.onSignIn, required this.onTerms, required this.onPrivacy});
  final VoidCallback onSubmit, onSignIn, onTerms, onPrivacy;
  @override
  Widget build(BuildContext context) => _AuthScaffold(child: _ScrollableForm(title: 'Create your account', subtitle: 'Join Skiflux and start building your verified portfolio today.', children: [const SkifluxInputField(label: 'Email Address', keyboardType: TextInputType.emailAddress), const SizedBox(height: 16), const Row(children: [Expanded(child: SkifluxInputField(label: 'First Name')), SizedBox(width: 12), Expanded(child: SkifluxInputField(label: 'Last Name'))]), const SizedBox(height: 16), const SkifluxInputField(label: 'Create Password', obscureText: true), const SizedBox(height: 16), const SkifluxInputField(label: 'Confirm Password', obscureText: true), const SizedBox(height: 20), SkifluxButton(label: 'Create an account', expanded: true, onPressed: onSubmit), const SizedBox(height: 16), _LegalLinks(onTerms: onTerms, onPrivacy: onPrivacy), const SizedBox(height: 20), _AuthLink(prefix: 'Already have an account?', action: 'Sign in', onTap: onSignIn)]));
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen({required this.error, required this.onSubmit, required this.onForgot, required this.onSignUp});
  final String? error; final void Function(String, String) onSubmit; final VoidCallback onForgot, onSignUp;
  @override State<_SignInScreen> createState() => _SignInScreenState();
}
class _SignInScreenState extends State<_SignInScreen> {
  final _email = TextEditingController(); final _password = TextEditingController();
  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _AuthScaffold(child: _ScrollableForm(title: 'Welcome Back', subtitle: 'Ready to pick up where you left off?', children: [SkifluxInputField(controller: _email, label: 'Email Address', keyboardType: TextInputType.emailAddress, hasError: widget.error?.startsWith('No account') ?? false, caption: widget.error?.startsWith('No account') ?? false ? widget.error : null), const SizedBox(height: 16), SkifluxInputField(controller: _password, label: 'Password', obscureText: true, hasError: widget.error == 'Incorrect password', caption: widget.error == 'Incorrect password' ? widget.error : null), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: widget.onForgot, child: Text('Forgot password?', style: SkifluxTypography.bodyP10Semibold.copyWith(color: SkifluxColors.contentBrand)))), const SizedBox(height: 8), SkifluxButton(label: 'Sign in', expanded: true, onPressed: () => widget.onSubmit(_email.text, _password.text)), const SizedBox(height: 24), _AuthLink(prefix: 'Don’t have an account?', action: 'Sign up', onTap: widget.onSignUp)]));
}

class _ForgotPassword extends StatelessWidget { const _ForgotPassword({required this.onSend}); final VoidCallback onSend; @override Widget build(BuildContext context) => _AuthScaffold(child: _ScrollableForm(title: 'Forgot your password?', subtitle: 'Enter your email and we’ll send a reset link - expires in 30 minutes', children: [const SkifluxInputField(label: 'Email Address', caption: 'Use the email tied to your Skiflux account'), const SizedBox(height: 24), SkifluxButton(label: 'Send Reset Link', expanded: true, onPressed: onSend)])); }

class _ResetPassword extends StatelessWidget { const _ResetPassword({required this.onSubmit}); final VoidCallback onSubmit; @override Widget build(BuildContext context) => _AuthScaffold(child: _ScrollableForm(title: 'Create a new password', subtitle: 'Choose something strong and secure', children: [const SkifluxInputField(label: 'Create Password', obscureText: true), const SizedBox(height: 16), const SkifluxInputField(label: 'Confirm Password', obscureText: true), const SizedBox(height: 24), SkifluxButton(label: 'Reset Password', expanded: true, onPressed: onSubmit)])); }

class _VerificationScreen extends StatelessWidget {
  const _VerificationScreen({
    required this.reset,
    required this.onComplete,
  });

  final bool reset;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(
                RemixIcons.mail_check_fill,
                size: 56,
                color: SkifluxColors.contentBrand,
              ),
              const SizedBox(height: 24),
              const Text('Verify your email', style: SkifluxTypography.headingH6Bold),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\nveek@nexacorp.io',
                style: SkifluxTypography.bodyP8Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const SizedBox(height: 28),
              const Text('Enter the 6-digit code', style: SkifluxTypography.uiInputLabel),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: SkifluxColors.borderSecondary),
                        borderRadius: SkifluxRadii.borderM,
                      ),
                      child: const Text('–', style: SkifluxTypography.headingH8Bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '05:59',
                style: SkifluxTypography.codeInline.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const Spacer(),
              SkifluxButton(
                label: reset ? 'Verify reset code' : 'Verify email',
                expanded: true,
                onPressed: onComplete,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Resend Code'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
  });

  final String title, description, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SkifluxColors.backgroundPositiveSubtle,
                ),
                child: const Icon(
                  RemixIcons.checkbox_circle_fill,
                  size: 48,
                  color: SkifluxColors.contentPositive,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: SkifluxTypography.headingH7Bold,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: SkifluxTypography.bodyP8Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const Spacer(),
              SkifluxButton(
                label: action,
                expanded: true,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      );
}

class _BiometricScreen extends StatelessWidget {
  const _BiometricScreen({
    required this.face,
    required this.onVerify,
    required this.onPassword,
    required this.onSwitch,
  });

  final bool face;
  final VoidCallback onVerify, onPassword, onSwitch;

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onPassword,
                  child: const Text('Login with Password'),
                ),
              ),
              const Spacer(),
              Icon(
                face ? RemixIcons.user_fill : RemixIcons.fingerprint_fill,
                size: 96,
                color: SkifluxColors.contentBrand,
              ),
              const SizedBox(height: 24),
              const Text('Welcome Back', style: SkifluxTypography.headingH6Bold),
              const SizedBox(height: 8),
              Text(
                'veek@nexacorp.io',
                style: SkifluxTypography.bodyP8Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click the button to verify that it’s you',
                textAlign: TextAlign.center,
                style: SkifluxTypography.bodyP8Regular,
              ),
              const Spacer(),
              SkifluxButton(
                label: 'Verify Identity',
                expanded: true,
                onPressed: onVerify,
              ),
              const SizedBox(height: 12),
              _AuthLink(
                prefix: 'Not Veek?',
                action: 'Switch accounts',
                onTap: onSwitch,
              ),
            ],
          ),
        ),
      );
}

class _ClaimIdentity extends StatelessWidget { const _ClaimIdentity({required this.value, required this.onChanged, required this.onContinue}); final String value; final ValueChanged<String> onChanged; final VoidCallback onContinue; @override Widget build(BuildContext context) => _AuthScaffold(child: _ScrollableForm(title: 'Claim your identity', subtitle: 'Set up your profile for the leaderboard.', progress: 1, children: [SkifluxInputField(label: 'Username', hintText: '@yourname', onChanged: onChanged), const SizedBox(height: 24), SkifluxButton(label: 'Continue', expanded: true, onPressed: value.isEmpty ? null : onContinue)])); }

class _GoalsScreen extends StatelessWidget { const _GoalsScreen({required this.value, required this.onChanged, required this.onContinue}); final String? value; final ValueChanged<String> onChanged; final VoidCallback onContinue; @override Widget build(BuildContext context) { const goals = ['Build a verified portfolio', 'Learn a new technical skill', 'Earn income through tasks', 'Network with creators']; return _AuthScaffold(child: _ScrollableForm(title: 'What brings you here?', subtitle: 'Select what you want to achieve. We’ll tailor your experience.', progress: 2, children: [...goals.map((goal) => _ChoiceRow(label: goal, selected: value == goal, onTap: () => onChanged(goal))), const SizedBox(height: 24), SkifluxButton(label: 'Continue', expanded: true, onPressed: value == null ? null : onContinue)])); } }

class _SkillworldScreen extends StatelessWidget { const _SkillworldScreen({required this.value, required this.onChanged, required this.onContinue}); final String? value; final ValueChanged<String> onChanged; final VoidCallback onContinue; @override Widget build(BuildContext context) { const worlds = [('Design', 'UI/UX, Graphic Design, Motion', RemixIcons.brush_fill), ('Engineering', 'Frontend, Backend, Mobile Dev', RemixIcons.braces_fill), ('Marketing', 'Growth, SEO, Content Creation', RemixIcons.megaphone_fill), ('Product', 'Strategy, Research, Operations', RemixIcons.lightbulb_flash_fill), ('Business', 'Sales, Finance, Leadership', RemixIcons.briefcase_4_fill), ('Health', 'Wellness, Fitness, Care', RemixIcons.heart_pulse_fill)]; return _AuthScaffold(child: _ScrollableForm(title: 'Choose your Skillworld', subtitle: 'Select the ecosystem you want to dive into first. You can change this later.', progress: 3, children: [GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .82, children: worlds.map((world) => _SkillCard(title: world.$1, caption: world.$2, icon: world.$3, selected: value == world.$1, onTap: () => onChanged(world.$1))).toList()), const SizedBox(height: 24), SkifluxButton(label: 'Continue', expanded: true, onPressed: value == null ? null : onContinue)])); } }

class _LegalScreen extends StatelessWidget { const _LegalScreen({required this.title, required this.onBack}); final String title; final VoidCallback onBack; @override Widget build(BuildContext context) { final items = title == 'Terms of Use' ? ['1. The Skiflux Ecosystem', '2. User Accounts & Identity', '3. The Gamified Economy (XP, Badges & SkillCoins)', '4. Task Submissions & Proof of Work', '5. Prohibited Conduct', '6. Termination & Suspension', '7. Limitation of Liability', '8. Changes to the Terms', '9. Contact Us'] : ['1. Information We Collect', '2. How We Use Your Information', '3. How We Share Your Information', '4. Data Security', '5. Your Rights & Choices', '6. Contact Us']; return _AuthScaffold(child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [IconButton(onPressed: onBack, icon: const Icon(RemixIcons.arrow_left_s_line)), Expanded(child: Text(title, textAlign: TextAlign.center, style: SkifluxTypography.headingH8Bold)), const SizedBox(width: 48)])), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [Text('Last Updated May 24th, 2026', style: SkifluxTypography.bodyP10Regular.copyWith(color: SkifluxColors.contentTertiary)), const SizedBox(height: 24), ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item, style: SkifluxTypography.headingH10Bold), const SizedBox(height: 8), Text('Skiflux is built to help people learn, prove their skills, and build meaningful work. This policy explains how the Skiflux ecosystem works and the choices available to you.', style: SkifluxTypography.bodyP9Regular.copyWith(color: SkifluxColors.contentSecondary))])))]))])); } }

class _ScrollableForm extends StatelessWidget { const _ScrollableForm({required this.title, required this.subtitle, required this.children, this.progress}); final String title, subtitle; final List<Widget> children; final int? progress; @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [if (progress != null) _Progress(value: progress!), const SizedBox(height: 30), Text(title, style: SkifluxTypography.headingH6Bold), const SizedBox(height: 8), Text(subtitle, style: SkifluxTypography.bodyP8Regular.copyWith(color: SkifluxColors.contentTertiary)), const SizedBox(height: 32), ...children]); }
class _Progress extends StatelessWidget { const _Progress({required this.value}); final int value; @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(width: 24, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i < value ? SkifluxColors.contentBrand : SkifluxColors.backgroundPressed, borderRadius: SkifluxRadii.borderPill)))); }
class _Pill extends StatelessWidget { const _Pill({required this.text}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: SkifluxColors.backgroundBrandOpacity50, borderRadius: SkifluxRadii.borderPill), child: Text(text, style: SkifluxTypography.uiBadgeTagMedium.copyWith(color: SkifluxColors.contentBrand))); }
class _AuthLink extends StatelessWidget { const _AuthLink({required this.prefix, required this.action, required this.onTap}); final String prefix, action; final VoidCallback onTap; @override Widget build(BuildContext context) => Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [Text('$prefix ', style: SkifluxTypography.bodyP10Regular.copyWith(color: SkifluxColors.contentTertiary)), TextButton(onPressed: onTap, child: Text(action, style: SkifluxTypography.bodyP10Semibold.copyWith(color: SkifluxColors.contentBrand)))])); }
class _LegalLinks extends StatelessWidget { const _LegalLinks({required this.onTerms, required this.onPrivacy}); final VoidCallback onTerms, onPrivacy; @override Widget build(BuildContext context) => Center(child: Wrap(alignment: WrapAlignment.center, children: [Text('By continuing, you agree to our ', style: SkifluxTypography.bodyP11Regular.copyWith(color: SkifluxColors.contentTertiary)), TextButton(onPressed: onTerms, child: const Text('Terms of Use')), Text(' and ', style: SkifluxTypography.bodyP11Regular.copyWith(color: SkifluxColors.contentTertiary)), TextButton(onPressed: onPrivacy, child: const Text('Privacy Policy'))])); }
class _ChoiceRow extends StatelessWidget { const _ChoiceRow({required this.label, required this.selected, required this.onTap}); final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(onTap: onTap, borderRadius: SkifluxRadii.borderL, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? SkifluxColors.backgroundBrandOpacity50 : SkifluxColors.backgroundHover, borderRadius: SkifluxRadii.borderL, border: Border.all(color: selected ? SkifluxColors.contentBrand : Colors.transparent, width: 2)), child: Row(children: [Expanded(child: Text(label, style: SkifluxTypography.headingH10Bold)), Icon(selected ? RemixIcons.checkbox_circle_fill : RemixIcons.circle_line, color: selected ? SkifluxColors.contentBrand : SkifluxColors.contentDisabled)])))); }
class _SkillCard extends StatelessWidget { const _SkillCard({required this.title, required this.caption, required this.icon, required this.selected, required this.onTap}); final String title, caption; final IconData icon; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: SkifluxRadii.borderL, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? SkifluxColors.backgroundBrandOpacity50 : SkifluxColors.backgroundHover, borderRadius: SkifluxRadii.borderL, border: Border.all(color: selected ? SkifluxColors.contentBrand : Colors.transparent, width: 2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: SkifluxColors.backgroundPrimaryBrand, shape: BoxShape.circle), child: Icon(icon, color: SkifluxColors.contentBrand, size: 28)), const Spacer(), Text(title, style: SkifluxTypography.headingH9Bold), const SizedBox(height: 4), Text(caption, style: SkifluxTypography.bodyP10Regular.copyWith(color: SkifluxColors.contentTertiary))]))); }
