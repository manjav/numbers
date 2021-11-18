import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:unity_ads_plugin/unity_ads.dart';

class Ads {
  static Map<AdPlace, AdState> _placements = {
    AdPlace.Interstitial: AdState.Closed,
    AdPlace.Rewarded: AdState.Closed
  };

  static Function(AdPlace, AdState)? onUpdate;
  static String platform = Platform.isAndroid ? "Android" : "iOS";
  static final isSupportAdMob = true;
  static final isSupportUnity = false;

  static AdmobInterstitial? _interstitialAd;
  static AdmobReward? _rewardedAd;
  static bool _hasReward = false;

  static var prefix = "ca-app-pub-5018637481206902/";

  static init() async {
    if (isSupportAdMob) {
      Admob.initialize();
      _interstitialAd = AdmobInterstitial(
        adUnitId: AdPlace.Interstitial.id,
        listener: (AdmobAdEvent event, Map<String, dynamic>? args) =>
            _adMobListeners(AdPlace.Interstitial, event, args),
      );
      _interstitialAd!.load();

      _rewardedAd = AdmobReward(
        adUnitId: AdPlace.Rewarded.id,
        listener: (AdmobAdEvent event, Map<String, dynamic>? args) =>
            _adMobListeners(AdPlace.Rewarded, event, args),
      );
      _rewardedAd!.load();
    }

    if (isSupportUnity) {
      UnityAds.init(
          gameId: "4230791",
          listener: (UnityAdState state, data) {
            AdPlace adPlace = _getPlacement(data['placementId']);
            if (state == UnityAdState.ready) {
              Analytics.ad(
                  GAAdAction.Loaded, adPlace.type, adPlace.name, "unityads");
              _updateState(adPlace, AdState.Loaded);
            } else if (state == UnityAdState.complete ||
                state == UnityAdState.skipped) {
              Analytics.ad(GAAdAction.RewardReceived, adPlace.type,
                  adPlace.name, "unityads");
              _updateState(adPlace, AdState.Closed);
            }
            debugPrint("Ads state =====> $state : $data");
          });
    }

    for (var id in AdPlace.values) {
      var ready = await UnityAds.isReady(placementId: id.name);
      if (ready ?? false) _placements[id] = AdState.Loaded;
    }
  }

  static bool isReady([AdPlace? id]) {
    var _id = id ?? AdPlace.Rewarded;
    if (id != AdPlace.Rewarded && Pref.noAds.value > 0) return false;
    return _placements.containsKey(_id) && _placements[_id] == AdState.Loaded;
  }

  static Widget getBanner({AdmobBannerSize? size}) {
    if (Pref.noAds.value > 0 || Pref.playCount.value < AdPlace.Banner.threshold)
      return SizedBox();
    if (isSupportAdMob)
      return AdmobBanner(
        adSize: size ?? AdmobBannerSize.LARGE_BANNER,
        adUnitId: AdPlace.Banner.id,
        listener: (AdmobAdEvent event, Map<String, dynamic>? args) {},
        onBannerCreated: (AdmobBannerController controller) {
          _updateState(AdPlace.Banner, AdState.Loaded);
        },
      );
    return UnityBannerAd(placementId: AdPlace.Banner.name);
  }

  static showInterstitial() async {
    if (Pref.noAds.value > 0) return;
    if (isSupportAdMob) {
      bool loaded = false;
      loaded = (await _interstitialAd!.isLoaded)!;
      if (!loaded) return;
      _interstitialAd!.show();
      await _waitForClose(AdPlace.Interstitial);
    }
  }

  static Future<bool> showRewarded() async {
    if (isSupportAdMob) {
      _hasReward = false;
      bool loaded = (await _rewardedAd!.isLoaded);
      if (!loaded) return false;
      _rewardedAd!.show();
      await _waitForClose(AdPlace.Rewarded);
      return _hasReward;
    }
    return false;
  }

  /* static Future<bool> _show([AdPlace? id]) async {
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
  } */

  static AdPlace _getPlacement(String id) {
    if (id.contains("Banner")) return AdPlace.Banner;
    if (id.contains("Interstitial")) return AdPlace.Interstitial;
    return AdPlace.Rewarded;
  }

  static _adMobListeners(
      AdPlace adPlace, AdmobAdEvent event, Map<String, dynamic>? args) {
    if (event == AdmobAdEvent.loaded) {
      _updateState(adPlace, AdState.Loaded);
    } else if (event == AdmobAdEvent.opened) {
      _updateState(adPlace, AdState.Opened);
    } else if (event == AdmobAdEvent.rewarded) {
      _hasReward = true;
    } else if (event == AdmobAdEvent.closed) {
      _updateState(adPlace, AdState.Closed);
      if (adPlace == AdPlace.Interstitial)
        _interstitialAd!.load();
      else
        _rewardedAd!.load();
    }
    var action = _getAction(event);
    if (action > 0) Analytics.ad(action, adPlace.type, adPlace.name, "admob");
    debugPrint("=====> $adPlace ${event.toString()} $args");
  }

  static void _updateState(AdPlace adPlace, AdState state) {
    _placements[adPlace] = state;
    onUpdate?.call(adPlace, state);
  }

  static _waitForClose(AdPlace adPlace) async {
    _placements[adPlace] = AdState.Opened;
    const d = Duration(milliseconds: 300);
    while (_placements[adPlace] != AdState.Closed) await Future.delayed(d);
  }

  static int _getAction(AdmobAdEvent event) {
    switch (event) {
      case AdmobAdEvent.loaded:
        return GAAdAction.Loaded;
      case AdmobAdEvent.opened:
        return GAAdAction.Show;
      case AdmobAdEvent.rewarded:
        return GAAdAction.RewardReceived;
      case AdmobAdEvent.leftApplication:
        return GAAdAction.Clicked;
      default:
        return 0;
    }
  }
}

enum AdState { Loaded, Opened, Closed }
enum AdPlace { Rewarded, Interstitial, Banner }

extension AdExt on AdPlace {
  AdPlace parse(String name) {
    return AdPlace.Banner;
  }

  String get name {
    switch (this) {
      case AdPlace.Banner:
        return "Banner_${Ads.platform}";
      case AdPlace.Interstitial:
        return "Interstitial_${Ads.platform}";
      case AdPlace.Rewarded:
        return "Rewarded_${Ads.platform}";
    }
  }

  String get id {
    switch (this) {
      case AdPlace.Banner:
        return "${Ads.prefix}9761457956";
      case AdPlace.Interstitial:
        return "${Ads.prefix}4317559580";
      case AdPlace.Rewarded:
        return "${Ads.prefix}2812906224";
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

  int get threshold {
    if (this == AdPlace.Interstitial) return 3;
    if (this == AdPlace.Banner) return 5;
    return 0;
  }
}
