import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

// Shared building blocks for the Settings flow — a labelled section wrapping a
// bordered white card, and the tinted-icon rows inside it. Used by the main
// Settings screen and every grouped detail screen (Notifications, Security,
// Privacy & Data, Download Quality, …) so the card/row look stays identical.

/// Figma's "Notification icon" badge: a 20px glyph with 5px padding inside a
/// pill, i.e. a 30×30 circle. Neither 30 nor 5 exists on the token scale.
const double _iconBadgeSize = 30;

/// A grey label above a bordered card of [children] rows, hairline-separated.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.label, required this.children});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: SkifluxTypography.uiButtonMedium.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SkifluxColors.backgroundPrimary,
            borderRadius: SkifluxRadii.borderL,
            border: Border.all(
              color: SkifluxColors.borderTertiary,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: SkifluxColors.borderTertiary,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: a tinted rounded-square icon, a title (+ optional
/// subtitle), and a trailing control (chevron by default). Set [onTap] to make
/// the whole row tappable; [titleColor] recolors the title (e.g. destructive).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;

  /// Defaults to a chevron; pass a [SkifluxSwitch], value label, external
  /// arrow, or [SizedBox.shrink] to override.
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      child: Row(
        // Two-line rows top-align icon/chevron with the title; single-line rows
        // centre everything against the 30px badge.
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: _iconBadgeSize,
            height: _iconBadgeSize,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: SkifluxUnit.u20, color: iconColor),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: titleColor ?? SkifluxColors.contentSecondary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  Text(
                    subtitle!,
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          trailing ?? _Chevron(color: titleColor),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Trailing "›" used by navigable rows. Destructive rows tint it to match the
/// title (Figma's red "Log out" chevron).
class _Chevron extends StatelessWidget {
  const _Chevron({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      RemixIcons.arrow_right_s_line,
      size: SkifluxIcons.sizeM,
      color: color ?? SkifluxColors.contentSecondary,
    );
  }
}

/// Trailing value + chevron (e.g. "English ›", "HD 720p ›").
class SettingsValueTrailing extends StatelessWidget {
  const SettingsValueTrailing(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: SkifluxTypography.bodyP10Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        const _Chevron(),
      ],
    );
  }
}

/// Trailing "open externally" arrow for links that leave the app.
class SettingsExternalTrailing extends StatelessWidget {
  const SettingsExternalTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      RemixIcons.arrow_right_up_line,
      size: SkifluxIcons.sizeM,
      color: SkifluxColors.contentSecondary,
    );
  }
}
