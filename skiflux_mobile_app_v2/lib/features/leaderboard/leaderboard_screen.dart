import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/leaderboard_store.dart';

// Figma: **Profile Flow 01** (`1256:25612`) — Leaderboard screen.
// League pill group, "#12 / better than 60%" notification, podium with
// top-3 avatars, then the RANK / TOTAL XP card (`1256:25657`) docked to
// the bottom at the podium's width (16px margins, 24px corners) with its
// own scrolling list — opened pre-scrolled so the signed-in user's
// highlighted row is in view (Figma shows rows 10–13). League switching
// only re-selects the pill — the demo store has one league of data.

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  /// How far the rank card slides up over the podium steps (Figma:
  /// podium bottom y565.92 − card top y538, in 361-frame units).
  static const double _cardOverlap = 27.92;

  int _leagueIndex = 0;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Leaderboard',
        // Figma: screen title uses Heading Style/Heading H8 Bold.
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 24px spacer mirrors the leading icon to keep the title centered.
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      // Top content is fixed (matching the Figma frame); only the rank
      // card's list scrolls. The card overlaps the podium's bottom by
      // ~28px (Figma: card top y538 vs podium bottom y565.9), sliding
      // over the steps, so the two live in a Stack.
      body: Column(
        children: [
          const SizedBox(height: SkifluxSpacing.spaceL),
          _pillGroup(board),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
            child: _RankNotification(board: board),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.maxWidth - SkifluxSpacing.spaceL * 2;
                final scale = width / _Podium.frameW;
                final podiumHeight = _Podium.frameH * scale;
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: SkifluxSpacing.spaceL,
                      right: SkifluxSpacing.spaceL,
                      child: _Podium(board: board),
                    ),
                    Positioned(
                      // Figma overlap: 565.92 − 538 ≈ 28 (scaled).
                      top: podiumHeight - _cardOverlap * scale,
                      left: SkifluxSpacing.spaceL,
                      right: SkifluxSpacing.spaceL,
                      bottom: 0,
                      child: _RankTable(board: board),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// League pills (`1256:25615`) — same Button Group Pill pattern as the
  /// creator profile (size S, selected = primary).
  Widget _pillGroup(LeaderboardData board) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
      child: Row(
        children: [
          for (var i = 0; i < board.leagues.length; i++) ...[
            if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: board.leagues[i],
              size: SkifluxButtonSize.s,
              type: i == _leagueIndex
                  ? SkifluxButtonType.primary
                  : SkifluxButtonType.secondary,
              onPressed: () => setState(() => _leagueIndex = i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Notification pill (`1256:25616`): brand-subtle pill, 32px brand "#12"
/// avatar, Creato Bold 14 brand message.
class _RankNotification extends StatelessWidget {
  const _RankNotification({required this.board});

  final LeaderboardData board;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceS,
        SkifluxSpacing.spaceS,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceS,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundBrandOpacity50,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        children: [
          Container(
            width: SkifluxUnit.u32,
            height: SkifluxUnit.u32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SkifluxColors.backgroundBrand,
              shape: BoxShape.circle,
            ),
            child: Text(
              '#${board.currentRank}',
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'You are doing better than '
              '${board.betterThanPercent}% of other participants',
              style: SkifluxTypography.uiButtonMedium.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Podium ───────────────────────────────────────────────────────────

/// Podium group (`1256:25622`): the podium SVG (baked 1st/2nd/3rd laurel
/// numerals) with the top-3 avatar columns above each step. Figma frame
/// is 361×325.92 with the SVG bottom-anchored at y 110.68; positions
/// scale with the available width.
class _Podium extends StatelessWidget {
  const _Podium({required this.board});

  final LeaderboardData board;

  // Figma geometry (361-wide frame) — shared with the screen's Stack so
  // the rank-card overlap scales with the same factor.
  static const double frameW = 361;
  static const double frameH = 325.92;
  static const double _svgH = 215.25;
  // Avatar-column centers (x) and tops (y) per place.
  static const double _firstX = 182.22, _firstY = 0;
  static const double _secondX = 60.29, _secondY = 48;
  static const double _thirdX = 300.71, _thirdY = 72.26;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / frameW;
        final podium = board.podium;
        return SizedBox(
          height: frameH * scale,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  'assets/badges/podium.svg',
                  width: constraints.maxWidth,
                  height: _svgH * scale,
                  fit: BoxFit.fill,
                ),
              ),
              _place(podium[0], _firstX, _firstY, scale, crowned: true),
              _place(podium[1], _secondX, _secondY, scale),
              _place(podium[2], _thirdX, _thirdY, scale),
            ],
          ),
        );
      },
    );
  }

  Widget _place(
    LeaderboardEntry entry,
    double centerX,
    double top,
    double scale, {
    bool crowned = false,
  }) {
    const columnW = 90.0;
    return Positioned(
      left: centerX * scale - columnW / 2,
      top: top * scale,
      width: columnW,
      child: _PodiumColumn(entry: entry, crowned: crowned),
    );
  }
}

/// One avatar column (`1256:25638`…): 64px initials avatar (1st place
/// gets the crown badge), Creato Bold 14 name, DM Mono 10 XP.
class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.entry, required this.crowned});

  final LeaderboardEntry entry;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SkifluxAvatar(
              style: SkifluxAvatarStyle.initial,
              size: SkifluxUnit.u64,
              initials: entry.initials,
            ),
            if (crowned)
              const Positioned(
                top: -SkifluxSpacing.spaceM,
                left: 0,
                right: 0,
                child: Center(child: _CrownBadge()),
              ),
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: SkifluxTypography.uiButtonMedium.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          '${entry.xpLabel} XP',
          textAlign: TextAlign.center,
          // Figma: DM Mono Regular 10 with default tracking (Code Inline
          // minus its letter-spacing).
          style: SkifluxTypography.codeInline.copyWith(
            color: SkifluxColors.contentPrimary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Crown badge on the 1st-place avatar (`I1256:25640;1221:12490`): brand
/// circle, white border, white vip-crown icon.
class _CrownBadge extends StatelessWidget {
  const _CrownBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.space2xs + 3),
      decoration: BoxDecoration(
        color: SkifluxColors.contentBrand,
        shape: BoxShape.circle,
        border: Border.all(
          color: SkifluxColors.borderInverse,
          width: SkifluxBorderWidth.m,
        ),
      ),
      child: const Icon(
        RemixIcons.vip_crown_fill,
        size: 13,
        color: SkifluxColors.contentPrimaryInverse,
      ),
    );
  }
}

// ── Rank table ───────────────────────────────────────────────────────

/// Rank card (`1256:25657`): white card at the podium's width (radius X,
/// 24px corners) with a fixed RANK / TOTAL XP header and its own
/// scrolling row list (starting at #4 — the podium holds 1–3). Opens
/// pre-scrolled so the signed-in user's highlighted row sits in view,
/// like the Figma frame (rows 10–13).
class _RankTable extends StatefulWidget {
  const _RankTable({required this.board});

  final LeaderboardData board;

  @override
  State<_RankTable> createState() => _RankTableState();
}

class _RankTableState extends State<_RankTable> {
  // Row extent: 4px vertical padding ×2 + 48px avatar + 8px separator.
  static const double _rowExtent = SkifluxUnit.u56 + SkifluxSpacing.spaceS;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      // Land the user's row 3rd in view (Figma shows 10, 11, [12], 13).
      initialScrollOffset: _userOffset,
    );
    // The initial offset can overshoot maxScrollExtent before layout;
    // settle it once the list has dimensions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpTo(
        _userOffset.clamp(0, _controller.position.maxScrollExtent),
      );
    });
  }

  double get _userOffset {
    final board = widget.board;
    final index = board.ranked.indexWhere(
      (entry) => entry.rank == board.currentRank,
    );
    if (index <= 2) return 0;
    return (index - 2) * _rowExtent;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SkifluxRadii.x),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceS,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: SkifluxColors.borderSecondary,
                  width: SkifluxBorderWidth.xs,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RANK',
                  style: SkifluxTypography.uiInputContent.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  'TOTAL XP',
                  style: SkifluxTypography.uiInputContent.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.symmetric(
                vertical: SkifluxSpacing.spaceL,
              ),
              itemExtent: _rowExtent,
              itemCount: board.ranked.length,
              itemBuilder: (context, index) {
                final entry = board.ranked[index];
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: SkifluxSpacing.spaceS),
                  child: _RankRow(
                    entry: entry,
                    highlighted: entry.rank == board.currentRank,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One ranked row (`1256:25664`…): rank number, 48px avatar,
/// name/handle, XP chip. Highlighted row = backgroundSelected, radius XL.
class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.highlighted});

  final LeaderboardEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceL,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: highlighted ? SkifluxColors.backgroundSelected : null,
        borderRadius: SkifluxRadii.borderXl,
      ),
      child: Row(
        children: [
          SizedBox(
            width: SkifluxUnit.u32,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH9Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          SkifluxAvatar(
            style: SkifluxAvatarStyle.initial,
            size: SkifluxUnit.u48,
            initials: entry.initials,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              // Keep the pair vertically centered on the avatar (the
              // default max-height Column pins them to the row's top).
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  entry.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          _XpChip(label: entry.xpLabel),
        ],
      ),
    );
  }
}

/// XP chip (`1256:25672`): selected-tint pill — flashlight icon, Creato
/// Bold 12 brand count, 10px "XP" in tertiary.
class _XpChip extends StatelessWidget {
  const _XpChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceXs),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundSelected,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            RemixIcons.flashlight_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentBrand,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceXs,
            ),
            child: Text(
              label,
              style: SkifluxTypography.uiButtonSmall.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: SkifluxSpacing.spaceXs),
            child: Text(
              'XP',
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
