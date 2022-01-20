import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/coins.dart';
import 'package:numbers/widgets/widgets.dart';

class StatsDialog extends AbstractDialog {
  StatsDialog({Key? key})
      : super(
          DialogMode.stats,
          key: key,
          height: 270.d,
          title: "stats_l".l(),
          statsButton: const SizedBox(),
          padding: EdgeInsets.all(12.d),
        );
  @override
  _StatsDialogState createState() => _StatsDialogState();
}

class _StatsDialogState extends AbstractDialogState<StatsDialog> {
  @override
  Widget build(BuildContext context) {
    stepChildren.clear();
    stepChildren.add(bannerAdsFactory("stats"));
    return super.build(context);
  }

  @override
  Widget coinsButtonFactory(ThemeData theme) =>
      Coins(widget.mode.name, left: 12.d);

  @override
  Widget contentFactory(ThemeData theme) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SVG.show("record", 24.d),
            Text(" ${Pref.record.value.format()}",
                style: theme.textTheme.headline5)
          ]),
          Text("stats_plays".l([Pref.playCount.value.toString()]),
              style: theme.textTheme.headline6),
          SizedBox(height: 8.d),
          SizedBox(
            width: 270.d,
            height: 164.d,
            child: GridView.count(
                padding: EdgeInsets.only(top: 8.d, left: 8.d),
                crossAxisCount: 3,
                crossAxisSpacing: 3.d,
                mainAxisSpacing: 2.d,
                childAspectRatio: 1.7,
                children:
                    List.generate(9, (i) => _bigRecordItem(theme, 9 + i))),
          )
        ]);
  }

  Widget _bigRecordItem(ThemeData theme, int i) {
    var score = Cell.getScore(i).toString();
    return Row(children: [
      SizedBox(
          width: 44.d,
          height: 44.d,
          child: Widgets.cell(theme, i,
              textStyle: Themes.style(
                  TColors.white.value[3],
                  22.d *
                      Cell.scales[
                          score.length.clamp(0, Cell.scales.length - 1)]))),
      Text(" x ${Prefs.getBig(i)}", style: theme.textTheme.headline6)
    ]);
  }
}
