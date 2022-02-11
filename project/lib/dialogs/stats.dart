import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/core/cell.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';
import 'package:project/widgets/coins.dart';
import 'package:project/widgets/widgets.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';

class StatsDialog extends AbstractDialog {
  StatsDialog({Key? key})
      : super(
          DialogMode.stats,
          key: key,
          title: "stats_l".l(),
          statsButton: const SizedBox(),
          padding: EdgeInsets.all(12.d),
        );
  @override
  _StatsDialogState createState() => _StatsDialogState();
}

class _StatsDialogState extends AbstractDialogState<StatsDialog> {
  final _screenshotController = ScreenshotController();
  var shareMode = false;
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
    return Screenshot(
        controller: _screenshotController,
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
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
          ),
          SizedBox(height: 10.d),
          shareMode
              ? Padding(
                  padding: EdgeInsets.all(4.d),
                  child:
                      Text("stats_share".l(), style: theme.textTheme.headline6))
              : BumpedButton(
                  onTap: _share,
                  colors: TColors.orange.value,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("I", theme),
                        SkinnedText("share_l".l(), style: theme.textTheme.headline5)
                      ]))
        ]));
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

  _share() async {
    shareMode = true;
    setState(() {});
    final directory = await getApplicationDocumentsDirectory();
    var imagePath = await _screenshotController.captureAndSave(directory.path);
    if (imagePath != null) {
      await Share.shareFiles([imagePath],
          text: "app_url".l(), subject: "app_title".l());
    }
    shareMode = false;
    Analytics.share("image", "stats");
    setState(() {});
  }
}
