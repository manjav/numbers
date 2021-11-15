import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:rive/rive.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class FreeCoinsDialog extends AbstractDialog {
  static bool allSuperMatchAppears = false;
  static int autoAppearance = 3;
  static int reward = 200;
  bool? playApplaud;

  FreeCoinsDialog({this.playApplaud})
      : super(DialogMode.piggy,
            height: 320.d,
            title: "freecoins_l".l(),
            padding: EdgeInsets.all(18.d));
  @override
  _FreeCoinsDialogState createState() => _FreeCoinsDialogState();
}

class _FreeCoinsDialogState extends AbstractDialogState<FreeCoinsDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    if (widget.playApplaud ?? false)
      Timer(Duration(milliseconds: 600), () => Sound.play("win"));
    widget.closeButton = GestureDetector(
        child: SVG.show("close", 14.d),
        onTap: () {
          widget.onWillPop?.call();
          Navigator.of(context).pop();
        });
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      SizedBox(
          width: 126.d,
          height: 126.d,
          child: RiveAnimation.asset('anims/nums-character.riv',
              stateMachines: ["happyState"])),
      Positioned(
          top: 126.d,
          width: 260.d,
          child: Text("piggy_collect".l([FreeCoinsDialog.reward.toString()]),
              textAlign: TextAlign.center, style: theme.textTheme.caption)),
      PunchButton(
          height: 76.d,
          width: 160.d,
          bottom: 4.d,
          cornerRadius: 16.d,
          padding: EdgeInsets.fromLTRB(8.d, 0, 8.d, 8.d),
          isEnable: Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage: Toast("ads_unavailable".l(), monoIcon: "0"),
          onTap: () {
            FreeCoinsDialog.autoAppearance = 0;
            buttonsClick(context, "freecoins", 0, true);
          },
          content:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            SVG.icon("0", theme),
            Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("free_l".l(), style: theme.textTheme.headline4),
                  Row(children: [
                    SVG.show("coin", 32.d),
                    Text("+${FreeCoinsDialog.reward}",
                        style: theme.textTheme.headline5)
                  ])
                ])
          ]))
    ]);
    return super.build(context);
  }
}
