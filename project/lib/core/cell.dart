import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:project/animations/animate.dart';
import 'package:project/core/cells.dart';
import 'package:project/core/game.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';

enum CellState { init, float, falling, fell, fixed }

class Cell extends PositionComponent {
  static int lastRandomValue = 9;
  static int maxRandom = 0;
  static const firstBigRecord = 8;
  static const maxRandomValue = 4;
  static final colors = [
    const PaletteEntry(Color(0xFF191C1D)),
    const PaletteEntry(Color(0xFF9600FF)),
    const PaletteEntry(Color(0xFFF0145A)),
    const PaletteEntry(Color(0xFFFFBC15)),
    const PaletteEntry(Color(0xFF21C985)),
    const PaletteEntry(Color(0xFF00B0F0)),
    const PaletteEntry(Color(0xFFE007B4)),
    const PaletteEntry(Color(0xFF7EE024)),
    const PaletteEntry(Color(0xFFFF5B8E)),
    const PaletteEntry(Color(0xFFFF5518)),
    const PaletteEntry(Color(0xFFACC723)),
    const PaletteEntry(Color(0xFF6132D6)),
    const PaletteEntry(Color(0xFFAC3674)),
    const PaletteEntry(Color(0xFF8E7C58)),
    const PaletteEntry(Color(0xFFE2DB21)),
    const PaletteEntry(Color(0xFF0070C0)),
    const PaletteEntry(Color(0xFF00C0C0)),
    const PaletteEntry(Color(0xFF004940))
  ];

  static double minSpeed = 0.01;
  static double maxSpeed = 0.8;
  static double diameter = 64.0;
  static double padding = 1.8;
  static double roundness = 16.0;
  static double thickness = 2.0;
  static double strock = 3.0;
  static double radius = 32.0;
  static RRect _backRect = RRect.zero;
  static RRect _sideRect = RRect.zero;
  static RRect _overRect = RRect.zero;
  static Vector2 _valuePos = Vector2.zero();
  static Vector2 _rewardPos = Vector2.zero();
  static Vector2 _rewardSize = Vector2.zero();

  static final scales = [0, 1, 0.9, 0.75, 0.65, 0.6, 0.55];
  static double getX(int col) => MyGame.bounds.left + col * diameter + radius;
  static double getY(int row) =>
      MyGame.bounds.top + (Cells.height - row) * diameter + radius;
  static int getScore(int value) => pow(2, value).toInt();
  // static int getNextValue(int step) => [1, 2, 3, 3, 2, 2, 1, 1][step];
  // static int getNextColumn(int step) => [0, 1, 1, 2, 4, 4, 4, 4][step];
  static int getNextValue(int seed) {
    if (Pref.tutorMode.value == 0) return [1, 3, 5, 1, 2, 4, 5][seed];
    var min = seed.min(1).max((maxRandom * 0.4).ceil());
    return min + MyGame.random.nextInt(maxRandom - min);
  }

  static void updateSizes(double mdiameter) {
    minSpeed = mdiameter * 0.01;
    maxSpeed = mdiameter * 0.8;
    diameter = mdiameter;
    padding = mdiameter * 0.04;
    strock = mdiameter * 0.045;
    roundness = mdiameter * 0.15;
    thickness = mdiameter * 0.1;
    radius = mdiameter * 0.5;

    _valuePos = Vector2(0, mdiameter * -0.05);
    _rewardPos = Vector2.all(mdiameter * -0.43);
    _rewardSize = Vector2.all(mdiameter * 0.4);

    _backRect = RRect.fromLTRBXY(padding - radius, padding - radius,
        radius - padding, radius - padding, roundness * 1.3, roundness * 1.3);
    _sideRect = RRect.fromLTRBXY(strock - radius, strock - radius,
        radius - strock, radius - strock, roundness, roundness);
    _overRect = RRect.fromLTRBXY(strock - radius, strock - radius,
        radius - strock, radius - strock - thickness, roundness, roundness);
  }

  static int getNextColumn(int seed) => Pref.tutorMode.value == 0
      ? [2, 0, 3, 2, 1, 1, 2][seed]
      : MyGame.random.nextInt(Cells.width);

  bool matched = false;
  int hiddenMode = 0;
  int column = 0, row = 0, reward = 0, value = 0;
  Function(Cell)? onInit;
  CellState state = CellState.init;

  static final Paint _backPaint = colors[0].paint();
  Paint? _hiddenPaint;
  Paint? _sidePaint;
  Paint? _overPaint;
  TextPaint? _valuePaint;
  Svg? _rewardPaint;

  Cell(int column, int row, int value, {int reward = 0, Function(Cell)? onInit})
      : super() {
    init(column, row, value, reward: reward, onInit: onInit);
    size = Vector2(1, 1);
  }

  Future<Cell> init(int column, int row, int value,
      {int reward = 0, Function(Cell)? onInit, int hiddenMode = 0}) async {
    this.column = column;
    this.row = row;
    this.value = value;
    this.reward = reward;
    this.onInit = onInit;
    this.hiddenMode = hiddenMode;
    state = CellState.init;

    // Init paints
    _sidePaint = colors[value].withAlpha(180).paint();
    _overPaint = colors[value].paint();

    var shadows = <Shadow>[];
    if (hiddenMode == 0) {
      shadows.add(BoxShadow(
          color: Colors.black.withAlpha(150),
          blurRadius: 3,
          offset: Offset(0, radius * 0.05)));
    }
    _valuePaint = TextPaint(
        style: TextStyle(
            fontSize:
                radius * scales[getScore(value).toString().length.clamp(0, 5)],
            fontFamily: 'quicksand',
            color: hiddenMode > 1 ? colors[value].color : Colors.white,
            shadows: shadows));

    if (hiddenMode > 0) {
      _hiddenPaint = Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..color = hiddenMode > 1 ? colors[value].color : Colors.white;
    }
    if (reward > 0) {
      _rewardPaint = await Svg.load('images/${Asset.prefix}coin.svg');
    }

    scale = Vector2(1.3, 1.3);
    var controller = EffectController(
        duration: matched ? 0.2 : 0.3, curve: Curves.easeOutBack);
    add(ScaleEffect.to(Vector2(1, 1), controller));
    Animate.checkCompletion(controller, _animationComplete);
    return this;
  }

  void _animationComplete() {
    scale = Vector2(1, 1);
    if (state == CellState.init) state = CellState.float;
    onInit?.call(this);
    onInit = null;
  }

  void delete(Function(Cell)? onDelete) {
    var controller = EffectController(
        duration: MyGame.random.nextDouble() * 0.8, curve: Curves.easeInBack);
    add(ScaleEffect.to(Vector2.zero(), controller));
    Animate.checkCompletion(controller, () => onDelete?.call(this));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (hiddenMode > 0) {
      canvas.drawRRect(_overRect.s(scale), _hiddenPaint!);
    } else {
      canvas.drawRRect(_backRect.s(scale), _backPaint);
      canvas.drawRRect(_sideRect.s(scale), _sidePaint!);
      canvas.drawRRect(_overRect.s(scale), _overPaint!);
    }

    _valuePaint!.render(
        canvas, "${hiddenMode == 1 ? "?" : getScore(value)}", _valuePos,
        anchor: Anchor.center);
    if (reward > 0) {
      _rewardPaint!.renderPosition(canvas, _rewardPos, _rewardSize);
    }
  }

  @override
  String toString() => "Cell c:$column, r:$row, v:$value, s:$state}";
}

extension RRectExt on RRect {
  RRect s(Vector2 scale) {
    if (scale.x == 1 && scale.y == 1) return this;
    return RRect.fromLTRBXY(left * scale.x, top * scale.y, right * scale.x,
        bottom * scale.y, blRadiusX * scale.x, blRadiusY * scale.y);
  }
}
