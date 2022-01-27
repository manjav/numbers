import 'dart:async';
import 'dart:io';

import 'package:app_tutti/apptutti.dart';
import 'package:flutter/material.dart';
import 'package:project/utils/prefs.dart';

class Ads {
  static Function(AdPlace, AdState)? onUpdate;
  static String platform = Platform.isAndroid ? "Android" : "iOS";
  static const rewardCoef = 10;
  static const costCoef = 6;
  static const isSupportAdMob = true;
  static const isSupportUnity = false;

  static bool showSuicideInterstitial = false;

  static var prefix = "";

  static bool isReady = true;
  static bool hasReward = false;

  static init() async {
    Apptutti.init(listener: (map) {
      _isReady();
    });
  }

  /* static BannerAd getBanner(String type, {AdSize? size}) {
    var place = AdPlace.Banner;
    var name = place.name + "_" + type;
  }
 */

  static Future<bool?> _isReady([AdPlace? place]) async {
    var _place = place ?? AdPlace.rewarded;
    if (_place != AdPlace.rewarded) {
      if (Pref.playCount.value < _place.threshold) return false;
      if (Pref.noAds.value > 0) return false;
    }
    var r = await Apptutti.isAdReady();
    isReady = r ?? false;
    onUpdate?.call(AdPlace.rewarded, AdState.loaded);
    return isReady;
  }

  static showInterstitial(AdPlace place) {
    if (Pref.noAds.value > 0) return;
    if (!isReady) return;
    Apptutti.showAd(Apptutti.ADTYPE_INTERSTITIAL, listener: _listener);
  }

  static showRewarded() async {
    hasReward = false;
    if (!isReady) return;
    Apptutti.showAd(Apptutti.ADTYPE_REWARDED, listener: _listener);
  }

  static void _listener(Map<dynamic, dynamic> args) {
    if (args[Apptutti.ADTYPE] == Apptutti.ADTYPE_REWARDED &&
        args[Apptutti.ADEVENT] == Apptutti.ADEVENT_COMPLETE) hasReward = true;
    debugPrint("Ads => $args   $hasReward");
  }
}

enum AdState {
  closed,
  clicked,
  failedLoad,
  failedShow,
  loaded,
  rewardReceived,
  request,
  show,
}

extension AdExt on AdState {
  int get order {
    if (this == AdState.failedLoad) return -1;
    return index;
  }
}

enum AdPlace {
  banner,
  interstitial,
  interstitialVideo,
  rewarded,
}

extension AdPlaceExt on AdPlace {
  int get threshold {
    if (this == AdPlace.banner) return 7;
    if (this == AdPlace.interstitialVideo) return 4;
    return 0;
  }
}
