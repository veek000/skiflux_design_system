import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/payment_store.dart';

// Figma: **Settings → Add New Card** sheet (`1256:20477`) — Cardholder Name,
// Card Number, Expiry Date + CVV, an encrypted-details reassurance banner, and
// "Save Card Details". Saves to [paymentCardsProvider] and resolves with the
// new card.

Future<SavedCard?> showAddCardSheet(BuildContext context) {
  return showSkifluxSheet<SavedCard>(
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
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  bool get _valid {
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    return _name.text.trim().isNotEmpty &&
        digits.length >= 15 &&
        _expiry.text.trim().length >= 4 &&
        _cvv.text.trim().length >= 3;
  }

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
            _label('Cardholder Name'),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxInputField(
              controller: _name,
              hintText: 'e.g John Doe',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _label('Card Number'),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxInputField(
              controller: _number,
              hintText: '0000 0000 0000 0000',
              keyboardType: TextInputType.number,
              trailingIcon: const Icon(
                RemixIcons.bank_card_fill,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentTertiary,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Expiry Date'),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      SkifluxInputField(
                        controller: _expiry,
                        hintText: 'MM/YY',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SkifluxSpacing.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('CVV'),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      SkifluxInputField(
                        controller: _cvv,
                        hintText: 'e.g 123',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _encryptedBanner(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Save Card Details',
              expanded: true,
              onPressed: _valid ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: SkifluxTypography.headingH9Bold.copyWith(
        color: SkifluxColors.contentPrimary,
      ),
    );
  }

  /// Green "your details are encrypted" reassurance banner.
  Widget _encryptedBanner() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPositiveSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        children: [
          const Icon(
            RemixIcons.lock_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentPositive,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'Your payment details are encrypted and secure.',
              style: SkifluxTypography.bodyP11Regular.copyWith(
                color: SkifluxColors.contentPositive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    // Infer the network from the leading digit (demo — real apps use a BIN
    // lookup): 4 → Visa, 5 → Mastercard, else Verve.
    final brand = switch (digits.isEmpty ? '' : digits[0]) {
      '4' => CardBrand.visa,
      '5' => CardBrand.mastercard,
      _ => CardBrand.verve,
    };
    final card = SavedCard(
      brand: brand,
      last4: digits.substring(digits.length - 4),
      expiry: _expiry.text.trim(),
    );
    ref.read(paymentCardsProvider.notifier).addCard(card);
    Navigator.of(context).pop(card);
  }
}
