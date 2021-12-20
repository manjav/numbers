import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class FreeCoinsDialog extends AbstractDialog {
  static final waitingTime = 30000;
  static final showTime = 2500;
  static final autoAppearance = 3;
  static final reward = 20;

  bool? playApplaud;
  static int earnedAt = 0;

  FreeCoinsDialog({this.playApplaud})
      : super(DialogMode.piggy,
            height: 320.d,
            showCloseButton: false,
            title: "freecoins_l".l(),
            padding: EdgeInsets.all(18.d));
  @override
  _FreeCoinsDialogState createState() => _FreeCoinsDialogState();
}

class _FreeCoinsDialogState extends AbstractDialogState<FreeCoinsDialog> {
  @override
  void initState() {
    super.initState();
    Analytics.updateVariantIDs();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var reward = FreeCoinsDialog.reward;
    FreeCoinsDialog.earnedAt = DateTime.now().millisecondsSinceEpoch;
    if (widget.playApplaud ?? false)
      Timer(Duration(milliseconds: 600), () => Sound.play("win"));
    widget.onWillPop = () => buttonsClick(context, "freecoins", reward, false);
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      SizedBox(
          width: 126.d,
          height: 126.d,
          child: RiveAnimation.asset('anims/nums-character.riv',
              stateMachines: ["happyState"])),
      Positioned(
          top: 126.d,
          width: 260.d,
          child: Text("piggy_collect".l([(reward * Ads.rewardCoef).format()]),
              textAlign: TextAlign.center, style: theme.textTheme.caption)),
      PunchButton(
          height: 76.d,
          width: 130.d,
          bottom: 4.d,
          right: 4.d,
          cornerRadius: 16.d,
          isEnable: Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage: Toast("ads_unavailable".l(), monoIcon: "A"),
          onTap: () =>
              buttonsClick(context, "freecoins", reward * Ads.rewardCoef, true),
          content: Stack(alignment: Alignment.centerLeft, children: [
            SVG.icon("A", theme),
            Positioned(
                top: 4.d,
                left: 40.d,
                child: Text((reward * Ads.rewardCoef).format(),
                    style: theme.textTheme.headline4)),
            Positioned(
                bottom: 4.d,
                left: 40.d,
                child: Row(children: [
                  SVG.show("coin", 22.d),
                  Text("x${Ads.rewardCoef}", style: theme.textTheme.headline6)
                ])),
          ])),
      Positioned(
          height: 76.d,
          width: 110.d,
          bottom: 4.d,
          left: 4.d,
          child: BumpedButton(
              onTap: () => buttonsClick(context, "freecoins", reward, false),
              cornerRadius: 16.d,
              content: Stack(alignment: Alignment.centerLeft, children: [
                SVG.show("coin", 36.d),
                Positioned(
                    top: 5.d,
                    left: 40.d,
                    child:
                        Text(reward.format(), style: theme.textTheme.button)),
                Positioned(
                    bottom: 7.d,
                    left: 40.d,
                    child:
                        Text("claim_l".l(), style: theme.textTheme.subtitle2)),
              ])))
    ]);
    return super.build(context);
  }
}
