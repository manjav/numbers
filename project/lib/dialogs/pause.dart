import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';

class PauseDialog extends AbstractDialog {
  PauseDialog({Key? key})
      : super(
          DialogMode.pause,
          key: key,
          title: "pause_l".l(),
          popDuration: 300,
          showCloseButton: false,
        );
  @override
  createState() => _PauseDialogState();
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
                  onTap: () => Rout.pop(context, ["home"]),
                  colors: TColors.green.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("J", theme),
                        SkinnedText("home_l".l(),
                            style: theme.textTheme.headline5)
                      ])),
              BumpedButton(
                  onTap: () => Rout.pop(context, ["resume"]),
                  colors: TColors.blue.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("E", theme),
                        SkinnedText("continue_l".l(),
                            style: theme.textTheme.headline5)
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
