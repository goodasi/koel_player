import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  static const routeName = '/library';

  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overviewProvider = context.watch<OverviewProvider>();
    final recentlyAddedSongs = overviewProvider.recentlyAddedSongs;
    final mostPlayedSongs = overviewProvider.mostPlayedSongs;

    final menuItems = ListTile.divideTiles(
      context: context,
      tiles: <Widget>[
        LibraryMenuItem(
          icon: CupertinoIcons.music_note,
          label: '곡',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const SongsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.heart_fill,
          label: '즐겨찾기',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_note_list,
          label: '재생목록',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const PlaylistsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_mic,
          label: '가수',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const ArtistsScreen()),
          ),
        ),
        LibraryMenuItem(
          icon: CupertinoIcons.music_albums,
          label: '앨범',
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const AlbumsScreen()),
          ),
        ),
        // LibraryMenuItem(
        //   icon: CupertinoIcons.cloud_download_fill,
        //   label: 'Downloaded',
        //   onTap: () => Navigator.of(context).push(
        //     CupertinoPageRoute(builder: (_) => DownloadedScreen()),
        //   ),
        // ),
      ],
    ).toList();

    return Scaffold(
      body: CupertinoTheme(
        data: CupertinoThemeData(primaryColor: Colors.white),
        child: GradientDecoratedContainer(
          child: CustomScrollView(
            slivers: <Widget>[
              const CupertinoSliverNavigationBar(
                backgroundColor: AppColors.screenHeaderBackground,
                largeTitle: const LargeTitle(text: '보관함'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(menuItems),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.hPadding,
                  24,
                  AppDimensions.hPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: const Heading5(text: '최근곡'),
                ),
              ),
              recentlyAddedSongs.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverSongList(songs: recentlyAddedSongs),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.hPadding,
                  24,
                  AppDimensions.hPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: const Heading5(text: '많이 들은곡'),
                ),
              ),
              mostPlayedSongs.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverSongList(songs: mostPlayedSongs),
              const BottomSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryMenuItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final void Function() onTap;

  const LibraryMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  })  : assert(
          icon is IconData || icon is Widget,
          'icon must be of either IconData or Widget type.',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.hPadding,
          ),
          horizontalTitleGap: 12,
          leading: icon is IconData ? Icon(icon, color: Colors.white54) : icon,
          title: Text(label, style: const TextStyle(fontSize: 20)),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: Colors.white30,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
