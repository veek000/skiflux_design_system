import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../playlists/data/playlists_store.dart';
import 'add_bank_sheet.dart';
import 'data/wallet_store.dart';
import 'widgets/coin_widgets.dart';

// Figma: **Profile Flow 09 → 07** (`1256:24896` empty → `1256:24977` filled
// → `1256:25058` "Withdrawal initiated" sheet) — cash out SkillCoins.
// Balance banner, coin amount input (min 100 / Max), live conversion
// summary, withdrawal destination (saved bank + Add Bank Account), notice,
// pinned Withdraw button.

/// Minimum withdrawal per the Figma notice: 100 coins (₦600).
const int _kMinWithdrawCoins = 100;

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => WithdrawScreenState();
}

class WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountController = TextEditingController();
  int _coins = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(playlistsProvider).skillCoins;
    final bank = ref.watch(walletProvider).defaultBank;
    final naira = _coins * kCoinRateNaira;
    final valid =
        _coins >= _kMinWithdrawCoins && _coins <= balance && bank != null;

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
                  CoinBalanceCard(coins: balance),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Text(
                    'Amount to withdraw (coins)',
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _amountField(balance),
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  _minMaxRow(balance),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  CoinSummaryCard(
                    rows: [
                      CoinSummaryRow('Coins to withdraw', '$_coins'),
                      const CoinSummaryRow(
                        'Rate',
                        '1 coin = ₦$kCoinRateNaira',
                      ),
                    ],
                    totalLabel: 'You Receive',
                    total: '₦${CoinPack.thousands(naira)}'
                        '${naira == 0 ? '.0' : ''}',
                  ),
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
                  _notice(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: valid
                    ? 'Withdraw ₦${CoinPack.thousands(naira)}'
                    : 'Enter amount to withdraw',
                expanded: true,
                onPressed: valid ? () => withdraw(naira) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill input with the coin glyph leading and "Coins" trailing label.
  Widget _amountField(int balance) {
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

  /// "Min: 100 coins" · "Max" (fills the field with the full balance).
  Widget _minMaxRow(int balance) {
    return Row(
      children: [
        Text(
          'Min: $_kMinWithdrawCoins coins',
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            _amountController.text = '$balance';
            setState(() => _coins = balance);
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

  /// Notice-subtle info banner: processing time + minimum.
  Widget _notice() {
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
              'withdrawal is $_kMinWithdrawCoins coins '
              '(₦${CoinPack.thousands(_kMinWithdrawCoins * kCoinRateNaira)}).',
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

  Future<void> withdraw(int naira) async {
    try {
      final balance = ref.read(playlistsProvider).skillCoins;
      final bank = ref.read(walletProvider).defaultBank;
      final coins = _coins;
      if (bank == null || coins < _kMinWithdrawCoins || coins > balance) {
        throw const SkifluxFailure(SkifluxErrorKind.skillCoinWithdrawal);
      }
      // Deduct from the shared wallet + record the ledger entry.
      ref.read(playlistsProvider.notifier).withdraw(coins);
      ref.read(walletProvider.notifier).recordWithdrawal(
            coins,
            naira,
            bank.last4,
          );
      if (!mounted) return;
      await showWithdrawalSuccessSheet(
        context,
        coins: coins,
        naira: naira,
        bank: bank,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
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
/// check circle, title, routing copy, amount/deducted/new-balance summary,
/// Done.
Future<void> showWithdrawalSuccessSheet(
  BuildContext context, {
  required int coins,
  required int naira,
  required BankAccount bank,
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => _WithdrawalSuccessSheet(
      coins: coins,
      naira: naira,
      bank: bank,
    ),
  );
}

class _WithdrawalSuccessSheet extends ConsumerWidget {
  const _WithdrawalSuccessSheet({
    required this.coins,
    required this.naira,
    required this.bank,
  });

  final int coins;
  final int naira;
  final BankAccount bank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(playlistsProvider).skillCoins;
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
              'Withdrawal initiated',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              '₦${CoinPack.thousands(naira)} is on its way to your '
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
                CoinSummaryRow('Amount', '₦${CoinPack.thousands(naira)}'),
                CoinSummaryRow('Coins deducted', '-$coins'),
              ],
              totalLabel: 'New balance',
              totalCoins: balance,
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
