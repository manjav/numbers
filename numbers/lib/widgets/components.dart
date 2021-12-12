import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

class Components {
  static Widget scores(ThemeData theme, {Function()? onTap}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Hero(
        tag: "score",
        child: GestureDetector(
            onTap: onTap,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text("${Pref.record.value.format()}",
                    style:
                        theme.textTheme.headline5!.copyWith(letterSpacing: -1)),
                SizedBox(width: 3.d),
                SVG.show("record", 20.d),
                SizedBox(width: 4.d),
              ])
            ])));
  }

  static Widget stats(ThemeData theme, {Function()? onTap}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Hero(
        tag: "stats",
        child: SizedBox(
            width: 50.d,
            child: BumpedButton(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 10),
                content: GestureDetector(
                    onTap: onTap, child: SVG.show("profile", 48.d)))));
  }

  static Widget coins(BuildContext context, String source,
      {Function()? onTap, bool clickable = true}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    var theme = Theme.of(context);
    var text = "${Pref.coin.value.format()}";
    return Hero(
        tag: "coin",
        child: BumpedButton(
            content: Row(children: [
              SVG.show("coin", 32.d),
              Expanded(
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyText2!
                          .copyWith(fontSize: text.length > 5 ? 17.d : 22.d))),
              clickable
                  ? Text("+  ",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.button)
                  : SizedBox()
            ]),
            onTap: () {
              if (clickable) {
                Analytics.design('guiClick:shop:$source');
                if (onTap != null)
                  onTap();
                else
                  Rout.push(context, ShopDialog());
              }
            }));
  }

  static Widget startButton(
      BuildContext context, String title, String boost, Function? onSelect) {
    var theme = Theme.of(context);
    return Expanded(
        child: Container(
            padding: EdgeInsets.all(8.d),
            decoration: ButtonDecor(TColors.whiteFlat.value, 12.d, true, false),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SVG.show(boost, 58.d),
                _has(boost) ? SVG.show("accept", 22.d) : SizedBox()
              ]),
              SizedBox(height: 6.d),
              Text(title,
                  style: theme.textTheme.subtitle2,
                  textAlign: TextAlign.center),
              SizedBox(height: 6.d),
              SizedBox(
                  width: 92.d,
                  height: 39.d,
                  child: BumpedButton(
                      cornerRadius: 8.d,
                      isEnable: !_has(boost),
                      content: Row(children: [
                        SVG.show("coin", 24.d),
                        Expanded(
                            child: Text("100",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyText2))
                      ]),
                      onTap: () => _onStartTap(context, boost, 100, onSelect))),
              SizedBox(height: 4.d),
              SizedBox(
                  width: 92.d,
                  height: 39.d,
                  child: BumpedButton(
                      cornerRadius: 8.d,
                      errorMessage: Toast("ads_unavailable".l(), monoIcon: "A"),
                      isEnable: !_has(boost) && Ads.isReady(),
                      colors: TColors.orange.value,
                      content: Row(children: [
                        SVG.icon("A", theme, scale: 0.7),
                        Expanded(
                            child: Text("free_l".l(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headline5))
                      ]),
                      onTap: () => _onStartTap(context, boost, 0, onSelect))),
              SizedBox(height: 6.d)
            ])));
  }

  static void _onStartTap(
      context, String boost, int cost, Function? onSelect) async {
    if (cost > 0) {
      if (Pref.coin.value < cost) {
        Rout.push(context, ShopDialog());
        return;
      }
    } else {
      var reward = await Ads.showRewarded();
      if (reward == null) return;
    }
    Pref.coin.increase(-cost, itemType: "start", itemId: boost);

    if (boost == "next") MyGame.boostNextMode = 1;
    if (boost == "512") MyGame.boostBig = true;
    onSelect?.call();
  }

  static bool _has(String boost) {
    return (boost == "next") ? MyGame.boostNextMode > 0 : MyGame.boostBig;
  }

  static Widget confetty(ConfettiController controller) {
    return ConfettiWidget(
        gravity: 0.5,
        maxBlastForce: 50,
        numberOfParticles: 20,
        emissionFrequency: 0.05,
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple
        ],
        createParticlePath: drawStar);
  }

  /// A custom Path to paint stars.
  static Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
