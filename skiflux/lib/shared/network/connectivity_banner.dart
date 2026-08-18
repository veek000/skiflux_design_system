/// The offline bar — a thin strip under the status bar that is up for exactly
/// as long as the app cannot reach the backend.
///
/// Deliberately *not* a [SkifluxToast]. A toast is a report of one event, and
/// it leaves after 3.5s whether or not the event is over; being offline is a
/// **condition**, so it gets a persistent affordance that removes itself when
/// the condition ends. This is the same split TikTok and Instagram make: the
/// failed action still says what went wrong where it happened (the auth
/// screens' [AuthErrorBanner]), while this answers "is it me or the app?".
///
/// It has no dismiss button on purpose. Dismissing would leave the user with
/// the same broken app and no explanation for it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'connectivity_store.dart';

/// Wraps [child] with the bar overlaid at the top.
///
/// An overlay rather than a [Column]: pushing the whole app down by 28px and
/// back up is a full relayout of whatever is on screen, and mid-scroll that
/// reads as a jump. Sliding a strip over the top of it does not disturb the
/// content underneath.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              // Grows downward from the status bar rather than out of its own
              // centre, so it reads as sliding in from off-screen.
              alignment: Alignment.topCenter,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: status == ConnectivityStatus.online
                ? const SizedBox(width: double.infinity)
                : _Bar(status: status),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.status});

  final ConnectivityStatus status;

  @override
  Widget build(BuildContext context) {
    final offline = status == ConnectivityStatus.offline;
    return Material(
      // The bar draws its own colour; Material is here for the elevation
      // overlay against whatever screen is behind it.
      color: offline
          ? SkifluxColors.backgroundNegative
          : SkifluxColors.backgroundPositive,
      child: SafeArea(
        // Only the top inset: the bar hangs off the status bar, and taking the
        // bottom one would pad it by the home indicator for no reason.
        bottom: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceL,
            vertical: SkifluxSpacing.spaceXs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                offline ? RemixIcons.wifi_off_line : RemixIcons.wifi_line,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentPrimaryInverse,
              ),
              const SizedBox(width: SkifluxSpacing.spaceXs),
              Flexible(
                child: Text(
                  offline ? 'No internet connection' : 'Back online',
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
