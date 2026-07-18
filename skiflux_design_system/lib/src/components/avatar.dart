import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/icons.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Avatar** (`64:3370`)
///
/// Styles: Blank | Initial | Add Count | Add Avatar | Icon | Avatar
///
/// Uses surface/content tokens for blank/initial states. Photo style expects
/// an [image] provider. Exact avatar diameters vary by instance; default uses
/// Unit 40 (common in style guide samples).
enum SkifluxAvatarStyle {
  blank,
  initial,
  addCount,
  addAvatar,
  icon,
  avatar,
}

class SkifluxAvatar extends StatelessWidget {
  const SkifluxAvatar({
    super.key,
    this.style = SkifluxAvatarStyle.blank,
    this.size = SkifluxUnit.u40,
    this.initials,
    this.image,
    this.icon,
    this.count,
    this.onAdd,
  });

  final SkifluxAvatarStyle style;
  final double size;
  final String? initials;
  final ImageProvider? image;
  final Widget? icon;
  final int? count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SkifluxAvatarStyle.avatar:
        // Photo avatar — falls back to the initials treatment when no
        // image is available (network failure, no upload yet, previews).
        if (image == null) return _initialCircle();
        return _circle(
          child: ClipOval(
            child: Image(
              image: image!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialCircle(),
            ),
          ),
        );
      case SkifluxAvatarStyle.initial:
        return _initialCircle();
      case SkifluxAvatarStyle.icon:
        return _circle(
          color: SkifluxColors.backgroundHover,
          child: IconTheme(
            data: IconThemeData(
              color: SkifluxColors.contentTertiary,
              size: size * 0.5,
            ),
            child: icon ??
                const Icon(SkifluxIcons.userLine),
          ),
        );
      case SkifluxAvatarStyle.addCount:
        return _circle(
          color: SkifluxColors.backgroundHover,
          child: Text(
            count == null ? '+' : '+$count',
            style: SkifluxTypography.bodyP10Semibold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
        );
      case SkifluxAvatarStyle.addAvatar:
        return GestureDetector(
          onTap: onAdd,
          child: _circle(
            color: SkifluxColors.backgroundHover,
            border: Border.all(
              color: SkifluxColors.borderSecondary,
              width: SkifluxBorderWidth.xs,
            ),
            child: Icon(
              SkifluxIcons.addLine,
              color: SkifluxColors.contentBrand,
              size: size * 0.5,
            ),
          ),
        );
      case SkifluxAvatarStyle.blank:
        return _circle(color: SkifluxColors.backgroundHover);
    }
  }

  /// Initials treatment — also the fallback for photo avatars without an
  /// image. Text scales with the avatar diameter.
  Widget _initialCircle() {
    return _circle(
      color: SkifluxColors.backgroundPrimaryBrand,
      child: Text(
        (initials ?? '?').toUpperCase(),
        style: SkifluxTypography.headingH10Bold.copyWith(
          color: SkifluxColors.contentBrand,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _circle({Color? color, Widget? child, BoxBorder? border}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? SkifluxColors.backgroundHover,
        shape: BoxShape.circle,
        border: border,
      ),
      child: child,
    );
  }
}
