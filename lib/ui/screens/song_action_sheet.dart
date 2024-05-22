import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/screens/add_to_playlist.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongActionSheet extends StatefulWidget {
  final Song song;

  const SongActionSheet({Key? key, required this.song}) : super(key: key);

  @override
  _SongActionSheetState createState() => _SongActionSheetState();
}

class _SongActionSheetState extends State<SongActionSheet> {
  var _queued = false;

  initState() {
    super.initState();

    audioHandler.queued(widget.song).then((queued) {
      setState(() => _queued = queued);
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final favoriteProvider = context.read<FavoriteProvider>();
    final isCurrent = audioHandler.mediaItem.value != null &&
        audioHandler.mediaItem.value!.id == song.id;
    final inOfflineMode =
        AppState.get('mode', AppMode.online) == AppMode.offline;

    return FrostedGlassBackground(
      sigma: 40.0,
      child: Container(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(), // to properly align the thumbnail area
            Column(
              children: [
                SongThumbnail.lg(song: song),
                const SizedBox(height: 16),
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${song.artistName} • ${song.albumName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
            ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: <Widget>[
                if (!isCurrent)
                  SongActionButton(
                    text: '다음 재생',
                    icon: const Icon(
                      CupertinoIcons.arrow_right_circle_fill,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.queueAfterCurrent(song);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.arrow_right_circle_fill,
                        caption: '대기열',
                        message: '다음 대기열에 추가되었습니다.',
                      );
                    },
                  ),
                if (!isCurrent)
                  SongActionButton(
                    text: '마지막 재생',
                    icon: const Icon(
                      CupertinoIcons.arrow_down_right_circle_fill,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.queueToBottom(song);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.arrow_down_right_circle_fill,
                        caption: '대기열',
                        message: '마지막 대기열에 추가되었습니다.',
                      );
                    },
                  ),
                if (_queued)
                  SongActionButton(
                    text: '대기열에서 제거',
                    icon: const Icon(
                      CupertinoIcons.text_badge_minus,
                      color: Colors.white30,
                    ),
                    onTap: () async {
                      await audioHandler.removeFromQueue(song);
                      showOverlay(
                        context,
                        icon: CupertinoIcons.text_badge_minus,
                        caption: '제거됨',
                        message: '대기열에서 제거 되었습니다.',
                      );
                    },
                  ),
                SongActionButton(
                  enabled: !inOfflineMode,
                  text: song.liked ? '즐겨찾기 제거' : '즐겨찾기 추가',
                  icon: Icon(
                    song.liked
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    showOverlay(
                      context,
                      caption: song.liked ? '제거됨' : '추가됨',
                      message: song.liked
                          ? '즐겨찾기에서 제거 되었습니다.'
                          : '즐겨찾기에 추가 되었습니다.',
                      icon: song.liked
                          ? CupertinoIcons.heart_slash
                          : CupertinoIcons.heart_fill,
                    );
                    favoriteProvider.toggleOne(song: song);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                SongActionButton(
                  enabled: !inOfflineMode,
                  text: '앨범 보기',
                  icon: const Icon(
                    CupertinoIcons.music_albums_fill,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    AppRouter().gotoAlbumDetailsScreen(
                      context,
                      albumId: song.albumId,
                    );
                  },
                  hideSheetOnTap: false,
                ),
                SongActionButton(
                  enabled: !inOfflineMode,
                  text: '가수 보기',
                  icon: const Icon(
                    CupertinoIcons.music_mic,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    AppRouter().gotoArtistDetailsScreen(
                      context,
                      artistId: song.artistId,
                    );
                  },
                  hideSheetOnTap: false,
                ),
                const Divider(indent: 16, endIndent: 16),
                SongActionButton(
                  enabled: !inOfflineMode,
                  text: '재생목록에 추가…',
                  icon: const Icon(
                    CupertinoIcons.text_badge_plus,
                    color: Colors.white30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    gotoAddToPlaylistScreen(context, song: song);
                  },
                  hideSheetOnTap: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SongActionButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final Function onTap;
  final bool hideSheetOnTap;
  final bool enabled;

  const SongActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.hideSheetOnTap = true,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      minLeadingWidth: 16,
      title: Text(
        text,
        style: enabled ? null : const TextStyle(color: Colors.white30),
      ),
      onTap: enabled
          ? () {
              onTap();
              if (hideSheetOnTap) Navigator.pop(context);
            }
          : null,
    );
  }
}
