import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/sheets/success_sheet.dart';
import 'add_card_sheet.dart';
import 'data/payment_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Payment Methods** (`1256:19943`) — saved cards used to
// buy SkillCoins, each with a red remove control, plus "Add New Card". Removing
// routes through "Remove Card?" (`1256:20587`) → "Card Removed" success
// (`1256:20639`); adding routes through the sheet → "Card Saved!" success
// (`1256:20535`).

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(paymentCardsProvider);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Payment Methods',
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
              'Manage the debit and credit cards you use to buy SkillCoins.',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            if (cards.isNotEmpty) ...[
              SettingsSection(
                label: 'Saved Cards',
                children: [
                  for (final card in cards)
                    SettingsTile(
                      icon: RemixIcons.bank_card_fill,
                      iconBackground: card.tint,
                      iconColor: card.glyph,
                      title: card.title,
                      subtitle: card.subtitle,
                      trailing: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          RemixIcons.delete_bin_fill,
                          size: SkifluxIcons.sizeM,
                          color: SkifluxColors.contentNegative,
                        ),
                        onPressed: () => _removeCard(context, ref, card),
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
                  title: 'Add New Card',
                  titleColor: SkifluxColors.contentBrand,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _addCard(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeCard(
    BuildContext context,
    WidgetRef ref,
    SavedCard card,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Remove Card?',
      message: 'Are you sure you want to remove this ${card.brand.label} '
          'ending in ${card.last4}?',
      confirmLabel: 'Remove',
      icon: RemixIcons.delete_bin_fill,
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(paymentCardsProvider.notifier).removeCard(card);
    await showSuccessSheet(
      context,
      title: 'Card Removed',
      message: '${card.brand.label} ending in ${card.last4} has been removed '
          'from your payment methods.',
    );
  }

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final card = await showAddCardSheet(context);
    if (card == null || !context.mounted) return;
    await showSuccessSheet(
      context,
      title: 'Card Saved!',
      message: 'Your new card has been securely added to your payment '
          'methods.',
    );
  }
}
