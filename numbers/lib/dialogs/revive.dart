import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class ReviveDialog extends AbstractDialog {
  final int numRevive;
  ReviveDialog(this.numRevive)
      : super(DialogMode.revive,
            sfx: "lose", title: "revive_l".l(), width: 310.d);
  @override
  _ReviveDialogState createState() => _ReviveDialogState();
}

class _ReviveDialogState extends AbstractDialogState<ReviveDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var cost = 200 * pow(2, widget.numRevive).round();
    widget.child = Stack(
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
        Center(
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
                      child: Text("${cost.format()}",
                          style: theme.textTheme.button)),
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
            errorMessage: Toast("ads_unavailable".l(), monoIcon: "0"),
            isEnable: widget.numRevive < 2 && Ads.isReady(),
            onTap: () => buttonsClick(context, "revive", 0, true),
            colors: TColors.orange.value,
            content: Stack(alignment: Alignment.centerLeft, children: [
              SVG.icon("0", theme),
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
    return super.build(context);
  }
}
