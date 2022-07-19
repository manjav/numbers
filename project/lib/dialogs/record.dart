import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/components.dart';
import 'package:rive/rive.dart';

class RecordDialog extends AbstractDialog {
  final ConfettiController confettiController;
  RecordDialog(this.confettiController, {Key? key})
      : super(
          DialogMode.record,
          key: key,
          showCloseButton: false,
          height: 310.d,
          padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d),
        );
  @override
  createState() => _RecordDialogState();
}

class _RecordDialogState extends AbstractDialogState<RecordDialog> {
  @override
  void initState() {
    reward = Price.record;
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
          top: 152.d,
          child: Text("record_l".l(), style: theme.textTheme.caption)),
      Positioned(
          top: 166.d,
          child: Text(Prefs.score.format(), style: theme.textTheme.headline2)),
      buttonPayFactory(theme),
      buttonAdsFactory(theme),
      Positioned(
          top: 60, child: Components.confetty(widget.confettiController)),
      const Center(
          heightFactor: 0.52,
          child: RiveAnimation.asset('anims/${Asset.prefix}record.riv',
              stateMachines: ["machine"])),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    widget.confettiController.stop();
  }
}
