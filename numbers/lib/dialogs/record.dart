import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class RecordDialog extends AbstractDialog {
  final ConfettiController confettiController;
  RecordDialog(this.confettiController)
      : super(DialogMode.record,
            showCloseButton: false,
            height: 310.d,
            padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d));
  @override
  _RecordDialogState createState() => _RecordDialogState();
}

class _RecordDialogState extends AbstractDialogState<RecordDialog> {
  @override
  Widget build(BuildContext context) {
    var reward = 10;
    var rewardCoef = 10;
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 500), () {
      widget.confettiController.play();
      Sound.play("win");
    });
    widget.onWillPop = () => buttonsClick(context, "record", reward);
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          top: 152.d,
          child: Text("record_l".l(), style: theme.textTheme.caption)),
      Positioned(
          top: 166.d,
          child: Text(Prefs.score.format(), style: theme.textTheme.headline2)),
      Positioned(
          height: 76.d,
          width: 110.d,
          bottom: 4.d,
          left: 4.d,
          child: BumpedButton(
              onTap: () => buttonsClick(context, "record", reward),
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
              ]))),
      PunchButton(
          height: 76.d,
          width: 130.d,
          bottom: 4.d,
          right: 4.d,
          cornerRadius: 16.d,
          isEnable: Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage: Toast("ads_unavailable".l(), monoIcon: "0"),
          onTap: () => buttonsClick(context, "record", rewardCoef * reward,
              adId: AdPlace.Rewarded),
          content: Stack(alignment: Alignment.centerLeft, children: [
            SVG.icon("0", theme),
            Positioned(
                top: 5.d,
                left: 44.d,
                child: Text((rewardCoef * reward).format(),
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
          top: 60, child: Components.confetty(widget.confettiController)),
      Center(
          heightFactor: 0.52,
          child: RiveAnimation.asset('anims/nums-record.riv',
              stateMachines: ["machine"])),
    ]);
    return super.build(context);
  }
}
