import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:install_prompt/install_prompt.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/overlays/shop.dart';
import 'package:numbers/overlays/stats.dart';
import 'package:numbers/utils/Analytics.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/gemeservice.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';
import 'package:numbers/widgets/punchbutton.dart';
import 'package:numbers/widgets/widgets.dart';
import 'package:rive/rive.dart';

class Overlays {
  static Widget basic(
    BuildContext context,
    String tag, {
    String? sfx,
    String? title,
    double? width,
    double? height,
    Widget? content,
    Widget? scoreButton,
    Widget? coinButton,
    Widget? statsButton,
    Function? onWillPop,
    EdgeInsets? padding,
    bool hasChrome = true,
    bool hasClose = true,
    bool closeOnBack = true,
  }) {
    var theme = Theme.of(context);
    Sound.play(sfx ?? "pop");
    Analytics.setScreen(tag);
    return WillPopScope(
        key: Key(tag),
        onWillPop: () async {
          onWillPop?.call();
          return closeOnBack;
        },
        child: Stack(alignment: Alignment.center, children: [
          scoreButton ??
              Positioned(
                  top: 46.d,
                  right: 10.d,
                  child: Components.scores(theme,
                      onTap: () =>
                          PlayGames.showLeaderboard("CgkIw9yXzt4XEAIQAQ"))),
          statsButton ??
              Positioned(
                  top: 32.d,
                  left: 12.d,
                  child: Components.stats(theme,
                      onTap: () => Rout.push(context, StatsOverlay()))),
          coinButton ??
              Positioned(
                  top: 32.d, left: 66.d, child: Components.coins(context)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
                padding: EdgeInsets.fromLTRB(48.d, 80.d, 48.d, 10.d),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      title != null
                          ? Text(title, style: theme.textTheme.headline4)
                          : SizedBox(),
                      if (hasClose)
                        GestureDetector(
                            child: SVG.show("close", 28.d),
                            onTap: () {
                              onWillPop?.call();
                              Navigator.of(context).pop();
                            })
                    ])),
            Container(
                width: width ?? 300.d,
                height: height == null ? 340.d : (height == 0 ? null : height),
                padding: padding ?? EdgeInsets.fromLTRB(18.d, 12.d, 18.d, 18.d),
                decoration: hasChrome
                    ? BoxDecoration(
                        color: theme.dialogTheme.backgroundColor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(24.d)))
                    : null,
                child: content ?? SizedBox())
          ])
        ]));
  }

  static revive(BuildContext context, int numRevive) {
    var theme = Theme.of(context);
    var cost = 100 * pow(2, numRevive).round();
    return basic(context, "revive",
        sfx: "lose",
        title: Device.aspectRatio < 0.7 ? "Revive" : null,
        width: 310.d,
        height: 300.d,
        content: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SVG.show("record", 16.d),
              Text(" ${Pref.record.value.format()}",
                  style: theme.textTheme.headline6)
            ])),
            Positioned(
                top: 24.d,
                child: Text(Prefs.score.format(),
                    style: theme.textTheme.headline3)),
            Center(
                heightFactor: 0.85,
                child: RiveAnimation.asset('anims/nums-revive.riv',
                    stateMachines: ["machine"])),
            Positioned(
                height: 76.d,
                width: 116.d,
                bottom: 4.d,
                left: 4.d,
                child: BumpedButton(
                    onTap: () => _buttonsClick(context, "revive", -cost),
                    cornerRadius: 16.d,
                    content: Stack(alignment: Alignment.centerLeft, children: [
                      SVG.show("coin", 36.d),
                      Positioned(
                          top: 5.d,
                          left: 40.d,
                          child: Text("${cost.format()}",
                              style: theme.textTheme.button)),
                      Positioned(
                          bottom: 7.d,
                          left: 40.d,
                          child:
                              Text("Revive", style: theme.textTheme.subtitle1)),
                    ]))),
            PunchButton(
                height: 76.d,
                width: 130.d,
                bottom: 4.d,
                right: 4.d,
                cornerRadius: 16.d,
                errorMessage: Ads.errorMessage(theme),
                isEnable: numRevive < 2 && Ads.isReady(),
                onTap: () =>
                    _buttonsClick(context, "revive", 0, adId: AdPlace.Rewarded),
                colors: TColors.orange.value,
                content: Stack(alignment: Alignment.centerLeft, children: [
                  SVG.icon("0", theme),
                  Positioned(
                      top: 5.d,
                      left: 40.d,
                      child: Text("Free", style: theme.textTheme.headline4)),
                  Positioned(
                      bottom: 7.d,
                      left: 40.d,
                      child: Text("Revive", style: theme.textTheme.headline6)),
                ]))
          ],
        ));
  }

  static int rewardCoef = 2;
  static record(BuildContext context, ConfettiController confettiController) {
    var reward = 100;
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 500), () => confettiController.play());
    return basic(context, "record",
        sfx: "win",
        hasClose: false,
        height: 310.d,
        padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d),
        onWillPop: () => _buttonsClick(context, "record", reward),
        content: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
              top: 152.d,
              child: Text("New Record", style: theme.textTheme.caption)),
          Positioned(
              top: 166.d,
              child:
                  Text(Prefs.score.format(), style: theme.textTheme.headline2)),
          Positioned(
              height: 76.d,
              width: 110.d,
              bottom: 4.d,
              left: 4.d,
              child: BumpedButton(
                  onTap: () => _buttonsClick(context, "record", reward),
                  cornerRadius: 16.d,
                  content: Stack(alignment: Alignment.centerLeft, children: [
                    SVG.show("coin", 36.d),
                    Positioned(
                        top: 5.d,
                        left: 40.d,
                        child: Text(reward.format(),
                            style: theme.textTheme.button)),
                    Positioned(
                        bottom: 7.d,
                        left: 40.d,
                        child: Text("Claim", style: theme.textTheme.subtitle2)),
                  ]))),
          PunchButton(
              height: 76.d,
              width: 130.d,
              bottom: 4.d,
              right: 4.d,
              cornerRadius: 16.d,
              isEnable: Ads.isReady(),
              colors: TColors.orange.value,
              errorMessage: Ads.errorMessage(theme),
              onTap: () => _buttonsClick(context, "record", rewardCoef * reward,
                  adId: AdPlace.Rewarded),
              content: Stack(alignment: Alignment.centerLeft, children: [
                SVG.icon("0", theme),
                Positioned(
                    top: 5.d,
                    left: 44.d,
                    child: Text((rewardCoef * reward).format(),
                        style: theme.textTheme.headline4)),
                Positioned(
                    bottom: 7.d,
                    left: 44.d,
                    child: Row(children: [
                      SVG.show("coin", 22.d),
                      Text("x$rewardCoef", style: theme.textTheme.headline6)
                    ])),
              ])),
          Positioned(top: 60, child: Components.confetty(confettiController)),
          Center(
              heightFactor: 0.52,
              child: RiveAnimation.asset('anims/nums-record.riv',
                  stateMachines: ["machine"])),
        ]));
  }

  static bigValue(
      BuildContext context, int value, ConfettiController confettiController) {
    var reward = value * 20;
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 500), () => confettiController.play());
    return basic(context, "bigValue",
        sfx: "win",
        height: 330.d,
        hasClose: false,
        padding: EdgeInsets.fromLTRB(18.d, 0.d, 18.d, 18.d),
        title: Device.aspectRatio < 0.7 ? "Big Block" : null,
        onWillPop: () => _buttonsClick(context, "big", reward),
        content: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
              top: 140.d,
              child: Text(
                  "Congratulations.\nYou made ${Cell.getScore(value)}!\n\nEarn more reward?",
                  style: theme.textTheme.caption,
                  textAlign: TextAlign.center)),
          Positioned(
              height: 76.d,
              width: 110.d,
              bottom: 4.d,
              left: 4.d,
              child: BumpedButton(
                  onTap: () => _buttonsClick(context, "big", reward),
                  cornerRadius: 16.d,
                  content: Stack(alignment: Alignment.centerLeft, children: [
                    SVG.show("coin", 36.d),
                    Positioned(
                        top: 5.d,
                        left: 36.d,
                        child: Text(reward.format(),
                            style: theme.textTheme.button)),
                    Positioned(
                        bottom: 7.d,
                        left: 36.d,
                        child: Text("Claim", style: theme.textTheme.subtitle2)),
                  ]))),
          PunchButton(
              height: 76.d,
              width: 130.d,
              bottom: 4.d,
              right: 4.d,
              cornerRadius: 16.d,
              isEnable: Ads.isReady(),
              colors: TColors.orange.value,
              errorMessage: Ads.errorMessage(theme),
              onTap: () => _buttonsClick(context, "big", reward * rewardCoef,
                  adId: AdPlace.Rewarded),
              content: Stack(alignment: Alignment.centerLeft, children: [
                SVG.icon("0", theme),
                Positioned(
                    top: 5.d,
                    left: 44.d,
                    child: Text((reward * rewardCoef).format(),
                        style: theme.textTheme.headline4)),
                Positioned(
                    bottom: 7.d,
                    left: 44.d,
                    child: Row(children: [
                      SVG.show("coin", 22.d),
                      Text("x$rewardCoef", style: theme.textTheme.headline6)
                    ])),
              ])),
          Positioned(top: 90, child: Components.confetty(confettiController)),
          Positioned(
              top: 0,
              width: 180.d,
              height: 180.d,
              child: RiveAnimation.asset('anims/nums-shine.riv',
                  stateMachines: ["machine"])),
          Positioned(
              top: 48.d,
              width: 80.d,
              height: 80.d,
              child: RotationTransition(
                  turns: AlwaysStoppedAnimation(-0.02),
                  child: Widgets.cell(theme, value)))
        ]));
  }

  static Widget? endTutorial(
      BuildContext context, ConfettiController confettiController) {
    var theme = Theme.of(context);
    Timer(Duration(milliseconds: 1), () => confettiController.play());
    return basic(context, "endTutorial",
        sfx: "win",
        title: "Good Job!",
        height: 200.d,
        width: 340.d,
        hasClose: false,
        content: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
              top: 20.d,
              child: Text("Now lets try the next large number.\nAre you ready?",
                  style: theme.textTheme.caption)),
          Positioned(
              height: 76.d,
              width: 140.d,
              bottom: 0,
              left: 0,
              child: BumpedButton(
                  onTap: () => Navigator.of(context).pop("tutorReset"),
                  colors: TColors.green.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("5", theme),
                        Text("Replay", style: theme.textTheme.headline5)
                      ]))),
          Positioned(
              height: 76.d,
              width: 140.d,
              bottom: 0,
              right: 0,
              child: BumpedButton(
                  onTap: () => Navigator.of(context).pop("tutorFinish"),
                  colors: TColors.blue.value,
                  cornerRadius: 16.d,
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SVG.icon("4", theme),
                        Text("Ok", style: theme.textTheme.headline5)
                      ]))),
          Center(child: Components.confetty(confettiController))
        ]));
  }

  static callout(BuildContext context, String title, String type,
      {EdgeInsets? padding}) {
    var cost = 100;
    Sound.play("pop");
    var theme = Theme.of(context);
    return Stack(children: [
      Positioned(
          left: padding != null && padding.left != 0 ? padding.left : null,
          top: padding != null && padding.top != 0 ? padding.top : null,
          right: padding != null && padding.right != 0 ? padding.right : null,
          bottom:
              padding != null && padding.bottom != 0 ? padding.bottom : null,
          child: Container(
              width: 220.d,
              height: 84.d,
              padding: EdgeInsets.all(8.d),
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 3,
                        color: Colors.black,
                        offset: Offset(0.5, 2))
                  ],
                  color: theme.cardColor,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: theme.textTheme.subtitle2),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: 98.d,
                              height: 40.d,
                              child: BumpedButton(
                                  cornerRadius: 8.d,
                                  content: Row(children: [
                                    SVG.show("coin", 24.d),
                                    Expanded(
                                        child: Text("$cost",
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyText2))
                                  ]),
                                  onTap: () =>
                                      _buttonsClick(context, type, -cost))),
                          SizedBox(
                              width: 98.d,
                              height: 40.d,
                              child: BumpedButton(
                                  cornerRadius: 8.d,
                                  isEnable: Ads.isReady(),
                                  colors: TColors.orange.value,
                                  errorMessage: Ads.errorMessage(theme),
                                  content: Row(children: [
                                    SVG.icon("0", theme, scale: 0.7),
                                    Expanded(
                                        child: Text("Free",
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.headline5))
                                  ]),
                                  onTap: () => _buttonsClick(context, type, 0,
                                      adId: AdPlace.Rewarded)))
                        ])
                  ])))
    ]);
  }

  static Widget quit(BuildContext context) {
    InstallPrompt.showInstallPrompt();
    var theme = Theme.of(context);
    return basic(context, "quit",
        hasClose: false,
        coinButton: SizedBox(),
        statsButton: SizedBox(),
        scoreButton: Positioned(
            right: 10.d,
            width: 120.d,
            height: 120.d,
            child: RiveAnimation.asset('anims/nums-character.riv',
                stateMachines: ["unhappy"])),
        padding: EdgeInsets.fromLTRB(16.d, 4.d, 16.d, 8.d),
        height: 54.d,
        title: "Quit",
        content: GestureDetector(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text("Are you sure?",
                          style: theme.textTheme.headline5)),
                  SVG.show("accept", 28.d)
                ]),
            onTap: () => _buttonsClick(context, "quit", 0)));
  }

  static Widget confirm(BuildContext context, String message,
      {String? acceptText, String? declineText}) {
    var theme = Theme.of(context);
    return basic(context, "confirm",
        hasClose: false,
        coinButton: SizedBox(),
        statsButton: SizedBox(),
        scoreButton: SizedBox(),
        padding: EdgeInsets.fromLTRB(16.d, 0, 16.d, 16.d),
        height: 0,
        content: Column(children: [
          SizedBox(
              width: 120.d,
              height: 120.d,
              child: RiveAnimation.asset('anims/nums-character.riv',
                  stateMachines: ["happy"])),
          SizedBox(height: 8.d),
          Text(message, style: theme.textTheme.headline5),
          SizedBox(height: 16.d),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            declineText == null
                ? SizedBox()
                : SizedBox(
                    width: 100.d,
                    child: BumpedButton(
                        onTap: () => Navigator.of(context).pop(false),
                        colors: TColors.orange.value,
                        cornerRadius: 12.d,
                        content: Center(
                            child: Text(declineText,
                                style: theme.textTheme.headline5)))),
            acceptText == null
                ? SizedBox()
                : SizedBox(
                    width: 158.d,
                    child: BumpedButton(
                        onTap: () => Navigator.of(context).pop(true),
                        colors: TColors.blue.value,
                        cornerRadius: 12.d,
                        content: Center(
                            child: Text(acceptText,
                                style: theme.textTheme.headline5))))
          ])
        ]));
  }

  static _buttonsClick(BuildContext context, String type, int coin,
      {AdPlace? adId}) async {
    if (coin < 0 && Pref.coin.value < -coin) {
      Rout.push(context, ShopOverlay());
      return;
    }
    if (adId != null) {
      var complete = await Ads.show(adId);
      if (!complete) {
        // Navigator.of(context).pop(null);
        return;
      }
    }
    if (coin != 0) Pref.coin.increase(coin, itemType: "confirm", itemId: type);
    Navigator.of(context).pop(type);
  }

  static Widget message(BuildContext context, Widget? content) {
    return basic(context, "message",
        height: 54.d,
        sfx: "merge-9",
        hasClose: false,
        coinButton: SizedBox(),
        statsButton: SizedBox(),
        scoreButton: SizedBox(),
        padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 8.d),
        content: content);
  }
}
