import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:unity_ads_plugin/unity_ads.dart';

class Ads {
  static LinkedHashSet<String> _placementIds = new LinkedHashSet();

  static Function? onAdsReady;
  static UnityAdState? _lastAdState;

  static String platform = "Android";
  static init() async {
    debugPrint("Ads init =====> ${DateTime.now().millisecondsSinceEpoch}");
    UnityAds.init(
        gameId: "4230791",
        listener: (UnityAdState state, data) {
          AdPlace place = _getPlacement(data['placementId']);
          if (state == UnityAdState.ready) {
            Analytics.ad(GAAdAction.Loaded, place.type, place.name);
            _placementIds.add(data['placementId']);
            onAdsReady?.call();
          } else if (state == UnityAdState.complete ||
              state == UnityAdState.skipped) {
            Analytics.ad(GAAdAction.RewardReceived, place.type, place.name);
            _lastAdState = state;
          }
          debugPrint(
              "Ads state =====> $state : $data ${DateTime.now().millisecondsSinceEpoch}");
        });

    for (var id in [AdPlace.Rewarded]) {
      var ready = await UnityAds.isReady(placementId: id.name);
      if (ready ?? false) _placementIds.add(id.name);
    }
  }

  static bool isReady([AdPlace? id]) =>
      _placementIds.contains(id == null ? AdPlace.Rewarded.name : id.name);

  static Future<bool> show([AdPlace? id]) async {
    var placement = id ?? AdPlace.Rewarded;
    if (placement.type == GAAdType.Interstitial && Pref.noAds.value > 0)
      return true; // No ads mode
    if (!isReady(placement)) {
      debugPrint("ads ${placement.name} is not ready.");
      Analytics.ad(GAAdAction.FailedShow, placement.type, placement.name);
      return false;
    }
    Analytics.ad(GAAdAction.Show, placement.type,
        placement.name); // where is this from?????
    _lastAdState = UnityAdState.started;
    _placementIds.remove(placement.name);
    UnityAds.showVideoAd(placementId: placement.name);
    const d = Duration(milliseconds: 500);
    while (_lastAdState == UnityAdState.started) await Future.delayed(d);
    return _lastAdState == UnityAdState.complete;
  }

  static AdPlace _getPlacement(String id) {
    switch (id) {
      case "Interstitial_Android":
      case "Interstitial_iOS":
        return AdPlace.Interstitial;
      case "Banner_Android":
      case "Banner_iOS":
        return AdPlace.Banner;
      default:
        return AdPlace.Rewarded;
    }
  }
}

enum AdPlace { Rewarded, Interstitial, Banner }

extension AdExt on AdPlace {
  String get name {
    switch (this) {
      case AdPlace.Rewarded:
        return "Rewarded_${Ads.platform}";
      case AdPlace.Interstitial:
        return "Interstitial_${Ads.platform}";
      case AdPlace.Banner:
        return "Banner_${Ads.platform}";
    }
  }

  int get type {
    switch (this) {
      case AdPlace.Rewarded:
        return GAAdType.RewardedVideo;
      case AdPlace.Interstitial:
        return GAAdType.Interstitial;
      case AdPlace.Banner:
        return GAAdType.Banner;
    }
  }
}
