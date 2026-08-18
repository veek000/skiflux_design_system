/// The three loading shapes the app's lists, grids and forms share.
///
/// Every screen that fetches used to render `CircularProgressIndicator` —
/// a spinner says only "something is happening", holds no space, and lets the
/// whole layout jump when the answer arrives. A skeleton says *what* is
/// coming, in the size it will occupy, so the screen settles instead of
/// snapping.
///
/// Pick by the shape of what is loading, not by the screen:
///
/// * [ListRowSkeleton] — rows with a leading avatar/thumbnail and two lines.
/// * [CardGridSkeleton] — a two-column grid of cards (coin packs, badges).
/// * [FormSkeleton] — stacked label/field pairs.
///
/// A determinate progress ring (a score gauge) and a button's own busy state
/// are not loaders in this sense and keep their [CircularProgressIndicator].
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Rows of `[leading] · title · subtitle`, sweeping together.
///
/// [rowHeight] should match the real row so the list does not resize under the
/// user when the data lands.
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({
    super.key,
    this.rows = 5,
    this.rowHeight = SkifluxUnit.u48,
    this.leadingIsCircle = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: SkifluxSpacing.spaceL,
      vertical: SkifluxSpacing.spaceM,
    ),
  });

  final int rows;
  final double rowHeight;

  /// Circle for an avatar, rounded rectangle for a video thumbnail.
  final bool leadingIsCircle;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SkifluxSkeletonGroup(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: rows,
        separatorBuilder: (_, _) =>
            const SizedBox(height: SkifluxSpacing.spaceL),
        itemBuilder: (_, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leadingIsCircle)
              SkifluxSkeleton.circle(size: rowHeight)
            else
              SkifluxSkeleton(
                width: rowHeight * 1.5,
                height: rowHeight,
                radius: SkifluxRadii.m,
              ),
            const SizedBox(width: SkifluxSpacing.spaceM),
            // The two text lines are deliberately unequal: a pair of identical
            // bars reads as a table, not as a title over a subtitle.
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkifluxSkeleton.text(height: SkifluxSpacing.spaceM),
                  SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxSkeleton.text(width: 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-column grid of cards — coin packs, badges.
class CardGridSkeleton extends StatelessWidget {
  const CardGridSkeleton({
    super.key,
    this.count = 6,
    this.columns = 2,
    this.aspectRatio = 1,
    this.padding = const EdgeInsets.all(SkifluxSpacing.spaceL),
  });

  final int count;
  final int columns;
  final double aspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SkifluxSkeletonGroup(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: SkifluxSpacing.spaceL,
          crossAxisSpacing: SkifluxSpacing.spaceL,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (_, _) =>
            const SkifluxSkeleton(radius: SkifluxRadii.l),
      ),
    );
  }
}

/// Stacked label-over-field pairs, for a screen whose form needs remote data
/// (a saved bank list, a balance) before it can be filled in.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({
    super.key,
    this.fields = 3,
    this.showAction = true,
    this.padding = const EdgeInsets.all(SkifluxSpacing.spaceL),
  });

  final int fields;

  /// The primary button under the fields.
  final bool showAction;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SkifluxSkeletonGroup(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < fields; i++) ...[
              const SkifluxSkeleton.text(width: 96),
              const SizedBox(height: SkifluxSpacing.spaceS),
              const SkifluxSkeleton(
                height: SkifluxUnit.u48,
                radius: SkifluxRadii.m,
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
            ],
            if (showAction)
              const SkifluxSkeleton(
                height: SkifluxUnit.u48,
                radius: SkifluxRadii.pill,
              ),
          ],
        ),
      ),
    );
  }
}
