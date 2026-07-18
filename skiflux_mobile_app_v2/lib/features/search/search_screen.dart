import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../playlists/playlist_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/public_user_profile_screen.dart';
import 'data/recent_searches_store.dart';
import 'data/search_index.dart';
import 'search_result_widgets.dart';
import 'search_results_screen.dart';

/// Figma: **Search flow 04/05/07/08** — search landing + live results
/// overview.
///
/// States:
/// - Empty query, no history → first-use empty state ("What are you looking
///   for?", flow 07)
/// - Empty query, has history → Recent list with Clear all (flow 08)
/// - Typing, hits → grouped overview with See-all sections + bottom
///   "See all results" link (flow 04)
/// - Typing, no hits → Nothing-found empty state (flow 05)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _store = RecentSearchesStore();

  List<RecentSearch> _recents = [];
  SearchResults _results = SearchIndex.search('');

  @override
  void initState() {
    super.initState();
    _store.load().then((entries) {
      if (mounted) setState(() => _recents = entries);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() => _results = SearchIndex.search(query));
  }

  /// Commit the query to history, then open the results screen on [tab].
  Future<void> _openResults(SearchCategory tab) async {
    final results = _results;
    if (results.query.isEmpty) return;
    final updated = await _store.add(RecentSearch(
      query: results.query,
      topCategory: results.topCategory,
      resultCount: results.total,
    ));
    if (!mounted) return;
    setState(() => _recents = updated);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(results: results, initialTab: tab),
      ),
    );
  }

  void _runRecent(RecentSearch entry) {
    _controller.text = entry.query;
    _onQueryChanged(entry.query);
  }

  Future<void> _removeRecent(RecentSearch entry) async {
    final updated = await _store.remove(entry.query);
    if (mounted) setState(() => _recents = updated);
  }

  Future<void> _clearRecents() async {
    await _store.clear();
    if (mounted) setState(() => _recents = []);
  }

  void _openCreatorProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openUserProfile(PersonResult person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(
          profile: PublicUserProfile.demo(
            name: person.name,
            username: person.username,
          ),
        ),
      ),
    );
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
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  /// Figma `304:9524` — 48px back circle + Search Container.
  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
        ),
        const SizedBox(width: SkifluxSpacing.spaceL),
        Expanded(
          child: SkifluxSearchField(
            controller: _controller,
            autofocus: true,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _openResults(SearchCategory.episodes),
            onCleared: () => _onQueryChanged(''),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_results.query.isEmpty) {
      return _recents.isEmpty ? _firstUseState() : _recentList();
    }
    return _results.isEmpty ? _nothingFoundState() : _overview();
  }

  /// Flow 07 (`304:9481`).
  Widget _firstUseState() {
    return const Center(
      child: SkifluxEmptyState(
        icon: Icon(
          RemixIcons.search_fill,
          size: SkifluxSpacing.space4xl,
          color: SkifluxColors.contentBrand,
        ),
        title: 'What are you looking for?',
        message: 'Search across episodes, creators, users and playlists '
            'all in one place.',
      ),
    );
  }

  /// Flow 05 (`2374:11917`) — uses the search-x glyph exported from Figma
  /// (missing from remixicon).
  Widget _nothingFoundState() {
    return Center(
      child: SkifluxEmptyState(
        icon: Image.asset(
          'assets/images/search_x_fill.png',
          package: 'skiflux_design_system',
          width: SkifluxSpacing.space4xl,
          height: SkifluxSpacing.space4xl,
        ),
        title: 'Nothing found',
        message: 'No episodes, creators, or playlists match '
            '"${_results.query}". Try a different term.',
      ),
    );
  }

  /// Flow 08 (`304:9423`) — Recent header with Clear all + rows.
  Widget _recentList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SearchSectionHeader(
          title: 'Recent',
          // Figma: "Recent" heading is H7-scale (78×29) unlike the 16px
          // overview section headers.
          titleStyle: SkifluxTypography.headingH7Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
          actionLabel: 'Clear all',
          onAction: _clearRecents,
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        for (final entry in _recents) ...[
          RecentSearchRow(
            entry: entry,
            onTap: () => _runRecent(entry),
            onRemove: () => _removeRecent(entry),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
        ],
      ],
    );
  }

  /// Flow 04 (`304:9521`) — grouped overview. Each section shows up to
  /// [_previewLimit] items with a See-all link into the tabbed screen.
  static const _previewLimit = 2;

  Widget _overview() {
    final r = _results;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (r.episodes.isNotEmpty)
          _section(
            category: SearchCategory.episodes,
            first: true,
            children: [
              for (final e in r.episodes.take(_previewLimit))
                EpisodeResultCard(episode: e, onTap: () {}),
            ],
          ),
        if (r.creators.isNotEmpty)
          _section(
            category: SearchCategory.creators,
            first: r.episodes.isEmpty,
            children: [
              for (final c in r.creators.take(_previewLimit))
                PersonResultRow(
                  person: c,
                  actionLabel: 'Follow',
                  onAction: () {},
                  onTap: _openCreatorProfile,
                ),
            ],
          ),
        if (r.users.isNotEmpty)
          _section(
            category: SearchCategory.users,
            first: r.episodes.isEmpty && r.creators.isEmpty,
            children: [
              for (final u in r.users.take(_previewLimit))
                PersonResultRow(
                  person: u,
                  actionLabel: 'View Profile',
                  onAction: () => _openUserProfile(u),
                  onTap: () => _openUserProfile(u),
                ),
            ],
          ),
        if (r.playlists.isNotEmpty)
          _section(
            category: SearchCategory.playlists,
            first: r.episodes.isEmpty && r.creators.isEmpty && r.users.isEmpty,
            children: [
              for (final p in r.playlists.take(_previewLimit))
                PlaylistResultCard(
                  playlist: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlaylistScreen(),
                    ),
                  ),
                ),
            ],
          ),
        _seeAllResultsLink(),
      ],
    );
  }

  /// Figma `304:9562` — sections after the first carry a top divider and
  /// vertical padding.
  Widget _section({
    required SearchCategory category,
    required bool first,
    required List<Widget> children,
  }) {
    return Container(
      padding: first
          ? const EdgeInsets.only(bottom: SkifluxSpacing.spaceS)
          : const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceS),
      decoration: first
          ? null
          : const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: SkifluxColors.borderTertiary,
                  width: SkifluxBorderWidth.xs,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchSectionHeader(
            title: category.label,
            actionLabel: 'See all',
            onAction: () => _openResults(category),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          for (final child in children) ...[
            child,
            const SizedBox(height: SkifluxSpacing.spaceL),
          ],
        ],
      ),
    );
  }

  /// Figma `304:9598` — bottom link into the tabbed screen (Episodes tab).
  Widget _seeAllResultsLink() {
    return GestureDetector(
      onTap: () => _openResults(SearchCategory.episodes),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceXs),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceXs,
              ),
              child: Text(
                'See all results for "${_results.query}"',
                style: SkifluxTypography.headingH10Bold.copyWith(
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ),
            const Icon(
              RemixIcons.arrow_right_line,
              size: 20,
              color: SkifluxColors.contentBrand,
            ),
          ],
        ),
      ),
    );
  }
}
