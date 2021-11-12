import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class Callout extends AbstractDialog {
  static double chromeWidth = 220.d;
  static double chromeHeight = 84.d;
  final String text;
  final String type;
  final EdgeInsets? padding;
  final bool? hasCoinButton;
  final double? width;
  final double? height;
  Callout(this.text, this.type,
      {this.padding, this.width, this.height, this.hasCoinButton})
      : super(
          DialogMode.callout,
        );
  @override
  _CalloutState createState() => _CalloutState();
}

class _CalloutState extends AbstractDialogState<Callout> {
  @override
  Widget build(BuildContext context) {
    var pd = widget.padding;
    var cost = 200;
    var theme = Theme.of(context);
    var hasCoinButton = widget.hasCoinButton ?? true;
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
                    Text(widget.text, style: theme.textTheme.subtitle2),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: 98.d,
                              height: 40.d,
                              child: hasCoinButton
                                  ? BumpedButton(
                                      cornerRadius: 8.d,
                                      content: Row(children: [
                                        SVG.show("coin", 24.d),
                                        Expanded(
                                            child: Text("$cost",
                                                textAlign: TextAlign.center,
                                                style:
                                                    theme.textTheme.bodyText2))
                                      ]),
                                      onTap: () => buttonsClick(
                                          context, widget.type, -cost, false))
                                  : SizedBox()),
                          SizedBox(
                              width: 98.d,
                              height: 40.d,
                              child: BumpedButton(
                                  cornerRadius: 8.d,
                                  isEnable: Ads.isReady(),
                                  colors: TColors.orange.value,
                                  errorMessage: Toast("ads_unavailable".l(),
                                      monoIcon: "0"),
                                  content: Row(children: [
                                    SVG.icon("0", theme, scale: 0.7),
                                    Expanded(
                                        child: Text("free_l".l(),
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.headline5))
                                  ]),
                                  onTap: () => buttonsClick(
                                      context, widget.type, 0, true)))
                        ])
                  ])))
    ]);
  }
}
