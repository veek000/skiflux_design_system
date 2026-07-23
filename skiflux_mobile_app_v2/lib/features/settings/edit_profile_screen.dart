import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/toast/skiflux_toast.dart';

// Figma: **Settings → Edit Profile** (`1256:19929`) — avatar with a "Change
// Profile Picture" action, a read-only email, and editable first/last name +
// username, over a pinned "Save Changes" button.
// TODO(backend, blocking): load and persist the authenticated user's profile fields (avatar, email, first/last name, username) — expects: {avatarUrl: String?, email: String, firstName: String, lastName: String, userName: String}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Seeded with the demo identity shown on My Profile.
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _userName = TextEditingController(text: 'amara');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _userName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Edit Profile',
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
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  const _AvatarPicker(),
                  const SizedBox(height: SkifluxSpacing.spaceXl),
                  _label('Email Address'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  const SkifluxInputField(
                    hintText: 'amaradesign@gmail.com',
                    enabled: false,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('First Name'),
                            const SizedBox(height: SkifluxSpacing.spaceS),
                            SkifluxInputField(controller: _firstName),
                          ],
                        ),
                      ),
                      const SizedBox(width: SkifluxSpacing.spaceL),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Last Name'),
                            const SizedBox(height: SkifluxSpacing.spaceS),
                            SkifluxInputField(controller: _lastName),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('User Name'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxInputField(
                    controller: _userName,
                    hintText: '@amara',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: 'Save Changes',
                expanded: true,
                onPressed: _save,
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

  void _save() {
    SkifluxToast.success(context, 'Profile updated');
    Navigator.of(context).pop();
  }
}

/// Avatar with a brand camera badge + "Change Profile Picture" link.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: SkifluxUnit.u80,
          height: SkifluxUnit.u80,
          child: Stack(
            children: [
              const SkifluxAvatar(
                style: SkifluxAvatarStyle.initial,
                size: SkifluxUnit.u80,
                initials: 'AD',
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: SkifluxUnit.u28,
                  height: SkifluxUnit.u28,
                  decoration: const BoxDecoration(
                    color: SkifluxColors.backgroundBrand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    RemixIcons.camera_fill,
                    size: SkifluxIcons.sizeS,
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          'Change Profile Picture',
          style: SkifluxTypography.uiButtonMedium.copyWith(
            color: SkifluxColors.contentBrand,
          ),
        ),
      ],
    );
  }
}
