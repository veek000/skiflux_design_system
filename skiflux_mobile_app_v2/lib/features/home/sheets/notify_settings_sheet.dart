import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';

// Figma: Home & In-app Flow 04 (`827:35820`) — Notify preferences.

enum NotifyPreference { all, personalized, none }

extension NotifyPreferenceLabel on NotifyPreference {
  String get label => switch (this) {
        NotifyPreference.all => 'All',
        NotifyPreference.personalized => 'Personalized',
        NotifyPreference.none => 'None',
      };

  String get toastTitle => switch (this) {
        NotifyPreference.none => 'Notifications Off',
        _ => 'Notify Activated',
      };

  String get toastBody => switch (this) {
        NotifyPreference.all =>
          'You\'ll get notified for every new episode and update.',
        NotifyPreference.personalized =>
          'You\'ll only get highlights matching your interests.',
        NotifyPreference.none =>
          'You won\'t receive notifications from this creator.',
      };
}

Future<NotifyPreference?> showNotifySettingsSheet(
  BuildContext context, {
  NotifyPreference current = NotifyPreference.personalized,
}) {
  return showSkifluxSheet<NotifyPreference>(
    context: context,
    builder: (_) => _NotifySettingsSheet(current: current),
  );
}

class _NotifySettingsSheet extends StatefulWidget {
  const _NotifySettingsSheet({required this.current});

  final NotifyPreference current;

  @override
  State<_NotifySettingsSheet> createState() => _NotifySettingsSheetState();
}

class _NotifySettingsSheetState extends State<_NotifySettingsSheet> {
  late NotifyPreference _selected = widget.current;

  static const _options = <(NotifyPreference, String, String)>[
    (
      NotifyPreference.all,
      'All',
      'Get notified for every new episode and update.',
    ),
    (
      NotifyPreference.personalized,
      'Personalized',
      'Only highlights and episodes matching your interests.',
    ),
    (
      NotifyPreference.none,
      'None',
      'Mute notifications from this creator.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Notify me of',
      child: Padding(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label, subtitle) in _options) ...[
              InkWell(
                onTap: () => setState(() => _selected = value),
                borderRadius: SkifluxRadii.borderL,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: SkifluxSpacing.spaceM,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: SkifluxTypography.uiButtonLarge.copyWith(
                                color: SkifluxColors.contentPrimary,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: SkifluxTypography.bodyP10Regular.copyWith(
                                color: SkifluxColors.contentTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selected == value
                            ? RemixIcons.radio_button_fill
                            : RemixIcons.checkbox_blank_circle_line,
                        color: _selected == value
                            ? SkifluxColors.contentBrand
                            : SkifluxColors.contentDisabled,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Done',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
