import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/success_sheet.dart';
import '../auth/data/auth_repository.dart';

// Figma: **Settings → Change Password** (`1256:21189`) — Current / Create New /
// Confirm New password fields with a strength meter, over a pinned "Update
// Password" button. The button POSTs `/auth/change-password`; the "Password
// Updated Successfully" sheet (`1256:21136`) is shown only after the server
// says 2xx, and a rejection surfaces through ErrorDisplay with the fields
// left intact for a retry.

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  /// Per-field reveal state behind the trailing eye icon Figma puts on every
  /// password field.
  final _revealed = <TextEditingController, bool>{};

  /// A request is in flight — the button shows its spinner and refuses a
  /// second tap that would double-submit.
  var _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Maps the new password onto the [SkifluxPasswordStrength] variants: empty
  /// is the neutral default, anything under the 8-character minimum is "too
  /// short", and past that each satisfied rule fills one more bar.
  SkifluxPasswordStrengthLevel get _strength {
    final value = _next.text;
    if (value.isEmpty) return SkifluxPasswordStrengthLevel.none;
    if (value.length < 8) return SkifluxPasswordStrengthLevel.tooShort;
    var score = 1;
    if (value.length >= 12) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) ||
        RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return switch (score) {
      1 => SkifluxPasswordStrengthLevel.weak,
      2 => SkifluxPasswordStrengthLevel.fair,
      3 => SkifluxPasswordStrengthLevel.good,
      _ => SkifluxPasswordStrengthLevel.strong,
    };
  }

  bool get _canSubmit =>
      !_submitting &&
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
                  _passwordField(_current),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('Create New Password'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _passwordField(_next),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  SkifluxPasswordStrength(level: _strength),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('Confirm New Password'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _passwordField(
                    _confirm,
                    hasError:
                        _confirm.text.isNotEmpty && _confirm.text != _next.text,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: 'Update Password',
                expanded: true,
                loading: _submitting,
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
      style: SkifluxTypography.uiInputLabel.copyWith(
        color: SkifluxColors.contentPrimary,
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller, {
    bool hasError = false,
  }) {
    final revealed = _revealed[controller] ?? false;
    return SkifluxInputField(
      controller: controller,
      obscureText: !revealed,
      hasError: hasError,
      trailingIcon: GestureDetector(
        onTap: () => setState(() => _revealed[controller] = !revealed),
        child: Icon(
          revealed ? RemixIcons.eye_off_fill : RemixIcons.eye_fill,
          size: SkifluxIcons.sizeS,
          color: SkifluxColors.contentTertiary,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// `POST /auth/change-password`. The success sheet appears only after the
  /// server accepted the change; any rejection (wrong current password, weak
  /// new one, no connection) surfaces via ErrorDisplay and leaves the form as
  /// typed so the user can fix and resubmit.
  Future<void> _update() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
        confirmNewPassword: _confirm.text,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await ErrorDisplay.show(context, ref, error, stackTrace: stackTrace);
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    await showSuccessSheet(
      context,
      title: 'Password Updated Successfully',
      message:
          'Your password has been changed. Use your new password the '
          'next time you log in.',
    );
    if (mounted) Navigator.of(context).pop();
  }
}
