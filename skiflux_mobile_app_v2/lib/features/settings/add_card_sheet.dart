import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/utils/external_link.dart';
import '../wallet/data/cards_repository.dart';
import '../wallet/data/topup_repository.dart';
import 'data/payment_store.dart';

// Figma: **Settings → Add New Card** sheet (`1256:20477`).
//
// PCI honesty: the app never collects a card number, expiry, or CVV. Per the
// spec, `POST /wallet/cards/add` returns a gateway-hosted checkout URL where
// the card is entered (Paystack charges a small refunded verification
// amount; Stripe uses a no-charge setup session) — only the token and masked
// details are ever stored. This sheet is the hand-off to that hosted page,
// then refreshes the saved-card list.
//
// Resolves with `true` when the user came back and the list was refreshed;
// null when they backed out.

Future<bool?> showAddCardSheet(BuildContext context) {
  return showSkifluxSheet<bool>(
    context: context,
    builder: (_) => const _AddCardSheet(),
  );
}

class _AddCardSheet extends ConsumerStatefulWidget {
  const _AddCardSheet();

  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  bool _busy = false;

  /// True once the checkout URL has been handed off to the browser.
  bool _handedOff = false;

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Add New Card',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _secureBanner(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              _handedOff
                  ? 'Finish adding your card on the secure page, then come '
                        'back here and tap "I\'ve added my card".'
                  : 'You\'ll be taken to our payment provider\'s secure page '
                        'to enter your card details. A small verification '
                        'charge may apply and is refunded automatically.',
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            if (!_handedOff)
              SkifluxButton(
                label: _busy
                    ? 'Preparing secure page…'
                    : 'Continue to Secure Page',
                expanded: true,
                onPressed: _busy ? null : _startHostedFlow,
              )
            else ...[
              SkifluxButton(
                label: _busy ? 'Refreshing…' : "I've added my card",
                expanded: true,
                onPressed: _busy ? null : _confirmReturn,
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              SkifluxButton(
                label: 'Cancel',
                type: SkifluxButtonType.secondary,
                expanded: true,
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Honest security banner: the card is entered on the gateway's page, not
  /// in this app.
  Widget _secureBanner() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPositiveSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        children: [
          const Icon(
            RemixIcons.lock_2_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentPositiveBold,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'Your card details are entered on the payment provider\'s '
              'secure page — Skiflux never sees or stores your card number.',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `POST /wallet/cards/add` → open the returned checkout URL.
  Future<void> _startHostedFlow() async {
    setState(() => _busy = true);
    try {
      final checkoutUrl = await ref
          .read(cardsRepositoryProvider)
          .startAddCard(gatewayName: _preferredGateway());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _handedOff = true;
      });
      await openExternalUrl(context, checkoutUrl);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// Re-reads the card vault; the caller decides whether a new card actually
  /// appeared — nothing here claims success on its own.
  Future<void> _confirmReturn() async {
    setState(() => _busy = true);
    await ref.read(savedCardsProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  /// Gateway for `AddCardRequest.gateway_name` (required by the spec).
  /// Best-effort from the cached top-up methods discovery payload; the
  /// documented server default (paystack) otherwise.
  String _preferredGateway() {
    final methods = ref.read(topupMethodsProvider).value;
    if (methods != null) {
      for (final key in const ['enabled_topup_gateways', 'gateways']) {
        final list = methods[key];
        if (list is List) {
          for (final entry in list) {
            if (entry is String && entry.isNotEmpty) return entry;
            if (entry is Map) {
              final name = entry['name'] ?? entry['gateway_name'];
              if (name is String && name.isNotEmpty) return name;
            }
          }
        }
      }
    }
    return 'paystack';
  }
}
