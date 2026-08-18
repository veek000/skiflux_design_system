import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/load_failure.dart';
import '../../shared/widgets/network_image.dart';
import 'data/leaderboard_store.dart';

// Figma: **Profile Flow 01** (`1256:25612`) — Leaderboard screen.
// League pill group, "#12 / better than 60%" notification, podium with
// top-3 avatars, then the RANK / TOTAL XP card (`1256:25657`) docked to
// the bottom at the podium's width (16px margins, 24px corners) with its
// own scrolling list — opened pre-scrolled so the signed-in user's
// highlighted row is in view (Figma shows rows 10–13). Tapping a league
// pill refetches `GET /me/leaderboard` filtered to that level.

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  /// How far the rank card slides up over the podium steps (Figma:
  /// podium bottom y565.92 − card top y538, in 361-frame units).
  static const double cardOverlap = 27.92;

  /// The rank card's comfortable height: its header plus about two rows.
  static const double minRankCardHeight = 200;

  /// The least the rank card may be squeezed to before anything else gives:
  /// its header plus a single row.
  ///
  /// The card is a scroll view, so height only costs it visible rows — which
  /// makes it the right thing to squeeze first, ahead of the podium. Only once
  /// the card is down to this does the podium begin to scale, and even then it
  /// is clamped (see `_Board._minPodiumScale`).
  static const double minRankCardFloor = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Column(
        children: [
          const SizedBox(height: SkifluxSpacing.spaceL),
          const _LeaguePills(),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: _RankNotification(board: board.value),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Expanded(
            child: switch (board) {
              AsyncLoading() => const _LeaderboardSkeleton(),
              AsyncError(:final error) => LoadFailure(
                error: error,
                title: "We couldn't load the leaderboard",
                onRetry: () => ref.read(leaderboardProvider.notifier).refresh(),
              ),
              AsyncData(:final value) when value.isEmpty => const Center(
                child: SkifluxEmptyState(
                  icon: Icon(
                    RemixIcons.trophy_fill,
                    size: SkifluxEmptyState.iconSize,
                    color: SkifluxColors.contentBrand,
                  ),
                  title: 'No rankings yet',
                  message: 'Earn XP to appear on the leaderboard.',
                ),
              ),
              AsyncData(:final value) => _Board(board: value),
            },
          ),
        ],
      ),
    );
  }
}

/// Podium + rank card. Split out of the screen so the async switch above
/// reads as four states rather than four states and a layout.
class _Board extends StatelessWidget {
  const _Board({required this.board});

  final LeaderboardData board;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - SkifluxSpacing.spaceL * 2;
        final scale = width / _Podium.frameW;

        // Measured, not estimated. The podium art scales with the screen but
        // the type inside a column does not, so the only honest way to know
        // how far a column rises above its step is to lay the two lines out.
        final rise = _Podium.columnRiseFor(context);
        final natural = _Podium.heightAt(scale, rise);

        // Who yields on a short screen — and now only one thing does.
        //
        // The rank table is a scroll view, so losing height costs it visible
        // rows and nothing else. The podium cannot give ground the same way: it
        // is one fixed composition, and scaling it shrinks the type inside the
        // columns along with the art, which is how the 1st-place XP line ended
        // up sitting on the podium in the first place.
        //
        // So the podium is drawn at its natural size, always. The table takes
        // whatever is left; once that is down to [minRankCardFloor] the whole
        // board scrolls. Previously the podium was scaled to protect the table
        // — first to a ruinous 0.09, then clamped to 0.72 — and a clamped
        // shrink is still a shrink: at 0.72 the labels closed the gap onto the
        // step on exactly the short screens the clamp was meant to rescue.
        final drawn = natural;

        final board = Stack(
          children: [
            Positioned(
              top: 0,
              left: SkifluxSpacing.spaceL,
              right: SkifluxSpacing.spaceL,
              height: drawn,
              child: _Podium(board: this.board, rise: rise),
            ),
            Positioned(
              // Figma overlap: 565.92 − 538 ≈ 28 (scaled).
              top: drawn - LeaderboardScreen.cardOverlap * scale,
              left: SkifluxSpacing.spaceL,
              right: SkifluxSpacing.spaceL,
              bottom: 0,
              child: _RankTable(board: this.board),
            ),
          ],
        );

        // The table has stopped being usable — scroll rather than squeeze the
        // podium. The table starts below the fold, which is recoverable; a
        // podium with its labels on the art is not.
        final wanted = drawn + LeaderboardScreen.minRankCardFloor;
        if (wanted <= constraints.maxHeight) return board;

        // The Stack needs a definite height: inside a scroll view the table's
        // `bottom: 0` has nothing to resolve against.
        return SingleChildScrollView(
          child: SizedBox(height: wanted, child: board),
        );
      },
    );
  }
}

/// League pills (`1256:25615`) — same Button Group Pill pattern as the
/// creator profile (size S, selected = primary).
class _LeaguePills extends ConsumerWidget {
  const _LeaguePills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(leaderboardLeagueProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
      child: Row(
        children: [
          for (var i = 0; i < kLeaderboardLeagues.length; i++) ...[
            if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: kLeaderboardLeagues[i],
              size: SkifluxButtonSize.s,
              type: i == selected
                  ? SkifluxButtonType.primary
                  : SkifluxButtonType.secondary,
              // Writing the selection re-runs the provider's build, which
              // refetches with the new `level` — the screen holds no second
              // copy of which pill is on.
              onPressed: () =>
                  ref.read(leaderboardLeagueProvider.notifier).select(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Notification pill (`1256:25616`): brand-subtle pill, 32px brand "#12"
/// avatar, Creato Bold 14 brand message.
///
/// Both halves are only drawn once the standing is actually known. Before
/// then the rank badge shimmers and the sentence is withheld — an invented
/// "#12 / better than 60%" was the previous behaviour and read as fact.
class _RankNotification extends StatelessWidget {
  const _RankNotification({required this.board});

  final LeaderboardData? board;

  @override
  Widget build(BuildContext context) {
    final rank = board?.currentRank;
    final percent = board?.betterThanPercent;

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
      child: SkifluxSkeletonGroup(
        child: Row(
          children: [
            if (rank == null)
              const SkifluxSkeleton.circle(size: SkifluxUnit.u32)
            else
              Container(
                width: SkifluxUnit.u32,
                height: SkifluxUnit.u32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundBrand,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: percent == null
                  ? const SkifluxSkeleton.text(width: 200)
                  : Text(
                      'You are doing better than '
                      '$percent% of other participants',
                      style: SkifluxTypography.uiButtonMedium.copyWith(
                        color: SkifluxColors.contentBrand,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Podium ───────────────────────────────────────────────────────────

/// Podium group (`1256:25622`): the podium SVG (baked 1st/2nd/3rd laurel
/// numerals) with the top-3 avatar columns standing on each step. Figma frame
/// is 361×325.92 with the SVG bottom-anchored at y 110.68; positions
/// scale with the available width.
class _Podium extends StatelessWidget {
  const _Podium({required this.board, required this.rise});

  final LeaderboardData board;

  /// How far the tallest column reaches above the step it stands on, from
  /// [columnRiseFor].
  final double rise;

  // Figma geometry (361-wide frame) — shared with the screen's Stack so
  // the rank-card overlap scales with the same factor.
  static const double frameW = 361;
  static const double frameH = 325.92;
  static const double _svgH = 215.25;

  /// The crown badge hangs this far above the avatar it sits on
  /// (`_CrownBadge` is offset by `-spaceM` inside an unclipped Stack).
  static const double _crownOverhang = SkifluxSpacing.spaceM;

  /// The gap between the XP line and the step it stands on.
  ///
  /// Deliberately a constant in logical pixels rather than a scaled fraction:
  /// the labels are laid out in logical pixels too, so a gap that scaled with
  /// the art would close exactly where the text did not — which is what the
  /// 1st-place XP line touching the podium was. Also deliberately larger than
  /// the 4 the Figma frame implies: that 4 is measured against the step's flat
  /// top face, while the SVG's leading edge (what [_firstStep] resolves to) is
  /// the front of the bevel, a few pixels below where the label visually lands.
  static const double stepClearance = SkifluxSpacing.spaceM;

  /// Everything in a column that is *not* the two text lines: the crown's
  /// overhang, the 64px avatar, the gap under it, the gap between the two
  /// lines, and the clearance that keeps the XP off the step's bevel.
  static const double _columnChrome =
      _crownOverhang +
      SkifluxUnit.u64 +
      SkifluxSpacing.spaceS +
      SkifluxSpacing.spaceXs +
      stepClearance;

  /// The exact height of a podium column above its step, for the text metrics
  /// in force in [context].
  ///
  /// This used to be a constant with slack added on top, and the slack is what
  /// failed: the two lines are laid out in logical pixels and grow with the
  /// system text size, while the frame they sit in scales with the screen's
  /// width. Any fixed guess is therefore right at exactly one combination of
  /// the two and wrong at the rest — under-guessing clipped the crown and ran
  /// the column up into the standing pill above it, over-guessing pushed the
  /// whole podium and rank card down the screen. Laying the lines out costs
  /// two [TextPainter]s and is right at every combination.
  static double columnRiseFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _columnChrome +
        _lineHeight(SkifluxTypography.uiButtonMedium, scaler) +
        _lineHeight(SkifluxTypography.codeInline, scaler);
  }

  static double _lineHeight(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      // Ascender + descender: the tallest a single line of this style gets.
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.height;
  }

  /// The podium's drawn height at [scale] with a column rising [rise] above
  /// the top step: whichever of the art and the tallest column needs more.
  static double heightAt(double scale, double rise) =>
      math.max(frameH * scale, rise + _firstStep * scale);

  /// Avatar-column centers (x) per place — the middle of each step.
  static const double _firstX = 182.22, _secondX = 60.29, _thirdX = 300.71;

  /// The top surface of each step, measured **up from the frame's bottom** in
  /// frame units: the y of that step's leading edge in
  /// `assets/badges/podium.svg` (22.20 / 48.74 / 73.68 in its 216-tall viewBox),
  /// mapped through the SVG's draw height.
  ///
  /// Columns are anchored to *this*, not to a fixed avatar top: the name and XP
  /// hang below the avatar, and bottom-anchoring is what guarantees they cannot
  /// grow down onto the step no matter what the text metrics do at a given
  /// screen width. That overlap is exactly what these labels were previously
  /// moved above the avatar to escape.
  static const double _svgScale = _svgH / 216;
  static const double _firstStep = _svgH - 0 * _svgScale;
  static const double _secondStep = _svgH - 48.7402 * _svgScale;
  static const double _thirdStep = _svgH - 73.6758 * _svgScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / frameW;
        final podium = board.podium;
        return SizedBox(
          height: heightAt(scale, rise),
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
              // A league filter can come back with fewer than three learners,
              // so each step is placed only if someone is standing on it.
              _place(
                podium.elementAtOrNull(0),
                _firstX,
                _firstStep,
                scale,
                crowned: true,
              ),
              _place(podium.elementAtOrNull(1), _secondX, _secondStep, scale),
              _place(podium.elementAtOrNull(2), _thirdX, _thirdStep, scale),
            ],
          ),
        );
      },
    );
  }

  Widget _place(
    LeaderboardEntry? entry,
    double centerX,
    double stepTop,
    double scale, {
    bool crowned = false,
  }) {
    if (entry == null) return const SizedBox.shrink();
    const columnW = 90.0;
    return Positioned(
      left: centerX * scale - columnW / 2,
      // Measured from the frame's bottom so the column stands *on* the step:
      // whatever height the avatar + labels come to, they stack upward.
      bottom: stepTop * scale,
      width: columnW,
      child: _PodiumColumn(entry: entry, crowned: crowned),
    );
  }
}

/// One podium column: the avatar, with the name and XP **under** it, resting on
/// the step. See [_Podium._firstStep] for why the column is bottom-anchored
/// rather than placed by its avatar.
class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.entry, required this.crowned});

  final LeaderboardEntry entry;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _EntryAvatar(entry: entry, size: SkifluxUnit.u64),
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
        // Figma `1256:25641`: the XP line sits 4 below the name's box.
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
        // Clears the step's leading edge so the XP line does not sit flush on
        // the bevel it is standing on. See [_Podium.stepClearance].
        const SizedBox(height: _Podium.stepClearance),
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
    _settleAfterLayout();
  }

  @override
  void didUpdateWidget(_RankTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A league filter reshuffles the rows, so the user's row has moved and the
    // pre-scroll has to run again.
    if (!identical(oldWidget.board, widget.board)) _settleAfterLayout();
  }

  void _settleAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpTo(
        _userOffset.clamp(0, _controller.position.maxScrollExtent),
      );
    });
  }

  double get _userOffset {
    final index = widget.board.currentIndexInRanked;
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
          const _RankTableHeader(),
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
                  padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceS),
                  child: _RankRow(
                    entry: entry,
                    highlighted: entry.isCurrentUser,
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

class _RankTableHeader extends StatelessWidget {
  const _RankTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _EntryAvatar(entry: entry, size: SkifluxUnit.u48),
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

/// A learner's avatar: their photo when the API sent one, else the initials
/// circle. [SkifluxAvatar] itself falls back to initials on a decode/network
/// error, so a broken URL degrades rather than showing a blank.
class _EntryAvatar extends StatelessWidget {
  const _EntryAvatar({required this.entry, required this.size});

  final LeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = entry.avatarUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return SkifluxAvatar(
      style: hasPhoto ? SkifluxAvatarStyle.avatar : SkifluxAvatarStyle.initial,
      size: size,
      initials: entry.initials,
      image: hasPhoto ? skifluxImageProvider(url) : null,
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

// ── Loading ──────────────────────────────────────────────────────────

/// The board's shape while `GET /me/leaderboard` is in flight: three podium
/// columns of descending height, then the rank card's rows.
class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkifluxSkeletonGroup(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SkifluxSpacing.spaceXl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PodiumColumnSkeleton(stepHeight: 56),
                _PodiumColumnSkeleton(stepHeight: 88),
                _PodiumColumnSkeleton(stepHeight: 36),
              ],
            ),
            SizedBox(height: SkifluxSpacing.spaceL),
            Expanded(child: _RankListSkeleton()),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumnSkeleton extends StatelessWidget {
  const _PodiumColumnSkeleton({required this.stepHeight});

  final double stepHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SkifluxSkeleton.circle(size: SkifluxUnit.u64),
        const SizedBox(height: SkifluxSpacing.spaceS),
        const SkifluxSkeleton.text(width: 64),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        const SkifluxSkeleton.text(width: 40, height: SkifluxSpacing.spaceM),
        const SizedBox(height: SkifluxSpacing.spaceS),
        SkifluxSkeleton(
          width: 90,
          height: stepHeight,
          radius: SkifluxRadii.s,
        ),
      ],
    );
  }
}

class _RankListSkeleton extends StatelessWidget {
  const _RankListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: SkifluxSpacing.spaceL),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceS),
      itemBuilder: (_, _) => const SizedBox(
        height: SkifluxUnit.u56,
        child: Row(
          children: [
            SkifluxSkeleton.text(width: SkifluxSpacing.spaceL),
            SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxSkeleton.circle(size: SkifluxUnit.u48),
            SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkifluxSkeleton.text(width: 120),
                  SizedBox(height: SkifluxSpacing.spaceXs),
                  SkifluxSkeleton.text(width: 72, height: SkifluxSpacing.spaceS),
                ],
              ),
            ),
            SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxSkeleton(width: 72, height: SkifluxUnit.u32,
              radius: SkifluxRadii.pill),
          ],
        ),
      ),
    );
  }
}
