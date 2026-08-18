import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../playlists/data/season_providers.dart';
import '../playlists/playlist_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/public_user_profile_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/search_index.dart';
import 'search_result_widgets.dart';

/// Figma: **Search flow 01/02/03/06** — full results with count header and
/// Episodes | Creators | Users | Playlists tabs.
///
/// The Figma copy says "6 result for" — a slip; the header computes the real
/// total and pluralizes properly.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.results,
    this.initialTab = SearchCategory.episodes,
  });

  final SearchResults results;
  final SearchCategory initialTab;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late SearchCategory _tab = widget.initialTab;
  late final TextEditingController _queryController = TextEditingController(
    text: widget.results.query,
  );

  SearchResults get _results => widget.results;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// `GET /creators/{id}` takes the creator UUID from the search payload.
  void _openCreatorProfile(PersonResult person) {
    if (person.id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(creatorId: person.id),
      ),
    );
  }

  /// `GET /users/by-username/{username}` — no username, nothing to open.
  void _openUserProfile(PersonResult person) {
    if (person.username.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(username: person.username),
      ),
    );
  }

  /// Search knows a season's id, title and episode count but not its creator —
  /// `Season` carries none — so [SeasonArg] goes in with the hints it has and
  /// the screen fills the rest in from the episodes call.
  void _openPlaylist(PlaylistResult playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          season: SeasonArg(
            id: playlist.id,
            title: playlist.title,
            episodeCount: playlist.episodeCount,
            skillworld: playlist.skillworld,
          ),
        ),
      ),
    );
  }

  /// A search result has no feed behind it, so an episode opens in the player
  /// modal — the counterpart to home's inline behaviour.
  void _openEpisode(EpisodeResult episode) {
    showEpisodePlayerModal(
      context,
      SubscriptionEpisode(
        id: episode.id,
        epNumber: episode.epNumber,
        title: episode.title,
        creatorUsername: episode.creator,
        duration: episode.duration,
        views: episode.views,
        // Search's `Episode` rows are mapped without `created_at`, so there is
        // no age to state. Blank, not a guess.
        postedAgo: '',
        thumbnailUrl: episode.thumbnailUrl,
      ),
    );
  }

  Future<void> _followCreator(PersonResult person) async {
    try {
      await ref.read(subscriptionsProvider.notifier).subscribe(
            SubscribedCreator(
              id: person.id,
              name: person.name,
              username: person.username,
              initials:
                  person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
            ),
          );
      if (!mounted) return;
      SkifluxToast.success(context, 'Subscribed to ${person.name}');
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              _countHeader(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              SkifluxTextTabs(
                tabs: [
                  for (final category in SearchCategory.values)
                    SkifluxTextTab(
                      label: category.label,
                      count: _results.countFor(category),
                    ),
                ],
                selectedIndex: SearchCategory.values.indexOf(_tab),
                onSelected: (i) =>
                    setState(() => _tab = SearchCategory.values[i]),
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
              Expanded(child: _tabContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// Figma `304:9611` — back circle + Search Container showing the query.
  /// Tapping the pill (or clearing it) returns to the live-search screen.
  Widget _topBar() {
    return Row(
      children: [
        _BackButton(onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: SkifluxSpacing.spaceL),
        Expanded(
          child: GestureDetector(
            // The field is read-only here — editing happens back on the
            // search screen, which is still live underneath this route.
            onTap: () => Navigator.of(context).pop(),
            child: AbsorbPointer(
              child: SkifluxSearchField(controller: _queryController),
            ),
          ),
        ),
      ],
    );
  }

  /// `"8 results for "UI Design""` — count in Content/Disabled, quoted query
  /// in Content/Primary, both UI Input Label (Figma 304:9684, grammar fixed).
  Widget _countHeader() {
    final n = _results.total;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$n ${n == 1 ? 'result' : 'results'} for ',
            style: SkifluxTypography.uiInputLabel.copyWith(
              color: SkifluxColors.contentDisabled,
            ),
          ),
          TextSpan(
            text: '"${_results.query}"',
            style: SkifluxTypography.uiInputLabel.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _tabContent() {
    final items = switch (_tab) {
      SearchCategory.episodes => [
        for (final e in _results.episodes)
          EpisodeResultCard(
            episode: e,
            onTap: e.id.isEmpty ? null : () => _openEpisode(e),
          ),
      ],
      SearchCategory.creators => [
        for (final c in _results.creators) _creatorRow(c),
      ],
      SearchCategory.users => [
        for (final u in _results.users)
          PersonResultRow(
            person: u,
            actionLabel: 'View Profile',
            onAction: u.username.isEmpty ? null : () => _openUserProfile(u),
            onTap: () => _openUserProfile(u),
          ),
      ],
      SearchCategory.playlists => [
        for (final p in _results.playlists)
          PlaylistResultCard(
            playlist: p,
            onTap: p.id.isEmpty ? null : () => _openPlaylist(p),
          ),
      ],
    };

    if (items.isEmpty) {
      return Center(
        child: _emptyState(),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceL),
      itemBuilder: (_, i) => items[i],
    );
  }

  /// Creator row with a live Follow action mirroring the overview screen.
  Widget _creatorRow(PersonResult c) {
    final followed = ref
        .watch(subscriptionsProvider)
        .isSubscribed(c.id.isNotEmpty ? c.id : c.username);
    return PersonResultRow(
      person: c,
      actionLabel: followed ? 'Following' : 'Follow',
      onAction: followed || c.id.isEmpty ? null : () => _followCreator(c),
      onTap: () => _openCreatorProfile(c),
    );
  }

  Widget _emptyState() {
    return SkifluxEmptyState(
      icon: Image.asset(
        'assets/images/search_x_fill.png',
        package: 'skiflux_design_system',
        width: SkifluxSpacing.space4xl,
        height: SkifluxSpacing.space4xl,
      ),
      title: 'Nothing found',
      message:
          'No ${_tab.label.toLowerCase()} match "${_results.query}". '
          'Try a different term.',
    );
  }
}

/// Figma `304:9525` — 48px Background/Hover circle with a back chevron.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: SkifluxSpacing.space4xl,
        height: SkifluxSpacing.space4xl,
        decoration: const BoxDecoration(
          color: SkifluxColors.backgroundHover,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          RemixIcons.arrow_left_s_line,
          size: SkifluxIcons.sizeM,
          color: SkifluxColors.contentPrimary,
        ),
      ),
    );
  }
}
