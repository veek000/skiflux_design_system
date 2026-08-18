import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/network/api_exception.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import 'data/models/supported_bank.dart';
import 'data/wallet_repository.dart';
import 'data/wallet_store.dart';

// Figma: **Profile Flow 06** (`2069:11204`) — "Add New Bank Account" sheet.
//
// Real flow: the bank picker is fed by `GET /wallet/withdrawals/banks`
// (gateway discovered via `GET /wallet/withdrawals/methods`), and
// Verify & Save runs `POST /wallet/withdrawals/accounts` — the *backend*
// performs the account-name verification against the gateway. The saved
// account (with its server id and verified holder name) becomes the
// wallet's default withdrawal destination. No bank names or holder names
// are invented client-side.

/// Figma's dialog avatar: a 98px circle around a 48px glyph. Neither size
/// exists on the token scale.
const double _avatarSize = 98;
const double _glyphSize = 48;

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
  SupportedBank? _bank;
  bool _numberValid = false;
  bool _busy = false;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(addBankOptionsProvider);
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
              style: SkifluxTypography.uiInputLabel.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            options.when(
              loading: () => _bankShell(
                child: Row(
                  children: [
                    const SizedBox(
                      width: SkifluxUnit.u20,
                      height: SkifluxUnit.u20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceS),
                    Text(
                      'Loading banks…',
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              error: (e, st) => _banksError(),
              data: (data) => data.banks.isEmpty
                  ? _banksError()
                  : _bankDropdown(data.banks),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              'Account Number',
              style: SkifluxTypography.uiInputLabel.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxInputField(
              controller: _numberController,
              hintText: '01234567890',
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  setState(() => _numberValid = value.trim().length >= 10),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: _busy ? 'Verifying…' : 'Verify & Save',
              expanded: true,
              onPressed:
                  _numberValid && _bank != null && !_busy ? _save : null,
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
                    text:
                        'The bank account name must exactly match your '
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

  /// The pill container the picker states share.
  Widget _bankShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceL,
        vertical: SkifluxSpacing.spaceM,
      ),
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderPill,
        border: Border.all(
          color: SkifluxColors.borderSecondary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: child,
    );
  }

  /// Banks couldn't be loaded — named error + retry; the list is never
  /// substituted with made-up banks.
  Widget _banksError() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        children: [
          Text(
            "We couldn't load the bank list. Please try again.",
            textAlign: TextAlign.center,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          SkifluxButton(
            label: 'Retry',
            size: SkifluxButtonSize.s,
            type: SkifluxButtonType.secondary,
            onPressed: () => ref.invalidate(addBankOptionsProvider),
          ),
        ],
      ),
    );
  }

  /// Pill-shaped bank picker fed by the gateway's own list.
  Widget _bankDropdown(List<SupportedBank> banks) {
    final value = _bank != null && banks.contains(_bank) ? _bank : null;
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
        child: DropdownButton<SupportedBank>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Choose your bank',
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
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
            for (final bank in banks)
              DropdownMenuItem(value: bank, child: Text(bank.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _bank = value);
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    final bank = _bank;
    final gateway = ref.read(addBankOptionsProvider).value?.gatewayName;
    try {
      final number = _numberController.text.trim();
      // Client-side format guard only; the *verification* is the backend's.
      if (bank == null ||
          gateway == null ||
          number.length < 10 ||
          !RegExp(r'^\d+$').hasMatch(number)) {
        throw const SkifluxFailure(SkifluxErrorKind.bankVerificationFailed);
      }
      setState(() => _busy = true);
      final saved = await ref
          .read(walletRepositoryProvider)
          .addWithdrawalAccount(
            bankCode: bank.code,
            accountNumber: number,
            gatewayName: gateway,
            bankName: bank.name,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      final account = BankAccount(
        id: saved.id,
        bankName: saved.bankName.isNotEmpty ? saved.bankName : bank.name,
        accountNumber: saved.accountNumber.isNotEmpty
            ? saved.accountNumber
            : number,
        // The holder name the *gateway* resolved — never typed client-side.
        holderName: saved.accountName.isNotEmpty
            ? saved.accountName
            : saved.displayName,
      );
      ref.read(walletProvider.notifier).addBank(account);
      Navigator.of(context).pop(account);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (_isNameMismatch(e)) {
        // The designed rejection state (`1256:20435`) for the backend's
        // name-match refusal.
        await showAccountMismatchSheet(context);
        return;
      }
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// True when the backend's rejection text names an account-name mismatch —
  /// the one failure with its own designed sheet. Everything else goes to
  /// the standard bankVerificationFailed modal.
  static bool _isNameMismatch(Object error) {
    if (error is! SkifluxFailure) return false;
    final cause = error.cause;
    if (cause is! ApiException) return false;
    final text = [
      cause.detail ?? '',
      for (final messages in cause.fieldErrors.values) ...messages,
    ].join(' ').toLowerCase();
    return text.contains('name') && text.contains('match');
  }
}

// Figma: **Account Name Mismatch** (`1256:20435`) — the verification-failed
// branch of Verify & Save. Red X circle, explanation, "Link Another Account"
// (dismiss and retry) over a "Contact Support" text action.
Future<void> showAccountMismatchSheet(BuildContext context) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => const _AccountMismatchSheet(),
  );
}

class _AccountMismatchSheet extends StatelessWidget {
  const _AccountMismatchSheet();

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Stack(
        children: [
          Padding(
            // Same dialog metrics as the confirm/success cards (`1256:20468`):
            // 16 at the top of the card, the label block inset a further 16
            // either side, the sticky button area carrying its own 16/8.
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.space2xl,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.space2xl,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: const BoxDecoration(
                      color: SkifluxColors.backgroundNegativeSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      RemixIcons.close_fill,
                      size: _glyphSize,
                      color: SkifluxColors.contentNegativeBold,
                    ),
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                Text(
                  'Account Name Mismatch',
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  'For your security, withdrawals can only be processed to a '
                  'bank account that exactly matches your verified Skiflux '
                  'profile. The account provided does not match. Please use an '
                  'account with your legal name, or reach out to support for a '
                  'profile update.',
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.bodyP8Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                SkifluxButton(
                  label: 'Link Another Account',
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                // Figma `I1256:20476;190:6566` is a secondary (border/tertiary)
                // button carrying a Content/Negative label — a pairing the
                // design system's button variants don't cover, so it's built
                // here from the same pill metrics.
                const _ContactSupportButton(),
              ],
            ),
          ),
          const Positioned(
            top: SkifluxSpacing.spaceL,
            right: SkifluxSpacing.spaceL,
            child: SkifluxSheetCloseButton(),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportButton extends StatelessWidget {
  const _ContactSupportButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        borderRadius: SkifluxRadii.borderPill,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          constraints: const BoxConstraints(minHeight: SkifluxUnit.u48),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: Border.all(
              color: SkifluxColors.borderTertiary,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Text(
            'Contact Support',
            textAlign: TextAlign.center,
            style: SkifluxTypography.uiButtonLarge.copyWith(
              color: SkifluxColors.contentNegative,
            ),
          ),
        ),
      ),
    );
  }
}
