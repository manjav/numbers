import 'package:project/core/cell.dart';
import 'package:project/dialogs/daily.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static int score = 0;
  static SharedPreferences? _instance;

  static void init(Function onInit) {
    SharedPreferences.getInstance().then((SharedPreferences prefs) async {
      _instance = prefs;
      var now = DateTime.now().millisecondsSinceEpoch;
      if (!contains("visitCount")) {
        Pref.boostRemoveOne.set(3);
        Pref.boostRemoveColor.set(3);
        Pref.rateLastTime.set(DateTime.now().hoursSinceEpoch - 23);
      }
      Pref.dayFirst.setIfEmpty(now - Days.dayLen);
      Pref.lastBig.setIfEmpty(Cell.firstBigRecord);
      Pref.maxRandom.setIfEmpty(Cell.maxRandomValue);
      Pref.coinPiggy.set(0);
      Pref.visitCount.increase(1);
      onInit();
    });
  }

  static bool contains(String key) => _instance!.containsKey(key);
  static String getString(String key) => _instance!.getString(key) ?? "";
  static void setString(String key, String value) {
    _instance!.setString(key, value);
  }

  static int getInt(String key) => _instance!.getInt(key) ?? 0;
  static void setInt(String key, int value, bool backup) {
    _instance!.setInt(key, value);
    // if (backup) _backup();
  }

  static int increase(String key, int value) {
    if (value == 0) return 0;
    var newValue = getInt(key) + value;
    setInt(key, newValue, false);
    return newValue;
  }

  static int getBig(int value) => _instance!.getInt("big_$value") ?? 0;
  static int increaseBig(int value) {
    var key = "big_$value";
    var newValue = increase(key, 1);
    if (value == 6 || value == 7 || value == 10) Analytics.funnle(key);
    return newValue;
  }

  static int getCount(Pref type) => getInt("${type.name}_count");
  static void setCount(Pref type, int value) =>
      setInt("${type.name}_count", value, false);
  static void increaseCount(Pref type) {
    var key = "${type.name}_count";
    setInt(key, getInt(key) + 1, false);
  }
}

enum Pref {
  boostBig,
  boostNext,
  boostRemoveColor,
  boostRemoveOne,
  coin,
  coinPiggy,
  dayCount,
  dayFirst,
  isMute,
  isVibrateOff,
  noAds,
  lastBig,
  maxRandom,
  playCount,
  rate,
  ratedBefore,
  rateLastTime,
  record,
  revive,
  score,
  tutorMode,
  visitCount
}

extension PrefExt on Pref {
  String get name {
    switch (this) {
      case Pref.boostBig:
        return "boostBig";
      case Pref.boostNext:
        return "boostNext";
      case Pref.boostRemoveColor:
        return "boostRemoveColor";
      case Pref.boostRemoveOne:
        return "boostRemoveOne";
      case Pref.coin:
        return "coin";
      case Pref.coinPiggy:
        return "coinPiggy";
      case Pref.dayFirst:
        return "dayFirst";
      case Pref.dayCount:
        return "dayCount";
      case Pref.isMute:
        return "isMute";
      case Pref.isVibrateOff:
        return "isVibrateOff";
      case Pref.lastBig:
        return "lastBig";
      case Pref.maxRandom:
        return "maxRandom";
      case Pref.noAds:
        return "noAds";
      case Pref.playCount:
        return "playCount";
      case Pref.rate:
        return "rate";
      case Pref.ratedBefore:
        return "ratedBefore";
      case Pref.rateLastTime:
        return "rateLastTime";
      case Pref.record:
        return "record";
      case Pref.revive:
        return "revive";
      case Pref.score:
        return "score";
      case Pref.tutorMode:
        return "tutorMode";
      case Pref.visitCount:
        return "visitCount";
    }
  }

  int get value {
    return Prefs.getInt(name);
  }

  void setIfEmpty(int value) {
    if (!Prefs.contains(name)) set(value);
  }

  int set(int value, {bool backup = true}) {
    Prefs.setInt(name, value, backup);
    return value;
  }

  int increase(int value, {bool backup = true}) {
    return Prefs.increase(name, value);
  }
}
