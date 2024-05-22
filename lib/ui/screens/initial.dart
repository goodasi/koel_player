import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:app/exceptions/exceptions.dart';

class InitialScreen extends StatefulWidget {
  static const routeName = '/';

  const InitialScreen({Key? key}) : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> with StreamSubscriber {
  
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();

    _auth = context.read();
    
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        Navigator.of(context).pushReplacementNamed(
          NoConnectionScreen.routeName,
        );
      } else {
        _resolveAuthenticatedUser();
      }
    });
  }

  String standardizeHost(String host) {
    host = host.trim().replaceAll(RegExp(r'/+$'), '');

    if (!host.startsWith("http://") && !host.startsWith("https://")) {
      host = "https://" + host;
    }

    return host;
  }

  Future<void> showErrorDialog(BuildContext context, {String? message}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(
          message ?? '로그인 도중 에러가 발생했습니다. 다시 시도해 주세요.',
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> attemptLogin() async {
    
    var successful = false;
    
    String _host = 'http://49.247.160.238:8000';
    String _email = 'admin@koel.dev';
    String _password = 'KoelIsCool';

    try {
      _host = standardizeHost(_host);
      await _auth.login(host: _host, email: _email, password: _password);
      await _auth.tryGetAuthUser();
      successful = true;
    } on HttpResponseException catch (error) {
      await showErrorDialog(
        context,
        message: error.response.statusCode == 401
            ? 'Invalid email or password.'
            : null,
      );
    } catch (error) {
      await showErrorDialog(context);
    } 

    if (successful) {
      preferences.host = _host;
      preferences.userEmail = _email;
      DataLoadingScreen();
    }
  }

  Future<void> _resolveAuthenticatedUser() async {
    try {
      final user = await context.read<AuthProvider>().tryGetAuthUser();

      if (user == null) {
        await attemptLogin();
      }

      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            const DataLoadingScreen(),
        transitionDuration: Duration.zero,
      ));
    } catch (e) {
      await Navigator.of(context, rootNavigator: true).pushReplacementNamed(
        LoginScreen.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const ContainerWithSpinner();
}
