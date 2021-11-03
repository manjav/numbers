import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:numbers/widgets/widgets.dart';
import 'package:rive/rive.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class BigBlockDialog extends AbstractDialog {
  final ConfettiController confettiController;

  final int value;
  BigBlockDialog(this.value, this.confettiController)
      : super(DialogMode.big,
            height: 330.d,
            showCloseButton: false,
            padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d),
            title: Device.aspectRatio < 0.7 ? "big_l".l() : null);
  @override
  _BigBlockDialogState createState() => _BigBlockDialogState();
}

class _BigBlockDialogState extends AbstractDialogState<BigBlockDialog> {
  @override
  Widget build(BuildContext context) {
    var rewardCoef = 10;
    var reward = (widget.value-8) * 10;
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 500), () {
      widget.confettiController.play();
      Sound.play("win");
    });
    widget.onWillPop = () => buttonsClick(context, "big", reward);

    widget.child = Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          top: 140.d,
          child: Text("big_message".l([Cell.getScore(widget.value).toString()]),
              style: theme.textTheme.caption, textAlign: TextAlign.center)),
      Positioned(
          height: 76.d,
          width: 110.d,
          bottom: 4.d,
          left: 4.d,
          child: BumpedButton(
              onTap: () => buttonsClick(context, "big", reward),
              cornerRadius: 16.d,
              content: Stack(alignment: Alignment.centerLeft, children: [
                SVG.show("coin", 36.d),
                Positioned(
                    top: 5.d,
                    left: 36.d,
                    child:
                        Text(reward.format(), style: theme.textTheme.button)),
                Positioned(
                    bottom: 7.d,
                    left: 36.d,
                    child:
                        Text("claim_l".l(), style: theme.textTheme.subtitle2)),
              ]))),
      PunchButton(
          height: 76.d,
          width: 130.d,
          bottom: 4.d,
          right: 4.d,
          cornerRadius: 16.d,
          isEnable: Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage:
              Toast("ads_unavailable".l(), monoIcon: "0"),
          onTap: () => buttonsClick(context, "big", reward * rewardCoef,
              adId: AdPlace.Rewarded),
          content: Stack(alignment: Alignment.centerLeft, children: [
            SVG.icon("0", theme),
            Positioned(
                top: 5.d,
                left: 44.d,
                child: Text((reward * rewardCoef).format(),
                    style: theme.textTheme.headline4)),
            Positioned(
                bottom: 4.d,
                left: 44.d,
                child: Row(children: [
                  SVG.show("coin", 22.d),
                  Text("x$rewardCoef", style: theme.textTheme.headline6)
                ])),
          ])),
      Positioned(
          top: 90, child: Components.confetty(widget.confettiController)),
      Positioned(
          top: 0,
          width: 180.d,
          height: 180.d,
          child: RiveAnimation.asset('anims/nums-shine.riv',
              stateMachines: ["machine"])),
      Positioned(
          top: 48.d,
          width: 80.d,
          height: 80.d,
          child: RotationTransition(
              turns: AlwaysStoppedAnimation(-0.02),
              child: Widgets.cell(theme, widget.value)))
    ]);
    return super.build(context);
  }
}
