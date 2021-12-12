import 'package:flutter/material.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/utils/utils.dart';

class Widgets {
  static Widget cell(ThemeData theme, int value, {TextStyle? textStyle}) {
    return Container(
        padding: EdgeInsets.only(bottom: 6.d),
        alignment: Alignment.center,
        child: Text("${Cell.getScore(value)}",
            textAlign: TextAlign.center,
            style: textStyle ?? theme.textTheme.headline4),
        decoration: CellDecoration(value),
        width: 154.d,
        height: 52.d);
  }
}

class CellDecoration extends Decoration {
  final int value;
  CellDecoration(this.value);
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CellDecorationPainter(value);
  }
}

class _CellDecorationPainter extends BoxPainter {
  var _backPaint = Paint()
    ..color = Color(0xFF212527)
    ..style = PaintingStyle.fill;
  var _shadowPaint = Paint()
    ..color = Color(0xFF000000)
    ..style = PaintingStyle.fill
    ..maskFilter = MaskFilter.blur(BlurStyle.outer, 2);
  static final _mainPaint = Paint()..style = PaintingStyle.fill;
  var _overPaint = Paint()..style = PaintingStyle.fill;

  final int value;
  _CellDecorationPainter(this.value) : super() {
    _mainPaint.color = Cell.colors[value].color.withAlpha(180);
    _overPaint.color = Cell.colors[value].color;
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    var b = 2.0;
    var _cr = 7.d;
    var r = RRect.fromLTRBXY(
        offset.dx,
        offset.dy,
        offset.dx + configuration.size!.width,
        offset.dy + configuration.size!.height,
        _cr * 1.1,
        _cr * 1.1);
    var mr = RRect.fromLTRBXY(
        r.left + b, r.top + b, r.right - b, r.bottom - b, _cr, _cr);
    var or = RRect.fromLTRBXY(
        r.left + b, r.top + b, r.right - b, r.bottom - b - 5.d, _cr, _cr);

    canvas.drawRRect(r, _shadowPaint);
    canvas.drawRRect(r, _backPaint);
    canvas.drawRRect(mr, _mainPaint);
    canvas.drawRRect(or, _overPaint);
  }
}
