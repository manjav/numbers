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
          height: 180.d,
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
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      Positioned(
          height: 76.d,
          width: 146.d,
          top: 0,
          left: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop("reset"),
              colors: TColors.green.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("5", theme),
                    Text("pause_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Positioned(
          height: 76.d,
          width: 146.d,
          top: 0,
          right: 0,
          child: BumpedButton(
              onTap: () => Navigator.of(context).pop("resume"),
              colors: TColors.blue.value,
              cornerRadius: 16.d,
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SVG.icon("4", theme),
                    Text("continue_l".l(), style: theme.textTheme.headline5)
                  ]))),
      Positioned(
          height: 76.d,
          width: 76.d,
          top: 90.d,
          left: 66.d,
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
      Positioned(
          height: 76.d,
          width: 76.d,
          top: 90.d,
          right: 66.d,
          child: BumpedButton(
              onTap: () {
                Pref.isMute.set(Pref.isMute.value == 0 ? 1 : 0);
                setState(() {});
              },
              colors: TColors.yellow.value,
              cornerRadius: 16.d,
              content: Center(
                  child: SVG.icon("${Pref.isMute.value + 1}", theme,
                      scale: 1.2)))),
    ]);
    return super.build(context);
  }
}
