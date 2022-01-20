import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:rive/rive.dart';

class Confirm extends AbstractDialog {
  final String text;
  final String? acceptText;
  final String? declineText;
  Confirm(this.text, {Key? key, this.acceptText, this.declineText,})
      : super(
          DialogMode.confirm,
          key: key,
          showCloseButton: false,
          statsButton: const SizedBox(),
          scoreButton: const SizedBox(),
          padding: EdgeInsets.fromLTRB(16.d, 0, 16.d, 16.d),
          height: 0,
        );
  @override
  _ConfirmState createState() => _ConfirmState();
}

class _ConfirmState extends AbstractDialogState<Confirm> {
  @override
  Widget coinsButtonFactory(ThemeData theme) => const SizedBox();

  @override
  Widget contentFactory(ThemeData theme) {
    return Column(children: [
      SizedBox(
          width: 120.d,
          height: 120.d,
          child: const RiveAnimation.asset('anims/nums-character.riv',
              stateMachines: ["happyState"])),
      SizedBox(height: 12.d),
      Text(widget.text, style: theme.textTheme.headline6),
      SizedBox(height: 16.d),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        widget.declineText == null
            ? const SizedBox()
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
            ? const SizedBox()
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
