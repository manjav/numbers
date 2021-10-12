import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/overlays/rating.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/home.dart';

import 'all.dart';

class StartOverlay extends StatefulWidget {
  StartOverlay({Key? key}) : super(key: key);
  @override
  _StartOverlayState createState() => _StartOverlayState();
}

class _StartOverlayState extends State<StartOverlay> {
  @override
  void initState() {
    if (Pref.tutorMode.value == 0) _onStart();
    Ads.onAdsReady = _onAdsReady;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    var theme = Theme.of(context);
    return Overlays.basic(context, "start",
        height: 300.d,
        hasClose: false,
        title: "Select Boost Items",
        padding: EdgeInsets.fromLTRB(12.d, 12.d, 12.d, 14.d),
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Components.startButton(context,
                    "Start the game with block 512!", "512", _onUpdate),
                SizedBox(width: 2.d),
                Components.startButton(context,
                    "Preview the next upcoming block!", "next", _onUpdate)
              ])),
          SizedBox(height: 10.d),
          Container(
              height: 64.d,
              child: BumpedButton(
                  colors: TColors.blue.value,
                  onTap: _onStart,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SVG.icon("4", theme),
                        SizedBox(width: 12.d),
                        Text("Start",
                            style: theme.textTheme.headline5,
                            textAlign: TextAlign.center)
                      ])))
        ]));
  }

  _onStart() async {
    var shown = await RateOverlay.showRating(context);
    if (!shown && Pref.playCount.value > 3)
      await Ads.show(AdPlace.Interstitial);
    await Rout.push(context, HomePage());
    Cell.maxRandomValue = 3;
    MyGame.boostNextMode = 0;
    MyGame.boostBig = false;
    _onUpdate();
  }

  _onUpdate() => setState(() {});

  _onAdsReady() => setState(() {});

  @override
  void dispose() {
    super.dispose();
    Ads.onAdsReady = null;
  }
}
