import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Presents a Skiflux bottom sheet the way the Figma overlays do:
/// an `Overlay/50` scrim behind a white card with 24px top corners (Figma
/// nodes `198:13821` / `198:13822` etc.). Figma draws a 5px blur behind the
/// scrim; it is deliberately not reproduced — see [_SkifluxSheetRoute].
///
/// Built on `modal_bottom_sheet`'s [ModalSheetRoute] (confirmed per package
/// policy) so every sheet is draggable: swipe down past the threshold (or
/// fling) to dismiss, with inner scrollables coordinated — a list drags the
/// sheet only once it is scrolled to its top. Scrollable sheets should pass
/// `controller: ModalScrollController.of(context)` to their scroll view to
/// opt into that coordination. A grabber pill is overlaid on every card.
Future<T?> showSkifluxSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push(_SkifluxSheetRoute<T>(builder: builder));
}

/// [ModalSheetRoute] restyled to the Skiflux overlay look: the package's plain
/// dim barrier is replaced with an animated `Overlay/50` scrim, and the sheet
/// card gets the grabber pill overlay.
class _SkifluxSheetRoute<T> extends ModalSheetRoute<T> {
  _SkifluxSheetRoute({required super.builder})
    : super(
        expanded: false,
        bounce: false,
        enableDrag: true,
        isDismissible: true,
        // Painted by [buildModalBarrier] instead.
        modalBarrierColor: const Color(0x00000000),
        duration: const Duration(milliseconds: 260),
        animationCurve: Curves.easeOutCubic,
        containerBuilder: (context, animation, child) =>
            _GrabberOverlay(child: child),
      );

  /// Dimmed backdrop; tap to dismiss. Follows [animation] so the scrim also
  /// relaxes while the sheet is dragged down.
  ///
  /// This was a 5px [BackdropFilter] blur behind every sheet. A blur is a
  /// full-screen GPU read-back repainted on every frame of the open animation,
  /// on top of whatever the sheet itself is doing — which is what made sheets
  /// hitch on cold open. A solid scrim reads the same at 50% and costs a fill.
  @override
  Widget buildModalBarrier() {
    final curved = CurvedAnimation(
      parent: animation!,
      curve: Curves.easeOutCubic,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => navigator?.maybePop(),
      child: FadeTransition(
        opacity: curved,
        child: const ColoredBox(color: SkifluxColors.overlay50),
      ),
    );
  }
}

/// Grabber pill overlaid top-center on the sheet card — signals the sheet
/// can be dragged down. [IgnorePointer] keeps taps/drag reaching the card.
class _GrabberOverlay extends StatelessWidget {
  const _GrabberOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        child,
        Positioned(
          top: SkifluxSpacing.spaceS,
          child: IgnorePointer(
            child: Container(
              width: SkifluxUnit.u40,
              height: SkifluxSpacing.spaceXs,
              decoration: BoxDecoration(
                color: SkifluxColors.borderTertiary,
                borderRadius: SkifluxRadii.borderPill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White sheet card: top radius `Radius/X` (24), header with H7 title,
/// optional [subtitle] line (Body p8 regular tertiary, e.g. the playlist
/// menu's "Amara Design • 8 Episodes"), optional count pill, close control,
/// then [child].
///
/// [showHeader] (default true) drops the entire header region — title row,
/// close circle, and the divider stroke beneath it — for headerless dialogs
/// like the error modal, where content supplies its own centered title.
/// Dismissal still works via the backdrop tap and drag-down in
/// [showSkifluxSheet].
class SkifluxSheetShell extends StatelessWidget {
  const SkifluxSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.count,
    this.showHeader = true,
  });

  final String title;
  final String? subtitle;
  final int? count;
  final bool showHeader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      // Keep the card above the keyboard (comments compose bar).
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SkifluxRadii.x),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHeader) _header(context),
              Flexible(child: child),
              SizedBox(
                height: media.viewInsets.bottom > 0
                    ? SkifluxSpacing.spaceL
                    : media.padding.bottom + SkifluxSpacing.spaceL,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SkifluxTypography.headingH7Bold.copyWith(
                          color: SkifluxColors.contentPrimary,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: SkifluxSpacing.spaceXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SkifluxSpacing.spaceS,
                          vertical: SkifluxSpacing.space2xs,
                        ),
                        decoration: BoxDecoration(
                          color: SkifluxColors.brand50,
                          borderRadius: SkifluxRadii.borderPill,
                        ),
                        child: Text(
                          '$count',
                          style: SkifluxTypography.bodyP9Regular.copyWith(
                            color: SkifluxColors.contentBrand,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  // Figma 1256:27274 — Body p8 regular on tertiary. Wraps to
                  // as many lines as needed (e.g. the Unlock Episode
                  // transaction note) — never truncate.
                  Text(
                    subtitle!,
                    style: SkifluxTypography.bodyP8Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SkifluxSheetCloseButton(),
        ],
      ),
    );
  }
}

/// Close control shared by the sheet header and the headerless dialog cards:
/// a grey circle with 8px padding around a 24px close-line, i.e. 40×40
/// (Figma `198:13830`, and the "Main Avatar" in every confirm/success modal).
class SkifluxSheetCloseButton extends StatelessWidget {
  const SkifluxSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundPressed,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.all(SkifluxSpacing.spaceS),
          child: Icon(
            RemixIcons.close_line,
            size: SkifluxIcons.sizeM,
            color: SkifluxColors.contentPrimary,
          ),
        ),
      ),
    );
  }
}
