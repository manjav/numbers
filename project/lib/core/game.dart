import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_svg/svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project/animations/animate.dart';
import 'package:project/core/achieves.dart';
import 'package:project/core/cell.dart';
import 'package:project/core/cells.dart';
import 'package:project/dialogs/quests.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/games.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';

enum GameEvent {
  boost,
  celebrate,
  completeTutorial,
  lose,
  remove,
  reward,
  rewardBig,
  rewardCube,
  rewardPiggy,
  rewardRecord,
  score,
}

class MyGame extends FlameGame with TapDetector {
  static final Random random = Random();
  static int boostNextMode = 0;
  static bool boostBig = false;
  static bool isPlaying = false;
  static Rect bounds = const Rect.fromLTRB(0, 0, 0, 0);

  final Function(GameEvent, int)? onGameEvent;
  Pref? removingMode;

  bool _tutorMode = false;
  int _reward = 0;
  int _newRecord = 0;
  int _numRewardCells = 0;
  int _mergesCount = 0;
  int _valueRecord = 0;
  int _fallingsCount = 0;
  int _lastFallingColumn = 0;
  double _speed = Cell.minSpeed;
  final Cell _nextCell = Cell(0, 0, 0);
  final Cells _cells = Cells();

  RRect? _bgRect;
  RRect? _lineRect;
  List<Rect>? _rects;
  final Paint _linePaint = Paint();
  final Paint _mainPaint = Paint()..color = TColors.dark.value[2];
  final Paint _zebraPaint = Paint()
    ..color = TColors.dark.value[3].withAlpha(10);
  FallingEffect? _fallingEffect;
  ColumnHint? _columnHint;

  MyGame({this.onGameEvent}) : super() {
    Prefs.score = Pref.score.value;
    Cell.maxRandom = Pref.maxRandom.value;
  }

  @override
  Color backgroundColor() => TColors.dark.value[0];

  void _addScore(int value) {
    if (_tutorMode) return;
    var _new = Prefs.score += Cell.getScore(value);
    onGameEvent?.call(GameEvent.score, _new);
    if (Pref.record.value >= Prefs.score) return;
    Games.submitScore(Prefs.score);
    Pref.record.set(Prefs.score);
    _newRecord = Prefs.score;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _tutorMode = Pref.tutorMode.value == 0;
    if (_tutorMode) {
      Prefs.setString("cells", "");
    } else {
      Pref.playCount.increase(1);
    }
    Analytics.startProgress(
        "main", Pref.playCount.value, "big $boostBig next $boostNextMode");

    _linePaint.color = TColors.dark.value[0];
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
        (i) => Rect.fromLTWH(bounds.left + (i * 2 + 1) * Cell.diameter,
            _bgRect!.top, Cell.diameter, _bgRect!.height));

    add(_fallingEffect = FallingEffect());

    _valueRecord = Pref.lastBig.value;
    _nextCell.init(Cell.getNextColumn(_fallingsCount), 0,
        Cell.getNextValue(_fallingsCount),
        hiddenMode: boostNextMode + 1);
    _nextCell.x = Cell.getX(_nextCell.column);
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

    var data = Prefs.getString("cells");
    if (data.isEmpty) {
      // Add initial cells
      if (boostBig) _defineCell(_nextCell.column, 9);
      for (var i = 0; i < (_tutorMode ? 3 : 5); i++) {
        _defineCell(Cell.getNextColumn(_fallingsCount),
            Cell.getNextValue(_fallingsCount));
        ++_fallingsCount;
      }
    } else {
      var columns = data.split("|");
      for (var i = 0; i < columns.length; i++) {
        var cells = columns[i].split(",");
        for (var j = 0; j < cells.length; j++) {
          if (cells[j].isEmpty) continue;
          _createCell(i, j, int.parse(cells[j]));
        }
      }
    }
    isPlaying = true;
    _spawn();
    await Future.delayed(const Duration(milliseconds: 10));
    onGameEvent?.call(GameEvent.score, 0);
  }

  void _defineCell(int column, value) {
    var row = _cells.length(column);
    while (_cells.getMatchs(column, row, value).isNotEmpty) {
      value = Cell.getNextValue(0);
    }
    _createCell(column, row, value);
  }

  void _createCell(int column, int row, value) {
    var cell = Cell(column, row, value);
    cell.x = Cell.getX(column);
    cell.y = Cell.getY(row);
    cell.state = CellState.fixed;
    _cells.set(column, row, cell);
    add(cell);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_bgRect!, _mainPaint);
    for (var r in _rects!) {
      canvas.drawRect(r, _zebraPaint);
    }
    canvas.drawRRect(_lineRect!, _linePaint);
    super.render(canvas);
  }

  void _spawn() {
    // Check space is clean
    if (_cells.existState(CellState.float)) return;
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
    if (_tutorMode) {
      _nextCell.init(_nextCell.column, 0, Cell.getNextValue(_fallingsCount),
          hiddenMode: boostNextMode + 1);
    }

    if (_reward > 0) _numRewardCells++;
    var cell = Cell(_nextCell.column, row, _nextCell.value, reward: _reward);
    _reward = 0;
    cell.x = Cell.getX(cell.column);
    cell.y = _nextCell.y + Cell.diameter - 20;
    _cells.map[cell.column][row] = _cells.last = cell;
    _cells.target =
        bounds.top + Cell.diameter * (Cells.height - row) + Cell.radius;
    add(cell);
    if (!_tutorMode) {
      var seed = _tutorMode ? _fallingsCount : _cells.getMinValue();
      _nextCell.init(_nextCell.column, 0, Cell.getNextValue(seed),
          hiddenMode: boostNextMode + 1);
    }
    _speed = Cell.minSpeed;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaying) return;
    if (_cells.last == null || _cells.last!.state != CellState.float) return;

    if (_tutorMode && _cells.last!.y > bounds.top + Cell.diameter * 1.54) {
      isPlaying = false;
      var c = Cell.getNextColumn(_fallingsCount);
      _columnHint!.show(Cell.getX(c), c - _nextCell.column);
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

  @override
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
      if (cell == null || cell.state != CellState.fixed) return;
      if (removingMode == Pref.boostRemoveOne) {
        Quests.increase(QuestType.removeone, 1);
        Analytics.funnle("boost_removeone");
        _removeCell(cell.column, cell.row, true);
      } else {
        Analytics.funnle("boost_removecolor");
        _removeCellsByValue(cell.value);
      }
      removingMode!.increase(-1);
      Prefs.increaseCount(removingMode!);
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
    if (_cells.last!.state == CellState.float && !_cells.last!.matched) {
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
      var _y = Cell.getY(row);
      if (_cells.last!.y > _y) {
        debugPrint("col:$col  ${_cells.last!.y}  >>> $_y");
        return;
      }
      var _x = Cell.getX(col);
      // Change column
      if (_nextCell.column != col) {
        _nextCell.column = col;
        _nextCell.add(MoveEffect.to(Vector2(_x, _nextCell.y),
            EffectController(duration: 0.3, curve: Curves.easeInOutQuad)));

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
      c.state = CellState.falling;
      var dy = Cell.getY(c.row);
      var coef = ((dy - c.y) / (Cell.diameter * Cells.height)) * 0.4;
      var hasDistance = dy - c.y > 0;

      var c1 = EffectController(duration: time);
      c.add(MoveEffect.to(Vector2(c.x, dy + Cell.radius * coef), c1));
      c.add(SizeEffect.to(Vector2(1, 1 - coef), c1));

      var c2 = DelayedEffectController(EffectController(duration: time * 2),
          delay: time);
      c.add(MoveEffect.to(Vector2(c.x, dy), c2));
      c.add(SizeEffect.to(Vector2(1, 1), c2));

      Animate.checkCompletion(c2, () => fallingComplete(c, dy, hasDistance));
    }, state: CellState.float, startFrom: _lastFallingColumn);
  }

  void fallingComplete(Cell cell, double dy, bool hasDistance) {
    if (hasDistance) _lastFallingColumn = cell.column;
    cell.size = Vector2(1, 1);
    cell.y = dy;
    cell.state = CellState.fell;

    // All cells falling completed
    var hasFloat = false;
    _cells.loop((i, j, c) {
      if (c.state.index < CellState.fell.index) hasFloat = true;
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
    Quests.increase(QuestType.merges, numMerges);
    return numMerges > 0;
  }

  int _foundMatch(int i) {
    var merges = 0;
    for (var j = 0; j < Cells.height; j++) {
      var c = _cells.map[i][j];
      if (c == null || c.state != CellState.fell) continue;
      c.state = CellState.fixed;

      var matchs = _cells.getMatchs(c.column, c.row, c.value);
      // Relaese all cells over matchs
      for (var m in matchs) {
        _cells.accumulateColumn(m.column, m.row);
        _collectReward(m);
        var controller = EffectController(duration: 0.1);
        m.add(MoveEffect.to(c.position, controller));
        Animate.checkCompletion(controller, () => remove(m));
      }

      if (matchs.isNotEmpty) {
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

    // Send block data
    if (cell.value > 5) {
      Analytics.funnle("block", Cell.getScore(cell.value).toString());
    }

    // Show big number popup
    if (cell.value > _valueRecord) {
      if (cell.value == 11) Quests.increase(QuestType.ce11, 1);
      Pref.lastBig.set(_valueRecord = cell.value);
      Prefs.increaseBig(_valueRecord);
      onGameEvent?.call(GameEvent.rewardBig, _valueRecord);
    }

    // More chance for spawm new cells
    var index = cell.value - (Cell.maxRandom * 0.7).ceil();
    if (index > -1 && index < Cell.lastRandomValue) {
      Pref.maxRandom.set(Cell.maxRandom = index.min(Cell.maxRandom));
    }

    _fallAll();
  }

  void _removeCell(int column, int row, bool accumulate) {
    if (_cells.map[column][row] == null) return;
    _cells.map[column][row].delete((c) => remove(c));
    if (accumulate) {
      _cells.accumulateColumn(column, row);
    } else {
      _cells.set(column, row, null);
    }
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
    _linePaint.color = TColors.dark.value[0];
    Prefs.increaseCount(Pref.revive);
    for (var i = 0; i < Cells.width; i++) {
      for (var j = Cells.height - 3; j < Cells.height; j++) {
        _removeCell(i, j, false);
      }
    }

    Future.delayed(const Duration(seconds: 1), null).then((value) {
      isPlaying = true;
      _spawn();
    });
  }

  Future<void> _celebrate() async {
    var limit = 3;
    if (_mergesCount < limit) return;
    _reward = _numRewardCells > 0 || _tutorMode
        ? 0
        : random.nextInt(3) + _mergesCount * 2;
    var sprite = await Sprite.load(
        '${Asset.prefix}celebration-${(_mergesCount - limit).clamp(0, 3)}.png');
    var celebration = SpriteComponent(
        position: Vector2(_bgRect!.center.dx, _bgRect!.center.dy),
        size: Vector2.zero(),
        sprite: sprite);
    celebration.anchor = Anchor.center;
    var _size = Vector2(bounds.width, bounds.width * 0.2);
    var start = SizeEffect.to(
        _size, EffectController(duration: 0.3, curve: Curves.easeInExpo));
    var idle1 = SizeEffect.to(_size * 1.05,
        EffectController(duration: 0.4, curve: Curves.easeOutExpo));
    var idle2 = SizeEffect.to(_size * 1.0, EffectController(duration: 0.6));
    var end = SizeEffect.to(Vector2(_size.x, 0),
        EffectController(duration: 0.2, curve: Curves.easeInBack));
    Animate(celebration, [start, idle1, idle2, end],
        onComplete: () => remove(celebration));
    add(celebration);
    await Future.delayed(const Duration(milliseconds: 200));
    Sound.play("merge-end");
    onGameEvent?.call(GameEvent.celebrate, 0);
  }
}

class FallingEffect extends PositionComponent {
  RRect? _rect;
  Color? _color;
  int _alpha = 0;

  void tint(RRect rect, Color color) {
    _rect = rect;
    _color = color;
    _alpha = 255;
  }

  @override
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

class ColumnHint extends PositionComponent {
  int appearanceState = 0;
  RRect rect;
  static final Paint _paint = const PaletteEntry(Color(0xAAAADDFF)).paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  int alpha = 0;
  double _scale = 0.99;

  Svg? _hand;
  Svg? _arrow;
  final Vector2 _arrowPos = Vector2.all(0);
  final Vector2 _arrowSize = Vector2.all(32.d);
  final Vector2 _handPos = Vector2.all(0);
  final Vector2 _handSize = Vector2.all(96.d);

  ColumnHint(this.rect) : super() {
    _create();
  }

  Future<void> _create() async {
    _hand = await Svg.load('images/${Asset.prefix}hand.svg');
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    super.render(canvas);
    canvas.drawRRect(rect, alphaPaint(alpha));
    if (appearanceState == 0) {
      alpha -= 15;
    } else if (appearanceState == 2) {
      alpha += 15;
    }

    if (_handSize.x < 88.d) {
      _scale = 1.003;
    } else if (_handSize.x > 96.d) {
      _scale = 0.992;
    }
    _handSize.scale(_scale);
    if (alpha >= 1000) _hand?.renderPosition(canvas, _handPos, _handSize);
    _arrow?.renderPosition(canvas, _arrowPos, _arrowSize);
  }

  show(double x, int direction) async {
    var side = direction == 0 ? "vertical" : (direction > 0 ? "right" : "left");
    _arrow = await Svg.load('images/${Asset.prefix}arrow-$side.svg');
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
