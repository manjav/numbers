import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/dialogs/rating.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/home.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class StartDialog extends AbstractDialog {
  StartDialog()
      : super(DialogMode.start,
            height: 300.d,
            showCloseButton: false,
            title: "start_title".l(),
            padding: EdgeInsets.fromLTRB(12.d, 12.d, 12.d, 14.d));
  @override
  _StartDialogState createState() => _StartDialogState();
}

class _StartDialogState extends AbstractDialogState<StartDialog> {
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
    widget.child =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Components.startButton(context, "start_big".l(), "512", _onUpdate),
        SizedBox(width: 2.d),
        Components.startButton(context, "start_next".l(), "next", _onUpdate)
      ])),
      SizedBox(height: 10.d),
      Container(
          height: 64.d,
          child: BumpedButton(
              colors: TColors.blue.value,
              onTap: _onStart,
              cornerRadius: 16.d,
              content:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SVG.icon("4", theme),
                SizedBox(width: 12.d),
                Text("start_l".l(),
                    style: theme.textTheme.headline5,
                    textAlign: TextAlign.center)
              ])))
    ]);
    return super.build(context);
  }

  _onStart() async {
    var shown = await RatingDialog.showRating(context);
    if (!shown && Pref.playCount.value > 7)
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
