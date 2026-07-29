/// The "we couldn't load this" panel, shared by every screen that reads from
/// the API.
///
/// It exists because the alternative screens used to take was to fall back to
/// seeded sample content: the request failed, the user saw a plausible feed /
/// balance / streak, and had no way to tell it apart from the real thing or
/// any way to retry. This says what happened and offers the retry instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../error_handling/error_handler.dart';

class LoadFailure extends ConsumerWidget {
  const LoadFailure({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = "We couldn't load this",
    this.icon = RemixIcons.wifi_off_line,
  });

  /// Whatever the provider threw. Copy comes from [ErrorHandler.classify], so
  /// this never puts an exception string in front of the user.
  final Object error;

  final VoidCallback onRetry;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classified = ref.read(errorHandlerProvider).classify(error);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkifluxEmptyState(
              icon: Icon(
                icon,
                size: SkifluxEmptyState.iconSize,
                color: SkifluxColors.contentBrand,
              ),
              title: title,
              message: classified.message,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceL,
              ),
              child: SkifluxButton(
                label: 'Try again',
                type: SkifluxButtonType.secondary,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
