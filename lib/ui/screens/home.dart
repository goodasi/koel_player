import 'dart:math';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _loading = false;
  var _errored = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<OverviewProvider>().refresh();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverviewProvider>(
      builder: (_, overviewProvider, __) {
        if (_loading) return const HomeScreenPlaceholder();
        if (_errored) return OopsBox(onRetry: fetchData);

        final blocks = <Widget>[
          if (overviewProvider.mostPlayedSongs.isNotEmpty)
            HorizontalCardScroller(
              headingText: '인기 곡',
              cards: <Widget>[
                ...overviewProvider.mostPlayedSongs
                    .map((song) => SongCard(song: song)),
                PlaceholderCard(
                  icon: CupertinoIcons.music_note,                 
                  onPressed: () => Navigator.of(context).push(                    
                    CupertinoPageRoute(builder: (_) => SongsScreen()),
                  ),
                ),
              ],
            ),
          if (overviewProvider.mostPlayedAlbums.isNotEmpty)
            HorizontalCardScroller(
              headingText: '인기 앨범',
              cards: <Widget>[
                ...overviewProvider.mostPlayedAlbums
                    .map((album) => AlbumCard(album: album)),
                PlaceholderCard(
                  icon: CupertinoIcons.music_albums,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => AlbumsScreen()),
                  ),
                ),
              ],
            ),
          if (overviewProvider.mostPlayedArtists.isNotEmpty)
            HorizontalCardScroller(
              headingText: '인기 가수',
              cards: <Widget>[
                ...overviewProvider.mostPlayedArtists
                    .map((artist) => ArtistCard(artist: artist)),
                PlaceholderCard(
                  icon: CupertinoIcons.music_mic,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const ArtistsScreen()),
                  ),
                ),
              ],
            ),
        ]
            .map(
              (widget) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: widget,
              ),
            )
            .toList();

        return Scaffold(
          body: CupertinoTheme(
            data: const CupertinoThemeData(
              primaryColor: AppColors.white,
              barBackgroundColor: AppColors.screenHeaderBackground,
            ),
            child: PullToRefresh(
              onRefresh: () => context.read<OverviewProvider>().refresh(),
              child: CustomScrollView(
                slivers: overviewProvider.isEmpty
                    ? [SliverToBoxAdapter(child: const EmptyHomeScreen())]
                    : <Widget>[
                        CupertinoSliverNavigationBar(
                          largeTitle: const LargeTitle(text: '홈'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(RecentlyPlayedScreen.routeName);
                                },
                                icon: const Icon(CupertinoIcons.time, size: 23),
                              ),
                              const ProfileAvatar(),
                            ],
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            HomeRecentlyPlayedSection(
                              initialSongs:
                                  overviewProvider.recentlyPlayedSongs,
                            ),
                            ...blocks,
                          ]),
                        ),
                        const BottomSpace(height: 192),
                      ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeRecentlyPlayedSection extends StatefulWidget {
  final List<Song> initialSongs;

  const HomeRecentlyPlayedSection({Key? key, required this.initialSongs})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeRecentlyPlayedSectionState();
}

class _HomeRecentlyPlayedSectionState extends State<HomeRecentlyPlayedSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RecentlyPlayedProvider>(
      builder: (_, overviewProvider, __) {
        final songs = overviewProvider.songs.isNotEmpty
            ? overviewProvider.songs
                .getRange(0, min(4, overviewProvider.songs.length))
            : widget.initialSongs
                .getRange(0, min(4, widget.initialSongs.length));

        return songs.isEmpty ? SizedBox.shrink() : SimpleSongList(songs: songs);
      },
    );
  }
}

class EmptyHomeScreen extends StatelessWidget {
  const EmptyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.music_note,
              size: 100,
              color: AppColors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 없습니다…',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '새로고침 하려면 아래로 끌어내리세요.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
