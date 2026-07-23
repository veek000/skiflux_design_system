import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/success_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../wallet/add_bank_sheet.dart';
import '../wallet/data/wallet_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Bank Accounts / Withdrawal accounts** (`1256:19981`) —
// saved withdrawal destinations with a red remove control and "Add new bank
// account". Adding routes through the Add New Bank Account sheet → "Bank
// Account Saved" success (`1256:20393`). Shares [walletProvider] with the
// Withdraw screen so the default destination stays in sync.

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(walletProvider).banks;

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Bank Accounts',
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
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            Text(
              'Add and manage the bank accounts where you withdraw your '
              'SkillCoin earnings.',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            if (banks.isNotEmpty) ...[
              SettingsSection(
                label: 'Saved Accounts',
                children: [
                  for (final bank in banks)
                    SettingsTile(
                      icon: RemixIcons.bank_fill,
                      iconBackground: SkifluxColors.brand100,
                      iconColor: SkifluxColors.contentBrand,
                      title: bank.bankName,
                      subtitle: '${bank.holderName} ·· ${bank.last4}',
                      trailing: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          RemixIcons.delete_bin_fill,
                          size: SkifluxIcons.sizeM,
                          color: SkifluxColors.contentNegative,
                        ),
                        onPressed: () {
                          ref.read(walletProvider.notifier).removeBank(bank);
                          SkifluxToast.info(context, 'Bank account removed');
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
            ],
            SettingsSection(
              children: [
                SettingsTile(
                  icon: RemixIcons.add_line,
                  iconBackground: SkifluxColors.brand100,
                  iconColor: SkifluxColors.contentBrand,
                  title: 'Add new bank account',
                  titleColor: SkifluxColors.contentBrand,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _addBank(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBank(BuildContext context, WidgetRef ref) async {
    final account = await showAddBankSheet(context);
    if (account == null || !context.mounted) return;
    await showSuccessSheet(
      context,
      title: 'Bank Account Saved',
      message: 'Your withdrawal account has been verified and added '
          'successfully.',
    );
  }
}
