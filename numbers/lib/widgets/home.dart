import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/overlays/all.dart';
import 'package:numbers/overlays/pause.dart';
import 'package:numbers/overlays/shop.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/components.dart';

class HomePage extends StatefulWidget {
  final Function() onBack;
  HomePage(this.onBack, {Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MyGame? _game;
  int loadingState = 0;

  void initState() {
    super.initState();
    _game = MyGame(onGameEvent: _onGameEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
        body: Stack(children: [
      GameWidget(game: _game!),
      Positioned(
          top: _game!.bounds.top - 68.d,
          right: 28.d,
          child: Components.scores(theme)),
      Positioned(
          top: _game!.bounds.top - 70.d,
          left: 28.d,
          child: Components.coins(context, onTap: () async {
            _game!.isPlaying = false;
            await Rout.push(context, ShopOverlay());
            _game!.isPlaying = true;
          })),
      Positioned(
          bottom: 6.d,
          left: 20.d,
          width: 56.d,
          height: 65.d,
          child: IconButton(icon: SVG.show("pause", 48.d), onPressed: _pause)),
      Positioned(
          bottom: 4.d,
          right: 20.d,
          width: 72.d,
          height: 72.d,
          child: IconButton(
              icon: SVG.show("remove-one", 64.d),
              onPressed: () => _boost("one"))),
      Positioned(
          bottom: 4.d,
          right: 92.d,
          width: 72.d,
          height: 72.d,
          child: IconButton(
              icon: SVG.show("remove-color", 64.d),
              onPressed: () => _boost("color"))),
      _game!.removingMode == null
          ? SizedBox()
          : Positioned(
              bottom: 4,
              right: 4.d,
              left: 4.d,
              height: 86.d,
              child: Container(
                padding: EdgeInsets.fromLTRB(32, 28, 32, 32),
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 3,
                          color: Colors.black,
                          offset: Offset(0.5, 2))
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
    ]));
  }

  void _onGameEventHandler(GameEvent event, int value) async {
    Widget? _widget;
    switch (event) {
      case GameEvent.big:
        _widget = Overlays.bigValue(context, value);
        break;
      case GameEvent.boost:
        await _boost("next");
        break;
      case GameEvent.lose:
        _widget = Overlays.revive(context, 100 * (_game!.numRevives + 1));
        break;
      case GameEvent.record:
        _widget = Overlays.record(context);
        break;
      case GameEvent.remove:
        _onRemoveBlock();
        break;
      case GameEvent.score:
        setState(() {});
        return;
    }

    if (_widget != null) {
      var result = await Rout.push(context, _widget);
      if (event == GameEvent.lose) {
        if (result == null) widget.onBack();
        _game!.revive();
        setState(() {});
        return;
      }
    }
    _onPauseButtonsClick("resume");
  }

  void _pause({bool showMenu = true}) async {
    _game!.isPlaying = false;
    if (!showMenu) return;
    var result = await Rout.push(context, PauseOverlay());
    _onPauseButtonsClick(result ?? "resume");
  }

  void _onPauseButtonsClick(String type) {
    switch (type) {
      case "reset":
        widget.onBack();
        break;
      case "resume":
        _game!.isPlaying = true;
        setState(() {});
        break;
    }
  }

  _boost(String type) async {
    _game!.isPlaying = false;

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
    _game!.isPlaying = true;
  }

  void _onRemoveBlock() {
    _game!.removingMode = null;
    _game!.isPlaying = true;
    setState(() {});
  }
}
