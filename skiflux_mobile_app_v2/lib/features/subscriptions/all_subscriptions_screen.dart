import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/subscriptions_store.dart';
import 'filter_sheet.dart';
import 'subscription_widgets.dart';
import 'subscriptions_screen.dart';

/// Figma: **Subscription Flow 01** (`1256:29931`)
///
/// "All Subscriptions" — pushed from the stories-row View-all tile. Search
/// filters the creator list; the "Filter" link sorts it (Most relevant /
/// New activity / A–Z); each row's bell pill opens the notification-level
/// dropdown (All / Personalized / None / Unsubscribe).
class AllSubscriptionsScreen extends ConsumerStatefulWidget {
  const AllSubscriptionsScreen({super.key});

  @override
  ConsumerState<AllSubscriptionsScreen> createState() =>
      _AllSubscriptionsScreenState();
}

class _AllSubscriptionsScreenState
    extends ConsumerState<AllSubscriptionsScreen> {
  String _query = '';
  SubscriptionListSort _sort = SubscriptionListSort.mostRelevant;

  Future<void> _onBellTap(SubscribedCreator creator) async {
    final action = await showBellSheet(context, creator: creator);
    if (action == null || !mounted) return;
    final notifier = ref.read(subscriptionsProvider.notifier);
    switch (action) {
      case SetNotificationMode(:final mode):
        notifier.setNotificationMode(creator, mode);
      case Unsubscribe():
        notifier.unsubscribe(creator);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final creators = ref
        .watch(subscriptionsProvider)
        .sortedCreators(_sort)
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.username.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SkifluxSpacing.spaceL),
              _topBar(context),
              const SizedBox(height: SkifluxSpacing.spaceL),
              SkifluxSearchField(
                hintText: 'Search',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              Expanded(
                child: creators.isEmpty
                    ? Center(
                        child: SkifluxEmptyState(
                          icon: const Icon(
                            RemixIcons.user_search_fill,
                            size: SkifluxSpacing.space4xl,
                            color: SkifluxColors.contentBrand,
                          ),
                          title: 'No creators found',
                          message: 'No subscription matches "$_query".',
                        ),
                      )
                    : ListView.builder(
                        itemCount: creators.length,
                        itemBuilder: (context, i) {
                          final creator = creators[i];
                          return SubscribedCreatorRow(
                            creator: creator,
                            onBellTap: () => _onBellTap(creator),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreatorChannelScreen(creator: creator),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Back chevron · centered "All Subscriptions" · "Filter" link.
  Widget _topBar(BuildContext context) {
    return SizedBox(
      height: SkifluxUnit.u48,
      child: Row(
        children: [
          CircleTapTarget(
            icon: RemixIcons.arrow_left_s_line,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'All Subscriptions',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ),
          // "Filter" link — opens the sort sheet (Most relevant / New
          // activity / A–Z).
          GestureDetector(
            onTap: () async {
              final picked =
                  await showSubscriptionSortSheet(context, current: _sort);
              if (picked != null) setState(() => _sort = picked);
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  RemixIcons.filter_fill,
                  size: SkifluxIcons.sizeS,
                  color: SkifluxColors.contentBrand,
                ),
                const SizedBox(width: SkifluxSpacing.space2xs),
                Text(
                  'Filter',
                  style: SkifluxTypography.bodyP9Semibold.copyWith(
                    color: SkifluxColors.contentBrand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
