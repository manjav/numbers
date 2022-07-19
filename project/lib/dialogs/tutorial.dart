import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';
import 'package:project/widgets/components.dart';

class TutorialDialog extends AbstractDialog {
  final ConfettiController confettiController;
  TutorialDialog(this.confettiController, {Key? key})
      : super(
          DialogMode.tutorial,
          key: key,
          sfx: "win",
          height: 200.d,
          width: 340.d,
          showCloseButton: false,
          statsButton: const SizedBox(),
          scoreButton: const SizedBox(),
          padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 12.d),
        );
  @override
  createState() => _TutorialDialogState();
}

class _TutorialDialogState extends AbstractDialogState<TutorialDialog> {
  @override
  Widget coinsButtonFactory(ThemeData theme) => const SizedBox();

  @override
  void initState() {
    Timer(const Duration(milliseconds: 10),
        () => widget.confettiController.play());
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
              onTap: () => Rout.pop(context, ["tutorReset"]),
              colors: TColors.yellow.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("F", theme),
                    SkinnedText("replay_l".l(),
                        style: theme.textTheme.headline5)
                  ]))),
      Positioned(
          height: 76.d,
          width: 150.d,
          bottom: 0,
          right: 0,
          child: BumpedButton(
              onTap: () => Rout.pop(context, ["tutorFinish"]),
              colors: TColors.green.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("E", theme),
                    SkinnedText("ok_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Center(child: Components.confetty(widget.confettiController))
    ]);
  }
}
