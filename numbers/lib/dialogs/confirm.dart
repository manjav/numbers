import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:rive/rive.dart';

class Toast extends AbstractDialog {
  final String text;
  final String? acceptText;
  final String? declineText;
  Toast(this.text, {this.acceptText, this.declineText})
      : super(DialogMode.confirm,
            showCloseButton: false,
            statsButton: SizedBox(),
            scoreButton: SizedBox(),
            padding: EdgeInsets.fromLTRB(16.d, 0, 16.d, 16.d),
            height: 0);
  @override
  _ToastState createState() => _ToastState();
}

class _ToastState extends AbstractDialogState<Toast> {
  @override
  Widget coinsButtonFactory(ThemeData theme) => SizedBox();

  @override
  Widget contentFactory(ThemeData theme) {
    return Column(children: [
      SizedBox(
          width: 120.d,
          height: 120.d,
          child: RiveAnimation.asset('anims/nums-character.riv',
              stateMachines: ["happyState"])),
      SizedBox(height: 12.d),
      Text(widget.text, style: theme.textTheme.headline6),
      SizedBox(height: 16.d),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        widget.declineText == null
            ? SizedBox()
            : SizedBox(
                width: 100.d,
                child: BumpedButton(
                    onTap: () => Navigator.of(context).pop(false),
                    colors: TColors.orange.value,
                    cornerRadius: 12.d,
                    content: Center(
                        child: Text(widget.declineText!,
                            style: theme.textTheme.headline5)))),
        widget.acceptText == null
            ? SizedBox()
            : SizedBox(
                width: 158.d,
                child: BumpedButton(
                    onTap: () => Navigator.of(context).pop(true),
                    colors: TColors.blue.value,
                    cornerRadius: 12.d,
                    content: Center(
                        child: Text(widget.acceptText!,
                            style: theme.textTheme.headline5))))
      ])
    ]);
  }
}
