import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../playlists/data/playlists_store.dart' show CoinPack, kCoinRateNaira;
import 'add_bank_sheet.dart';
import 'data/models/withdrawal_request.dart';
import 'data/wallet_repository.dart';
import 'data/wallet_store.dart';
import 'widgets/coin_widgets.dart';

// Figma: **Profile Flow 09 → 07** (`1256:24896` empty → `1256:24977` filled
// → `1256:25058` "Withdrawal initiated" sheet) — cash out SkillCoins.
//
// Real money flow: the ceiling is the backend wallet's hold-aware
// `withdrawable_balance` (Decimal, floored for whole-coin entry), a locked
// wallet can't withdraw at all, and confirming runs
// `POST /wallet/withdrawals/request {account_id, amount}`. The success sheet
// renders only the 201 response's own amount / fee / net figures.

/// Client-side minimum per the Figma notice: 100 coins. The backend enforces
/// the real `min_withdrawal_amount`; a rejection surfaces as the withdrawal
/// modal.
const int _kMinWithdrawCoins = 100;

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => WithdrawScreenState();
}

class WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountController = TextEditingController();
  int _coins = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The withdrawable ceiling and saved accounts come from the backend.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refreshFromBackend();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final bank = wallet.defaultBank;
    final maxCoins = wallet.wholeWithdrawableCoins;
    final feeAsync = ref.watch(withdrawalFeePercentProvider);
    final feePercent = feeAsync.value;
    final valid = !_busy &&
        wallet.balanceKnown &&
        !wallet.isLocked &&
        _coins >= _kMinWithdrawCoins &&
        _coins <= maxCoins &&
        bank?.id != null;

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Withdraw',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                children: [
                  if (wallet.balanceKnown)
                    CoinBalanceCard(coins: wallet.wholeCoins)
                  else if (wallet.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(SkifluxSpacing.spaceL),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _balanceUnavailable(),
                  if (wallet.isLocked) ...[
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    _lockedBanner(),
                  ],
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Text(
                    'Amount to withdraw (coins)',
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _amountField(),
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  _minMaxRow(maxCoins),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _summaryCard(feePercent),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Text(
                    'Withdrawal destination',
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _DestinationCard(bank: bank, onAddBank: _addBank),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  _notice(feePercent),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: _busy
                    ? 'Submitting request…'
                    : valid
                        ? 'Withdraw $_coins coins'
                        : 'Enter amount to withdraw',
                expanded: true,
                onPressed: valid ? withdraw : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Conversion summary. Coin figures are exact; the naira line is an
  /// estimate (≈) — the authoritative fee/net come from the backend response.
  Widget _summaryCard(Decimal? feePercent) {
    final amount = Decimal.fromInt(_coins);
    Decimal? feeEstimate;
    Decimal? netEstimate;
    if (feePercent != null) {
      feeEstimate = (amount * feePercent / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);
      netEstimate = amount - feeEstimate;
    }
    final receiveCoins = netEstimate ?? amount;
    final approxNaira =
        (receiveCoins * Decimal.fromInt(kCoinRateNaira));
    return CoinSummaryCard(
      rows: [
        CoinSummaryRow('Coins to withdraw', '$_coins'),
        if (feePercent != null)
          CoinSummaryRow(
            'Fee (${CoinPack.thousandsOf(feePercent)}%)',
            '≈ −${CoinPack.thousandsOf(feeEstimate!)}',
          )
        else
          const CoinSummaryRow('Fee', 'Confirmed on submission'),
        CoinSummaryRow(
          'Estimated value',
          '≈ ₦${CoinPack.thousandsOf(approxNaira)}',
        ),
      ],
      totalLabel: 'You Receive',
      total:
          '${feePercent != null ? '≈ ' : ''}'
          '${CoinPack.thousandsOf(receiveCoins)} coins',
    );
  }

  /// Pill input with the coin glyph leading and "Coins" trailing label.
  Widget _amountField() {
    return SkifluxInputField(
      controller: _amountController,
      hintText: '0',
      keyboardType: TextInputType.number,
      leadingIcon: const Icon(
        RemixIcons.copper_coin_fill,
        size: SkifluxIcons.sizeS,
        color: SkifluxColors.contentNotice,
      ),
      trailingIcon: Padding(
        padding: const EdgeInsets.only(right: SkifluxSpacing.spaceXs),
        child: Text(
          'Coins',
          style: SkifluxTypography.bodyP10Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
      ),
      onChanged: (value) {
        setState(() => _coins = int.tryParse(value.trim()) ?? 0);
      },
    );
  }

  /// "Min: 100 coins" · withdrawable ceiling · "Max" (fills the field with
  /// the real withdrawable whole-coin balance).
  Widget _minMaxRow(int maxCoins) {
    return Row(
      children: [
        Text(
          'Min: $_kMinWithdrawCoins coins · '
          'Withdrawable: ${CoinPack.thousands(maxCoins)}',
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            _amountController.text = '$maxCoins';
            setState(() => _coins = maxCoins);
          },
          child: Text(
            'Max',
            style: SkifluxTypography.uiButtonSmall.copyWith(
              color: SkifluxColors.contentBrand,
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceUnavailable() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        children: [
          Text(
            "We couldn't load your balance. Withdrawals need a live "
            'balance check.',
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
            onPressed: () =>
                ref.read(walletProvider.notifier).refreshFromBackend(),
          ),
        ],
      ),
    );
  }

  Widget _lockedBanner() {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            RemixIcons.lock_2_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentNegative,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'Your wallet is locked, so withdrawals are unavailable. '
              'Contact support for help.',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Notice-subtle info banner: processing time + minimum + fee honesty.
  Widget _notice(Decimal? feePercent) {
    final feeLine = feePercent == null
        ? 'The exact processing fee is applied by the backend and shown '
          'in your confirmation.'
        : 'A ${CoinPack.thousandsOf(feePercent)}% processing fee applies.';
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
            child: Text(
              'Withdrawals are processed within 24 hours. Minimum '
              'withdrawal is $_kMinWithdrawCoins coins. $feeLine',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addBank() async {
    final account = await showAddBankSheet(context);
    if (account != null && mounted) setState(() {});
  }

  /// Submits the real withdrawal request. Success UI only on the 201, and it
  /// renders the response's own figures.
  Future<void> withdraw() async {
    try {
      final wallet = ref.read(walletProvider);
      final bank = wallet.defaultBank;
      final coins = _coins;
      final accountId = bank?.id;
      if (accountId == null ||
          !wallet.balanceKnown ||
          wallet.isLocked ||
          coins < _kMinWithdrawCoins ||
          coins > wallet.wholeWithdrawableCoins) {
        throw const SkifluxFailure(SkifluxErrorKind.skillCoinWithdrawal);
      }
      setState(() => _busy = true);
      final request = await ref
          .read(walletRepositoryProvider)
          .requestWithdrawal(
            accountId: accountId,
            amount: Decimal.fromInt(coins),
          );
      if (!mounted) return;
      setState(() => _busy = false);
      // Ledger row from the backend's own response; then re-read the wallet
      // so the hold-adjusted balances replace the local mirror.
      ref.read(walletProvider.notifier).recordWithdrawalRequest(request);
      unawaited(ref.read(walletProvider.notifier).refreshFromBackend());
      await showWithdrawalSuccessSheet(context, request: request, bank: bank!);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }
}

/// Saved-bank + "Add Bank Account" card (`1256:24940`).
class _DestinationCard extends ConsumerWidget {
  const _DestinationCard({required this.bank, required this.onAddBank});

  final BankAccount? bank;
  final VoidCallback onAddBank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: SkifluxRadii.borderL),
      foregroundDecoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Column(
        children: [
          if (bank != null) ...[
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: SkifluxColors.backgroundPositiveSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      RemixIcons.bank_fill,
                      size: SkifluxUnit.u20,
                      color: SkifluxColors.contentPositiveBold,
                    ),
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank!.bankName,
                          style: SkifluxTypography.headingH10Bold.copyWith(
                            color: SkifluxColors.contentSecondary,
                          ),
                        ),
                        const SizedBox(height: SkifluxSpacing.space2xs),
                        Text(
                          '${bank!.holderName} ·· ${bank!.last4}',
                          style: SkifluxTypography.bodyP11Regular.copyWith(
                            color: SkifluxColors.contentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Single saved destination — always the selected one.
                  SkifluxRadio<bool>(
                    value: true,
                    groupValue: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            const Divider(
              height: SkifluxBorderWidth.xs,
              thickness: SkifluxBorderWidth.xs,
              color: SkifluxColors.borderTertiary,
            ),
          ],
          InkWell(
            onTap: onAddBank,
            child: Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: SkifluxColors.backgroundSelected,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      RemixIcons.add_line,
                      size: SkifluxUnit.u20,
                      color: SkifluxColors.contentBrand,
                    ),
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceL),
                  Text(
                    'Add Bank Account',
                    style: SkifluxTypography.uiButtonLarge.copyWith(
                      color: SkifluxColors.contentBrand,
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
}

/// "Withdrawal initiated" sheet (`1256:25058`): headerless card — green
/// check circle, title, routing copy, and a summary built from the 201
/// response's own amount / fee / net figures. Naira is an estimate (≈).
Future<void> showWithdrawalSuccessSheet(
  BuildContext context, {
  required WithdrawalRequest request,
  required BankAccount bank,
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => _WithdrawalSuccessSheet(request: request, bank: bank),
  );
}

class _WithdrawalSuccessSheet extends ConsumerWidget {
  const _WithdrawalSuccessSheet({required this.request, required this.bank});

  final WithdrawalRequest request;
  final BankAccount bank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netCoins = request.netAmount;
    final approxNaira = netCoins * Decimal.fromInt(kCoinRateNaira);
    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          // Headerless card — clear the grabber pill (top 8px + 4px tall).
          SkifluxSpacing.space2xl,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPositiveSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.check_fill,
                  size: 48,
                  color: SkifluxColors.contentPositive,
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              'Withdrawal requested',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              '${CoinPack.thousandsOf(netCoins)} coins '
              '(≈ ₦${CoinPack.thousandsOf(approxNaira)}) are headed to your '
              '${bank.bankName} account ending in ${bank.last4}. This '
              'usually takes up to 24 hours.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            CoinSummaryCard(
              filled: true,
              rows: [
                CoinSummaryRow(
                  'Coins withdrawn',
                  '-${CoinPack.thousandsOf(request.amount)}',
                ),
                if (request.fee != null)
                  CoinSummaryRow(
                    'Fee',
                    '-${CoinPack.thousandsOf(request.fee!)}',
                  ),
                CoinSummaryRow(
                  'You receive',
                  '${CoinPack.thousandsOf(netCoins)} coins',
                ),
              ],
              totalLabel: 'New balance',
              totalCoins: ref.watch(walletProvider).wholeCoins,
            ),
            const SizedBox(height: SkifluxSpacing.spaceXl),
            SkifluxButton(
              label: 'Done',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
