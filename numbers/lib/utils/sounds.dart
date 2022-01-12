import 'package:flutter/services.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:soundpool/soundpool.dart';
import 'package:vibration/vibration.dart';

class Sound {
  static Map<String, int> map = Map();
  static Soundpool pool = Soundpool.fromOptions();
  static Future<void> init() async {
    for (var i = 1; i <= 6; i++) add("merge-$i");
    add("foul");
    add("fall");
    add("bell");
    add("lose");
    add("pop");
    add("win");
    add("coin");
    add("coins");
    add("merge-end");
    add("button-down");
    add("button-up");
  }

  static Future<void> add(String name) async {
    int soundId =
        await rootBundle.load("assets/sounds/$name.ogg").then((soundData) {
      return pool.load(soundData);
    });
    map[name] = soundId;
  }

  static Future<int> play(String name) async {
    if (Pref.isMute.value == 1) return 0;
    if (map.isEmpty || map[name] == null) return 0;
    return await pool.play(map[name]!);
  }

  static void vibrate(int duration) {
    if (Pref.isVibrateOff.value > 0) return;
    Vibration.vibrate(duration: duration);
  }
}
