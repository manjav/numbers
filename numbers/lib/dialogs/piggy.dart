import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/punchbutton.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class PiggyDialog extends AbstractDialog {
  PiggyDialog()
      : super(DialogMode.piggy,
            height: 272.d, title: "piggy_l".l(), padding: EdgeInsets.all(18.d));
  @override
  _PiggyDialogState createState() => _PiggyDialogState();
}

class _PiggyDialogState extends AbstractDialogState<PiggyDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    widget.child = Stack(alignment: Alignment.topCenter, children: [
      SVG.show("piggy", 144.d),
      Positioned(
          top: 112.d,
          child: Text("piggy_message".l(), style: theme.textTheme.caption)),
      _slider(theme, Pref.coinPiggy.value, Cell.maxDailyCoins)
    ]);
    return super.build(context);
  }

  Widget _slider(ThemeData theme, int value, int maxValue) {
    var rewardAvailble = value >= maxValue;
    if (rewardAvailble) {
      return PunchButton(
          height: 76.d,
          width: 160.d,
          bottom: 4.d,
          // right: 4.d,
          cornerRadius: 16.d,
          padding: EdgeInsets.all(14.d),
          isEnable: rewardAvailble && Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage: Toast("ads_unavailable".l(), monoIcon: "0"),
          onTap: () =>
              buttonsClick(context, "piggy", 0, adId: AdPlace.Rewarded),
          content: Row(children: [
            SVG.icon("0", theme),
            Expanded(child: SizedBox()),
            SVG.show("coin", 32.d),
            Text("x$maxValue", style: theme.textTheme.headline4)
          ]));
    }
    var label = "$value / $maxValue";
    return Positioned(
        height: 32.d,
        bottom: 12.d,
        width: 200.d,
        child: Stack(alignment: Alignment.centerLeft, children: [
          Positioned(
              height: 20.d,
              left: 26.d,
              right: 0,
              child: Container(
                  child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12.d),
                          bottomRight: Radius.circular(12.d)),
                      child: LinearProgressIndicator(value: value / maxValue)),
                  decoration: _badgeDecoration())),
          SVG.show("coin", 32.d),
          Positioned(
              left: 32.d,
              right: 4.d,
              child: Text(label,
                  style: TextStyle(fontSize: 12.d, color: Colors.black),
                  textAlign: TextAlign.center)),
        ]));
  }

  Decoration _badgeDecoration({double? cornerRadius}) {
    return BoxDecoration(
        boxShadow: [
          BoxShadow(
              blurRadius: 3.d, color: Colors.black, offset: Offset(0.5.d, 1.d))
        ],
        color: Colors.pink[700],
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(cornerRadius ?? 12.d)));
  }
}
