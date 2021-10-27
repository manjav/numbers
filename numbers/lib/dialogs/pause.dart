import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class PauseDialog extends AbstractDialog {
  PauseDialog()
      : super(
          DialogMode.pause,
          hasChrome: false,
          title: "pause_l".l(),
          showCloseButton: false,
          padding: EdgeInsets.only(top: 10.d),
        );
  @override
  _PauseDialogState createState() => _PauseDialogState();
}

class _PauseDialogState extends AbstractDialogState<PauseDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    widget.child =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      bannerAdsFactory(),
      SizedBox(height: 16.d),
      SizedBox(
          height: 76.d,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BumpedButton(
                    onTap: () => Navigator.of(context).pop("reset"),
                    colors: TColors.green.value,
                    cornerRadius: 16.d,
                    content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SVG.icon("5", theme),
                          Text("pause_l".l(), style: theme.textTheme.headline5)
                        ])),
                BumpedButton(
                    onTap: () => Navigator.of(context).pop("resume"),
                    colors: TColors.blue.value,
                    cornerRadius: 16.d,
                    content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SVG.icon("4", theme),
                          Text("continue_l".l(),
                              style: theme.textTheme.headline5)
                        ]))
              ])),
      SizedBox(height: 12.d),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
            width: 76.d,
            height: 76.d,
            child: BumpedButton(
                onTap: () {
                  Pref.isVibrateOff.set(Pref.isVibrateOff.value == 0 ? 1 : 0);
                  setState(() {});
                },
                colors: TColors.orange.value,
                cornerRadius: 16.d,
                content: Center(
                    child: SVG.icon("${Pref.isVibrateOff.value + 6}", theme,
                        scale: 1.2)))),
        SizedBox(width: 12.d),
        SizedBox(
            width: 76.d,
            height: 76.d,
            child: BumpedButton(
                onTap: () {
                  Pref.isMute.set(Pref.isMute.value == 0 ? 1 : 0);
                  setState(() {});
                },
                colors: TColors.yellow.value,
                cornerRadius: 16.d,
                content: Center(
                    child: SVG.icon("${Pref.isMute.value + 1}", theme,
                        scale: 1.2))))
      ])
    ]);
    return super.build(context);
  }
}
