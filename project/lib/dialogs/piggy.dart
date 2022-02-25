import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/components.dart';

class PiggyDialog extends AbstractDialog {
  final bool playApplaud;
  PiggyDialog(this.playApplaud, {Key? key})
      : super(DialogMode.piggy,
            key: key,
            height: Pref.coinPiggy.value >= Price.piggy ? 340.d : 280.d,
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
                        Rout.pop(context);
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
    return buttonPayFactory(theme);
  }

  Widget _rightButton(ThemeData theme, int value, int maxValue) {
    if (value >= maxValue) return buttonAdsFactory(theme);
    return Positioned(
        height: 66.d,
        bottom: 12.d,
        width: 200.d,
        child: Components.slider(
          theme,
          maxValue,
          value,
          maxValue,
        ));
  }
}
