import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Presents a Skiflux bottom sheet the way the Figma overlays do:
/// 5px backdrop blur + `Overlay/50` scrim behind a white card with
/// 24px top corners (Figma nodes `198:13821` / `198:13822` etc.).
Future<T?> showSkifluxSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return Stack(
        children: [
          // Blurred + dimmed backdrop; tap to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5 * curved.value,
                  sigmaY: 5 * curved.value,
                ),
                child: ColoredBox(
                  color: SkifluxColors.overlay50
                      .withValues(alpha: 0.5 * curved.value),
                ),
              ),
            ),
          ),
          // Card slides up from the bottom.
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// White sheet card: top radius `Radius/X` (24), header with H7 title,
/// optional count pill, close control, then [child].
class SkifluxSheetShell extends StatelessWidget {
  const SkifluxSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.count,
  });

  final String title;
  final int? count;
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
              _header(context),
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
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
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
          ),
          // Close control — grey circle + close-line (198:13830).
          Material(
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
          ),
        ],
      ),
    );
  }
}
