import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

// Shared building blocks for the Settings flow — a labelled section wrapping a
// bordered white card, and the tinted-icon rows inside it. Used by the main
// Settings screen and every grouped detail screen (Notifications, Security,
// Privacy & Data, Download Quality, …) so the card/row look stays identical.

/// A grey uppercase-ish label above a bordered card of [children] rows,
/// hairline-separated.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.label,
    required this.children,
  });

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
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
        ],
        Container(
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
        children: [
          Container(
            width: SkifluxUnit.u40,
            height: SkifluxUnit.u40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(SkifluxRadii.m),
            ),
            child: Icon(icon, size: SkifluxIcons.sizeS, color: iconColor),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: SkifluxTypography.uiButtonMedium.copyWith(
                    color: titleColor ?? SkifluxColors.contentPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: SkifluxSpacing.space2xs),
                  Text(
                    subtitle!,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          trailing ?? const _Chevron(),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderL,
      child: row,
    );
  }
}

/// Trailing "›" used by navigable rows.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      RemixIcons.arrow_right_s_line,
      size: SkifluxIcons.sizeM,
      color: SkifluxColors.contentTertiary,
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
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceXs),
        const Icon(
          RemixIcons.arrow_right_s_line,
          size: SkifluxIcons.sizeM,
          color: SkifluxColors.contentTertiary,
        ),
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
      color: SkifluxColors.contentTertiary,
    );
  }
}
