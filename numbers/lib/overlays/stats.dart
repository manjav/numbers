import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/widgets.dart';

import 'all.dart';

class StatsOverlay extends StatefulWidget {
  StatsOverlay({Key? key}) : super(key: key);
  @override
  _StatsOverlayState createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<StatsOverlay> {
  var shareMode = false;
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Overlays.basic(context,
        title: "Stats",
        height: 460.d,
        statsButton: SizedBox(),
        coinButton:
            Positioned(top: 48.d, left: 12.d, child: Components.coins(context)),
        content: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SVG.show("record", 24.d),
            Text(" ${Pref.record.value.format()}",
                style: theme.textTheme.headline5)
          ]),
          SizedBox(height: 6.d),
          // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // SVG.show("record", 24.d),
          Text("Games Played: ${Pref.playCount.value}",
              style: theme.textTheme.headline6)
          // ])
          ,
          SizedBox(
            width: 240.d,
            height: 280.d,
            child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 3.d,
                mainAxisSpacing: 2.d,
                childAspectRatio: 2,
                children:
                    List.generate(8, (i) => _bigRecordItem(theme, 9 + i))),
          )
        ]));
  }

  Widget _bigRecordItem(ThemeData theme, int i) {
    return Row(children: [
      SizedBox(
          width: 56,
          height: 56,
          child: Widgets.cell(theme, i, textStyle: theme.textTheme.headline6)),
      Text(" x ${Prefs.getBig(i)}", style: theme.textTheme.headline4)
    ]);
  }
}
