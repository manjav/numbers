import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/core/cells.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/dialogs/big.dart';
import 'package:numbers/dialogs/callout.dart';
import 'package:numbers/dialogs/tutorial.dart';
import 'package:numbers/dialogs/cube.dart';
import 'package:numbers/dialogs/pause.dart';
import 'package:numbers/dialogs/piggy.dart';
import 'package:numbers/dialogs/record.dart';
import 'package:numbers/dialogs/revive.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/stats.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/coins.dart';
import 'package:numbers/widgets/components.dart';
import 'package:rive/rive.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  MyGame? _game;
  GameWidget? _gameWidget;
  int loadingState = 0;

  AnimationController? _rewardLineAnimation;
  ConfettiController? _confettiController;

  bool _animationTime = false;
  Timer? _timer;

  void initState() {
    super.initState();
    _createGame();
    _rewardLineAnimation = AnimationController(
        vsync: this,
        upperBound: Price.piggy * 1.0,
        value: Pref.coinPiggy.value * 1.0);
    _rewardLineAnimation!.addListener(() => setState(() {}));
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            body: Stack(alignment: Alignment.bottomCenter, children: [
          _game == null ? SizedBox() : _gameWidget!,
          Positioned(
              top: MyGame.bounds.top - 69.d,
              left: MyGame.bounds.left,
              right: MyGame.bounds.left,
              child: _getHeader(theme)),
          Positioned(
              top: MyGame.bounds.bottom + 10.d,
              left: MyGame.bounds.left - 22.d,
              right: MyGame.bounds.left,
              child: _getFooter(theme)),
          _underFooter(),
          Center(child: Components.confetty(_confettiController!)),
          Coins("home",
              top: MyGame.bounds.top - 69.d,
              left: MyGame.bounds.left + 52.d,
              height: 56.d, onTap: () async {
            MyGame.isPlaying = false;
            await Rout.push(context, ShopDialog());
            MyGame.isPlaying = true;
            setState(() {});
          })
        ])));
  }

  Widget _getHeader(ThemeData theme) {
    if (Pref.tutorMode.value == 0) {
      return Center(
          child: Text("home_tutor".l(), style: theme.textTheme.headline4));
    }
    return SizedBox(
        height: 56.d,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Components.stats(theme, onTap: () {
            _pause("stats");
            Analytics.design('guiClick:stats:home');
            Rout.push(context, StatsDialog());
          }),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(height: 4.d),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(Prefs.score.format(),
                  style:
                      theme.textTheme.headline5!.copyWith(letterSpacing: -1)),
              SizedBox(width: 2.d),
              SVG.show("cup", 22.d)
            ]),
            Components.scores(theme, onTap: () {
              // _pause("record");
              // Analytics.design('guiClick:record:home');
              // GamesServices.showLeaderboards();
            })
          ]))
        ]));
  }

  Widget _getFooter(ThemeData theme) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    if (_game!.removingMode != null) {
      return Padding(
          padding: EdgeInsets.only(left: 22.d),
          child: Container(
              padding: EdgeInsets.fromLTRB(24.d, 18.d, 24.d, 20.d),
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 3.d,
                        color: Colors.black,
                        offset: Offset(0.5.d, 2.d))
                  ],
                  color: theme.cardColor,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("home_rm_${_game!.removingMode!}".l()),
                    GestureDetector(
                        child: SVG.show("close", 32.d), onTap: _onRemoveBlock)
                  ])));
    }
    return SizedBox(
        height: 68.d,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(
                icon: SVG.show("pause", 48.d),
                iconSize: 72.d,
                onPressed: () => _pause("tap")),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(
                      child: _button(
                          theme, 20.d, "piggy", () => _boost("piggy"),
                          // width: 96.d,
                          badge: Positioned(
                              height: 32.d,
                              bottom: 0,
                              left: 0,
                              right: 6.d,
                              child: Components.slider(
                                  theme,
                                  0,
                                  _rewardLineAnimation!.value.round(),
                                  Price.piggy,
                                  icon: SVG.show("coin", 32.d))),
                          colors: Pref.coinPiggy.value >= Price.piggy
                              ? TColors.orange.value
                              : null))
                ])),
            SizedBox(width: 4.d),
            _button(theme, 96.d, "remove-color", () => _boost("color"),
                badge: _badge(theme, Pref.removeColor.value)),
            SizedBox(width: 4.d),
            _button(theme, 20.d, "remove-one", () => _boost("one"),
                badge: _badge(theme, Pref.removeOne.value)),
          ],
        ));
  }

  _underFooter() {
    var isAdsReady = Ads.isReady();
    if (isAdsReady && _timer == null) {
      var duration = Duration(
          milliseconds: _animationTime
              ? CubeDialog.showTime
              : CubeDialog.waitingTime +
                  Random().nextInt(CubeDialog.waitingTime));
      _timer = Timer(duration, () {
        _animationTime = !_animationTime;
        _timer = null;
        setState(() {});
      });
    }

    if (!_animationTime) {
      var isBannerAdReady = Ads.isReady(AdPlace.Banner);
      var ad = Ads.getBanner("game", size: AdSize.banner);
      if (!isBannerAdReady) return SizedBox();
      return Positioned(
          bottom: 2.d,
          child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8.d)),
              child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad))));
    }
    return Positioned(
        left: 0,
        bottom: 0.d,
        height: 120.d,
        child: GestureDetector(
            onTap: _showCubeDialog,
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                  width: 80.d,
                  child: RiveAnimation.asset('anims/nums-character.riv',
                      stateMachines: ["runState"])),
              Container(
                  height: 44.d,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 12.d),
                  child: Text("cube_catch".l()),
                  decoration: Components.badgeDecoration(color: Colors.white)),
            ])));
  }

  Widget _button(
      ThemeData theme, double right, String icon, Function() onPressed,
      {double? width, Widget? badge, List<Color>? colors}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return SizedBox(
        width: width ?? 64.d,
        child: BumpedButton(
            colors: colors ?? TColors.whiteFlat.value,
            padding: EdgeInsets.fromLTRB(4.d, 0, 0, 4.d),
            content: Stack(children: [
              Positioned(
                  height: 46.d,
                  top: 4.d,
                  right: 2.d,
                  child: SVG.show(icon, 48.d)),
              badge ?? SizedBox()
            ]),
            onTap: () {
              Analytics.design('guiClick:$icon:game');
              onPressed();
            }));
  }

  Widget _badge(ThemeData theme, int value) {
    return Positioned(
        height: 22.d,
        bottom: 2.d,
        left: 0,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.d),
            child: Text(value == 0 ? "free_l".l() : "$value",
                style: theme.textTheme.headline6),
            decoration: Components.badgeDecoration()));
  }

  void _onGameEventHandler(GameEvent event, int value) async {
    Widget? _widget;
    switch (event) {
      case GameEvent.boost:
        await _boost("next");
        break;
      case GameEvent.celebrate:
        _confettiController!.play();
        return;
      case GameEvent.completeTutorial:
        _widget = TutorialDialog(_confettiController!);
        break;
      case GameEvent.lose:
        await Future.delayed(Duration(seconds: 1));
        _widget = ReviveDialog();
        break;
      case GameEvent.remove:
        _onRemoveBlock();
        break;
      case GameEvent.reward:
        await Coins.effect(value,
            x: MyGame.bounds.center.dx,
            y: MyGame.bounds.bottom + 8.d,
            duraion: 1000);
        var piggyCoins = (Pref.coinPiggy.value + value).clamp(0, Price.piggy);
        Pref.coinPiggy.set(piggyCoins);
        _rewardLineAnimation!.animateTo(piggyCoins * 1.0,
            duration: const Duration(seconds: 1), curve: Curves.easeInOutSine);
        if (piggyCoins >= Price.piggy) {
          await Future.delayed(Duration(milliseconds: 500));
          _game!.onGameEvent?.call(GameEvent.rewardPiggy, 1);
        }
        return;
      case GameEvent.rewardBig:
        await Future.delayed(Duration(milliseconds: 250));
        _widget = BigBlockDialog(value, _confettiController!);
        break;
      case GameEvent.rewardCube:
        _widget = CubeDialog();
        break;
      case GameEvent.rewardPiggy:
        _widget = PiggyDialog(playApplaud: value > 0);
        break;
      case GameEvent.rewardRecord:
        _widget = RecordDialog(_confettiController!);
        break;
      case GameEvent.score:
        setState(() {});
        return;
    }

    if (_widget != null) {
      MyGame.isPlaying = false;
      var result = await Rout.push(context, _widget);
      if (event == GameEvent.lose) {
        if (result == null) {
          if (value > 0)
            _game!.onGameEvent?.call(GameEvent.rewardRecord, 0);
          else
            _closeGame(result);
          return;
        }
        await Coins.change(result[1], "game", "revive");
        _game!.revive();
        MyGame.isPlaying = true;
        setState(() {});
        return;
      }

      if (event == GameEvent.rewardPiggy) {
        Pref.coinPiggy.set(0);
        _rewardLineAnimation!
            .animateTo(0, duration: const Duration(milliseconds: 400));
      }
      if (event == GameEvent.rewardRecord) {
        _closeGame(result);
        return;
      }
      MyGame.isPlaying = true;
      if (event == GameEvent.rewardBig ||
          event == GameEvent.rewardCube ||
          event == GameEvent.rewardPiggy) {
        await Future.delayed(Duration(milliseconds: 250));
        await Coins.change(result[1], "game", event.name);
        return;
      }

      if (event == GameEvent.completeTutorial) {
        Prefs.setString("cells", "");
        if (result[0] == "tutorFinish") {
          Pref.tutorMode.set(1);
          MyGame.boostNextMode = 1;
        }
        setState(() => _createGame());
        if (result[0] == "tutorFinish") {
          await Future.delayed(Duration(microseconds: 200));
          await Coins.change(Price.tutorial, "game", event.name);
        }
      }
    }
    _onPauseButtonsClick("resume");
  }

  void _pause(String source, {bool showMenu = true}) async {
    MyGame.isPlaying = false;
    Analytics.design('guiClick:pause:$source');
    if (!showMenu) return;
    var result = await Rout.push(context, PauseDialog());
    _onPauseButtonsClick(result == null ? "resume" : result[0]);
  }

  void _onPauseButtonsClick(String type) {
    switch (type) {
      case "home":
        Pref.score.set(Prefs.score);
        Navigator.of(context).pop();
        break;
      case "resume":
        MyGame.isPlaying = true;
        setState(() {});
        break;
    }
  }

  _boost(String type) async {
    if (type == "piggy") {
      Rout.push(context, PiggyDialog());
      return;
    }
    MyGame.isPlaying = false;
    if (type == "one" && Pref.removeOne.value > 0 ||
        type == "color" && Pref.removeColor.value > 0) {
      setState(() => _game!.removingMode = type);
      return;
    }
    EdgeInsets padding = EdgeInsets.only(
        right: MyGame.bounds.left, top: MyGame.bounds.bottom - 78.d);
    if (type == "next")
      padding = EdgeInsets.only(
          left: (Device.size.width - Callout.chromeWidth) * 0.5,
          top: MyGame.bounds.top + 68.d);
    var result = await Rout.push(
        context, Callout("clt_${type}_text".l(), type, padding: padding),
        barrierColor: Colors.transparent, barrierDismissible: true);
    if (result != null) {
      await Coins.change(result[1], "game", result[0]);
      if (type == "next") {
        _game!.boostNext();
        return;
      }
      if (type == "one") Pref.removeOne.set(1);
      if (type == "color") Pref.removeColor.set(1);
      setState(() => _game!.removingMode = type);
      return;
    }
    MyGame.isPlaying = true;
  }

  _createGame() {
    Analytics.setScreen("game");
    var top = 140.d;
    var bottom = 180.d;
    Cell.updateSizes((Device.size.height - top - bottom) / (Cells.height + 1));
    var padding = (Device.size.width - (Cells.width * Cell.diameter)) * 0.5;
    MyGame.bounds = Rect.fromLTRB(
        padding, top, Device.size.width - padding, Device.size.height - bottom);
    _game = MyGame(onGameEvent: _onGameEventHandler);
    _gameWidget = GameWidget(game: _game!);
  }

  _showCubeDialog() async {
    // Check fruad in frequently tap on cube man
    if (DateTime.now().millisecondsSinceEpoch - CubeDialog.earnedAt >
        CubeDialog.waitingTime)
      _game!.onGameEvent?.call(GameEvent.rewardCube, 0);
  }

  void _onRemoveBlock() {
    _game!.removingMode = null;
    MyGame.isPlaying = true;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    _pause("back");
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController?.stop();
    _confettiController?.dispose();
    _rewardLineAnimation?.dispose();
    super.dispose();
  }

  void _closeGame(result) {
    Analytics.endProgress(
        "main", Pref.playCount.value, Pref.record.value, Prefs.score);
    Navigator.of(context).pop(result);
  }
}
