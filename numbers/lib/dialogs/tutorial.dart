import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';

class TutorialDialog extends AbstractDialog {
  final ConfettiController confettiController;
  TutorialDialog(this.confettiController)
      : super(DialogMode.tutorial,
            sfx: "win",
            height: 200.d,
            width: 340.d,
            showCloseButton: false,
            statsButton: SizedBox(),
            scoreButton: SizedBox(),
            padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 12.d));
  @override
  _TutorialDialogState createState() => _TutorialDialogState();
}

class _TutorialDialogState extends AbstractDialogState<TutorialDialog> {
  @override
  Widget coinsButtonFactory(ThemeData theme) => SizedBox();

  @override
  void initState() {
    Timer(Duration(milliseconds: 10), () => widget.confettiController.play());
    super.initState();
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          top: 20.d,
          child: Text("tutor_message".l(), style: theme.textTheme.caption)),
      Positioned(
          height: 76.d,
          width: 150.d,
          bottom: 0,
          left: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop(["tutorReset"]),
              colors: TColors.green.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("F", theme),
                    Text("replay_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Positioned(
          height: 76.d,
          width: 150.d,
          bottom: 0,
          right: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop(["tutorFinish"]),
              colors: TColors.blue.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("E", theme),
                    Text("ok_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Center(child: Components.confetty(widget.confettiController))
    ]);
  }
}
