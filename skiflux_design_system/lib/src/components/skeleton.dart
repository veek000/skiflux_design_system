import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// One sweep of the highlight across a placeholder.
const Duration _kSweep = Duration(milliseconds: 1400);

/// The band travels from fully off the left edge to fully off the right, so
/// the gradient has to slide two widths, not one.
const double _kTravel = 2;

/// A shimmering placeholder for content that has not arrived yet.
///
/// Screens use these instead of seeded sample values: a grey block reads as
/// "loading", whereas a plausible-looking number reads as fact and is still
/// on screen — believed — when the request fails.
///
/// Sizing is the caller's job, the same as a [SizedBox]: pass [width] and
/// [height], or leave one null to fill the parent along that axis. Three
/// shapes cover almost every use:
///
/// ```dart
/// const SkifluxSkeleton.circle(size: 40);            // an avatar
/// const SkifluxSkeleton.text(width: 120);            // one line of copy
/// const SkifluxSkeleton(height: 180, radius: SkifluxRadii.l); // a card
/// ```
///
/// Placeholders standing together should sweep together. Wrap the group in a
/// [SkifluxSkeletonGroup] and they share one ticker; a skeleton with no group
/// above it quietly runs its own, so a lone placeholder still animates.
class SkifluxSkeleton extends StatefulWidget {
  const SkifluxSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius = SkifluxRadii.s,
  });

  /// One line of text. [height] defaults to a body line's ink, and the corner
  /// is tight so a stack of lines reads as prose rather than as buttons.
  const SkifluxSkeleton.text({
    super.key,
    this.width,
    this.height = SkifluxSpacing.spaceM,
    this.radius = SkifluxRadii.xs,
  });

  /// An avatar, coin, or any other round placeholder.
  const SkifluxSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = SkifluxRadii.pill;

  /// Null fills the parent's width — useful for a full-bleed card.
  final double? width;

  /// Null fills the parent's height.
  final double? height;

  /// Corner radius, in the same units as [SkifluxRadii].
  final double radius;

  @override
  State<SkifluxSkeleton> createState() => _SkifluxSkeletonState();
}

class _SkifluxSkeletonState extends State<SkifluxSkeleton>
    with SingleTickerProviderStateMixin {
  /// Only built when there is no group to borrow from.
  AnimationController? _own;
  Animation<double>? _sweep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = _SkeletonSweep.maybeOf(context);
    if (shared != null) {
      _own?.dispose();
      _own = null;
      _sweep = shared;
      return;
    }
    final own = _own ??= AnimationController(vsync: this, duration: _kSweep);
    _sweep = _skeletonSweepOf(own);
    _applyMotionPreference(own, context);
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _sweep!,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              // `neutral100` is the resting grey; `neutral50` is one step
              // lighter, so the highlight reads without flashing white.
              colors: const [
                SkifluxColors.neutral100,
                SkifluxColors.neutral50,
                SkifluxColors.neutral100,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(_sweep!.value),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drives every [SkifluxSkeleton] beneath it from a single ticker.
///
/// Without this each placeholder animates on its own phase, so a list of ten
/// shimmers in ten different places at once — visual noise that reads as
/// broken rather than as loading. It also costs ten [Ticker]s where one will
/// do.
class SkifluxSkeletonGroup extends StatefulWidget {
  const SkifluxSkeletonGroup({super.key, required this.child});

  final Widget child;

  @override
  State<SkifluxSkeletonGroup> createState() => _SkifluxSkeletonGroupState();
}

class _SkifluxSkeletonGroupState extends State<SkifluxSkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _kSweep,
  );

  late final Animation<double> _sweep = _skeletonSweepOf(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPreference(_controller, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonSweep(sweep: _sweep, child: widget.child);
}

Animation<double> _skeletonSweepOf(AnimationController controller) =>
    Tween<double>(begin: -_kTravel / 2, end: _kTravel / 2).animate(controller);

/// "Reduce motion" turns the sweep off rather than the placeholder: a still
/// grey block is the accessible form of the same message.
void _applyMotionPreference(
  AnimationController controller,
  BuildContext context,
) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    controller.stop();
    controller.value = 0.5;
  } else if (!controller.isAnimating) {
    controller.repeat();
  }
}

/// Carries the group's animation down to each placeholder.
class _SkeletonSweep extends InheritedWidget {
  const _SkeletonSweep({required this.sweep, required super.child});

  final Animation<double> sweep;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonSweep>()?.sweep;

  @override
  bool updateShouldNotify(_SkeletonSweep oldWidget) => sweep != oldWidget.sweep;
}

/// Slides the highlight band across the block. [dx] is in multiples of the
/// block's own width, so the same value sweeps a 40px avatar and a full-width
/// card at the same apparent speed.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * dx, 0, 0);
}
