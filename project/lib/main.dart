import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:install_prompt/install_prompt.dart';
import 'package:project/dialogs/confirm.dart';
import 'package:project/dialogs/daily.dart';
import 'package:project/dialogs/home.dart';
import 'package:project/dialogs/quests.dart';
import 'package:project/dialogs/quit.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/games.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/notification.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  AppState createState() => AppState();
  static AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppState>();
}

class AppState extends State<MyApp> {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  ThemeData _themeData = Themes.darkData;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        theme: _themeData,
        builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
            child: child!),
        home: MainPage(analytics: analytics));
  }

  updateTheme() async {
    await Future.delayed(const Duration(milliseconds: 1));
    _themeData = Themes.darkData;
    setState(() {});
  }
}

class MainPage extends StatefulWidget {
  final FirebaseAnalytics analytics;
  const MainPage({Key? key, required this.analytics}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _loadingState = 0;
  @override
  Widget build(BuildContext context) {
    if (Device.size == Size.zero) {
      Device.size = MediaQuery.of(context).size;
      Device.ratio = Device.size.height / 764;
      Device.aspectRatio = Device.size.width / Device.size.height;
      // print("${Device.size} ${MediaQuery.of(context).devicePixelRatio}");
      MyApp.of(context)!.updateTheme();
      return const SizedBox();
    }

    _initServices();
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            body: _loadingState < 2
                ? const SizedBox()
                : SizedBox(
                    width: Device.size.width,
                    height: Device.size.height,
                    child: HomeDialog())));
  }

  Future<bool> _onWillPop() async {
    var result = await Rout.push(
        context,
        Confirm(
            "Install the game on your device to make sure you’ll always have your progress saved and safe!",
            acceptText: "Install",
            declineText: "Not yet"));
    if (result) InstallPrompt.showInstallPrompt();
    result = await Rout.push(context, QuitDialog(showAvatar: !result),
        barrierDismissible: true);
    return result != null;
  }

  _initServices() async {
    if (_loadingState > 0) return;
    _loadingState = 1;

    Ads.init();
    Sound.init();
    Games.signIn();
    Prefs.init(() async {
      await Localization.init();
      Analytics.init(widget.analytics);
      Days.init();
      Quests.init();
      Notifier.init();
      _recordApp();
      _loadingState = 2;
      setState(() {});
    });
    WidgetsBinding.instance!.addObserver(this);
  }

  _recordApp() async {
    /* if (Pref.visitCount.value > 1) return;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt < 30) return;
    Smartlook.setupAndStartRecording(SetupOptionsBuilder("sl_key".l()).build()); */
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) Ads.pausedApp();
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
