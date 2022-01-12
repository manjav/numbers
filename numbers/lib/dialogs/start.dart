import 'dart:async';

import 'package:flutter/material.dart';
import 'package:install_prompt/install_prompt.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/dialogs/confirm.dart';
import 'package:numbers/dialogs/daily.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/dialogs/quests.dart';
import 'package:numbers/dialogs/rating.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/notifications/questnotify.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/coins.dart';
import 'package:numbers/widgets/home.dart';
import 'package:numbers/widgets/punchbutton.dart';

class StartDialog extends AbstractDialog {
  StartDialog()
      : super(DialogMode.start,
            height: 330.d,
            showCloseButton: false,
            title: "start_title".l(),
            padding: EdgeInsets.fromLTRB(12.d, 12.d, 12.d, 14.d));
  @override
  _StartDialogState createState() => _StartDialogState();
}

class _StartDialogState extends AbstractDialogState<StartDialog> {
  String _startButtonLabel = "start_l".l();

  @override
  void initState() {
    super.initState();
    Quests.onQuestComplete = _onQuestUpdate;
    if (Pref.tutorMode.value == 0)
      Timer(const Duration(milliseconds: 100), _onStart);
  }

  @override
  Widget headerFactory(ThemeData theme, double width) {
    return Container(
        width: width - 36.d,
        height: 150.d,
        padding: EdgeInsets.only(bottom: 12.d),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Text(widget.title!, style: theme.textTheme.headline4)]));
  }

  @override
  Widget build(BuildContext context) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    var theme = Theme.of(context);
    stepChildren.clear();
    if (Analytics.variant == 3) {
      stepChildren.add(_questButton(theme));
      stepChildren.add(_dailyButton(theme));
    }
    stepChildren.add(bannerAdsFactory("start"));
    return super.build(context);
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (Prefs.getString("cells").isEmpty)
          _boostButton("start_big".l(), "512"),
        SizedBox(width: 2.d),
        _boostButton("start_next".l(), "next")
      ])),
      SizedBox(height: 10.d),
      Container(
          height: 80.d,
          child: BumpedButton(
              colors: TColors.blue.value,
              isEnable: _startButtonLabel == "start_l".l(),
              onTap: _onStart,
              cornerRadius: 16.d,
              content:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SVG.icon("E", theme),
                SizedBox(width: 12.d),
                Text(_startButtonLabel,
                    style: theme.textTheme.headline5,
                    textAlign: TextAlign.center)
              ])))
    ]);
  }

  Widget _boostButton(String title, String boost) {
    var theme = Theme.of(context);
    return Expanded(
        child: Container(
            padding: EdgeInsets.all(8.d),
            decoration: ButtonDecor(TColors.whiteFlat.value, 12.d, true, false),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SVG.show(boost, 58.d),
                _has(boost) ? SVG.show("accept", 22.d) : SizedBox()
              ]),
              SizedBox(height: 6.d),
              Expanded(
                  child: Text(title,
                      style: theme.textTheme.subtitle2,
                      textAlign: TextAlign.center)),
              SizedBox(height: 6.d),
              SizedBox(
                  width: 92.d,
                  height: 40.d,
                  child: BumpedButton(
                      cornerRadius: 8.d,
                      isEnable: !_has(boost),
                      content: Row(children: [
                        SVG.show("coin", 24.d),
                        Expanded(
                            child: Text("${Price.boost}",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyText2))
                      ]),
                      onTap: () => _onBoostTap(boost, Price.boost))),
              SizedBox(height: 4.d),
              SizedBox(
                  width: 92.d,
                  height: 42.d,
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
                      onTap: () => _onBoostTap(boost, 0))),
              SizedBox(height: 6.d)
            ])));
  }

  void _onBoostTap(String boost, int cost) async {
    if (cost > 0) {
      if (Pref.coin.value < cost) {
        Rout.push(context, Toast("coin_notenough".l(), icon: "coin"));
        return;
      }
    } else {
      var reward = await Ads.showRewarded();
      if (reward == null) return;
    }
    await Coins.change(-cost, "start", boost);

    if (boost == "next") MyGame.boostNextMode = 1;
    if (boost == "512") MyGame.boostBig = true;
    _onUpdate();
  }

  bool _has(String boost) {
    return (boost == "next") ? MyGame.boostNextMode > 0 : MyGame.boostBig;
  }

  _onStart() async {
    _startButtonLabel = "wait_l".l();
    _onUpdate();
    await Analytics.updateVariantIDs();
    if (Pref.playCount.value > AdPlace.InterstitialVideo.threshold)
      await Ads.showInterstitial(AdPlace.InterstitialVideo);
    var result = await Rout.push(context, HomePage());
    MyGame.boostNextMode = 0;
    MyGame.boostBig = false;
    _startButtonLabel = "start_l".l();
    _onUpdate();
    if (result != null) {
      await Future.delayed(Duration(milliseconds: 100));
      await Coins.change(result[1], "game", result[0]);
      var accept = await Rout.push(
          context,
          Confirm(
              "Install the game on your device to make sure you’ll always have your progress saved and safe!",
              acceptText: "Install",
              declineText: "Not yet"));
      if (accept)
        InstallPrompt.showInstallPrompt();
      else
        await RatingDialog.showRating(context);
    }
  }

  _onUpdate() => setState(() {});

  Widget _questButton(ThemeData theme) {
    var completed = Quests.hasCompleted;
    var button = PunchButton(
        top: 110.d,
        left: 24.d,
        width: 110.d,
        height: 110.d,
        colors: (completed ? TColors.orange : TColors.whiteFlat).value,
        content: Column(children: [
          SVG.show("quests", 72.d),
          Text("quests_l".l(), style: theme.textTheme.subtitle2)
        ]),
        onTap: () async {
          await Rout.push(context, QuestsDialog());
          _onUpdate();
        });
    button.isPlaying = completed;
    return button;
  }

  Widget _dailyButton(ThemeData theme) {
    var available = Days.collectable;
    var button = PunchButton(
        top: 110.d,
        right: 24.d,
        width: 110.d,
        height: 110.d,
        padding: EdgeInsets.fromLTRB(2.d, 6.d, 0.d, 12.d),
        colors: (available ? TColors.orange : TColors.whiteFlat).value,
        content: Column(children: [
          SVG.show("calendar", 72.d),
          Text("daily_l".l(), style: theme.textTheme.subtitle2)
        ]),
        onTap: () async {
          await Rout.push(context, DailyDialog());
          _onUpdate();
        });
    button.isPlaying = available;
    return button;
  }

  void _onQuestUpdate(Quest quest) {
    _onUpdate();
    final theme = Theme.of(context);
    final notification = QuestNotification(quest, 48.d);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: notification,
        backgroundColor: theme.cardColor,
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.symmetric(horizontal: 6.d, vertical: 14.d),
        margin: EdgeInsets.only(
            right: 12.d,
            left: 12.d,
            bottom: Device.size.height - 62 - notification.size),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.d))));
  }
}
