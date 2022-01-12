import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

class CubeDialog extends AbstractDialog {
  static final waitingTime = 30000;
  static final showTime = 2500;
  static final autoAppearance = 3;

  static int earnedAt = 0;

  CubeDialog()
      : super(DialogMode.cube,
            height: 320.d,
            showCloseButton: false,
            title: "cube_l".l(),
            padding: EdgeInsets.all(18.d));
  @override
  _CubeDialogState createState() => _CubeDialogState();
}

class _CubeDialogState extends AbstractDialogState<CubeDialog> {
  @override
  void initState() {
    reward = Price.cube;
    Timer(Duration(milliseconds: 600), () => Sound.play("win"));
    CubeDialog.earnedAt = DateTime.now().millisecondsSinceEpoch;
    super.initState();
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Stack(alignment: Alignment.topCenter, children: [
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
          onTap: () => buttonsClick(
              context, widget.mode.name, reward * Ads.rewardCoef, true),
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
              onTap: () =>
                  buttonsClick(context, widget.mode.name, reward, false),
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
  }
}
