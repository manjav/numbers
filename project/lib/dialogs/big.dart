import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:project/core/cell.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/components.dart';
import 'package:project/widgets/widgets.dart';
import 'package:rive/rive.dart';

class BigBlockDialog extends AbstractDialog {
  final ConfettiController confettiController;

  final int value;
  BigBlockDialog(this.value, this.confettiController, {Key? key})
      : super(
          DialogMode.big,
          key: key,
          height: 330.d,
          showCloseButton: false,
          padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d),
          title: Device.aspectRatio < 0.7 ? "big_l".l() : null,
        );
  @override
  createState() => _BigBlockDialogState();
}

class _BigBlockDialogState extends AbstractDialogState<BigBlockDialog> {
  @override
  void initState() {
    reward = (widget.value - 8) * Price.big;
    Timer(const Duration(milliseconds: 500), () {
      widget.confettiController.play();
      Sound.play("win");
    });
    super.initState();
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          top: 140.d,
          child: Text("big_message".l([Cell.getScore(widget.value).toString()]),
              style: theme.textTheme.caption, textAlign: TextAlign.center)),
      buttonPayFactory(theme),
      buttonAdsFactory(theme),
      Positioned(
          top: 90, child: Components.confetty(widget.confettiController)),
      Positioned(
          top: 0,
          width: 180.d,
          height: 180.d,
          child: const RiveAnimation.asset('anims/${Asset.prefix}shine.riv',
              stateMachines: ["machine"])),
      Positioned(
          top: 48.d,
          width: 80.d,
          height: 80.d,
          child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-0.02),
              child: Widgets.cell(theme, widget.value)))
    ]);
  }
}
