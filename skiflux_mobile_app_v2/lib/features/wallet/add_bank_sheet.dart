import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/wallet_store.dart';

// Figma: **Profile Flow 06** (`2069:11204`) — "Add New Bank Account" sheet.
// Important-note banner, Select Bank dropdown, Account Number input,
// Verify & Save. Saves the account as the wallet's default withdrawal
// destination and resolves with it.

/// Demo bank list for the dropdown (no bank API yet).
const List<String> _kBanks = [
  'GT Bank',
  'Access Bank',
  'Zenith Bank',
  'First Bank',
  'UBA',
  'Kuda',
];

Future<BankAccount?> showAddBankSheet(BuildContext context) {
  return showSkifluxSheet<BankAccount>(
    context: context,
    builder: (_) => const _AddBankSheet(),
  );
}

class _AddBankSheet extends ConsumerStatefulWidget {
  const _AddBankSheet();

  @override
  ConsumerState<_AddBankSheet> createState() => _AddBankSheetState();
}

class _AddBankSheetState extends ConsumerState<_AddBankSheet> {
  final _numberController = TextEditingController();
  String _bank = _kBanks.first;
  bool _numberValid = false;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Add New Bank Account',
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
            _noteBanner(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              'Select Bank',
              style: SkifluxTypography.headingH9Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            _bankDropdown(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              'Account Number',
              style: SkifluxTypography.headingH9Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxInputField(
              controller: _numberController,
              hintText: '01234567890',
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(
                () => _numberValid = value.trim().length >= 10,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Verify & Save',
              expanded: true,
              onPressed: _numberValid ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Notice banner: name-match requirement.
  Widget _noteBanner() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNoticeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            RemixIcons.information_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentNoticeBold,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Important: ',
                    style: SkifluxTypography.bodyP10Semibold.copyWith(
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                  TextSpan(
                    text: 'The bank account name must exactly match your '
                        'Skiflux profile name to be saved and used for '
                        'withdrawals.',
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pill-shaped bank picker matching the input-field look.
  Widget _bankDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceL,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderPill,
        border: Border.all(
          color: SkifluxColors.borderSecondary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _bank,
          isExpanded: true,
          icon: const Icon(
            RemixIcons.arrow_down_s_line,
            size: SkifluxIcons.sizeM,
            color: SkifluxColors.contentPrimary,
          ),
          style: SkifluxTypography.bodyP10Regular.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
          borderRadius: SkifluxRadii.borderL,
          items: [
            for (final bank in _kBanks)
              DropdownMenuItem(value: bank, child: Text(bank)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _bank = value);
          },
        ),
      ),
    );
  }

  void _save() {
    final account = BankAccount(
      bankName: _bank,
      accountNumber: _numberController.text.trim(),
      // Demo identity — matches the profile header.
      holderName: 'Amara Design',
    );
    ref.read(walletProvider.notifier).addBank(account);
    Navigator.of(context).pop(account);
  }
}
