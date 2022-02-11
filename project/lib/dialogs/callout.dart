import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/dialogs/toast.dart';
import 'package:project/theme/skinnedtext.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';

class Callout extends AbstractDialog {
  static double chromeWidth = 220.d;
  static double chromeHeight = 84.d;
  final Pref type;
  final bool? hasCoinButton;
  const Callout(this.type,
      {Key? key,
      EdgeInsets? padding,
      double? width,
      double? height,
      this.hasCoinButton})
      : super(
          DialogMode.callout,
          key: key,
          padding: padding,
          width: width,
          height: height,
        );
  @override
  _CalloutState createState() => _CalloutState();
}

class _CalloutState extends AbstractDialogState<Callout> {
  @override
  Widget build(BuildContext context) {
    var pd = widget.padding;
    var cost = Price.boost * (Prefs.getCount(widget.type) + 1);
    var adyCost = Price.boost ~/ Ads.costCoef;
    var theme = Theme.of(context);
    Callout.chromeWidth = 220.d;
    Callout.chromeHeight = 84.d;
    Sound.play("pop");
    return Stack(children: [
      Positioned(
          left: pd != null && pd.left != 0 ? pd.left : null,
          top: pd != null && pd.top != 0 ? pd.top : null,
          right: pd != null && pd.right != 0 ? pd.right : null,
          bottom: pd != null && pd.bottom != 0 ? pd.bottom : null,
          child: Container(
              width: widget.width ?? Callout.chromeWidth,
              height: widget.height ?? Callout.chromeHeight,
              padding: EdgeInsets.all(8.d),
              decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                        blurRadius: 3,
                        color: Colors.black,
                        offset: Offset(0.5, 2))
                  ],
                  color: theme.cardColor,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(16))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("clt_${widget.type.name}_text".l(),
                        style: theme.textTheme.subtitle2),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(
                          width: 98.d,
                          height: 42.d,
                          child: BumpedButton(
                              cornerRadius: 8.d,
                              colors: TColors.orange.value,
                              content: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    SVG.show("coin", 24.d),
                                    SkinnedText("$cost",
                                        style: theme.textTheme.headline5)
                                  ]),
                              onTap: () => buttonsClick(
                                  context, widget.type.name, -cost, false))),
                      SizedBox(width: 8.d),
                      SizedBox(
                          width: 98.d,
                          height: 42.d,
                          child: BumpedButton(
                              cornerRadius: 8.d,
                              isEnable: Ads.isReady,
                              colors: TColors.green.value,
                              errorMessage:
                                  Toast("ads_unavailable".l(), monoIcon: "0"),
                              content: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    SVG.icon("A", theme, scale: 0.7),
                                    SizedBox(width: 2.d),
                                    SVG.show("coin", 18.d),
                                    SkinnedText("$adyCost",
                                        style: theme.textTheme.headline5)
                                  ]),
                              onTap: () => buttonsClick(
                                  context, widget.type.name, -adyCost, true)))
                    ])
                  ]))),      Visibility(child: waiting, visible: waiting.visible)

    ]);
  }
}
