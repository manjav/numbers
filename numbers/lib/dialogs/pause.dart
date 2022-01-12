import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

class PauseDialog extends AbstractDialog {
  PauseDialog()
      : super(
          DialogMode.pause,
          title: "pause_l".l(),
          popDuration: 300,
          showCloseButton: false,
        );
  @override
  _PauseDialogState createState() => _PauseDialogState();
}

class _PauseDialogState extends AbstractDialogState<PauseDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var children = <Widget>[];
    children.add(rankButtonFactory(theme));
    children.add(statsButtonFactory(theme));
    children.add(coinsButtonFactory(theme));

    var rows = <Widget>[];
    rows.add(headerFactory(theme, 300.d));
    rows.add(SizedBox(
        height: 76.d,
        width: 300.d,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BumpedButton(
                  onTap: () => Navigator.of(context).pop(["home"]),
                  colors: TColors.green.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("J", theme),
                        Text("home_l".l(), style: theme.textTheme.headline5)
                      ])),
              BumpedButton(
                  onTap: () => Navigator.of(context).pop(["resume"]),
                  colors: TColors.blue.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("E", theme),
                        Text("continue_l".l(), style: theme.textTheme.headline5)
                      ]))
            ])));
    rows.add(SizedBox(height: 12.d));
    rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                  child: SVG.icon(["G", "H"][Pref.isVibrateOff.value], theme,
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
                  child: SVG.icon(["B", "C"][Pref.isMute.value], theme,
                      scale: 1.2))))
    ]));

    children.add(
        Column(mainAxisAlignment: MainAxisAlignment.center, children: rows));
    children.add(bannerAdsFactory("pause"));

    return WillPopScope(
        key: Key(widget.mode.name),
        onWillPop: () async {
          widget.onWillPop?.call();
          return widget.closeOnBack ?? true;
        },
        child: Stack(alignment: Alignment.center, children: children));
  }
}
