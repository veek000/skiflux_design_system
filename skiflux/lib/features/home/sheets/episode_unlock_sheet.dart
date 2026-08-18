import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/sheets/skiflux_sheet.dart';
import '../../playlists/data/playlists_store.dart';
import '../../wallet/data/episode_purchase_repository.dart';
import '../../wallet/data/wallet_store.dart';
import 'buy_coins_sheet.dart';

// Figma: Other Video Player Flow 05 → 01
// (`1256:27523` transaction summary + insufficient → `1256:27868` unlocked).
//
// Headered "Unlock Episode" sheet showing a transaction summary
// (Available Balance / Episode Cost / New balance). When the balance can't
// cover the cost, a negative banner + "Buy Coins" CTA routes into the Buy
// Coins flow; on return with enough coins the summary re-enables.
//
// Confirming runs the real spend — `POST /episodes/purchase` — and only a
// 2xx unlocks the episode and mirrors the deduction; the wallet is then
// re-read for the authoritative balance. A failure shows the coin-purchase
// modal with no deduction and no unlock.

Future<void> showEpisodeUnlockSheet(
  BuildContext context, {
  required String episodeId,
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _EpisodeUnlockSheet(episodeId: episodeId),
  );
}

class _EpisodeUnlockSheet extends ConsumerStatefulWidget {
  const _EpisodeUnlockSheet({required this.episodeId});

  final String episodeId;

  @override
  ConsumerState<_EpisodeUnlockSheet> createState() =>
      _EpisodeUnlockSheetState();
}

enum _UnlockPhase { summary, success }

class _EpisodeUnlockSheetState extends ConsumerState<_EpisodeUnlockSheet> {
  _UnlockPhase _phase = _UnlockPhase.summary;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(playlistsProvider);
    final ep = store.byId(widget.episodeId);
    if (ep == null) {
      return const SkifluxSheetShell(
        title: 'Episode',
        child: Padding(
          padding: EdgeInsets.all(SkifluxSpacing.spaceL),
          child: Text('Episode not found'),
        ),
      );
    }

    return switch (_phase) {
      _UnlockPhase.summary => _summaryView(store, ep),
      _UnlockPhase.success => _successView(ep),
    };
  }

  Widget _summaryView(PlaylistsState store, PlaylistEpisode ep) {
    final balance = store.skillCoins;
    final cost = ep.coinCost;
    final canAfford = balance >= cost;
    final newBalance = balance - cost;

    return SkifluxSheetShell(
      title: 'Unlock Episode',
      subtitle: 'Please review the transaction summary before unlocking.',
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
            // Transaction summary card.
            Container(
              decoration: BoxDecoration(
                color: SkifluxColors.backgroundHover,
                borderRadius: SkifluxRadii.borderL,
              ),
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: Column(
                children: [
                  _summaryRow('Available Balance', '$balance'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _summaryRow('Episode Cost', '−$cost'),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  const Divider(
                    height: SkifluxBorderWidth.xs,
                    thickness: SkifluxBorderWidth.xs,
                    color: SkifluxColors.borderTertiary,
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  _summaryRow(
                    'New balance',
                    '$newBalance',
                    emphasizeCoins: true,
                    coinNegative: !canAfford,
                    bold: true,
                  ),
                ],
              ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: SkifluxSpacing.spaceL),
              _insufficientBanner(),
            ],
            const SizedBox(height: SkifluxSpacing.spaceL),
            if (canAfford) ...[
              // Busy = same pill, label swaps to a small inverse spinner +
              // "Unlocking…" — no modal resize, no title change.
              _busy
                  ? const _UnlockingButton()
                  : SkifluxButton(
                      label: 'Unlock for $cost coins',
                      expanded: true,
                      onPressed: () => _unlock(ep),
                    ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              SkifluxButton(
                label: 'Back',
                type: SkifluxButtonType.secondary,
                expanded: true,
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ] else ...[
              SkifluxButton(
                label: 'Buy Coins',
                type: SkifluxButtonType.negative,
                expanded: true,
                onPressed: _busy ? null : _openBuyCoins,
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              SkifluxButton(
                label: 'Back',
                type: SkifluxButtonType.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool emphasizeCoins = false,
    bool coinNegative = false,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style:
                (bold
                        ? SkifluxTypography.headingH10Bold
                        : SkifluxTypography.bodyP10Regular)
                    .copyWith(color: SkifluxColors.contentSecondary),
          ),
        ),
        if (emphasizeCoins)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                RemixIcons.copper_coin_fill,
                size: SkifluxUnit.u20,
                color: coinNegative
                    ? SkifluxColors.contentNegative
                    : SkifluxColors.contentNotice,
              ),
              const SizedBox(width: SkifluxSpacing.spaceXs),
              Text(
                value,
                style: SkifluxTypography.headingH10Bold.copyWith(
                  color: coinNegative
                      ? SkifluxColors.contentNegative
                      : SkifluxColors.contentNotice,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
      ],
    );
  }

  Widget _insufficientBanner() {
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
            RemixIcons.close_circle_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentNegative,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insufficient Coins',
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  'You do not have enough SkillCoins to unlock this episode.',
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView(PlaylistEpisode ep) {
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
              'Episode Unlocked!',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              '${ep.epTag} is now available. Enjoy the lesson and complete '
              'the task to earn rewards.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
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

  Future<void> _openBuyCoins() async {
    final bought = await showBuyCoinsSheet(context);
    // Returning here re-reads the wallet; summary re-enables if now affordable.
    if (bought != null && mounted) setState(() {});
  }

  Future<void> _unlock(PlaylistEpisode ep) async {
    // Busy state renders inline in the primary button — the sheet keeps its
    // exact layout (no resize, no "Unlocking" title swap).
    setState(() => _busy = true);
    try {
      // The real spend. Anything but 2xx throws — no deduction, no unlock.
      await ref.read(episodePurchaseRepositoryProvider).purchase(ep.id);
      if (!mounted) return;
      // Backend accepted: unlock + mirror the confirmed spend locally, then
      // re-read the wallet for the authoritative balance and ledger.
      ref.read(playlistsProvider.notifier).markPurchased(ep.id);
      ref.read(walletProvider.notifier).recordUnlock(ep.epTag, ep.coinCost);
      unawaited(ref.read(walletProvider.notifier).refreshFromBackend());
      setState(() {
        _busy = false;
        _phase = _UnlockPhase.success;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      // coinPurchaseFailed modal ("No charges were made") via the
      // repository's failure kind.
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }
}

/// Primary-pill busy state: brand fill, small inverse spinner + "Unlocking…"
/// — same height/shape as the Unlock button it replaces.
class _UnlockingButton extends StatelessWidget {
  const _UnlockingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: SkifluxUnit.u48),
      padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundBrand,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkifluxSpinner(
            size: SkifluxSpinnerSize.s,
            type: SkifluxSpinnerType.inverse,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Text(
            'Unlocking…',
            style: SkifluxTypography.uiButtonLarge.copyWith(
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
        ],
      ),
    );
  }
}
