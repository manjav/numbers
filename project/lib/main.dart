// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/dialogs/daily.dart';
import 'package:project/dialogs/home.dart';
import 'package:project/dialogs/quests.dart';
import 'package:project/dialogs/quit.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/notification.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  ThemeData _themeData = Themes.darkData;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return MaterialApp(
        theme: _themeData,
        builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
            child: child!),
        home: MainPage());
  }

  updateTheme() async {
    await Future.delayed(const Duration(milliseconds: 1));
    _themeData = Themes.darkData;
    setState(() {});
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _loadingState = 0;
  @override
  Widget build(BuildContext context) {
    if (Device.size.width == 0) {
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
    var result =
        await Rout.push(context, QuitDialog(), barrierDismissible: true);
    return result != null;
  }

  _initServices() async {
    if (_loadingState > 0) return;
    _loadingState = 1;

    Sound.init();
    Prefs.init(() async {
      await Localization.init();
      Analytics.init();
      Days.init();
      Quests.init();
      Notifier.init();
      Ads.init();
      _loadingState = 2;
      setState(() {});
    });
  }
}
