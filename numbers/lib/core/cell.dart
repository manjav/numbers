import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:numbers/core/cells.dart';
import 'package:numbers/core/game.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';

enum CellState { Init, Float, Falling, Fell, Fixed }

class Cell extends PositionComponent {
  static double diameter = 64.0;
  static double padding = 1.8;
  static double roundness = 7.0;
  static double thickness = 4.6;
  static final firstBigRecord = 8;
  static int maxRandomValue = 4;
  static int lastRandomValue = 9;

  static final signs = ["", ";", "<", "=", ">", "?", "@"];
  static final colors = [
    PaletteEntry(Color(0xFF191C1D)),
    PaletteEntry(Color(0xFF9600FF)),
    PaletteEntry(Color(0xFFF0145A)),
    PaletteEntry(Color(0xFFFFBC15)),
    PaletteEntry(Color(0xFF21C985)),
    PaletteEntry(Color(0xFF00B0F0)),
    PaletteEntry(Color(0xFFE007B4)),
    PaletteEntry(Color(0xFF7EE024)),
    PaletteEntry(Color(0xFFFF5B8E)),
    PaletteEntry(Color(0xFFFF5518)),
    PaletteEntry(Color(0xFFACC723)),
    PaletteEntry(Color(0xFF6132D6)),
    PaletteEntry(Color(0xFFAC3674)),
    PaletteEntry(Color(0xFF8E7C58)),
    PaletteEntry(Color(0xFFE2DB21)),
    PaletteEntry(Color(0xFF0070C0)),
    PaletteEntry(Color(0xFF00C0C0)),
    PaletteEntry(Color(0xFF004940))
  ];
  static final scales = [0, 1, 0.9, 0.75, 0.65, 0.6, 0.55];

  static double get radius => diameter * 0.5;
  static double get strock => padding * 1.1;
  static double getX(int col) => MyGame.bounds.left + col * diameter + radius;
  static double getY(int row) => MyGame.bounds.top + row * diameter + radius;
  static int getScore(int value) => pow(2, value) as int;
  static String getSign(int v) => v < signs.length ? signs[v] : v.toString();
  // static int getNextValue(int step) => [1, 2, 3, 3, 2, 2, 1, 1][step];
  // static int getNextColumn(int step) => [0, 1, 1, 2, 4, 4, 4, 4][step];
  static int getNextValue(int seed) {
    if (Pref.tutorMode.value == 0) return [1, 3, 5, 1, 2, 4, 5][seed];
    var min = seed.min(1).max((maxRandomValue * 0.4).ceil());
    return min + MyGame.random.nextInt(maxRandomValue - min);
  }

  static int getNextColumn(int seed) => Pref.tutorMode.value == 0
      ? [2, 0, 3, 2, 1, 1, 2][seed]
      : MyGame.random.nextInt(Cells.width);

  static final _center = Vector2(0, -3);

  bool matched = false;
  int hiddenMode = 0;
  int column = 0, row = 0, reward = 0, value = 0;
  Function(Cell)? onInit;
  CellState state = CellState.Init;
  static final RRect _backRect = RRect.fromLTRBXY(
      padding - radius,
      padding - radius,
      radius - padding,
      radius - padding,
      roundness * 1.3,
      roundness * 1.3);
  static final RRect _sideRect = RRect.fromLTRBXY(strock - radius,
      strock - radius, radius - strock, radius, roundness, roundness);
  static final RRect _overRect = RRect.fromLTRBXY(
      strock - radius,
      strock - radius,
      radius - strock,
      radius - strock - thickness,
      roundness,
      roundness);
  static final RRect _lightRect = RRect.fromRectAndRadius(
      _overRect.outerRect, Radius.circular(roundness * 5));

  static final Paint _backPaint = colors[0].paint();
  static final _lightPaint = PaletteEntry(Color(0x55FFFFFF)).paint();
  TextPaint? _textPaint;
  Paint? _sidePaint;
  Paint? _overPaint;
  Paint? _hiddenPaint;
  Svg? _coin;
  Vector2 _coinPos = Vector2.all(-radius * 0.86);
  Vector2 _coinSize = Vector2.all(26);

  get _fontColor {
    if (hiddenMode == 1) return Colors.white;
    if (hiddenMode == 2) return colors[value].color;
    return Colors.black.withAlpha(200);
  }

  get _color => hiddenMode > 1 ? colors[value].color : Colors.white;

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
    this.onInit = onInit ?? null;
    this.hiddenMode = hiddenMode;
    state = CellState.Init;

    _sidePaint = colors[value].withAlpha(180).paint();
    _overPaint = colors[value].paint();

    var shadows = <Shadow>[];
    if (hiddenMode == 0) {
      shadows.add(BoxShadow(
          color: Colors.white.withAlpha(150),
          blurRadius: 3,
          offset: Offset(0, -radius * 0.05)));
    }
    _textPaint = TextPaint(
        style: TextStyle(
            fontSize: radius * 0.8,
            fontFamily: 'icons',
            color: _fontColor,
            shadows: shadows));

    if (hiddenMode > 0)
      _hiddenPaint = Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..color = _color;
    if (reward > 0) _coin = await Svg.load('images/coin.svg');

    size = Vector2(1.3, 1.3);
    add(SizeEffect(
        size: Vector2(1, 1),
        duration: matched ? 0.2 : 0.3,
        curve: Curves.easeOutBack,
        onComplete: _animationComplete));
    return this;
  }

  void _animationComplete() {
    size = Vector2(1, 1);
    if (state == CellState.Init) state = CellState.Float;
    onInit?.call(this);
    onInit = null;
  }

  void delete(Function(Cell)? onDelete) {
    add(SizeEffect(
        size: Vector2(0, 0),
        duration: MyGame.random.nextDouble() * 0.8,
        curve: Curves.easeInBack,
        onComplete: () => onDelete?.call(this)));
  }

  @override
  void render(Canvas c) {
    super.render(c);
    if (hiddenMode > 0) {
      c.drawRRect(_overRect.s(size), _hiddenPaint!);
    } else {
      c.drawRRect(_backRect.s(size), _backPaint);
      c.drawRRect(_sideRect.s(size), _sidePaint!);
      c.drawRRect(_overRect.s(size), _overPaint!);
      c.drawRRect(_lightRect.s(size), _lightPaint);
    }

    _textPaint!.render(c, "${hiddenMode == 1 ? "?" : getSign(value)}", _center,
        anchor: Anchor.center);
    if (reward > 0) _coin!.renderPosition(c, _coinPos, _coinSize);
  }

  @override
  String toString() => "Cell c:$column, r:$row, v:$value, s:$state}";

  static void updateSizes(double _diameter) {
    diameter = _diameter;
    padding = _diameter * 0.04;
    roundness = _diameter * 0.15;
    thickness = _diameter * 0.05;
  }
}

extension RRectExt on RRect {
  RRect s(Vector2 size) {
    if (size.x == 1 && size.y == 1) return this;
    return RRect.fromLTRBXY(left * size.x, top * size.y, right * size.x,
        bottom * size.y, blRadiusX, blRadiusY);
  }
}
