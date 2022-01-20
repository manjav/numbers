import 'dart:math';

import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

class ReviveDialog extends AbstractDialog {
  ReviveDialog({Key? key})
      : super(
          DialogMode.revive,
          key: key,
          sfx: "lose",
          title: "revive_l".l(),
          width: 310.d,
        );
  @override
  _ReviveDialogState createState() => _ReviveDialogState();
}

class _ReviveDialogState extends AbstractDialogState<ReviveDialog> {
  var _cells = "";
  var _lastBig = 0;
  var _maxRandom = 0;
  var _numRevives = 0;
  var _score = 0;

  @override
  void initState() {
    // Immediate reset game stats (Anti fraud)
    _cells = Prefs.getString("cells");
    _lastBig = Pref.lastBig.value;
    _maxRandom = Pref.maxRandom.value;
    _numRevives = Pref.numRevives.value;
    _score = Pref.score.value;
    Prefs.setString("cells", "");
    Pref.lastBig.set(Cell.firstBigRecord);
    Pref.maxRandom.set(Cell.maxRandomValue);
    Pref.numRevives.set(0);
    Pref.score.set(0);

    super.initState();
  }

  @override
  Widget contentFactory(ThemeData theme) {
    var cost = Price.revive * pow(2, _numRevives).round();
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SVG.show("record", 16.d),
          Text(" ${Pref.record.value.format()}",
              style: theme.textTheme.headline6)
        ])),
        Positioned(
            top: 24.d,
            child:
                Text(Prefs.score.format(), style: theme.textTheme.headline3)),
        const Center(
            heightFactor: 0.85,
            child: RiveAnimation.asset('anims/nums-revive.riv',
                stateMachines: ["machine"])),
        Positioned(
            height: 76.d,
            width: 116.d,
            bottom: 4.d,
            left: 4.d,
            child: BumpedButton(
                onTap: () => buttonsClick(context, "revive", -cost, false),
                cornerRadius: 16.d,
                content: Stack(alignment: Alignment.centerLeft, children: [
                  SVG.show("coin", 36.d),
                  Positioned(
                      top: 5.d,
                      left: 40.d,
                      child: Text("$cost", style: theme.textTheme.button)),
                  Positioned(
                      bottom: 7.d,
                      left: 40.d,
                      child: Text("revive_l".l(),
                          style: theme.textTheme.subtitle1)),
                ]))),
        PunchButton(
            height: 76.d,
            width: 130.d,
            bottom: 4.d,
            right: 4.d,
            cornerRadius: 16.d,
            errorMessage: Toast("ads_unavailable".l(), monoIcon: "A"),
            isEnable: _numRevives < 2 && Ads.isReady(),
            onTap: () => buttonsClick(context, "revive", 0, true),
            colors: TColors.orange.value,
            content: Stack(alignment: Alignment.centerLeft, children: [
              SVG.icon("A", theme),
              Positioned(
                  top: 5.d,
                  left: 40.d,
                  child: Text("free_l".l(), style: theme.textTheme.headline4)),
              Positioned(
                  bottom: 7.d,
                  left: 40.d,
                  child:
                      Text("revive_l".l(), style: theme.textTheme.headline6)),
            ]))
      ],
    );
  }

  @override
  buttonsClick(BuildContext context, String type, int coin, bool showAd) async {
    if (coin < 0 && Pref.coin.value < -coin) {
      Rout.push(context, ShopDialog());
      return;
    }
    if (showAd) {
      var reward = await Ads.showRewarded();
      if (reward == null) return;
    } else if (coin > 0 && Ads.showSuicideInterstitial) {
      await Ads.showInterstitial(AdPlace.interstitial);
    }

    // rterive game stats (Anti fraud)
    Prefs.setString("cells", _cells);
    Pref.lastBig.set(_lastBig);
    Pref.maxRandom.set(_maxRandom);
    Pref.numRevives.set(_numRevives);
    Pref.score.set(_score);
    Navigator.of(context).pop([type, coin]);
  }
}
