import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/network_image.dart';
import '../profile/data/profile_store.dart';

// Figma: **Settings → Edit Profile** (`1256:19929`).
// Loads `GET /me/profile`; saves via multipart/JSON `PATCH /me/update`.

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _userName = TextEditingController();
  final _email = TextEditingController();

  XFile? _avatar;
  String? _remoteAvatarUrl;
  var _seeded = false;
  var _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _userName.dispose();
    _email.dispose();
    super.dispose();
  }

  void _seedFromProfile() {
    if (_seeded) return;
    final profile = ref.read(meProfileProvider).value;
    if (profile == null) return;
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    _userName.text = profile.username;
    _email.text = profile.email;
    _remoteAvatarUrl = profile.avatarUrl;
    _seeded = true;
  }

  Future<void> _changeAvatar() async {
    final source = await showSkifluxSheet<ImageSource>(
      context: context,
      builder: (_) => const _AvatarSourceSheet(),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _avatar = picked);
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'camera_access_denied') {
        SkifluxToast.info(
          context,
          'Camera access is off. Allow it in Settings to take a photo.',
        );
      } else if (e.code == 'photo_access_denied') {
        SkifluxToast.info(
          context,
          'Photo access is off. Allow it in Settings to pick a picture.',
        );
      } else {
        SkifluxToast.error(context, "Couldn't open the picker. Try again.");
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(meProfileProvider.notifier).save(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        username: _userName.text.trim().replaceFirst(RegExp(r'^@'), ''),
        avatarPath: _avatar?.path,
      );
      if (!mounted) return;
      SkifluxToast.success(context, 'Profile updated');
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(meProfileProvider);
    _seedFromProfile();

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
                  _AvatarPicker(
                    imagePath: _avatar?.path,
                    networkUrl: _avatar == null ? _remoteAvatarUrl : null,
                    onTap: _changeAvatar,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _label('Email Address'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxInputField(
                    controller: _email,
                    hintText: 'email@example.com',
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
                      const SizedBox(width: SkifluxSpacing.spaceS),
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
                  SkifluxInputField(controller: _userName, hintText: '@username'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: _saving ? 'Saving…' : 'Save Changes',
                expanded: true,
                onPressed: _saving ? null : _save,
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
}

const double _avatarSize = 98;
const double _badgeSize = 36;
const double _badgeRing = 3;

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.onTap,
    this.imagePath,
    this.networkUrl,
  });

  final VoidCallback onTap;
  final String? imagePath;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    Widget avatarBody;
    if (imagePath != null) {
      avatarBody = Image.file(File(imagePath!), fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      avatarBody = SkifluxNetworkImage(
        url: networkUrl!,
        errorWidget: const Icon(
          RemixIcons.user_fill,
          size: 40,
          color: SkifluxColors.contentBrand,
        ),
      );
    } else {
      avatarBody = const Icon(
        RemixIcons.user_fill,
        size: 40,
        color: SkifluxColors.contentBrand,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: Stack(
              children: [
                Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: SkifluxColors.backgroundSelected,
                    shape: BoxShape.circle,
                  ),
                  child: avatarBody,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      color: SkifluxColors.contentBrand,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SkifluxColors.backgroundPrimary,
                        width: _badgeRing,
                      ),
                    ),
                    child: const Icon(
                      RemixIcons.camera_fill,
                      size: 16,
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
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentBrand,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Profile photo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(RemixIcons.camera_fill),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(RemixIcons.image_fill),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
