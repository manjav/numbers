import 'package:flame/components.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/utils/utils.dart';

class ScoreFX extends PositionComponent with HasGameRef<MyGame> {
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
      remove();
      return;
    }
    var change = (dy - y);
    _alpha = (change / diff * -255).floor();
    y += change / 50;
    TextPaint(
            config: TextPaintConfig(
                fontSize: 24.d,
                fontFamily: 'quicksand',
                color: _textColor.withAlpha(_alpha)))
        .render(canvas, "+$value", Vector2.zero(), anchor: Anchor.center);
  }
}

class Reward extends PositionComponent with HasGameRef<MyGame> {
  static final _textColor = Color(0xFFFFFFFF);

  final value;
  int _alpha = 255;

  Svg? _coin;
  Vector2 _coinSize = Vector2.all(64);
  Vector2 _coinPos = Vector2(-50, -30);
  Vector2 _textPos = Vector2(20, 0);

  Reward(this.value, double x, double y) {
    this.x = x;
    this.y = y;
    this.size = Vector2.zero();
    init();
  }
  Future<void> init() async {
    _coin = await Svg.load('images/coin.svg');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_alpha <= 5) {
      remove();
      return;
    }
    // var change = (dy - y);
    // _alpha = (change / diff * -255).floor();
    TextPaint(
            config: TextPaintConfig(
                fontSize: 64 * size.x,
                fontFamily: 'quicksand',
                color: _textColor.withAlpha(_alpha)))
        .render(canvas, "x$value", _textPos, anchor: Anchor.centerLeft);

    var pos = Vector2(_coinPos.x * size.x, _coinPos.y * size.y);
    _coin!.renderPosition(canvas, pos, _coinSize.scaled(size.x));
  }
}
