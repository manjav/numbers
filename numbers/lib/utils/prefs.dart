import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:numbers/utils/analytics.dart';
import 'package:numbers/utils/gemeservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static int score = 0;
  static bool allowsBackup = false;
  static SharedPreferences? _instance;
  static void init(Function onInit) {
    SharedPreferences.getInstance().then((SharedPreferences prefs) async {
      _instance = prefs;
      if (!prefs.containsKey("visitCount")) {
        await _restore();
        if (!prefs.containsKey("visitCount")) {
          Pref.coin.set(500, itemType: "game", itemId: "initial");
          Pref.removeOne.set(3);
          Pref.removeColor.set(3);
          Pref.rateTarget.set(2);
        }
      } else {
        _initPlayService();
        allowsBackup = true;
      }
      Pref.coinPiggy.set(0);
      Pref.visitCount.increase(1);
      onInit();
    });
  }

  static void _set(String key, int value, bool backup) {
    _instance!.setInt(key, value);
    if (backup) _backup();
  }

  static int getBig(int value) => _instance!.getInt("big_$value") ?? 0;
  static void increaseBig(int value) {
    var key = "big_$value";
    if (_instance!.containsKey(key))
      _set(key, _instance!.getInt(key)! + 1, true);
    else
      _set(key, 1, true);
  }

  static Future<void> _restore() async {
    await _initPlayService();
    try {
      var save = await PlayGames.openSnapshot('prefs');
      if (save.content == null || save.content!.isEmpty)
        return; // default value when there is no save
      // var content =
      //     '{"playCount":32,"big_14":1,"removeColor":3,"big_11":1,"big_10":1,"big_13":1,"big_12":1,"visitCount":17,"record":148284,"rate":3,"rateTarget":35,"noAds":0,"big_9":2,"coin":2404,"tutorMode":1,"ratedBefore":0,"removeOne":3,"isMute":1,"isVibrateOff":1}';
      debugPrint("o ${save.content!}");
      var data = json.decode(save.content!);
      for (var entry in data.entries) _instance!.setInt(entry.key, entry.value);
      allowsBackup = true;
    } catch (e) {
      print(e.toString());
    }
  }

  static Timer? _wakeupTimer;
  static _backup() async {
    _wakeupTimer?.cancel();
    if (!allowsBackup) return;
    _wakeupTimer = Timer(Duration(seconds: 5), () async {
      try {
        var keys = _instance!.getKeys();
        var data = Map<String, int>();
        for (var key in keys) {
          var value = _instance!.getInt(key) ?? -1;
          if (value > -1) data[key] = value;
        }
        var saveData = json.encode(data);
        debugPrint("s $saveData");
        await PlayGames.saveSnapshot('prefs', saveData);
        PlayGames.openSnapshot('prefs');
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  static _initPlayService() async {
    SigninResult result = await PlayGames.signIn(scopeSnapshot: true);
    if (result.success) {
      // await PlayGames.setPopupOptions();
      debugPrint("${result.account!.displayName} ${result.account!.email}");
    } else {
      debugPrint(result.message);
    }
  }
}

enum Pref {
  coin,
  coinPiggy,
  isMute,
  isVibrateOff,
  noAds,
  playCount,
  rate,
  ratedBefore,
  rateTarget,
  record,
  removeOne,
  removeColor,
  tutorMode,
  visitCount
}

extension PrefExt on Pref {
  String get name {
    switch (this) {
      case Pref.coin:
        return "coin";
      case Pref.coinPiggy:
        return "coinPiggy";
      case Pref.isMute:
        return "isMute";
      case Pref.isVibrateOff:
        return "isVibrateOff";
      case Pref.noAds:
        return "noAds";
      case Pref.playCount:
        return "playCount";
      case Pref.rateTarget:
        return "rateTarget";
      case Pref.rate:
        return "rate";
      case Pref.ratedBefore:
        return "ratedBefore";
      case Pref.record:
        return "record";
      case Pref.removeOne:
        return "removeOne";
      case Pref.removeColor:
        return "removeColor";
      case Pref.tutorMode:
        return "tutorMode";
      case Pref.visitCount:
        return "visitCount";
    }
  }

  int get value {
    return Prefs._instance!.getInt(name) ?? 0;
  }

  int set(int value, {bool backup = true, String? itemType, String? itemId}) {
    if (this == Pref.coin) {
      var type = value > this.value
          ? GAResourceFlowType.Source
          : GAResourceFlowType.Sink;
      Analytics.resource(type, name, value.abs(), itemType!, itemId!);
    }
    Prefs._set(name, value, backup);
    return value;
  }

  int increase(int value,
      {bool backup = true, String? itemType, String? itemId}) {
    return set(this.value + value,
        backup: backup, itemType: itemType, itemId: itemId);
  }
}
