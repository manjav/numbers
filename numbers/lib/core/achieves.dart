import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:numbers/utils/utils.dart';

class ScoreFX extends PositionComponent {
  static final _textColor = Color(0xFFFFFFFF);

  final value;
  int _alpha = 255;
  double dy = 0;
  double diff = 100;
  ScoreFX(this.value, double x, double y) {
    position = Vector2(x, y);
    dy = y - diff;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_alpha <= 5) {
      removeFromParent();
      return;
    }
    var change = (dy - y);
    _alpha = (change / diff * -255).floor();
    y += change / 50;

    TextPaint(
            style: TextStyle(
                fontSize: 24.d,
                fontFamily: 'quicksand',
                color: _textColor.withAlpha(_alpha)))
        .render(canvas, "+$value", Vector2.zero(), anchor: Anchor.center);
  }
}
