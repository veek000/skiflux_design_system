import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';

// Figma: **Public User Profile view Screen** (`3092:14632`).
// Learner profile (not creator): XP / rank / tasks, skills, badges,
// completed projects & assessments. Opened from search Users and comments.

class PublicUserProfile {
  const PublicUserProfile({
    required this.name,
    required this.username,
    this.initials,
    this.league = 'Novice',
    this.xp = 350,
    this.leaderboardRank = 12,
    this.tasksDone = 8,
    this.email = 'hello@skiflux.app',
    this.skills = const ['UI Design', 'Figma', 'Design Systems'],
    this.badges = const [
      ProfileBadgeItem(
        'First Task',
        'assets/badges/badge_first_task_completed.svg',
      ),
      ProfileBadgeItem(
        '3 Day Streak',
        'assets/badges/badge_3_days_streak.svg',
      ),
      ProfileBadgeItem(
        'Top Learner',
        'assets/badges/badge_top_learner.svg',
      ),
    ],
    this.completedTasks = const [
      CompletedTaskItem(
        kind: 'Project',
        title: 'SaaS landing page design',
        meta: 'Submitted Mar 2025 · Verified',
        actionLabel: 'View Project',
      ),
      CompletedTaskItem(
        kind: 'Assessment',
        title: 'Design principles & theory',
        meta: 'Completed Jan 2025 · Verified',
        score: 88,
        band: 'Distinction',
        bandDetail: 'Top Performance band · 80–100',
        passed: true,
      ),
      CompletedTaskItem(
        kind: 'Project',
        title: 'Design system starter kit',
        meta: 'Submitted Feb 2025 · Verified',
        actionLabel: 'View Project',
      ),
    ],
  });

  final String name;
  final String username;
  final String? initials;
  final String league;
  final int xp;
  final int leaderboardRank;
  final int tasksDone;
  final String email;
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

  /// Demo users used by search / comments.
  static PublicUserProfile demo({
    String name = 'Amara Design',
    String username = 'amara',
  }) {
    return PublicUserProfile(name: name, username: username);
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

class PublicUserProfileScreen extends StatelessWidget {
  const PublicUserProfileScreen({
    super.key,
    this.profile = const PublicUserProfile(
      name: 'Amara Design',
      username: 'amara',
    ),
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
          onPressed: () => showShareSheet(context),
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
                for (final skill in profile.skills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SkifluxSpacing.spaceM,
                      vertical: SkifluxSpacing.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: SkifluxColors.backgroundSelected,
                      borderRadius: SkifluxRadii.borderPill,
                    ),
                    child: Text(
                      skill,
                      style: SkifluxTypography.uiButtonSmall.copyWith(
                        color: SkifluxColors.contentBrand,
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
                for (var i = 0; i < profile.badges.length; i++) ...[
                  if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
                  Expanded(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          profile.badges[i].asset,
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: SkifluxSpacing.spaceXs),
                        Text(
                          'Earned',
                          style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                            color: SkifluxColors.contentTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          _SectionCard(
            icon: RemixIcons.clipboard_fill,
            title: 'Completed Task',
            countLabel: '${profile.tasksDone} Done',
            child: Column(
              children: [
                for (var i = 0; i < profile.completedTasks.length; i++) ...[
                  if (i > 0) const SizedBox(height: SkifluxSpacing.spaceM),
                  _CompletedTaskCard(item: profile.completedTasks[i]),
                ],
              ],
            ),
          ),
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
        // League pill — Novice + medal.
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
                size: 16,
                color: SkifluxColors.contentBrand,
              ),
              const SizedBox(width: SkifluxSpacing.spaceXs),
              Text(
                profile.league,
                style: SkifluxTypography.uiButtonSmall.copyWith(
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        // Stats card: XP | Leaderboard | Task Done.
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
                  _StatCell(value: '${profile.xp}', label: 'XP'),
                  _vDivider(),
                  _StatCell(
                    value: '#${profile.leaderboardRank}',
                    label: 'Leaderboard',
                  ),
                  _vDivider(),
                  _StatCell(
                    value: '${profile.tasksDone}',
                    label: 'Task Done',
                  ),
                ],
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                ),
                child: Row(
                  children: [
                    const Icon(
                      RemixIcons.mail_fill,
                      size: 16,
                      color: SkifluxColors.contentTertiary,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceS),
                    Expanded(
                      child: Text(
                        profile.email,
                        style: SkifluxTypography.bodyP10Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                    SkifluxButton(
                      label: 'Message',
                      size: SkifluxButtonSize.s,
                      type: SkifluxButtonType.secondary,
                      onPressed: () {
                        SkifluxToast.info(context, 'Messaging coming soon');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
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
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: SkifluxColors.contentBrand),
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
                  color: SkifluxColors.backgroundHover,
                  borderRadius: SkifluxRadii.borderPill,
                ),
                child: Text(
                  countLabel,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: SkifluxColors.contentTertiary,
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

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.item});

  final CompletedTaskItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceS,
              vertical: SkifluxSpacing.spaceXs,
            ),
            decoration: BoxDecoration(
              color: SkifluxColors.backgroundPrimary,
              borderRadius: SkifluxRadii.borderPill,
            ),
            child: Text(
              item.kind,
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            item.title,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Row(
            children: [
              const Icon(
                RemixIcons.calendar_check_line,
                size: 16,
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
            const SizedBox(height: SkifluxSpacing.spaceM),
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: (item.score! / 100).clamp(0, 1),
                          strokeWidth: 4,
                          backgroundColor: SkifluxColors.backgroundPressed,
                          color: SkifluxColors.contentPositive,
                        ),
                      ),
                      Text(
                        '${item.score}',
                        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                          color: SkifluxColors.contentPrimary,
                        ),
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
                              color: SkifluxColors.contentPrimary,
                            ),
                          ),
                          if (item.passed) ...[
                            const SizedBox(width: SkifluxSpacing.spaceS),
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
                                style: SkifluxTypography.uiBadgeTagSmall
                                    .copyWith(
                                  color: SkifluxColors.contentPositive,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.bandDetail != null)
                        Row(
                          children: [
                            const Icon(
                              RemixIcons.award_line,
                              size: 16,
                              color: SkifluxColors.contentTertiary,
                            ),
                            const SizedBox(width: SkifluxSpacing.spaceXs),
                            Expanded(
                              child: Text(
                                item.bandDetail!,
                                style:
                                    SkifluxTypography.bodyP10Regular.copyWith(
                                  color: SkifluxColors.contentTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (item.actionLabel != null) ...[
            const SizedBox(height: SkifluxSpacing.spaceM),
            SkifluxButton(
              label: item.actionLabel!,
              size: SkifluxButtonSize.s,
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () {},
            ),
          ],
        ],
      ),
    );
  }
}
