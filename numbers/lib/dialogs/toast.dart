import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/utils.dart';

import 'dialogs.dart';

// ignore: must_be_immutable
class Toast extends AbstractDialog {
  final String text;
  final String? icon;
  final String? monoIcon;
  Toast(this.text, {this.icon, this.monoIcon})
      : super(DialogMode.toast,
            height: 54.d,
            sfx: "merge-9",
            showCloseButton: false,
            coinButton: SizedBox(),
            statsButton: SizedBox(),
            scoreButton: SizedBox(),
            padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 8.d));
  @override
  _ToastState createState() => _ToastState();
}

class _ToastState extends AbstractDialogState<Toast> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var iconWidget = <Widget>[];
    if (widget.monoIcon != null) {
      iconWidget.add(SVG.icon(widget.monoIcon!, theme));
      iconWidget.add(SizedBox(width: 8.d));
    }
    if (widget.icon != null) {
      iconWidget.add(SVG.show(widget.icon!, 32.d));
      iconWidget.add(SizedBox(width: 8.d));
    }
    iconWidget
        .add(Text(widget.text, style: Theme.of(context).textTheme.headline5));
    widget.child = Row(children: iconWidget);
    return super.build(context);
  }
}
