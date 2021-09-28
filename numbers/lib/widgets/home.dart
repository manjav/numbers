import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:install_prompt/install_prompt.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/core/cells.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/overlays/all.dart';
import 'package:numbers/overlays/pause.dart';
import 'package:numbers/overlays/shop.dart';
import 'package:numbers/overlays/stats.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/utils/gemeservice.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  MyGame? _game;
  int loadingState = 0;

  Positioned? _coins;
  AnimationController? _rewardAnimation;

  void initState() {
    super.initState();
    _createGame();
    _rewardAnimation = AnimationController(vsync: this);
    _rewardAnimation!.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            body: Stack(children: [
          _game == null ? SizedBox() : GameWidget(game: _game!),
          Positioned(
              top: _game!.bounds.top - 69.d,
              right: 20.d,
              child: Components.scores(theme, onTap: () {
                _pause();
                PlayGames.showLeaderboard("CgkIw9yXzt4XEAIQAQ");
              })),
          Positioned(
              top: _game!.bounds.top - 45.d,
              right: 23.d,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(Prefs.score.format(),
                    style:
                        theme.textTheme.headline5!.copyWith(letterSpacing: -1)),
                SizedBox(width: 2.d),
                SVG.show("cup", 22.d)
              ])),
          Positioned(
              top: _game!.bounds.top - 70.d,
              left: 22.d,
              child: Components.stats(theme, onTap: () {
                _pause();
                Rout.push(context, StatsOverlay());
              })),
          _coins = Positioned(
              top: _game!.bounds.top - 70.d,
              left: 73.d,
              height: 52.d - 5 * _rewardAnimation!.value,
              child: Components.coins(context, onTap: () async {
                MyGame.isPlaying = false;
                await Rout.push(context, ShopOverlay());
                MyGame.isPlaying = true;
                setState(() {});
              })),
          Pref.tutorMode.value == 0
              ? Positioned(
                  top: _game!.bounds.top - 68.d,
                  right: 22.d,
                  left: 28.d,
                  child: Text("How to play?",
                      style: theme.textTheme.headline4,
                      textAlign: TextAlign.center))
              : SizedBox(),
          Pref.tutorMode.value == 0
              ? SizedBox()
              : Positioned(
                  top: _game!.bounds.bottom + 16.d,
                  left: 20.d,
                  width: 56.d,
                  height: 65.d,
                  child: IconButton(
                      icon: SVG.show("pause", 48.d), onPressed: _pause)),
          _removeButton(theme, 20.d, "remove-one", () => _boost("one")),
          _badge(theme, 60.d, Pref.removeOne.value),
          _removeButton(theme, 96.d, "remove-color", () => _boost("color")),
          _badge(theme, 136.d, Pref.removeColor.value),
          _game!.removingMode == null
              ? SizedBox()
              : Positioned(
                  top: _game!.bounds.bottom + 10.d,
                  right: 4.d,
                  left: 4.d,
                  height: 86.d,
                  child: Container(
                      padding: EdgeInsets.fromLTRB(32.d, 28.d, 32.d, 32.d),
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
                            Text("Select ${_game!.removingMode} to remove!"),
                            GestureDetector(
                                child: SVG.show("close", 32.d),
                                onTap: _onRemoveBlock)
                          ])))
        ])));
  }

  Widget _removeButton(
      ThemeData theme, double right, String icon, Function() onPressed) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Positioned(
        top: _game!.bounds.bottom + 10.d,
        right: right,
        width: 72.d,
        height: 72.d,
        child: IconButton(icon: SVG.show(icon, 64.d), onPressed: onPressed));
  }

  Widget _badge(ThemeData theme, double right, int value) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Positioned(
        top: _game!.bounds.bottom + 52.d,
        height: 22.d,
        right: right,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.d),
            child: Text(value == 0 ? "free" : "$value",
                style: theme.textTheme.headline6),
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: 4.d,
                      color: Colors.black,
                      offset: Offset(0.5.d, 0.5.d))
                ],
                color: Colors.pink[700],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(12)))));
  }

  void _onGameEventHandler(GameEvent event, int value) async {
    Widget? _widget;
    switch (event) {
      case GameEvent.big:
        _widget = Overlays.bigValue(context, value);
        Prefs.increaseBig(value);
        break;
      case GameEvent.boost:
        await _boost("next");
        break;
      case GameEvent.completeTutorial:
        _widget = Overlays.endTutorial(context);
        break;
      case GameEvent.lose:
        await Future.delayed(Duration(seconds: 1));
        _widget = Overlays.revive(context, _game!.numRevives);
        break;
      case GameEvent.record:
        _widget = Overlays.record(context);
        break;
      case GameEvent.remove:
        _onRemoveBlock();
        break;
      case GameEvent.reward:
        _game!.showReward(
            value, Vector2(_coins!.left! + 24.d, _coins!.top! + 16.d));
        return;
      case GameEvent.rewarded:
        _rewardAnimation!.value = 1;
        _rewardAnimation!.animateTo(0,
            duration: Duration(milliseconds: 200), curve: Curves.easeOutSine);
        return;
      case GameEvent.score:
        setState(() {});
        return;
    }

    if (_widget != null) {
      var result = await Rout.push(context, _widget);
      if (event == GameEvent.lose) {
        if (result == null) {
          Navigator.of(context).pop();
          InstallPrompt.showInstallPrompt();
          return;
        }
        _game!.revive();
        setState(() {});
        return;
      }
      if (event == GameEvent.completeTutorial) {
        if (result == "tutorFinish") Pref.tutorMode.set(1);
        MyGame.boostNextMode = 1;
        _createGame();
      }
    }
    _onPauseButtonsClick("resume");
  }

  void _pause({bool showMenu = true}) async {
    MyGame.isPlaying = false;
    if (!showMenu) return;
    var result = await Rout.push(context, PauseOverlay());
    _onPauseButtonsClick(result ?? "resume");
  }

  void _onPauseButtonsClick(String type) {
    switch (type) {
      case "reset":
        Navigator.of(context).pop();
        break;
      case "resume":
        MyGame.isPlaying = true;
        setState(() {});
        break;
    }
  }

  _boost(String type) async {
    MyGame.isPlaying = false;

    if (type == "one" && Pref.removeOne.value > 0 ||
        type == "color" && Pref.removeColor.value > 0) {
      setState(() => _game!.removingMode = type);
      return;
    }
    var title = "";
    EdgeInsets padding = EdgeInsets.only(right: 16, bottom: 80);
    switch (type) {
      case "next":
        title = "Show next upcomming block!";
        padding = EdgeInsets.only(left: 32, top: _game!.bounds.top + 68);
        break;
      case "one":
        title = "Remove one block!";
        break;
      case "color":
        title = "Select color for remove!";
        break;
    }
    var result = await Rout.push(
        context, Overlays.callout(context, title, type, padding: padding),
        barrierColor: Colors.transparent, barrierDismissible: true);
    if (result != null) {
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

  void _createGame() {
    var padding = 24.d + (Device.size.aspectRatio - 0.5) * 200.d;
    var width = Device.size.width - padding * 2;
    Cell.diameter = width / Cells.width;
    Cell.radius = Cell.diameter * 0.5;

    var t = (Device.size.height - ((Cells.height + 1) * Cell.diameter)) * 0.5;
    var bounds = Rect.fromLTRB(
        padding, t, Device.size.width - padding, t + Cell.diameter * 7);
    _game = MyGame(bounds: bounds, onGameEvent: _onGameEventHandler);
  }

  void _onRemoveBlock() {
    _game!.removingMode = null;
    MyGame.isPlaying = true;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    _pause();
    return true;
  }
}
