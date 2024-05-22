import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  static const routeName = '/search';

  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var _hasFocus = false;
  var _initial = true;
  var _songs = <Song>[];
  var _artists = <Artist>[];
  var _albums = <Album>[];

  late final SearchProvider searchProvider;
  final _controller = TextEditingController(text: '');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    searchProvider = context.read();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  _search(String keywords) => EasyDebounce.debounce(
        '검색',
        const Duration(microseconds: 500), // typing on a phone isn't that fast
        () async {
          if (keywords.length == 0) return _resetSearch();
          if (keywords.length < 2) return;

          SearchResult result = await searchProvider.searchExcerpts(
            keywords: keywords,
          );

          setState(() {
            _initial = false;
            _songs = result.songs;
            _albums = result.albums;
            _artists = result.artists;
          });
        },
      );

  Widget get noResults {
    return const Padding(
      padding: EdgeInsets.only(left: AppDimensions.hPadding),
      child: Text(
        '없습니다.',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  void _resetSearch() {
    _controller.text = '';
    this.setState(() => _initial = true);
  }

  Widget get searchField {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.hPadding),
      child: Row(
        children: <Widget>[
          Expanded(
            child: CupertinoSearchTextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: AppDimensions.inputBorderRadius,
              ),
              placeholder: '검색어를 입력하세요.',
              onChanged: _search,
              onSuffixTap: _resetSearch,
            ),
          ),
          if (_hasFocus)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {
                  _resetSearch();
                  _focusNode.unfocus();
                },
                child: Text(
                  '취소',
                  style: TextStyle(color: AppColors.white.withOpacity(.7)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              searchField,
              if (!_initial)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SimpleSongList(songs: _songs, bordered: true),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppDimensions.hPadding,
                          ),
                          child: const Heading5(text: '앨범'),
                        ),
                        if (_albums.isEmpty)
                          noResults
                        else
                          HorizontalCardScroller(
                            cards: _albums.map(
                              (album) => AlbumCard(album: album),
                            ),
                          ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppDimensions.hPadding,
                          ),
                          child: const Heading5(text: '가수'),
                        ),
                        if (_artists.isEmpty)
                          noResults
                        else
                          HorizontalCardScroller(
                            cards: _artists.map(
                              (artist) => ArtistCard(artist: artist),
                            ),
                          ),
                        const BottomSpace(asSliver: false),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
