import 'dart:async' as t;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Animate {
  static void checkCompletion(
      EffectController controller, Function onComplete) {
    t.Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (controller.completed) {
        timer.cancel();
        onComplete();
      }
    });
  }

  int index = 0;
  Function? onComplete;
  List<ComponentEffect> effects;
  PositionComponent owner;
  Animate(this.owner, this.effects, {this.onComplete}) {
    _onEffectComplete();
  }

  _onEffectComplete() {
    if (index >= effects.length) {
      onComplete?.call();
      return;
    }
    checkCompletion(effects[index].controller, _onEffectComplete);
    owner.add(effects[index]);
    ++index;
  }
}
