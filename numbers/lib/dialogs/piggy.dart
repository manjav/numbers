import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/punchbutton.dart';

import 'dialogs.dart';
import 'toast.dart';

// ignore: must_be_immutable
class PiggyDialog extends AbstractDialog {
  static final capacity = 30;
  bool? playApplaud;
  PiggyDialog({this.playApplaud})
      : super(DialogMode.piggy,
            showCloseButton: false,
            height: 300.d,
            title: "piggy_l".l(),
            padding: EdgeInsets.all(18.d));
  @override
  _PiggyDialogState createState() => _PiggyDialogState();
}

class _PiggyDialogState extends AbstractDialogState<PiggyDialog> {
  @override
  void initState() {
    super.initState();
    Analytics.updateVariantIDs();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var filled = Pref.coinPiggy.value >= PiggyDialog.capacity;

    if (widget.playApplaud ?? false)
      Timer(Duration(milliseconds: 600), () => Sound.play("win"));
    widget.onWillPop = () => buttonsClick(
        context, "piggy", filled ? PiggyDialog.capacity : 0, false);

    widget.child = Stack(alignment: Alignment.topCenter, children: [
      SVG.show("piggy", 144.d),
      Positioned(
          top: 112.d,
          width: 260.d,
          child: Text(
              "piggy_${filled ? 'collect' : 'fill'}"
                  .l([(PiggyDialog.capacity * Ads.rewardCoef).toString()]),
              textAlign: TextAlign.center,
              style: theme.textTheme.caption)),
      _rightButton(theme, Pref.coinPiggy.value, PiggyDialog.capacity),
      _leftButton(theme, Pref.coinPiggy.value, PiggyDialog.capacity)
    ]);
    return super.build(context);
  }

  _leftButton(ThemeData theme, int value, int maxValue) {
    if (value < maxValue) return SizedBox();
    return Positioned(
        height: 76.d,
        width: 110.d,
        bottom: 4.d,
        left: 4.d,
        child: BumpedButton(
            onTap: () => buttonsClick(context, "piggy", maxValue, false),
            cornerRadius: 16.d,
            content: Stack(alignment: Alignment.centerLeft, children: [
              SVG.show("coin", 36.d),
              Positioned(
                  top: 5.d,
                  left: 40.d,
                  child:
                      Text(maxValue.format(), style: theme.textTheme.button)),
              Positioned(
                  bottom: 7.d,
                  left: 40.d,
                  child: Text("claim_l".l(), style: theme.textTheme.subtitle2)),
            ])));
  }

  Widget _rightButton(ThemeData theme, int value, int maxValue) {
    var rewardAvailble = value >= maxValue;
    if (rewardAvailble) {
      return PunchButton(
          height: 76.d,
          width: 130.d,
          bottom: 4.d,
          right: 4.d,
          cornerRadius: 16.d,
          isEnable: Ads.isReady(),
          colors: TColors.orange.value,
          errorMessage: Toast("ads_unavailable".l(), monoIcon: "A"),
          onTap: () =>
              buttonsClick(context, "piggy", maxValue * Ads.rewardCoef, true),
          content: Stack(alignment: Alignment.centerLeft, children: [
            SVG.icon("A", theme),
            Positioned(
                top: 5.d,
                left: 40.d,
                child: Text((maxValue * Ads.rewardCoef).format(),
                    style: theme.textTheme.headline4)),
            Positioned(
                bottom: 4.d,
                left: 40.d,
                child: Row(children: [
                  SVG.show("coin", 22.d),
                  Text("x${Ads.rewardCoef}", style: theme.textTheme.headline6)
                ])),
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
