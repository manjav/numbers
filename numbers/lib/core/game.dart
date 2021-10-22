import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/palette.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/core/achieves.dart';
import 'package:numbers/core/cell.dart';
import 'package:numbers/core/cells.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/sounds.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/gemeservice.dart';

enum GameEvent {
  big,
  boost,
  celebrate,
  openPiggy,
  completeTutorial,
  lose,
  remove,
  reward,
  rewarded,
  score
}

class MyGame extends BaseGame with TapDetector {
  static final Random random = new Random();
  static int boostNextMode = 0;
  static bool boostBig = false;
  static bool isPlaying = false;

  Rect bounds = Rect.fromLTRB(0, 0, 0, 0);
  Function(GameEvent, int)? onGameEvent;
  int numRevives = 0;
  String? removingMode;

  bool _tutorMode = false;
  int _reward = 0;
  int _newRecord = 0;
  int _numRewardCells = 0;
  int _mergesCount = 0;
  int _valueRecord = 0;
  int _fallingsCount = 0;
  int _lastFallingColumn = 0;
  double _speed = Cell.minSpeed;
  Cell _nextCell = Cell(0, 0, 0);
  Cells _cells = Cells();

  RRect? _bgRect;
  RRect? _lineRect;
  List<Rect>? _rects;
  Paint _linePaint = Paint();
  Paint _mainPaint = Paint()..color = TColors.black.value[2];
  Paint _zebraPaint = Paint()..color = TColors.black.value[3];
  FallingEffect? _fallingEffect;
  ColumnHint? _columnHint;

  MyGame({bounds, onGameEvent}) : super() {
    Prefs.score = 0;
    this.bounds = bounds;
    this.onGameEvent = onGameEvent;
  }
  @override
  Color backgroundColor() => TColors.black.value[0];

  void _addScore(int value) {
    if (_tutorMode) return;
    var _new = Prefs.score += Cell.getScore(value);
    onGameEvent?.call(GameEvent.score, _new);
    if (Pref.record.value >= Prefs.score) return;
    PlayGames.submitScoreById("CgkIw9yXzt4XEAIQAQ", Prefs.score);
    Pref.record.set(Prefs.score);
    _newRecord = Prefs.score;
  }

  @override
  void onAttach() async {
    super.onAttach();

    _tutorMode = Pref.tutorMode.value == 0;
    Pref.playCount.increase(1);
    Analytics.startProgress(
        "main", Pref.playCount.value, "big $boostBig next $boostNextMode");

    _linePaint.color = TColors.black.value[0];
    _bgRect = RRect.fromLTRBXY(bounds.left - 4, bounds.top - 4,
        bounds.right + 4, bounds.bottom + 4, 16, 16);
    _lineRect = RRect.fromLTRBXY(
        bounds.left + 2,
        bounds.top + Cell.diameter - 4,
        bounds.right - 2,
        bounds.top + Cell.diameter,
        4,
        4);
    _rects = List.generate(
        2,
        (i) => Rect.fromLTRB(
            bounds.left + (i + 1) * Cell.diameter,
            _bgRect!.top,
            bounds.right - (i + 1) * Cell.diameter,
            _bgRect!.bottom));

    add(_fallingEffect = FallingEffect());

    _valueRecord = Cell.firstBigRecord;
    _nextCell.init(Cell.getNextColumn(_fallingsCount), 0,
        Cell.getNextValue(_fallingsCount),
        hiddenMode: boostNextMode + 1);
    _nextCell.x = _nextCell.column * Cell.diameter + Cell.radius + bounds.left;
    _nextCell.y = bounds.top + Cell.radius;
    add(_nextCell);

    if (_tutorMode) {
      add(_columnHint = ColumnHint(RRect.fromLTRBXY(
          0,
          _bgRect!.top + Cell.diameter + Cell.padding * 3,
          0,
          _bgRect!.bottom - Cell.padding * 2,
          8,
          8)));
    }

    // Add initial cells
    if (boostBig) _createCell(_nextCell.column, 9);
    for (var i = 0; i < (_tutorMode ? 3 : 5); i++) {
      _createCell(Cell.getNextColumn(_fallingsCount),
          Cell.getNextValue(_fallingsCount));
      ++_fallingsCount;
    }

    isPlaying = true;
    _spawn();
    await Future.delayed(Duration(milliseconds: 10));
    onGameEvent?.call(GameEvent.score, 0);
  }

  void _createCell(int column, value) {
    var row = _cells.length(column);
    while (_cells.getMatchs(column, row, value).length > 0)
      value = Cell.getNextValue(0);
    var cell = Cell(column, row, value);
    cell.x = bounds.left + column * Cell.diameter + Cell.radius;
    cell.y = bounds.top + Cell.diameter * (Cells.height - row) + Cell.radius;
    cell.state = CellState.Fixed;
    _cells.map[column][row] = cell;
    add(cell);
  }

  void render(Canvas canvas) {
    canvas.drawRRect(_bgRect!, _mainPaint);
    canvas.drawRect(_rects![0], _zebraPaint);
    canvas.drawRect(_rects![1], _mainPaint);
    canvas.drawRRect(_lineRect!, _linePaint);
    super.render(canvas);
  }

  void _spawn() {
    // Check space is clean
    if (_cells.existState(CellState.Float)) return;
    // Check end of tutorial
    if (_tutorMode && _fallingsCount > 6) {
      onGameEvent?.call(GameEvent.completeTutorial, 0);
      return;
    }
    // Check end of game
    var row = _cells.length(_nextCell.column);
    if (row >= Cells.height) {
      _linePaint.color = TColors.orange.value[0];
      isPlaying = false;
      Sound.play("foul");
      Sound.vibrate(100);
      debugPrint("game over!");
      onGameEvent?.call(GameEvent.lose, _newRecord);
      return;
    }
    if (_tutorMode)
      _nextCell.init(_nextCell.column, 0, Cell.getNextValue(_fallingsCount),
          hiddenMode: boostNextMode + 1);

    if (_reward > 0) _numRewardCells++;
    var cell = Cell(_nextCell.column, row, _nextCell.value, reward: _reward);
    _reward = 0;
    cell.x = bounds.left + cell.column * Cell.diameter + Cell.radius;
    cell.y = _nextCell.y + Cell.diameter - 20;
    _cells.map[cell.column][row] = _cells.last = cell;
    _cells.target =
        bounds.top + Cell.diameter * (Cells.height - row) + Cell.radius;
    add(cell);
    if (!_tutorMode)
      _nextCell.init(_nextCell.column, 0, Cell.getNextValue(_fallingsCount),
          hiddenMode: boostNextMode + 1);
    _speed = Cell.minSpeed;
  }

  void update(double dt) {
    super.update(dt);

    if (!isPlaying) return;
    if (_cells.last == null || _cells.last!.state != CellState.Float) return;

    if (_tutorMode && _cells.last!.y > bounds.top + Cell.diameter * 1.54) {
      isPlaying = false;
      var c = Cell.getNextColumn(_fallingsCount);
      _columnHint!.show(
          bounds.left + c * Cell.diameter + Cell.radius, c - _nextCell.column);
    }

    // Check reach to target
    if (_cells.last!.y < _cells.target!) {
      _speed = (_speed + 0.01).clamp(Cell.minSpeed, Cell.maxSpeed);
      _cells.last!.y += _speed;
      return;
    }

    // Change cell state
    _fallAll();
  }

  void onTapDown(TapDownInfo info) {
    if (info.eventPosition.global.y > bounds.bottom) return;
    if (removingMode != null) {
      var cell = _cells.get(
          ((info.eventPosition.global.x - bounds.left) / Cell.diameter)
              .clamp(0, Cells.width - 1)
              .floor(),
          ((bounds.bottom - info.eventPosition.global.y) / Cell.diameter)
              .clamp(0, Cells.height - 1)
              .floor());
      if (cell == null || cell.state != CellState.Fixed) return;
      if (removingMode == "one") {
        Pref.removeOne.increase(-1);
        _removeCell(cell.column, cell.row, true);
      } else {
        Pref.removeColor.increase(-1);
        _removeCellsByValue(cell.value);
      }
      isPlaying = true;
      _fallAll();
      onGameEvent?.call(GameEvent.remove, 0);
      return;
    }
    if (_tutorMode == isPlaying) return;
    if (!_tutorMode &&
        boostNextMode == 0 &&
        info.eventPosition.global.y < bounds.top + Cell.diameter) {
      isPlaying = false;
      onGameEvent?.call(GameEvent.boost, 0);
      return;
    }
    if (_cells.last!.state == CellState.Float && !_cells.last!.matched) {
      var col = ((info.eventPosition.global.x - bounds.left) / Cell.diameter)
          .clamp(0, Cells.width - 1)
          .floor();
      if (_tutorMode) {
        if (col != Cell.getNextColumn(_fallingsCount)) return;
        _columnHint!.hide();
        isPlaying = true;
      }
      var row = _cells.length(col);
      if (_cells.last! == _cells.get(col, row - 1)) --row;
      var _y = bounds.top + Cell.diameter * (Cells.height - row) + Cell.radius;
      if (_cells.last!.y > _y) {
        debugPrint("col:$col  ${_cells.last!.y}  >>> $_y");
        return;
      }
      var _x = bounds.left + col * Cell.diameter + Cell.radius;
      // Change column
      if (_nextCell.column != col) {
        _nextCell.column = col;
        _nextCell.addEffect(MoveEffect(
            duration: 0.3,
            path: [Vector2(_x, _nextCell.y)],
            curve: Curves.easeInOutQuad));

        _cells.translate(_cells.last!, col, row);
        _cells.last!.x = _x;
      }
      _lastFallingColumn = _nextCell.column;

      Sound.play("fall");
      ++_fallingsCount;
      _fallingEffect!.tint(
          RRect.fromLTRBXY(
              _x - Cell.radius,
              _cells.last!.y + Cell.diameter,
              _x + Cell.radius,
              bounds.bottom - row * Cell.diameter,
              Cell.roundness,
              Cell.roundness),
          Cell.colors[_cells.last!.value].color);
    }
    _fallAll();
  }

  void _fallAll() {
    var time = 0.1;
    _cells.loop((i, j, c) {
      c.state = CellState.Falling;
      var dy =
          bounds.top + Cell.diameter * (Cells.height - c.row) + Cell.radius;
      var coef = ((dy - c.y) / (Cell.diameter * Cells.height)) * 0.2;
      var hasDistance = dy - c.y > 0;
      var s1 = CombinedEffect(effects: [
        MoveEffect(
            path: [Vector2(c.x, dy + Cell.radius * coef)], duration: time),
        ScaleEffect(size: Vector2(1, 1 - coef), duration: time)
      ]);
      var s2 = CombinedEffect(effects: [
        MoveEffect(path: [Vector2(c.x, dy)], duration: time),
        ScaleEffect(size: Vector2(1, 1), duration: time)
      ]);
      c.addEffect(SequenceEffect(
          effects: [s1, s2],
          onComplete: () => fallingComplete(c, dy, hasDistance)));
    }, state: CellState.Float, startFrom: _lastFallingColumn);
  }

  void fallingComplete(Cell cell, double dy, bool hasDistance) {
    if (hasDistance) _lastFallingColumn = cell.column;
    cell.size = Vector2(1, 1);
    cell.y = dy;
    cell.state = CellState.Fell;

    // All cells falling completed
    var hasFloat = false;
    _cells.loop((i, j, c) {
      if (c.state.index < CellState.Fell.index) hasFloat = true;
    });
    if (hasFloat) return;
    // Check all matchs after falling animation
    if (!_findMatchs()) {
      _celebrate();
      _mergesCount = 0;
      _spawn();
    }
  }

  bool _findMatchs() {
    var numMerges = 0;
    var cp = _lastFallingColumn;
    var cm = _lastFallingColumn - 1;
    while (cp < Cells.width || cm > -1) {
      if (cp < Cells.width) {
        numMerges += _foundMatch(cp);
        cp++;
      }
      if (cm > -1) {
        numMerges += _foundMatch(cm);
        cm--;
      }
    }
    return numMerges > 0;
  }

  int _foundMatch(int i) {
    var merges = 0;
    for (var j = 0; j < Cells.height; j++) {
      var c = _cells.map[i][j];
      if (c == null || c.state != CellState.Fell) continue;
      c.state = CellState.Fixed;

      var matchs = _cells.getMatchs(c.column, c.row, c.value);
      // Relaese all cells over matchs
      for (var m in matchs) {
        _cells.accumulateColumn(m.column, m.row);
        _collectReward(m);
        m.addEffect(MoveEffect(
            duration: 0.1, path: [c.position], onComplete: () => remove(m)));
      }

      if (matchs.length > 0) {
        _collectReward(c);
        c.matched = true;
        c.init(c.column, c.row, c.value + matchs.length, onInit: _onCellsInit);
        add(ScoreFX(Cell.getScore(c.value), c.x, c.y - 20));
        merges += matchs.length;
      }
      // debugPrint("match $c len:${matchs.length}");
    }
    if (merges > 0) {
      _mergesCount = (_mergesCount + 1).clamp(1, 6);
      Sound.play("merge-$_mergesCount");
      Sound.vibrate(3 + 4 * _mergesCount);
    }
    return merges;
  }

  void _collectReward(Cell cell) {
    if (cell.reward <= 0) return;
    onGameEvent?.call(GameEvent.reward, cell.reward);
    --_numRewardCells;
  }

  void _onCellsInit(Cell cell) {
    _addScore(cell.value);

    // Show big number popup
    if (cell.value > _valueRecord) {
      isPlaying = false;
      onGameEvent?.call(GameEvent.big, _valueRecord = cell.value);
    }

    // More chance for spawm new cells
    if (Cell.maxRandomValue < 7) {
      var distance = (1.5 * sqrt(Cell.maxRandomValue)).ceil();
      if (Cell.maxRandomValue < cell.value - distance)
        Cell.maxRandomValue = cell.value - distance;
    }

    _fallAll();
  }

  void _removeCell(int column, int row, bool accumulate) {
    if (_cells.map[column][row] == null) return;
    _cells.map[column][row].delete((c) => remove(c));
    if (accumulate)
      _cells.accumulateColumn(column, row);
    else
      _cells.map[column][row] = null;
  }

  void _removeCellsByValue(int value) {
    _cells.loop((i, j, c) => _removeCell(i, j, true), value: value);
  }

  void boostNext() {
    boostNextMode = 1;
    _nextCell.init(_nextCell.column, 0, _nextCell.value,
        hiddenMode: boostNextMode + 1);
  }

  void revive() {
    _linePaint.color = TColors.black.value[0];
    numRevives++;
    for (var i = 0; i < Cells.width; i++)
      for (var j = Cells.height - 3; j < Cells.height; j++)
        _removeCell(i, j, false);

    Future.delayed(Duration(seconds: 1), null).then((value) {
      isPlaying = true;
      _spawn();
    });
  }

  void showReward(int value, Vector2 destination, GameEvent event) {
    Sound.play("coin");
    var r = Reward(value, size.x * 0.5, size.y * 0.6);
    var start = ScaleEffect(
        size: Vector2(1, 1), duration: 0.3, curve: Curves.easeOutBack);
    var end = CombinedEffect(effects: [
      MoveEffect(path: [destination], duration: 0.3),
      ScaleEffect(size: Vector2(0.3, 0.3), duration: 0.3)
    ]);
    r.addEffect(SequenceEffect(
        effects: [start, ScaleEffect(size: Vector2(1, 1), duration: 0.3), end],
        onComplete: () {
          remove(r);
          onGameEvent?.call(event, value);
        }));
    add(r);
  }

  Future<void> _celebrate() async {
    var limit = 3;
    if (_mergesCount < limit) return;
    _reward = _numRewardCells > 0 || _tutorMode
        ? 0
        : random.nextInt(5) + _mergesCount * 3;
    var sprite = await Sprite.load(
        'celebration-${(_mergesCount - limit).clamp(0, 3)}.png');
    var celebration = SpriteComponent(
        position: Vector2(_bgRect!.center.dx, _bgRect!.center.dy),
        size: Vector2.zero(),
        sprite: sprite);
    celebration.anchor = Anchor.center;
    var _size = Vector2(bounds.width, bounds.width * 0.2);
    var start =
        ScaleEffect(size: _size, duration: 0.3, curve: Curves.easeInExpo);
    var idle1 = ScaleEffect(
        size: _size * 1.05, duration: 0.4, curve: Curves.easeOutExpo);
    var idle2 = ScaleEffect(size: _size * 1.0, duration: 0.6);
    var end = ScaleEffect(
        size: Vector2(_size.x, 0), duration: 0.2, curve: Curves.easeInBack);
    celebration.addEffect(SequenceEffect(
        effects: [start, idle1, idle2, end],
        onComplete: () {
          remove(celebration);
        }));
    add(celebration);
    await Future.delayed(Duration(milliseconds: 200));
    Sound.play("merge-end");
    onGameEvent?.call(GameEvent.celebrate, 0);
  }
}

class FallingEffect extends PositionComponent with HasGameRef<MyGame> {
  RRect? _rect;
  Color? _color;
  int _alpha = 0;

  void tint(RRect rect, Color color) {
    _rect = rect;
    _color = color;
    _alpha = 255;
  }

  void render(Canvas canvas) {
    if (_alpha <= 0) return;
    canvas.drawRRect(_rect!, alphaPaint(_alpha));
    _alpha -= 15;
    super.render(canvas);
  }

  Paint alphaPaint(int alpha) {
    return Paint()
      ..shader =
          ui.Gradient.linear(Offset(0, _rect!.top), Offset(0, _rect!.bottom), [
        _color!.withAlpha(0),
        _color!.withAlpha(_alpha),
      ]);
  }
}

class ColumnHint extends PositionComponent with HasGameRef<MyGame> {
  int appearanceState = 0;
  RRect rect;
  static final Paint _paint = PaletteEntry(Color(0xAAAADDFF)).paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  int alpha = 0;
  double _scale = 0.99;

  Svg? _hand;
  Svg? _arrow;
  Vector2 _arrowPos = Vector2.all(0);
  Vector2 _arrowSize = Vector2.all(32.d);
  Vector2 _handPos = Vector2.all(0);
  Vector2 _handSize = Vector2.all(96.d);

  ColumnHint(this.rect) : super() {
    _create();
  }

  Future<void> _create() async {
    _hand = await Svg.load('images/hand.svg');
  }

  void render(Canvas canvas) {
    if (alpha <= 0) return;
    super.render(canvas);
    canvas.drawRRect(rect, alphaPaint(alpha));
    if (appearanceState == 0)
      alpha -= 15;
    else if (appearanceState == 2) alpha += 15;

    if (_handSize.x < 88.d)
      _scale = 1.003;
    else if (_handSize.x > 96.d) _scale = 0.992;
    _handSize.scale(_scale);
    if (alpha >= 1000) _hand?.renderPosition(canvas, _handPos, _handSize);
    _arrow?.renderPosition(canvas, _arrowPos, _arrowSize);
  }

  show(double x, int direction) async {
    var side = direction == 0 ? "down" : (direction > 0 ? "right" : "left");
    _arrow = await Svg.load('images/arrow-$side.svg');
    alpha = 1;
    rect = RRect.fromLTRBXY(
        x - Cell.radius, rect.top, x + Cell.radius, rect.bottom, 8.d, 8.d);
    _handPos.x = rect.center.dx - 2.d;
    _handPos.y = rect.center.dy + 4.d;
    _arrowPos.x = rect.center.dx - _arrowSize.x * 0.5;
    _arrowPos.y = rect.top + Cell.radius * (direction == 0 ? 2.1 : 0.9);
    appearanceState = 2;
  }

  void hide() {
    alpha = 255;
    appearanceState = 0;
  }

  Paint alphaPaint(int alpha) {
    if (alpha >= 255) return _paint;
    return Paint()
      ..color = _paint.color.withAlpha(alpha)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
  }
}
