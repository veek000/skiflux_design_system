import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../playlists/data/playlists_store.dart';

// Shared money-flow widgets, used by both the Buy Coins modal sheet
// (`home/sheets/buy_coins_sheet.dart`, Other Video Player Flow 04) and the
// full-screen wallet flows (`wallet/`, Profile Flow 02–07). Extracted so the
// pack cards, balance banner, payment selector, and summary card render
// identically in both places.

/// Current-balance banner (brand-tinted): "Current Balance" + coin figure.
/// Figma `1256:27600` / `1256:24230`.
class CoinBalanceCard extends StatelessWidget {
  const CoinBalanceCard({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundSelected,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        children: [
          Text(
            'Current Balance',
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          const Spacer(),
          const Icon(
            RemixIcons.copper_coin_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentNotice,
          ),
          const SizedBox(width: SkifluxSpacing.spaceXs),
          Text(
            CoinPack.thousands(coins),
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentNotice,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single coin pack tile (`1256:27622`…). Tap selects it; the selected tile
/// gets the brand border + selected fill.
class CoinPackCard extends StatelessWidget {
  const CoinPackCard({
    super.key,
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final CoinPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        decoration: BoxDecoration(
          color: selected
              ? SkifluxColors.backgroundSelected
              : SkifluxColors.backgroundPrimary,
          borderRadius: SkifluxRadii.borderL,
          border: Border.all(
            color: selected
                ? SkifluxColors.contentBrand
                : SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${pack.coins}',
                    style: SkifluxTypography.headingH10Bold.copyWith(
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                ),
                if (pack.badgeLabel != null) CoinPackBadgePill(pack: pack),
              ],
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              'SkillCoins',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              pack.priceLabel,
              style: SkifluxTypography.headingH10Bold.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coin-pack badge pill (Best Value / Save N%).
class CoinPackBadgePill extends StatelessWidget {
  const CoinPackBadgePill({super.key, required this.pack});

  final CoinPack pack;

  @override
  Widget build(BuildContext context) {
    final isBest = pack.badge == CoinPackBadge.bestValue;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: isBest
            ? SkifluxColors.backgroundNoticeSubtle
            : SkifluxColors.backgroundPositiveSubtle,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        pack.badgeLabel!,
        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
          color: isBest
              ? SkifluxColors.contentNoticeBold
              : SkifluxColors.contentPositiveBold,
        ),
      ),
    );
  }
}
/// Card / Bank Transfer payment picker (`1256:27722`). A bordered card with
/// two selectable rows; [cardSelected] true → Card, false → Bank Transfer.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.cardSelected,
    required this.onChanged,
  });

  /// true = Card Payment, false = Bank Transfer.
  final bool cardSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _row(
            isCard: true,
            selected: cardSelected,
            icon: RemixIcons.bank_card_2_fill,
            iconBg: SkifluxColors.backgroundSelected,
            iconColor: SkifluxColors.contentBrand,
            label: 'Card Payment',
            divider: true,
          ),
          _row(
            isCard: false,
            selected: !cardSelected,
            icon: RemixIcons.bank_fill,
            iconBg: SkifluxColors.backgroundInfoSubtle,
            iconColor: SkifluxColors.contentInfoBold,
            label: 'Bank Transfer',
            divider: false,
          ),
        ],
      ),
    );
  }

  Widget _row({
    required bool isCard,
    required bool selected,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required bool divider,
  }) {
    return GestureDetector(
      onTap: () => onChanged(isCard),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        decoration: BoxDecoration(
          border: divider
              ? const Border(
                  bottom: BorderSide(
                    color: SkifluxColors.borderTertiary,
                    width: SkifluxBorderWidth.xs,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: SkifluxUnit.u20, color: iconColor),
            ),
            const SizedBox(width: SkifluxSpacing.spaceL),
            Expanded(
              child: Text(
                label,
                style: SkifluxTypography.headingH10Bold.copyWith(
                  color: SkifluxColors.contentSecondary,
                ),
              ),
            ),
            SkifluxRadio<bool>(
              value: isCard,
              groupValue: cardSelected,
              onChanged: (v) => onChanged(v),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label/value line in a [CoinSummaryCard]. When [emphasizeCoins], the
/// value renders as an amber coin figure with a coin glyph.
class CoinSummaryRow {
  const CoinSummaryRow(this.label, this.value, {this.emphasizeCoins = false});

  final String label;
  final String value;
  final bool emphasizeCoins;
}

/// Amount / rate / total breakdown card (Flow 03 payment + Flow 02 success,
/// also reused for withdrawal). [filled] uses the grey success style with no
/// border; otherwise it's a bordered white card.
class CoinSummaryCard extends StatelessWidget {
  const CoinSummaryCard({
    super.key,
    required this.rows,
    this.total,
    this.totalLabel,
    this.totalCoins,
    this.filled = false,
  });

  final List<CoinSummaryRow> rows;

  /// Plain-text total (payment view).
  final String? total;

  /// Coin-figure total (success view: "New balance").
  final String? totalLabel;
  final int? totalCoins;

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: filled
            ? SkifluxColors.backgroundHover
            : SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderL,
        border: filled
            ? null
            : Border.all(
                color: SkifluxColors.borderTertiary,
                width: SkifluxBorderWidth.xs,
              ),
      ),
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == rows.length - 1 ? 0 : SkifluxSpacing.spaceS,
              ),
              child: _line(rows[i]),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceS),
            child: Divider(
              height: SkifluxBorderWidth.xs,
              thickness: SkifluxBorderWidth.xs,
              color: SkifluxColors.borderTertiary,
            ),
          ),
          _totalLine(),
        ],
      ),
    );
  }

  Widget _line(CoinSummaryRow row) {
    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
        ),
        if (row.emphasizeCoins)
          _coinValue(row.value)
        else
          Text(
            row.value,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
      ],
    );
  }

  Widget _totalLine() {
    return Row(
      children: [
        Expanded(
          child: Text(
            totalLabel ?? 'Total',
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
        ),
        if (totalCoins != null)
          _coinValue(CoinPack.thousands(totalCoins!))
        else
          Text(
            total ?? '',
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
      ],
    );
  }

  Widget _coinValue(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          RemixIcons.copper_coin_fill,
          size: SkifluxUnit.u20,
          color: SkifluxColors.contentNotice,
        ),
        const SizedBox(width: SkifluxSpacing.spaceXs),
        Text(
          value,
          style: SkifluxTypography.headingH10Bold.copyWith(
            color: SkifluxColors.contentNotice,
          ),
        ),
      ],
    );
  }
}

