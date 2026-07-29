/// Figma: **Profile Flow 18** (`3664:13258`) — one ledger entry in full,
/// reached by tapping a row on the wallet's transaction list.
///
/// Two stacked cards: a grey summary (type, coin figure, naira conversion)
/// and a bordered detail table whose last row carries a copy control. The
/// frame's example is a 1,240-coin purchase; every value here comes from the
/// tapped [CoinTxn], and rows the entry has no value for are dropped rather
/// than shown empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/toast/skiflux_toast.dart';
import '../playlists/data/playlists_store.dart' show CoinPack, kCoinRateNaira;
import 'data/wallet_store.dart';

/// Figma draws the coin at 42.243 × 40 (`3664:13267`) — the asset's own
/// aspect ratio, not a token size.
const double _coinWidth = 42.243;
const double _coinHeight = 40;

/// `3664:13269`: the amount sits at an untokenised 26.667.
const double _amountSize = 26.667;

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key, required this.txn});

  final CoinTxn txn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Transaction details',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Balances the 24px back chevron so the title stays centred.
        trailing: const SizedBox(width: SkifluxIcons.sizeM),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                _SummaryCard(txn: txn),
                const SizedBox(height: SkifluxSpacing.spaceL),
                _DetailCard(txn: txn),
              ],
            ),
          ),
          // Sticky rail, same idiom as the submission/withdraw screens.
          Material(
            color: SkifluxColors.backgroundPrimary,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceS,
                ),
                child: SkifluxButton(
                  label: 'Report Transaction',
                  type: SkifluxButtonType.secondary,
                  expanded: true,
                  // TODO(backend, blocking): open a dispute for this entry — expects: POST /wallet/transactions/{reference}/report → {caseId}
                  onPressed: () => SkifluxToast.info(
                    context,
                    'Reporting is coming soon. Contact support for now.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `3664:13261` — grey card: transaction type, coin asset + amount, and the
/// naira conversion under it.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.txn});

  final CoinTxn txn;

  @override
  Widget build(BuildContext context) {
    final coins = txn.delta.abs();
    final naira = coins * kCoinRateNaira;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundDisabled,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        children: [
          Text(
            txn.typeLabel,
            style: SkifluxTypography.uiInputLabel.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/wallet/skillcoin.svg',
                width: _coinWidth,
                height: _coinHeight,
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Text(
                CoinPack.thousands(coins),
                style: SkifluxTypography.headingH6Bold.copyWith(
                  // Figma hard-codes #DBA506 here, which is `Content/Notice`.
                  color: SkifluxColors.contentNotice,
                  fontSize: _amountSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            '≈ ₦${CoinPack.thousands(naira)} · 1 coin = ₦$kCoinRateNaira',
            style: SkifluxTypography.uiInputContent.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// `3664:13437` — bordered table of label/value rows. The Transaction ID row
/// is last and carries the copy control.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.txn});

  final CoinTxn txn;

  /// Figma prints "07/21/2026 06:53:20 PM".
  static String _stamp(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final meridiem = at.hour < 12 ? 'AM' : 'PM';
    return '${two(at.month)}/${two(at.day)}/${at.year} '
        '${two(hour12)}:${two(at.minute)}:${two(at.second)} $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: SkifluxRadii.borderL),
      // Stroke on top of the fill so it can't be bled over on the corner
      // curves — same reason the wallet + notifications card stacks do this.
      foregroundDecoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.contentSecondaryInverse,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceM,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceM,
        ),
        child: Column(
          children: [
            _DetailRow(
              label: 'Status',
              trailing: _StatusPill(status: txn.status),
            ),
            _DetailRow(label: 'Transaction type', value: txn.typeLabel),
            if (txn.paymentMethod != null)
              _DetailRow(label: 'Payment method', value: txn.paymentMethod!),
            if (txn.createdAt != null)
              _DetailRow(label: 'Created', value: _stamp(txn.createdAt!)),
            if (txn.updatedAt != null)
              _DetailRow(label: 'Updated', value: _stamp(txn.updatedAt!)),
            if (txn.reference != null)
              _DetailRow(
                label: 'Transaction ID',
                value: txn.reference!,
                // No hairline: `3664:13446` is the card's last child and ends
                // flush with its bottom edge. The rule that used to be drawn
                // here sat below the final row with nothing under it.
                onCopy: () async {
                  await Clipboard.setData(
                    ClipboardData(text: txn.reference!),
                  );
                  if (context.mounted) {
                    SkifluxToast.success(context, 'Transaction ID copied');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One label/value pair. [value] and [trailing] are alternatives — the Status
/// row supplies a pill instead of text.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.trailing,
    this.onCopy,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 4 + 4 is the 8 Figma leaves between consecutive rows (`3664:13461`
      // onward sit on a 25px pitch over 17px of type).
      padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceXs),
      margin: const EdgeInsets.only(bottom: SkifluxSpacing.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trailing != null)
                  trailing!
                else
                  Flexible(
                    child: Text(
                      value ?? '',
                      textAlign: TextAlign.right,
                      style: SkifluxTypography.uiButtonMedium.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                  ),
                if (onCopy != null) ...[
                  const SizedBox(width: SkifluxSpacing.spaceS),
                  GestureDetector(
                    onTap: onCopy,
                    // Figma `3664:13494` names this glyph exactly.
                    child: const Icon(
                      RemixIcons.checkbox_multiple_blank_line,
                      size: SkifluxIcons.sizeS,
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `3664:13489` — status pill, tinted per [CoinTxnStatus].
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final CoinTxnStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        status.label,
        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
          color: status.foreground,
        ),
      ),
    );
  }
}
