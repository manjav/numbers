import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/utils.dart';

class BumpedButton extends StatefulWidget {
  final bool? isEnable;
  final Widget? content;
  final EdgeInsets? padding;
  final List<Color>? colors;
  final Function()? onTap;
  final double? cornerRadius;
  final Widget? errorMessage;

  const BumpedButton(
      {Key? key,
      this.onTap,
      this.isEnable,
      this.content,
      this.padding,
      this.colors,
      this.errorMessage,
      this.cornerRadius})
      : super(key: key);
  @override
  createState() => _BumpedButtonState();
}

class _BumpedButtonState extends State<BumpedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    var enable = widget.isEnable ?? true;
    var padding = widget.padding ?? EdgeInsets.fromLTRB(10.d, 6.d, 10.d, 12.d);
    if (_isPressed && enable) {
      padding = padding.copyWith(
          top: padding.top + 2.d, bottom: padding.bottom - 2.d);
    }
    return GestureDetector(
        onTap: () {
          if (enable) {
            Sound.play("button-up");
            widget.onTap?.call();
          } else if (widget.errorMessage != null) {
            Rout.push(context, widget.errorMessage!, barrierDismissible: true);
          }
          _isPressed = false;
          setState(() {});
        },
        onTapDown: (details) {
          if (enable) Sound.play("button-down");
          _isPressed = true;
          setState(() {});
        },
        onTapCancel: () {
          if (enable) Sound.play("button-up");
          _isPressed = false;
          setState(() {});
        },
        child: Container(
            padding: padding,
            decoration: ButtonDecor(widget.colors ?? TColors.white.value,
                widget.cornerRadius ?? 10.d, enable, _isPressed),
            width: 144.d,
            height: 52.d,
            child: widget.content ?? const SizedBox()));
  }
}

class ButtonDecor extends Decoration {
  final bool isEnable;
  final bool isPressed;
  final List<Color> colors;
  final double cornerRadius;

  const ButtonDecor(
      this.colors, this.cornerRadius, this.isEnable, this.isPressed);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ButtonDecorationPainter(colors, cornerRadius, isEnable, isPressed);
  }
}

class _ButtonDecorationPainter extends BoxPainter {
  final _backPaint = Paint()..style = PaintingStyle.fill;
  final _shadowPaint = Paint()
    ..color = const Color(0x66000000)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  final _mainPaint = Paint()..style = PaintingStyle.fill;
  var _overPaint = Paint()..style = PaintingStyle.fill;

  final List<Color> colors;
  final double cornerRadius;
  bool isPressed = false;
  bool isEnable = true;

  _ButtonDecorationPainter(
      this.colors, this.cornerRadius, this.isEnable, this.isPressed)
      : super() {
    _mainPaint.color = isEnable
        ? colors[2]
        : Color.lerp(colors[2], const Color(0xFF8a8a8a), 0.80)!;
    _backPaint.color = isEnable ? const Color(0xFF212527) : Colors.grey[600]!;
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    var s = 0.8.d;
    var b = isEnable ? 2.0.d : 0;
    var pressed = isPressed && isEnable;
    var cr = cornerRadius;
    var r = RRect.fromLTRBXY(
        offset.dx,
        offset.dy,
        offset.dx + configuration.size!.width,
        offset.dy + configuration.size!.height,
        cr * 1.2,
        cr * 1.2);
    var sr = RRect.fromLTRBXY(
        r.left - s, r.top, r.right + s, r.bottom + s * 3, cr * 1.2, cr * 1.2);
    var mr = RRect.fromLTRBXY(r.left + b, r.top + b + (isEnable ? 2.d : 0),
        r.right - b, r.bottom - b, cr, cr);
    var or = RRect.fromLTRBXY(
        r.left + b, r.top + b, r.right - b, r.bottom - b - 5.d, cr, cr);

    _overPaint = Paint()
      ..shader = ui.Gradient.linear(
          Offset(or.left, or.top), Offset(or.left, or.bottom), [
        isEnable
            ? colors[0]
            : Color.lerp(colors[0], const Color(0xFF8a8a8a), 0.70)!,
        isEnable
            ? colors[1]
            : Color.lerp(colors[1], const Color(0xFF8a8a8a), 0.70)!
      ]);

    if (isEnable) canvas.drawRRect(sr, _shadowPaint);
    if (isEnable) canvas.drawRRect(r, _backPaint);
    if (!pressed) canvas.drawRRect(mr, _mainPaint);
    canvas.drawRRect(pressed ? mr : or, _overPaint);
  }
}
