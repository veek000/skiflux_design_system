import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import 'data/skill_world_store.dart';

/// Figma's "Notification icon" badge: a 20px glyph with 5px padding inside a
/// circle, i.e. 30×30 (`1256:24184`). Neither 30 nor 5 is on the token scale.
const double _iconBadgeSize = 30;

/// Figma: **Profile Flow 16** (`1256:24173`) — "Change SkillWorld", opened from
/// the gradient world pill on My Profile. Header + explainer line, then one
/// bordered card per available [SkillWorld] with a trailing radio. There is no
/// CTA in the frame: picking a card commits the change and closes the sheet.
///
/// The card list is the enum filtered by the public `GET /skillworlds`
/// catalogue, and a pick persists through `PATCH /me/update` — the sheet
/// closes on the server's 2xx (or instantly for the signed-out demo); a
/// failure rolls the pill back and surfaces via [ErrorDisplay].
Future<void> showChangeSkillWorldSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _ChangeSkillWorldSheet(),
  );
}

class _ChangeSkillWorldSheet extends ConsumerStatefulWidget {
  const _ChangeSkillWorldSheet();

  @override
  ConsumerState<_ChangeSkillWorldSheet> createState() =>
      _ChangeSkillWorldSheetState();
}

class _ChangeSkillWorldSheetState
    extends ConsumerState<_ChangeSkillWorldSheet> {
  bool _saving = false;

  Future<void> _pick(SkillWorld world) async {
    if (_saving) return;
    // Same world: nothing to persist — mirror the old tap-to-close feel.
    if (world == ref.read(skillWorldProvider)) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(skillWorldProvider.notifier).selectAndPersist(world);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      // Selection already rolled back by the notifier.
      if (!mounted) return;
      setState(() => _saving = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(skillWorldProvider);
    // Backend-driven availability; while loading (or on failure) the full
    // enum shows so the sheet is never empty.
    final options = ref.watch(skillWorldOptionsProvider);
    final worlds = switch (options) {
      AsyncData(:final value) => value,
      _ => SkillWorld.values,
    };
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
          for (final world in worlds) ...[
            if (world != worlds.first)
              const SizedBox(height: SkifluxSpacing.spaceS),
            _WorldCard(
              world: world,
              selected: world == selected,
              onTap: _saving ? null : () => _pick(world),
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

  /// Null while a save is in flight — taps are ignored until it settles.
  final VoidCallback? onTap;

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
                onChanged: (_) => onTap?.call(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
