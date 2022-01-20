import 'package:numbers/core/cell.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';

class Cells {
  static int width = 5;
  static int height = 6;

  Cell? last;
  double? target;
  List<List> map = List.generate(
      width, (c) => List.generate(height, (r) => null, growable: false),
      growable: false);

  Cell? get(int column, int row) {
    if (column < 0 || column >= width || row < 0 || row >= height) return null;
    return map[column][row];
  }

  void set(int column, int row, Cell? cell) {
    map[column][row] = cell;
    _save();
  }

  int getMinValue() {
    int value = 1000;
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        value = (map[i][j] == null ? 1000 : get(i, j)!.value).max(value);
      }
    }
    return value;
  }

  void loop(Function(int, int, Cell) callback,
      {int startFrom = 0, CellState? state, int? value}) {
    var positive = startFrom;
    var negative = startFrom - 1;
    while (positive < Cells.width || negative > -1) {
      if (positive < Cells.width) {
        _verticalLoop(positive, callback, state: state, value: value);
        ++positive;
      }
      if (negative > -1) {
        _verticalLoop(negative, callback, state: state, value: value);
        --negative;
      }
    }
  }

  void _verticalLoop(int i, Function(int, int, Cell) callback,
      {CellState? state, int? value}) {
    for (var j = height - 1; j >= 0; --j) {
      var c = get(i, j);
      if (c != null &&
          (state == null || state == c.state) &&
          (value == null || value == c.value)) callback.call(i, j, map[i][j]);
    }
  }

  bool existState(CellState state) {
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        if (map[i][j] != null && map[i][j].state == state) return true;
      }
    }
    return false;
  }

  int length(int column) {
    var len = 0;
    for (var r = 0; r < height; r++) {
      if (get(column, r) == null) break;
      ++len;
    }
    return len;
  }

  void translate(Cell c, int column, int row) {
    // debugPrint(" => $c $column $row");
    map[c.column][c.row] = null;
    c.column = column;
    c.row = row;
    map[column][row] = c;
    _save();
  }

  List<Cell> getMatchs(int column, int row, int value) {
    var matchs = <Cell>[];
    _addMatch(column, row + 1, value, matchs); // top
    _addMatch(column, row - 1, value, matchs); // bottom
    _addMatch(column - 1, row, value, matchs); // left
    _addMatch(column + 1, row, value, matchs); // right
    return matchs;
  }

  void _addMatch(int column, int row, int value, List<Cell> matchs) {
    var cell = get(column, row);
    if (cell != null && cell.value == value) matchs.add(cell);
  }

  bool accumulateColumn(int column, int row) {
    var found = false;
    map[column][row] = null;
    for (var r = row + 1; r < height; r++) {
      var c = map[column][r];
      if (c == null) continue;
      map[c.column][c.row] = null;
      --c.row;
      c.state = CellState.float;
      map[c.column][c.row] = c;
      found = true;
      _save();
    }
    return found;
  }

  void _save() {
    var data = "";
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        data += (map[i][j] != null ? map[i][j]!.value.toString() : "") +
            (j < height - 1 ? "," : "");
      }
      data += (i < width - 1 ? "|" : "");
    }
    Prefs.setString("cells", data);
  }
}
