import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/public_user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';

// Figma: **Public User Profile view Screen** (`3092:14632`).
// Learner profile (not creator): league pill, XP / rank / tasks stats card
// with contact row, Skills / Badges / Completed Task sections. Opened from
// search Users and comments.

/// Another learner's profile, from `GET /users/{id}` / `/users/by-username/{u}`
/// (spec schema `PublicUserProfile`).
///
/// Nothing is defaulted to a sample value. Every field the payload can omit is
/// nullable or empty, because a stat cell reading "8 Task Done" is
/// indistinguishable from a real 8 — the previous defaults (league Novice, xp
/// 350, rank 12, 8 tasks, a demo email and three sample skills) rendered as
/// though they were this person's.
class PublicUserProfile {
  const PublicUserProfile({
    required this.name,
    required this.username,
    this.initials,
    this.avatarUrl,
    this.league,
    this.xp,
    this.leaderboardRank,
    this.tasksDone,
    this.email,
    this.skills = const [],
    this.badges = const [],
    this.completedTasks = const [],
  });

  final String name;
  final String username;
  final String? initials;
  final String? avatarUrl;

  /// `current_level` — the league pill. Null when the payload omits it.
  final String? league;
  final int? xp;
  final int? leaderboardRank;
  final int? tasksDone;

  /// Deliberately absent from the spec's `PublicUserProfile` — see the contact
  /// row in `_Header`, which hides itself rather than inventing an address.
  final String? email;

  final List<String> skills;
  final List<ProfileBadgeItem> badges;
  final List<CompletedTaskItem> completedTasks;

  String get handle => username.startsWith('@') ? username : '@$username';

  String get resolvedInitials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

class ProfileBadgeItem {
  const ProfileBadgeItem(this.label, this.asset);
  final String label;
  final String asset;
}

class CompletedTaskItem {
  const CompletedTaskItem({
    required this.kind,
    required this.title,
    required this.meta,
    this.actionLabel,
    this.score,
    this.band,
    this.bandDetail,
    this.passed = false,
  });

  final String kind;
  final String title;
  final String meta;
  final String? actionLabel;
  final int? score;
  final String? band;
  final String? bandDetail;
  final bool passed;
}



class PublicUserProfileScreen extends ConsumerWidget {
  const PublicUserProfileScreen({
    super.key,
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(publicUserProfileProvider(username));

    return asyncProfile.when(
      loading: () => _shell(context, const _ProfileSkeleton()),
      // Real failure panel with retry — a 404/timeout used to read as a bare
      // "Failed to load profile" with no way forward.
      error: (e, st) => _shell(
        context,
        LoadFailure(
          error: e,
          title: "We couldn't load this profile",
          onRetry: () =>
              ref.read(publicUserProfileProvider(username).notifier).retry(),
        ),
      ),
      data: (profile) => _PublicUserProfileView(profile: profile),
    );
  }

  /// Loading/error keep the same top bar as the loaded view, so back and
  /// share don't vanish while the request is in flight.
  Widget _shell(BuildContext context, Widget body) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Profile',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: body,
    );
  }
}

/// The loaded view's own shape while it is in flight: the avatar-and-name
/// header, then the stack of section cards.
///
/// Screen-specific rather than one of the shared skeletons — nothing else in
/// the app is a centred avatar over a column of cards, and a generic row list
/// here would resize the whole page the moment the profile landed.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkifluxSkeletonGroup(
      child: Padding(
        padding: EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  SkifluxSkeleton.circle(size: SkifluxUnit.u80),
                  SizedBox(height: SkifluxSpacing.spaceM),
                  SkifluxSkeleton.text(width: 160),
                  SizedBox(height: SkifluxSpacing.spaceS),
                  SkifluxSkeleton.text(width: 96),
                ],
              ),
            ),
            SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxSkeleton(height: 140, radius: SkifluxRadii.l),
            SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxSkeleton(height: 140, radius: SkifluxRadii.l),
          ],
        ),
      ),
    );
  }
}

class _PublicUserProfileView extends StatelessWidget {
  const _PublicUserProfileView({
    required this.profile,
  });

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Profile',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.share_forward_fill),
          onPressed: () => showShareSheet(
            context,
            title: '${profile.name} (@${profile.username}) on SkiFlux',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        children: [
          _Header(profile: profile),
          const SizedBox(height: SkifluxSpacing.spaceL),
          _SectionCard(
            icon: RemixIcons.medal_2_fill,
            title: 'Skills',
            countLabel: '${profile.skills.length} Skills',
            child: Wrap(
              spacing: SkifluxSpacing.spaceS,
              runSpacing: SkifluxSpacing.spaceS,
              children: [
                // White pills on the grey card (Figma 3092:14691).
                for (final skill in profile.skills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SkifluxSpacing.spaceM,
                      vertical: SkifluxSpacing.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: SkifluxColors.backgroundPrimary,
                      borderRadius: SkifluxRadii.borderPill,
                    ),
                    child: Text(
                      skill,
                      style: SkifluxTypography.uiButtonSmall.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          _SectionCard(
            icon: RemixIcons.award_fill,
            title: 'Badges',
            countLabel: '${profile.badges.length} Badges',
            child: Row(
              children: [
                for (final (i, badge) in profile.badges.indexed) ...[
                  if (i > 0) const SizedBox(width: SkifluxSpacing.spaceL),
                  Expanded(child: _BadgeTile(badge: badge)),
                ],
              ],
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          // Hidden entirely until the backend exposes a completed-task list —
          // an empty "0 Tasks" card reads as "this learner has done nothing",
          // which is a claim we cannot make.
          if (profile.completedTasks.isNotEmpty) ...[
            _SectionCard(
              icon: RemixIcons.clipboard_fill,
              title: 'Completed Task',
              // Figma pill reads "8 Badges" — copy slip; real task count used.
              countLabel: '${profile.completedTasks.length} Tasks',
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.completedTasks.length,
                itemBuilder: (context, i) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) const SizedBox(height: SkifluxSpacing.spaceL),
                      _CompletedTaskCard(item: profile.completedTasks[i]),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u64,
          initials: profile.resolvedInitials,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          profile.handle,
          textAlign: TextAlign.center,
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        // League pill — Novice + medal (3092:14644). Hidden when the payload
        // carries no `current_level`: a league is a claim about this learner.
        if (profile.league case final league?)
        Container(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceXs),
          decoration: BoxDecoration(
            color: SkifluxColors.backgroundPrimary,
            borderRadius: SkifluxRadii.borderPill,
            border: Border.all(
              color: SkifluxColors.contentBrandInactive,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                RemixIcons.medal_fill,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentBrand,
              ),
              const SizedBox(width: SkifluxSpacing.spaceXs),
              Text(
                league,
                style: SkifluxTypography.uiButtonSmall.copyWith(
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        // Stats card: XP | Leaderboard | Task Done + contact row (3092:14649).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceS),
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderL,
            border: Border.all(
              color: SkifluxColors.contentSecondaryInverse,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // An em dash where a number is unknown — "0 XP" would be a
                  // statement about this learner, and a wrong one.
                  _StatCell(value: _stat(profile.xp), label: 'XP'),
                  _vDivider(),
                  _StatCell(
                    value: profile.leaderboardRank == null
                        ? '—'
                        : '#${profile.leaderboardRank}',
                    label: 'Leaderboard',
                  ),
                  _vDivider(),
                  _StatCell(value: _stat(profile.tasksDone), label: 'Task Done'),
                ],
              ),
              // Contact row — top hairline inside the card (3092:14676):
              // mail icon + email (Nav Item, Creato Medium 14) + Contact.
              // The spec omits `email` from the public profile, so this hides
              // rather than showing a placeholder address next to a live
              // "Contact" button.
              if (profile.email case final email?) ...[
                const SizedBox(height: SkifluxSpacing.spaceS),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SkifluxSpacing.spaceS,
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(top: SkifluxSpacing.spaceS),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: SkifluxColors.contentSecondaryInverse,
                          width: SkifluxBorderWidth.xs,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          RemixIcons.mail_fill,
                          size: SkifluxIcons.sizeS,
                          color: SkifluxColors.contentPrimary,
                        ),
                        const SizedBox(width: SkifluxSpacing.spaceS),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SkifluxTypography.uiNavItem.copyWith(
                              color: SkifluxColors.contentPrimary,
                            ),
                          ),
                        ),
                        SkifluxButton(
                          label: 'Contact',
                          size: SkifluxButtonSize.s,
                          onPressed: () => SkifluxToast.info(
                            context,
                            'Messaging coming soon',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A count, or an em dash when the payload didn't carry one.
  static String _stat(int? value) => value?.toString() ?? '—';

  Widget _vDivider() {
    return Container(
      width: SkifluxBorderWidth.xs,
      height: 42,
      color: SkifluxColors.contentSecondaryInverse,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey `Background/Hover` section card, radius X (3092:14681):
/// 24px black icon + H9 Bold title + brand100 count pill, then [child].
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.countLabel,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String countLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentPrimary,
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                child: Text(
                  title,
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: SkifluxColors.backgroundPrimaryBrand,
                  borderRadius: SkifluxRadii.borderX,
                ),
                child: Text(
                  countLabel,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: SkifluxColors.contentBrand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          child,
        ],
      ),
    );
  }
}

/// Gradient badge tile (3092:14703): brand50 → brand200 vertical gradient,
/// 80px badge art, "Earned" in Button Small on `Content/Link Pressed`.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final ProfileBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma tile: radius 9.982, padding 14.973 (non-token frame values).
      padding: const EdgeInsets.all(14.97),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkifluxColors.brand50, SkifluxColors.brand200],
        ),
        borderRadius: BorderRadius.circular(9.98),
      ),
      child: Column(
        children: [
          SvgPicture.asset(badge.asset, width: 80, height: 80),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            'Earned',
            style: SkifluxTypography.uiButtonSmall.copyWith(
              color: SkifluxColors.contentLinkPressed,
            ),
          ),
        ],
      ),
    );
  }
}

/// Completed-task card (3092:14725 project / 3092:14742 assessment):
/// white card, 1px `Content/Secondary Inverse` stroke, radius L.
/// Projects get a 128px `Background/Selected` thumb strip + outlined
/// action pill; assessments get a brand score ring + band + Passed pill.
class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.item});

  final CompletedTaskItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundPrimary,
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.contentSecondaryInverse,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail strip — project cards only (3092:14726).
          if (item.score == null)
            Container(
              height: 128,
              width: double.infinity,
              color: SkifluxColors.backgroundSelected,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: _kindPill(),
            ),
          Padding(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.score != null) ...[
                  _kindPill(),
                  const SizedBox(height: SkifluxSpacing.spaceS),
                ],
                Text(
                  item.title,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentSecondary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Row(
                  children: [
                    const Icon(
                      RemixIcons.calendar_check_line,
                      size: SkifluxIcons.sizeS,
                      color: SkifluxColors.contentTertiary,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Expanded(
                      child: Text(
                        item.meta,
                        style: SkifluxTypography.bodyP10Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.score != null) ...[
                  const SizedBox(height: SkifluxSpacing.spaceS),
                  const Divider(
                    height: SkifluxSpacing.spaceL,
                    thickness: SkifluxBorderWidth.xs,
                    color: SkifluxColors.borderTertiary,
                  ),
                  _scoreRow(),
                ],
                if (item.actionLabel != null) ...[
                  const SizedBox(height: SkifluxSpacing.spaceM),
                  _actionPill(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundBrand,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        item.kind,
        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
      ),
    );
  }

  /// Outlined full-width pill — brand label on borderTertiary (3092:14741).
  Widget _actionPill(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        borderRadius: SkifluxRadii.borderPill,
        onTap: () => SkifluxToast.info(context, 'Submission link coming soon'),
        child: Container(
          height: SkifluxUnit.u32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: Border.all(
              color: SkifluxColors.borderTertiary,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: Text(
            item.actionLabel!,
            style: SkifluxTypography.uiButtonSmall.copyWith(
              color: SkifluxColors.contentBrand,
            ),
          ),
        ),
      ),
    );
  }

  /// Score ring + band row (3092:14759) — brand ring, "88 / 100" stacked,
  /// band H10 Bold + green "Passed" pill, award detail line.
  Widget _scoreRow() {
    return Row(
      children: [
        SizedBox(
          width: SkifluxUnit.u48,
          height: SkifluxUnit.u48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: SkifluxUnit.u48,
                height: SkifluxUnit.u48,
                child: CircularProgressIndicator(
                  value: (item.score! / 100).clamp(0, 1),
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: SkifluxColors.backgroundSelected,
                  color: SkifluxColors.contentBrand,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item.score}',
                    style: SkifluxTypography.uiInputContent.copyWith(
                      color: SkifluxColors.contentBrand,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                      color: SkifluxColors.contentDisabled,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.band ?? '',
                    style: SkifluxTypography.headingH10Bold.copyWith(
                      color: SkifluxColors.contentSecondary,
                    ),
                  ),
                  if (item.passed) ...[
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SkifluxSpacing.spaceS,
                        vertical: SkifluxSpacing.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: SkifluxColors.backgroundPositiveSubtle,
                        borderRadius: SkifluxRadii.borderPill,
                      ),
                      child: Text(
                        'Passed',
                        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                          color: SkifluxColors.contentPositiveBold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (item.bandDetail != null) ...[
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Row(
                  children: [
                    const Icon(
                      RemixIcons.award_line,
                      size: SkifluxIcons.sizeS,
                      color: SkifluxColors.contentTertiary,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Expanded(
                      child: Text(
                        item.bandDetail!,
                        style: SkifluxTypography.bodyP10Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
