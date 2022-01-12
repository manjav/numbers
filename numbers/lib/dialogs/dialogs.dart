import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/dialogs/stats.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/coins.dart';
import 'package:numbers/widgets/components.dart';

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
  });
  @override
  AbstractDialogState createState() => AbstractDialogState();
}

class AbstractDialogState<T extends AbstractDialog> extends State<T> {
  List<Widget> stepChildren = <Widget>[];
  int reward = 0;
  Function? onWillPop;
  @override
  void initState() {
    Ads.onUpdate = _onAdsUpdate;
    Sound.play(widget.sfx ?? "pop");
    Analytics.setScreen(widget.mode.name);
    if (widget.onWillPop != null)
      onWillPop = widget.onWillPop;
    else if (reward > 0)
      onWillPop = () => buttonsClick(context, widget.mode.name, reward, false);
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
    if (coin < 0 && Pref.coin.value < -coin) {
      Rout.push(context, ShopDialog());
      return;
    }
    if (showAd) {
      var reward = await Ads.showRewarded();
      if (reward == null) return;
    } else if (coin > 0 && Ads.showSuicideInterstitial) {
      await Ads.showInterstitial(AdPlace.Interstitial);
    }
    Navigator.of(context).pop([type, coin]);
  }

  Widget bannerAdsFactory(String type) {
    if (!Ads.isReady(AdPlace.Banner)) return SizedBox();
    var ad = Ads.getBanner(type);
    return Positioned(
        bottom: 8.d,
        child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16.d)),
                child: AdWidget(ad: ad))));
  }

  Widget rankButtonFactory(ThemeData theme) {
    return widget.scoreButton ??
        Positioned(
            top: 46.d,
            right: 10.d,
            child: Components.scores(theme, onTap: () {
              // Analytics.design('guiClick:record:${widget.mode.name}');
              // GamesServices.showLeaderboards();
            }));
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
                  ? Text(widget.title!, style: theme.textTheme.headline4)
                  : SizedBox(),
              if (hasClose)
                widget.closeButton ??
                    GestureDetector(
                        child: SVG.show("close", 28.d),
                        onTap: () {
                          widget.onWillPop?.call();
                          Navigator.of(context).pop();
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
            ? BoxDecoration(
                color: theme.dialogTheme.backgroundColor,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(24.d)))
            : null,
        child: contentFactory(theme));
  }

  Widget contentFactory(ThemeData theme) => SizedBox();

  _onAdsUpdate(AdPlace placement, AdState state) {
    if (placement == AdPlace.Rewarded && state != AdState.Closed)
      setState(() {});
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
  confirmDialog,
  cube,
  daily,
  pause,
  piggy,
  quests,
  quit,
  rating,
  record,
  review,
  revive,
  shop,
  start,
  stats,
  toast
}

extension DialogName on DialogMode {
  String get name {
    switch (this) {
      case DialogMode.big:
        return "big";
      case DialogMode.callout:
        return "callout";
      case DialogMode.confirmDialog:
        return "confirmDialog";
      case DialogMode.confirm:
        return "confirm";
      case DialogMode.cube:
        return "cube";
      case DialogMode.daily:
        return "daily";
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
      case DialogMode.start:
        return "start";
      case DialogMode.stats:
        return "stats";
      case DialogMode.toast:
        return "toast";
    }
  }
}
