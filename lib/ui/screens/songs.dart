import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/main.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/ui/widgets/song_list_header.dart' as BaseSongListHeader;
import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';


/*
* 모든 곡 리스트
*/
class SongsScreen extends StatefulWidget {
  static const routeName = '/songs';

  const SongsScreen({Key? key}) : super(key: key);

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  late final SongListScreenProvider _provider;

  final _paginationConfig =
      AppState.get('songs.paginationConfig', SongPaginationConfig())!;

  late final ScrollController _scrollController;
  var _currentScrollOffset = AppState.get('songs.scrollOffSet', 0.0)!;
  final _scrollThreshold = 64.0;
  var _searchQuery = '';
  var _cover = CoverImageStack(songs: []);
  var _loading = false;
  var _errored = false;
  var _inSearchMode = false;

  void _scrollListener() {
    _currentScrollOffset = _scrollController.offset;

    if (_inSearchMode) return;

    if (_scrollController.position.pixels + _scrollThreshold >=
        _scrollController.position.maxScrollExtent) {
      makeRequest();
    }
  }

  @override
  void initState() {
    super.initState();

    _provider = context.read();

    _scrollController = ScrollController(
      initialScrollOffset: _currentScrollOffset,
    );

    _scrollController.addListener(_scrollListener);

    makeRequest();
  }

  Future<void> makeRequest() async {
    if (_loading || (_paginationConfig.page == null && !_inSearchMode)) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      final result = await _provider.fetch(
        paginationConfig: _paginationConfig,
        searchQuery: _searchQuery,
      );

      if (result != null) {
        _paginationConfig.page = result.nextPage;
      }
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _loading = false;
    AppState.set('songs.scrollOffSet', _currentScrollOffset);
    AppState.set('songs.paginationConfig', _paginationConfig);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<SongListScreenProvider>(
          builder: (_, provider, __) {
            if (provider.songs.isEmpty) {
              if (_loading) return const SongListScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: makeRequest);
            }

            if (_cover.isEmpty) {
              _cover = CoverImageStack(songs: provider.songs);
            }

            var displayedSongs = provider.songs;

            if (_inSearchMode) {
              // In search mode, sorting is done from the client side.
              displayedSongs =
                  displayedSongs.$sort(_paginationConfig.sortConfig);
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                AppBar(
                  headingText: '모든 곡',
                  actions: [
                    SortButton(
                      fields: ['title', 'artist_name', 'created_at'],
                      currentField: _paginationConfig.sortField,
                      currentOrder: _paginationConfig.sortOrder,
                      onMenuItemSelected: (sortConfig) {
                        setState(() {
                          _paginationConfig.sortField = sortConfig.field;
                          _paginationConfig.sortOrder = sortConfig.order;
                        });

                        if (_inSearchMode) return;

                        // If we're not searching but displaying the full list,
                        // every time we sort, we fetch a new list of songs,
                        // since the sorting is done from the server.
                        provider.songs.clear();
                        makeRequest();
                      },
                    ),
                  ],
                  coverImage: _cover,
                ),
                SliverToBoxAdapter(
                  child: SongListHeader(
                    sortField: _paginationConfig.sortField,
                    sortOrder: _paginationConfig.sortOrder,
                    onSearchExpanded: () =>
                        setState(() => _inSearchMode = true),
                    onSearchCollapsed: () => setState(
                      () => _inSearchMode = false,
                    ),
                    onSearchQueryChanged: (query) {
                      setState(() => _searchQuery = query);
                      makeRequest();
                    },
                  ),
                ),
                SliverSongList(
                  songs: displayedSongs,
                  listContext: BaseSongListHeader.SongListContext.allSongs,
                ),
                _loading
                    ? SliverToBoxAdapter(
                        child: Container(
                          height: 72,
                          child: const Center(child: const Spinner(size: 16)),
                        ),
                      )
                    : const SliverToBoxAdapter(),
                const BottomSpace(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SongListHeader extends StatefulWidget {
  final String sortField;
  final SortOrder sortOrder;
  final Function(String) onSearchQueryChanged;
  final Function() onSearchExpanded;
  final Function() onSearchCollapsed;

  const SongListHeader({
    Key? key,
    required this.sortField,
    required this.sortOrder,
    required this.onSearchQueryChanged,
    required this.onSearchExpanded,
    required this.onSearchCollapsed,
  }) : super(key: key);

  @override
  _SongListHeaderState createState() => _SongListHeaderState();
}

class _SongListHeaderState extends State<SongListHeader> {
  bool _fetchingSongsToPlayAll = false;
  bool _fetchingSongsToShuffle = false;

  late final SongProvider _songProvider;

  @override
  initState() {
    super.initState();
    _songProvider = context.read();
  }

  Future<void> fetchSongsToPlayAll() async {
    setState(() => _fetchingSongsToPlayAll = true);
    final songs = await _songProvider.fetchInOrder(
      sortField: widget.sortField,
      order: widget.sortOrder,
    );
    setState(() => _fetchingSongsToPlayAll = false);
    audioHandler.replaceQueue(songs);
  }

  Future<void> fetchSongsToShuffleAll() async {
    setState(() => _fetchingSongsToShuffle = true);
    final songs = await _songProvider.fetchRandom();
    setState(() => _fetchingSongsToShuffle = false);
    audioHandler.replaceQueue(songs, shuffle: true);
  }

  @override
  Widget build(BuildContext context) {
    return BaseSongListHeader.SongListHeader(
      songs: [],
      playIcon: _fetchingSongsToPlayAll
          ? SpinKitThreeBounce(color: AppColors.white.withOpacity(.5), size: 16)
          : null,
      shuffleIcon: _fetchingSongsToShuffle
          ? SpinKitThreeBounce(color: AppColors.white.withOpacity(.5), size: 16)
          : null,
      onSearchExpanded: widget.onSearchExpanded,
      onSearchCollapsed: widget.onSearchCollapsed,
      onSearchQueryChanged: widget.onSearchQueryChanged,
      onPlayPressed: () async {
        if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;
        await fetchSongsToPlayAll();
      },
      onShufflePressed: () async {
        if (_fetchingSongsToPlayAll || _fetchingSongsToShuffle) return;
        await fetchSongsToShuffleAll();
      },
    );
  }
}
