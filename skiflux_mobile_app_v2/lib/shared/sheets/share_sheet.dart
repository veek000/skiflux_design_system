import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'skiflux_sheet.dart';

/// Figma: **Home & In-app Flow 08** (`198:13910`)
///
/// "Share to" sheet — horizontal row of share targets, each a
/// `Brand/50` circle icon with a small label.
Future<void> showShareSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _ShareSheet(),
  );
}

class _ShareTarget {
  const _ShareTarget(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet();

  // TODO(backend, minor): replace static demo share targets with real OS share sheet backed by actual deep links and content URLs from backend — expects: TBD, no current placeholder structure to infer from
  static const _targets = <_ShareTarget>[
    _ShareTarget('Copy Link', RemixIcons.checkbox_multiple_blank_fill),
    _ShareTarget('WhatsApp', RemixIcons.whatsapp_fill),
    _ShareTarget('X', RemixIcons.twitter_x_fill),
    _ShareTarget('Message', RemixIcons.chat_1_fill),
    _ShareTarget('Telegram', RemixIcons.telegram_fill),
    _ShareTarget('Snapchat', RemixIcons.snapchat_fill),
    _ShareTarget('Facebook', RemixIcons.facebook_circle_fill),
    _ShareTarget('Instagram', RemixIcons.instagram_fill),
  ];

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Share to',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _targets.length; i++) ...[
              if (i > 0) const SizedBox(width: SkifluxSpacing.spaceL),
              _ShareItem(target: _targets[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareItem extends StatelessWidget {
  const _ShareItem({required this.target});

  final _ShareTarget target;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: SkifluxColors.brand50,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              child: Center(
                child: Icon(
                  target.icon,
                  size: SkifluxIcons.sizeM,
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          target.label,
          style: SkifluxTypography.bodyP11Semibold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
      ],
    );
  }
}
