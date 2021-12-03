import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/cupertino.dart';

class Animate {
  static void tween(PositionComponent target, double duration,
      {double? x,
      double? y,
      double? sizeX,
      double? sizeY,
      double? delay,
      Cubic? curve,
      VoidCallback? onComplete}) {
    x = x ?? target.x;
    y = y ?? target.y;
    sizeX = sizeX ?? target.size.x;
    sizeY = sizeY ?? target.size.y;
    curve = curve ?? Curves.easeInExpo;
    target.add(MoveEffect(
      path: [Vector2(target.x, target.y), Vector2(x, y)],
      curve: curve,
      duration: duration,
      onComplete: onComplete,
    ));
  }

  int index = 0;
  Function? onComplete;
  List<ComponentEffect> effects;
  PositionComponent owner;
  Animate(this.owner, this.effects, {this.onComplete}) {
    this.effects = effects;
    _onEffectComplete();
  }

  _onEffectComplete() {
    if (index >= effects.length) {
      onComplete?.call();
      return;
    }
    var effect = effects[index];
    effect.onComplete = _onEffectComplete;
    owner.add(effects[index]);
    ++index;
  }
}
