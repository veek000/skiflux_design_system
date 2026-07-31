import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/confirm_sheet.dart';
import '../../shared/sheets/success_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import 'add_card_sheet.dart';
import 'data/payment_store.dart';
import 'widgets/settings_tile.dart';

// Figma: **Settings → Payment Methods** (`1256:19943`) — saved cards used to
// buy SkillCoins, each with a red remove control, plus "Add New Card".
//
// Backed by the real card vault: the list is `GET /wallet/cards`, removal is
// `DELETE /wallet/cards/{id}` (confirm sheet → backend → "Card Removed"
// success only after the 2xx), and adding routes through the spec's hosted
// save-card flow — "Card Saved!" appears only when the refreshed vault
// actually contains a new card.

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(savedCardsProvider);

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
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentDisabled,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            ...cardsAsync.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(SkifluxSpacing.space2xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, st) => [
                _CardsErrorState(
                  onRetry: () =>
                      ref.read(savedCardsProvider.notifier).refresh(),
                ),
              ],
              data: (cards) => [
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: SkifluxSpacing.spaceL,
                    ),
                    child: Text(
                      'No saved cards yet.',
                      style: SkifluxTypography.bodyP8Regular.copyWith(
                        color: SkifluxColors.contentTertiary,
                      ),
                    ),
                  )
                else ...[
                  SettingsSection(
                    label: 'Saved Cards',
                    children: [
                      for (final card in cards)
                        SettingsTile(
                          icon: card.logo,
                          iconBackground: SkifluxColors.brand100,
                          iconColor: SkifluxColors.contentBrand,
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
              ],
            ),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: RemixIcons.add_fill,
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

  /// Confirm → `DELETE /wallet/cards/{id}` → success sheet only after the
  /// backend accepted (the notifier rolls the row back on failure).
  Future<void> _removeCard(
    BuildContext context,
    WidgetRef ref,
    SavedCard card,
  ) async {
    try {
      final confirmed = await showConfirmSheet(
        context,
        title: 'Remove Card?',
        message:
            'Are you sure you want to remove this ${card.brandLabel} '
            'ending in ${card.last4}?',
        confirmLabel: 'Remove',
        icon: RemixIcons.delete_bin_fill,
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(savedCardsProvider.notifier).remove(card);
      if (!context.mounted) return;
      await showSuccessSheet(
        context,
        title: 'Card Removed',
        message:
            '${card.brandLabel} ending in ${card.last4} has been removed '
            'from your payment methods.',
      );
    } catch (e, st) {
      if (!context.mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// Hosted add-card hand-off. Success UI only when the refreshed vault
  /// actually gained a card; otherwise an honest "not there yet" notice.
  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    try {
      final before = ref.read(savedCardsProvider).value?.length ?? 0;
      final returned = await showAddCardSheet(context);
      if (returned != true || !context.mounted) return;
      final after = ref.read(savedCardsProvider).value?.length ?? 0;
      if (after > before) {
        await showSuccessSheet(
          context,
          title: 'Card Saved!',
          message:
              'Your new card has been securely added to your payment '
              'methods.',
        );
      } else {
        SkifluxToast.info(
          context,
          'No new card yet. Finish verification in your browser, then '
          'pull to refresh.',
        );
      }
    } catch (e, st) {
      if (!context.mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }
}

/// Vault read failed — named error + retry; no sample cards.
class _CardsErrorState extends StatelessWidget {
  const _CardsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SkifluxSpacing.spaceL),
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        children: [
          Text(
            "We couldn't load your saved cards. Please try again.",
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
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
