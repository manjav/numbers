import 'package:flutter/material.dart';
import 'package:project/core/cell.dart';
import 'package:project/utils/utils.dart';

class Widgets {
  static Widget cell(ThemeData theme, int value, {TextStyle? textStyle}) {
    return Container(
        padding: EdgeInsets.only(bottom: 6.d),
        alignment: Alignment.center,
        decoration: CellDecoration(value),
        width: 154.d,
        height: 52.d,
        child: Text("${Cell.getScore(value)}",
            textAlign: TextAlign.center,
            style: textStyle ?? theme.textTheme.headline4));
  }
}

class CellDecoration extends Decoration {
  final int value;
  const CellDecoration(this.value);
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CellDecorationPainter(value);
  }
}

class _CellDecorationPainter extends BoxPainter {
  final _backPaint = Paint()
    ..color = const Color(0xFF212527)
    ..style = PaintingStyle.fill;
  final _shadowPaint = Paint()
    ..color = const Color(0xFF000000)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);
  static final _mainPaint = Paint()..style = PaintingStyle.fill;
  final _overPaint = Paint()..style = PaintingStyle.fill;

  final int value;
  _CellDecorationPainter(this.value) : super() {
    _mainPaint.color = Cell.colors[value].color.withAlpha(180);
    _overPaint.color = Cell.colors[value].color;
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    var b = 2.0;
    var cr = 7.d;
    var r = RRect.fromLTRBXY(
        offset.dx,
        offset.dy,
        offset.dx + configuration.size!.width,
        offset.dy + configuration.size!.height,
        cr * 1.1,
        cr * 1.1);
    var mr = RRect.fromLTRBXY(
        r.left + b, r.top + b, r.right - b, r.bottom - b, cr, cr);
    var or = RRect.fromLTRBXY(
        r.left + b, r.top + b, r.right - b, r.bottom - b - 5.d, cr, cr);

    canvas.drawRRect(r, _shadowPaint);
    canvas.drawRRect(r, _backPaint);
    canvas.drawRRect(mr, _mainPaint);
    canvas.drawRRect(or, _overPaint);
  }
}
