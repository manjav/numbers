import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:project/core/cell.dart';
import 'package:project/core/cells.dart';
import 'package:project/core/game.dart';
import 'package:project/dialogs/big.dart';
import 'package:project/dialogs/callout.dart';
import 'package:project/dialogs/cube.dart';
import 'package:project/dialogs/pause.dart';
import 'package:project/dialogs/piggy.dart';
import 'package:project/dialogs/record.dart';
import 'package:project/dialogs/revive.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/dialogs/stats.dart';
import 'package:project/dialogs/tutorial.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';
import 'package:project/widgets/coins.dart';
import 'package:project/widgets/components.dart';
import 'package:rive/rive.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  MyGame? _game;
  GameWidget? _gameWidget;
  int loadingState = 0;

  AnimationController? _rewardLineAnimation;
  ConfettiController? _confettiController;

  bool _animationTime = false;
  Timer? _timer;

  @override
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
          _game == null ? const SizedBox() : _gameWidget!,
          Positioned(
              top: MyGame.bounds.top - 69.d,
              left: MyGame.bounds.left,
              right: MyGame.bounds.left,
              child: _getHeader(theme)),
          Positioned(
              top: MyGame.bounds.bottom + 16.d,
              left: MyGame.bounds.left + 2.d,
              right: MyGame.bounds.left,
              child: _getFooter(theme)),
          _underFooter(),
          Center(child: Components.confetty(_confettiController!)),
          Coins("home",
              top: MyGame.bounds.top - 69.d,
              left: MyGame.bounds.left + 52.d,
              height: 56.d)
        ])));
  }

  Widget _getHeader(ThemeData theme) {
    if (Pref.tutorMode.value == 0) {
      return Center(
          child: Text("game_tutor".l(), style: theme.textTheme.headline4));
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
            Components.scores(theme)
          ]))
        ]));
  }

  Widget _getFooter(ThemeData theme) {
    if (Pref.tutorMode.value == 0) return const SizedBox();
    if (_game!.removingMode != null) {
      return Container(
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
              borderRadius: const BorderRadius.all(Radius.circular(16))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("clt_${_game!.removingMode!.name}_tip".l()),
            GestureDetector(
                child: SVG.show("close", 32.d), onTap: _onRemoveBlock)
          ]));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      GestureDetector(
          child: SizedBox(
              width: 40.d, height: 64.d, child: SVG.show("pause", 40.d)),
          onTap: () => _pause("tap")),
      SizedBox(width: 6.d),
      Expanded(
        child: GestureDetector(
            onTap: () => _boost(Pref.coinPiggy),
            child: Components.slider(
                theme, 0, _rewardLineAnimation!.value.round(), Price.piggy,
                icon: SVG.show("piggy", 40.d))),
      ),
      SizedBox(width: 6.d),
      _button(theme, Pref.boostRemoveColor.name, () => _boost(Pref.boostRemoveColor),
          badge: _badge(theme, Pref.boostRemoveColor.value)),
      SizedBox(width: 2.d),
      _button(theme, Pref.boostRemoveOne.name, () => _boost(Pref.boostRemoveOne),
          badge: _badge(theme, Pref.boostRemoveOne.value)),
    ]);
  }

  _underFooter() {
    if (Ads.isReady && _timer == null) {
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
      return const SizedBox();
    }
    return Positioned(
        left: 0,
        bottom: 0,
        height: 120.d,
        child: GestureDetector(
            onTap: _showCubeDialog,
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                  width: 80.d,
                  child: const RiveAnimation.asset('anims/nums-character.riv',
                      stateMachines: ["runState"])),
              Container(
                  height: 44.d,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 12.d),
                  child: Text("cube_catch".l()),
                  decoration: Components.badgeDecoration(color: Colors.white)),
            ])));
  }

  Widget _button(ThemeData theme, String icon, Function() onPressed,
      {Widget? badge, List<Color>? colors}) {
    if (Pref.tutorMode.value == 0) return const SizedBox();
    return SizedBox(
        width: 68.d,
        height: 68.d,
        child: BumpedButton(
            colors: colors ?? TColors.whiteFlat.value,
            padding: EdgeInsets.fromLTRB(4.d, 0, 0, 4.d),
            content: Stack(children: [
              Positioned(
                  height: 46.d,
                  top: 4.d,
                  right: 2.d,
                  child: SVG.show(icon, 44.d)),
              badge ?? const SizedBox()
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
        await _boost(Pref.boostNext);
        break;
      case GameEvent.celebrate:
        _confettiController!.play();
        return;
      case GameEvent.completeTutorial:
        _widget = TutorialDialog(_confettiController!);
        break;
      case GameEvent.lose:
        await Future.delayed(const Duration(seconds: 1));
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
          await Future.delayed(const Duration(milliseconds: 500));
          _game!.onGameEvent?.call(GameEvent.rewardPiggy, 1);
        }
        return;
      case GameEvent.rewardBig:
        await Future.delayed(const Duration(milliseconds: 250));
        _widget = BigBlockDialog(value, _confettiController!);
        break;
      case GameEvent.rewardCube:
        _widget = CubeDialog();
        break;
      case GameEvent.rewardPiggy:
        _widget = PiggyDialog(value > 0);
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
          if (value > 0) {
            _game!.onGameEvent?.call(GameEvent.rewardRecord, 0);
          } else {
            _closeGame(result);
          }
          return;
        }
        await Coins.change(result[1], "game", "revive");
        _game!.revive();
        MyGame.isPlaying = true;
        setState(() {});
        return;
      }

      if (result != null && event == GameEvent.rewardPiggy) {
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
        await Future.delayed(const Duration(milliseconds: 250));
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
          await Future.delayed(const Duration(microseconds: 200));
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

  _boost(Pref type) async {
    if (type == Pref.coinPiggy) {
      _game!.onGameEvent?.call(GameEvent.rewardPiggy, 0);
      return;
    }
    MyGame.isPlaying = false;
    if (type.value > 0) {
      setState(() => _game!.removingMode = type);
      return;
    }
    EdgeInsets padding = EdgeInsets.only(
        right: MyGame.bounds.left, top: MyGame.bounds.bottom - 78.d);
    if (type == Pref.boostNext) {
      padding = EdgeInsets.only(
          left: (Device.size.width - Callout.chromeWidth) * 0.5,
          top: MyGame.bounds.top + 68.d);
    }
    var result = await Rout.push(context, Callout(type, padding: padding),
        barrierColor: Colors.transparent, barrierDismissible: true);
    if (result != null) {
      await Coins.change(result[1], "game", result[0]);
      if (type == Pref.boostNext) {
        _game!.boostNext();
        return;
      }
      type.set(1);
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
        CubeDialog.waitingTime) {
      _game!.onGameEvent?.call(GameEvent.rewardCube, 0);
    }
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
