import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/punchbutton.dart';

class PiggyDialog extends AbstractDialog {
  final bool playApplaud;
  PiggyDialog(this.playApplaud, {Key? key})
      : super(DialogMode.piggy,
            key: key,
            height: 300.d,
            title: "piggy_l".l(),
            padding: EdgeInsets.all(18.d));
  @override
  _PiggyDialogState createState() => _PiggyDialogState();
}

class _PiggyDialogState extends AbstractDialogState<PiggyDialog> {
  @override
  void initState() {
    reward = Pref.coinPiggy.value >= Price.piggy ? Price.piggy : 0;

    if (widget.playApplaud) {
      Timer(const Duration(milliseconds: 600), () => Sound.play("win"));
    }
    Analytics.updateVariantIDs();
    super.initState();
  }

  @override
  Widget headerFactory(ThemeData theme, double width) {
    return SizedBox(
        width: width - 36.d,
        height: 72.d,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(widget.title!, style: theme.textTheme.headline4),
              widget.playApplaud
                  ? const SizedBox()
                  : GestureDetector(
                      child: SVG.show("close", 28.d),
                      onTap: () {
                        widget.onWillPop?.call();
                        Navigator.of(context).pop();
                      })
            ]));
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Stack(alignment: Alignment.topCenter, children: [
      SVG.show("piggy", 144.d),
      Positioned(
          top: 112.d,
          width: 260.d,
          child: Text(
              "piggy_${reward > 0 ? 'collect' : 'fill'}"
                  .l([(Price.piggy * Ads.rewardCoef).toString()]),
              textAlign: TextAlign.center,
              style: theme.textTheme.caption)),
      _rightButton(theme, Pref.coinPiggy.value, Price.piggy),
      _leftButton(theme, Pref.coinPiggy.value, Price.piggy)
    ]);
  }

  _leftButton(ThemeData theme, int value, int maxValue) {
    if (value < maxValue) return const SizedBox();
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
    return Positioned(
        height: 32.d,
        bottom: 12.d,
        width: 200.d,
        child: Components.slider(theme, maxValue, value, maxValue,
            icon: SVG.show("coin", 32.d)));
  }
}
