import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoConnectionScreen extends StatefulWidget {
  static const routeName = '/no-connection';

  const NoConnectionScreen({Key? key}) : super(key: key);

  @override
  _NoConnectionScreenState createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen>
    with StreamSubscriber {
  @override
  void initState() {
    super.initState();

    subscribe(Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        AppState.delete('mode');
        Navigator.of(context).pushReplacementNamed(
          MainScreen.routeName,
        );
      }
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    subscribe(Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        AppState.set('mode', AppMode.online);
        Navigator.of(context).pushReplacementNamed(
          MainScreen.routeName,
        );
      }
    }));

    return Scaffold(
      body: GradientDecoratedContainer(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Wrap(
              direction: Axis.vertical,
              alignment: WrapAlignment.center,
              spacing: 24.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.wifi_slash,
                  size: 128,
                  color: AppColors.white.withOpacity(.4),
                ),
                Wrap(
                  direction: Axis.vertical,
                  alignment: WrapAlignment.center,
                  spacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('오프라인 상태입니다.'),
                    Text('인터넷에서 접속후 다시 시도해 주세요.')
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    AppState.set('mode', AppMode.offline);
                    Navigator.of(context).pushReplacementNamed(
                      MainScreen.routeName,
                    );
                  },
                  child: const Text('다운로드한 곡 보기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
