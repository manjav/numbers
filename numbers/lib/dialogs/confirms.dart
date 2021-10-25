import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class ConfirmDialog extends AbstractDialog {
  final ConfettiController confettiController;
  ConfirmDialog(this.confettiController)
      : super(DialogMode.confirmDialog,
            sfx: "win",
            height: 200.d,
            width: 340.d,
            showCloseButton: false,
            coinButton: SizedBox(),
            statsButton: SizedBox(),
            scoreButton: SizedBox(),
            padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 12.d));
  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends AbstractDialogState<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 10), () => widget.confettiController.play());
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          top: 20.d,
          child: Text("tutor_message".l(), style: theme.textTheme.caption)),
      Positioned(
          height: 76.d,
          width: 150.d,
          bottom: 0,
          left: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop("tutorReset"),
              colors: TColors.green.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("5", theme),
                    Text("Replay", style: theme.textTheme.headline5)
                  ]))),
      Positioned(
          height: 76.d,
          width: 150.d,
          bottom: 0,
          right: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop("tutorFinish"),
              colors: TColors.blue.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("4", theme),
                    Text("ok_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Center(child: Components.confetty(widget.confettiController))
    ]);
    return super.build(context);
  }
}
