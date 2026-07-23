import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/success_sheet.dart';

// Figma: **Settings → Change Password** (`1256:21189`) — Current / Create New /
// Confirm New password fields with a strength meter, over a pinned "Update
// Password" button. Success shows the "Password Updated Successfully" sheet
// (`1256:21136`).

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong.
  int get _strength {
    final value = _next.text;
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) ||
        RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return score.clamp(1, 3);
  }

  bool get _canSubmit =>
      _current.text.isNotEmpty &&
      _next.text.length >= 8 &&
      _next.text == _confirm.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Change Password',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                children: [
                  _label('Current Password'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxInputField(
                    controller: _current,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('Create New Password'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxInputField(
                    controller: _next,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _StrengthMeter(strength: _strength),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('Confirm New Password'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxInputField(
                    controller: _confirm,
                    obscureText: true,
                    hasError: _confirm.text.isNotEmpty &&
                        _confirm.text != _next.text,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: 'Update Password',
                expanded: true,
                onPressed: _canSubmit ? _update : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: SkifluxTypography.headingH9Bold.copyWith(
        color: SkifluxColors.contentPrimary,
      ),
    );
  }

  Future<void> _update() async {
    await showSuccessSheet(
      context,
      title: 'Password Updated Successfully',
      message: 'Your password has been changed. Use your new password the '
          'next time you log in.',
    );
    if (mounted) Navigator.of(context).pop();
  }
}

/// "Password strength" label + three segments that fill weak→strong.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      0 => SkifluxColors.borderTertiary,
      1 => SkifluxColors.contentNegative,
      2 => SkifluxColors.contentNoticeBold,
      _ => SkifluxColors.contentPositive,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password strength',
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: SkifluxSpacing.spaceXs),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < strength
                        ? color
                        : SkifluxColors.borderTertiary,
                    borderRadius: SkifluxRadii.borderPill,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
