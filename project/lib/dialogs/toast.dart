import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/utils/utils.dart';

class Toast extends AbstractDialog {
  final String text;
  final String? icon;
  final String? monoIcon;
  Toast(this.text, {Key? key, this.icon, this.monoIcon})
      : super(
          DialogMode.toast,
          key: key,
          height: 54.d,
          sfx: "merge-9",
          showCloseButton: false,
          statsButton: const SizedBox(),
          scoreButton: const SizedBox(),
          padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 8.d),
        );
  @override
  createState() => _ToastState();
}

class _ToastState extends AbstractDialogState<Toast> {
  @override
  Widget coinsButtonFactory(ThemeData theme) => const SizedBox();

  @override
  Widget contentFactory(ThemeData theme) {
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
    return Row(children: iconWidget);
  }
}
