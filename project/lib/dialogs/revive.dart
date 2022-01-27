import 'dart:math';

import 'package:flutter/material.dart';
import 'package:project/core/cell.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/dialogs/toast.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
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
    var adyCost = cost ~/ Ads.costCoef;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SVG.show("record", 20.d),
          Text(" ${Pref.record.value.format()}",
              style: theme.textTheme.headline6),
          SizedBox(width: 4.d)
        ]),
        Positioned(
            top: 24.d,
            child:
                Text(Prefs.score.format(), style: theme.textTheme.headline3)),
        const Center(
            heightFactor: 0.85,
            child: RiveAnimation.asset('anims/nums-revive.riv',
                stateMachines: ["machine"])),
        buttonFactory(
            theme,
            SVG.show("coin", 36.d),
            [
              SkinnedText("$cost", style: theme.textTheme.headline4),
              SkinnedText("revive_l".l(), style: theme.textTheme.headline6)
            ],
            false,
            () => buttonsClick(context, "revive", -cost, false)),
        buttonFactory(
            theme,
            SVG.icon("A", theme),
            [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                SVG.show("coin", 24.d),
                SkinnedText("$adyCost", style: theme.textTheme.headline4)
              ]),
              SkinnedText("revive_l".l(), style: theme.textTheme.headline6)
            ],
            true,
            () => buttonsClick(context, "revive", -adyCost, true))
      ],
    );
  }

  @override
  buttonsClick(BuildContext context, String type, int coin, bool showAd) async {
    if (coin < 0 && Pref.coin.value < -coin) {
      Rout.push(context, Toast("coin_notenough".l()));
      return;
    }
    if (showAd) {
      var reward = await Ads.showRewarded();
      if (reward == null) return;
    } else if (coin > 0 && Ads.showSuicideInterstitial) {
      await Ads.showInterstitial(AdPlace.interstitial);
    }

    // Reterive game stats (Anti fraud)
    Prefs.setString("cells", _cells);
    Pref.lastBig.set(_lastBig);
    Pref.maxRandom.set(_maxRandom);
    Pref.numRevives.set(_numRevives);
    Pref.score.set(_score);
    Navigator.of(context).pop([type, coin]);
  }
}
