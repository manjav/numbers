import 'package:flutter/material.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/dialogs/stats.dart';
import 'package:project/dialogs/toast.dart';
import 'package:project/theme/chrome.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/coins.dart';
import 'package:project/widgets/components.dart';
import 'package:project/widgets/punchbutton.dart';

class AbstractDialog extends StatefulWidget {
  final DialogMode mode;
  final String? sfx;
  final String? title;
  final double? width;
  final double? height;
  final Widget? scoreButton;
  final Widget? closeButton;
  final Widget? statsButton;
  final Function? onWillPop;
  final EdgeInsets? padding;
  final bool? hasChrome;
  final bool? showCloseButton;
  final bool? closeOnBack;
  final Map<String, dynamic>? args;
  final int? popDuration;

  AbstractDialog(
    this.mode, {
    Key? key,
    this.sfx,
    this.title,
    this.width,
    this.height,
    this.scoreButton,
    this.closeButton,
    this.statsButton,
    this.onWillPop,
    this.padding,
    this.hasChrome,
    this.showCloseButton,
    this.closeOnBack,
    this.args,
    this.popDuration,
  }) : super(key: key ??= Key(mode.name));
  @override
  AbstractDialogState createState() => AbstractDialogState();
}

class AbstractDialogState<T extends AbstractDialog> extends State<T> {
  List<Widget> stepChildren = <Widget>[];
  int reward = 0;
  Function? onWillPop;
  bool _enableButton = true;

  @override
  void initState() {
    Ads.onUpdate = _onAdsUpdate;
    Sound.play(widget.sfx ?? "pop");
    Analytics.setScreen(widget.mode.name);
    if (widget.onWillPop != null) {
      onWillPop = widget.onWillPop;
    } else if (reward > 0) {
      onWillPop = () => buttonsClick(context, widget.mode.name, reward, false);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var width = widget.width ?? 300.d;

    var children = <Widget>[];
    children.add(rankButtonFactory(theme));
    children.add(statsButtonFactory(theme));

    var rows = <Widget>[];
    rows.add(headerFactory(theme, width));
    rows.add(chromeFactory(theme, width));
    children.add(
        Column(mainAxisAlignment: MainAxisAlignment.center, children: rows));
    children.addAll(stepChildren);
    children.add(coinsButtonFactory(theme));

    return WillPopScope(
        key: Key(widget.mode.name),
        onWillPop: () async {
          onWillPop?.call();
          return widget.closeOnBack ?? true;
        },
        child: Stack(alignment: Alignment.center, children: children));
  }

  buttonsClick(BuildContext context, String type, int coin, bool showAd) async {
    if (!_enableButton) return;
    _enableButton = false;
    if (coin < 0 && Pref.coin.value < -coin) {
      Rout.push(context, ShopDialog());
      return;
    }

    var shouldPop = true;
    var exchangeMode = "withoutAd";
    if (showAd) {
      var reward = await Ads.showRewarded(widget.mode.name);
      shouldPop = reward != null;
      exchangeMode = "withAd";
    } else if (coin > 0 && Ads.showSuicideInterstitial) {
      await Ads.showInterstitial(AdPlace.interstitial, widget.mode.toString());
    }
    if (widget.mode == DialogMode.big ||
        widget.mode == DialogMode.cube ||
        widget.mode == DialogMode.piggy ||
        widget.mode == DialogMode.record) {
      await Coins.change(coin, "game", widget.mode.name);
    }
    Analytics.design("adconfirm_$type",
        parameters: {"type": exchangeMode, "coin": coin});
    if (shouldPop) Rout.pop(context, [type, coin]);
  }

  Widget bannerAdsFactory(String type) {
    if (!Ads.isReady(AdPlace.interstitial)) return const SizedBox();
    return Positioned(
        bottom: 8.d, child: Ads.getBannerWidget(type, widget.mode.name));
  }

  Widget rankButtonFactory(ThemeData theme) {
    return widget.scoreButton ??
        Positioned(
            top: 46.d,
            right: 10.d,
            child: Components.scores(theme, widget.mode.name));
  }

  Widget statsButtonFactory(ThemeData theme) {
    return widget.statsButton ??
        Positioned(
            top: 32.d,
            left: 12.d,
            child: Components.stats(theme, onTap: () {
              Analytics.design('guiClick:stats:${widget.mode.name}');
              Rout.push(context, StatsDialog());
            }));
  }

  Widget coinsButtonFactory(ThemeData theme) => Coins(widget.mode.name);

  Widget headerFactory(ThemeData theme, double width) {
    var hasClose = widget.showCloseButton ?? true;
    return SizedBox(
        width: width - 36.d,
        height: 72.d,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widget.title != null
                  ? SkinnedText(widget.title!, style: theme.textTheme.headline4)
                  : const SizedBox(),
              if (hasClose)
                widget.closeButton ??
                    GestureDetector(
                        child: SVG.show("close", 28.d),
                        onTap: () {
                          widget.onWillPop?.call();
                          Rout.pop(context);
                        })
            ]));
  }

  Widget chromeFactory(ThemeData theme, double width) {
    var hasChrome = widget.hasChrome ?? true;
    return Container(
        width: width,
        height: widget.height == null
            ? 340.d
            : (widget.height == 0 ? null : widget.height),
        padding: widget.padding ?? EdgeInsets.fromLTRB(18.d, 12.d, 18.d, 18.d),
        decoration: hasChrome
            ? ChromeDecoration(color: theme.dialogTheme.backgroundColor)
            : null,
        child: contentFactory(theme));
  }

  Widget contentFactory(ThemeData theme) => const SizedBox();

  Widget buttonFactory(
      ThemeData theme, Widget icon, List<Widget> texts, bool isAds,
      [Function()? onTap]) {
    var coef = isAds ? Ads.rewardCoef : 1;
    var button = PunchButton(
        bottom: 4.d,
        cornerRadius: 16.d,
        left: isAds ? null : 4.d,
        right: isAds ? 4.d : null,
        width: isAds ? 130.d : 112.d,
        height: 76.d,
        isEnable: !isAds || Ads.isReady(),
        colors: isAds ? TColors.green.value : TColors.orange.value,
        errorMessage:
            isAds ? Toast("ads_unavailable".l(), monoIcon: "A") : null,
        onTap: onTap ??
            () => buttonsClick(context, widget.mode.name, reward * coef, isAds),
        content: Row(children: [
          icon,
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: texts,
          ))
        ]));
    button.isPlaying = isAds;
    return button;
  }

  Widget buttonPayFactory(ThemeData theme) {
    return buttonFactory(
      theme,
      SVG.show("coin", 36.d),
      [
        SkinnedText(reward.format(), style: theme.textTheme.headline4),
        SkinnedText("claim_l".l(), style: theme.textTheme.headline6)
      ],
      false,
    );
  }

  Widget buttonAdsFactory(ThemeData theme) {
    return buttonFactory(
        theme,
        SVG.icon("A", theme),
        [
          SkinnedText((reward * Ads.rewardCoef).format(),
              style: theme.textTheme.headline4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SVG.show("coin", 22.d),
            SkinnedText("x${Ads.rewardCoef} ", style: theme.textTheme.headline6)
          ])
        ],
        true);
  }

  _onAdsUpdate(MyAd ad) {
    if (ad.type == AdPlace.rewarded && ad.state != AdState.closed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    Ads.onUpdate = null;
  }
}

enum DialogMode {
  big,
  callout,
  confirm,
  cube,
  daily,
  home,
  pause,
  piggy,
  quests,
  quit,
  rating,
  record,
  review,
  revive,
  shop,
  stats,
  toast,
  tutorial,
}

extension DialogName on DialogMode {
  String get name {
    switch (this) {
      case DialogMode.big:
        return "big";
      case DialogMode.callout:
        return "callout";
      case DialogMode.confirm:
        return "confirm";
      case DialogMode.cube:
        return "cube";
      case DialogMode.daily:
        return "daily";
      case DialogMode.home:
        return "home";
      case DialogMode.pause:
        return "pause";
      case DialogMode.piggy:
        return "piggy";
      case DialogMode.quests:
        return "quests";
      case DialogMode.quit:
        return "quit";
      case DialogMode.rating:
        return "record";
      case DialogMode.record:
        return "record";
      case DialogMode.review:
        return "review";
      case DialogMode.revive:
        return "revive";
      case DialogMode.shop:
        return "shop";
      case DialogMode.stats:
        return "stats";
      case DialogMode.toast:
        return "toast";
      case DialogMode.tutorial:
        return "tutorial";
    }
  }
}
