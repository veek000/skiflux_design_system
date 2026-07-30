import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../playlists/playlist_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/public_user_profile_screen.dart';
import 'data/search_index.dart';
import 'search_result_widgets.dart';

/// Figma: **Search flow 01/02/03/06** — full results with count header and
/// Episodes | Creators | Users | Playlists tabs.
///
/// The Figma copy says "6 result for" — a slip; the header computes the real
/// total and pluralizes properly.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.results,
    this.initialTab = SearchCategory.episodes,
  });

  final SearchResults results;
  final SearchCategory initialTab;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
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

  void _openCreatorProfile(PersonResult person) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(creatorId: person.username)));
  }

  void _openUserProfile(PersonResult person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicUserProfileScreen(username: person.username),
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
          EpisodeResultCard(episode: e, onTap: () {}),
      ],
      SearchCategory.creators => [
        for (final c in _results.creators)
          PersonResultRow(
            person: c,
            actionLabel: 'Follow',
            onAction: () {},
            onTap: () => _openCreatorProfile(c),
          ),
      ],
      SearchCategory.users => [
        for (final u in _results.users)
          PersonResultRow(
            person: u,
            actionLabel: 'View Profile',
            onAction: () => _openUserProfile(u),
            onTap: () => _openUserProfile(u),
          ),
      ],
      SearchCategory.playlists => [
        for (final p in _results.playlists)
          PlaylistResultCard(
            playlist: p,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlaylistScreen())),
          ),
      ],
    };

    if (items.isEmpty) {
      return Center(
        child: SkifluxEmptyState(
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
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceL),
      itemBuilder: (_, i) => items[i],
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
