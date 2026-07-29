import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/skill_world_store.dart';

/// Figma's "Notification icon" badge: a 20px glyph with 5px padding inside a
/// circle, i.e. 30×30 (`1256:24184`). Neither 30 nor 5 is on the token scale.
const double _iconBadgeSize = 30;

/// Figma: **Profile Flow 16** (`1256:24173`) — "Change SkillWorld", opened from
/// the gradient world pill on My Profile. Header + explainer line, then one
/// bordered card per [SkillWorld] with a trailing radio. There is no CTA in the
/// frame: picking a card commits the change and closes the sheet.
Future<void> showChangeSkillWorldSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _ChangeSkillWorldSheet(),
  );
}

class _ChangeSkillWorldSheet extends ConsumerWidget {
  const _ChangeSkillWorldSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(skillWorldProvider);
    return SkifluxSheetShell(
      title: 'Change SkillWorld',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when scrolled to the top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          Text(
            'Your SkillWorld determines the content, tasks, and gigs you see '
            'in your feed.',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          for (final world in SkillWorld.values) ...[
            if (world != SkillWorld.values.first)
              const SizedBox(height: SkifluxSpacing.spaceS),
            _WorldCard(
              world: world,
              selected: world == selected,
              onTap: () {
                ref.read(skillWorldProvider.notifier).select(world);
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// One 75px card: 30px tinted icon badge · world name + skills · 16px radio.
class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  final SkillWorld world;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: SkifluxRadii.borderL,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderL,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderL,
            border: Border.all(
              // Figma binds the card stroke to `Content/Secondary Inverse`.
              color: SkifluxColors.contentSecondaryInverse,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          child: Row(
            children: [
              Container(
                width: _iconBadgeSize,
                height: _iconBadgeSize,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPrimaryBrand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  world.icon,
                  size: SkifluxUnit.u20,
                  color: SkifluxColors.contentBrand,
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      world.label,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceXs),
                    Text(
                      world.skills,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceL),
              // Tapping the row selects — the radio mirrors the state and
              // routes its own tap through the same handler.
              SkifluxRadio<SkillWorld>(
                value: world,
                groupValue: selected ? world : null,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
