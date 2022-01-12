import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:numbers/dialogs/quests.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/prefs.dart';

class Ads {
  static Map<AdPlace, AdState> _placements = Map();

  static Function(AdPlace, AdState)? onUpdate;
  static String platform = Platform.isAndroid ? "Android" : "iOS";
  static final rewardCoef = 10;
  static final isSupportAdMob = true;
  static final isSupportUnity = false;
  static final prefix = "ca-app-pub-5018637481206902/";
  static final maxFailedLoadAttempts = 3;
  static final AdRequest _request = AdRequest(nonPersonalizedAds: false);
  static Map<String, Ad> _ads = Map();
  static Map<AdPlace, int> _attempts = {
    AdPlace.Interstitial: 0,
    AdPlace.InterstitialVideo: 0,
    AdPlace.Rewarded: 0
  };
  static bool showSuicideInterstitial = true;
  static RewardItem? reward;

  static init() async {
    if (isSupportAdMob) {
      MobileAds.instance.initialize();
      _getInterstitial(AdPlace.Interstitial);
      _getInterstitial(AdPlace.InterstitialVideo);
      _getRewarded();
    }

    /* if (isSupportUnity) {
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
            debugPrint("Ads ==> state: $state, $data");
          });
    } 

    for (var id in AdPlace.values) {
      var ready = await UnityAds.isReady(placementId: id.name);
      if (ready ?? false) _placements[id] = AdState.Loaded;
    }*/
  }

  static BannerAd getBanner(String type, {AdSize? size}) {
    var place = AdPlace.Banner;
    var name = place.name + "_" + type;
    if (_ads.containsKey(name)) return _ads[name]! as BannerAd;
    var _listener = BannerAdListener(
        onAdLoaded: (ad) => _updateState(place, AdState.Loaded, ad),
        onAdFailedToLoad: (ad, error) {
          _updateState(place, AdState.FailedLoad, ad, error);
          ad.dispose();
        },
        onAdOpened: (ad) => _updateState(place, AdState.Clicked, ad),
        onAdClosed: (ad) => _updateState(place, AdState.Closed, ad),
        onAdImpression: (ad) => _updateState(place, AdState.Show, ad));
    _updateState(place, AdState.Request);
    return _ads[name] = BannerAd(
        size: size ?? AdSize.largeBanner,
        adUnitId: place.id,
        listener: _listener,
        request: _request)
      ..load();
  }

  static void _getInterstitial(AdPlace place) {
    InterstitialAd.load(
        adUnitId: place.id,
        request: _request,
        adLoadCallback:
            InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          _updateState(place, AdState.Loaded, ad);
          _ads[place.name] = ad;
          _attempts[place] = 0;
          ad.setImmersiveMode(true);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.FailedLoad, null, error);
          _attempts[place] = _attempts[place]! + 1;
          _ads.remove(place.name);
          if (_attempts[place]! <= maxFailedLoadAttempts)
            _getInterstitial(place);
        }));
  }

  static void _getRewarded() {
    var place = AdPlace.Rewarded;
    RewardedAd.load(
        adUnitId: place.id,
        request: _request,
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(onAdLoaded: (RewardedAd ad) {
          _ads[place.name] = ad;
          _attempts[place] = 0;
          _updateState(place, AdState.Loaded, ad);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.FailedLoad, null, error);
          _ads.remove(place.name);
          _attempts[place] = _attempts[place]! + 1;
          if (_attempts[place]! <= maxFailedLoadAttempts) _getRewarded();
        }));
  }

  static bool isReady([AdPlace? place]) {
    var _place = place ?? AdPlace.Rewarded;
    if (_place != AdPlace.Rewarded) {
      if (Pref.playCount.value < _place.threshold) return false;
      if (Pref.noAds.value > 0) return false;
    }
    return _placements.containsKey(_place) &&
        _placements[_place] == AdState.Loaded;
  }

  static showInterstitial(AdPlace place) async {
    if (Pref.noAds.value > 0) return;
    if (!_ads.containsKey(place.name)) {
      debugPrint("Ads ==> attempt to show ${place.name} before loaded.");
      return;
    }
    if (!isReady(place)) return;
    var _ad = _ads[place.name] as InterstitialAd;
    _ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          _updateState(place, AdState.Closed, ad);
          ad.dispose();
          _getInterstitial(place);
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          _updateState(place, AdState.FailedShow, ad, error);
          ad.dispose();
          _getInterstitial(place);
        },
        onAdImpression: (ad) => _updateState(place, AdState.Show, ad));
    _ad.show();
    _ads.remove(place.name);
    await _waitForClose(place);
  }

  static Future<RewardItem?> showRewarded() async {
    reward = null;
    var place = AdPlace.Rewarded;
    if (!_ads.containsKey(place.name)) {
      debugPrint("Ads ==> attempt to show ${place.name} before loaded.");
      return null;
    }
    var _ad = _ads[place.name] as RewardedAd;
    _ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          _updateState(place, AdState.Closed, ad);
          ad.dispose();
          _getRewarded();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          _updateState(place, AdState.FailedShow, ad, error);
          ad.dispose();
          _getRewarded();
        },
        onAdImpression: (ad) => _updateState(place, AdState.Show, ad));
    _ad.setImmersiveMode(true);
    _ad.show(onUserEarnedReward: (RewardedAd ad, RewardItem rewardItem) {
      reward = rewardItem;
      _updateState(place, AdState.RewardReceived, ad);
    });
    await _waitForClose(place);
    _ads.remove(place.name);
    if (reward != null) Quests.increase(QuestType.video, 1);
    return reward;
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
  } 

  static AdPlace _getPlacement(String id) {
    if (id.contains("Banner")) return AdPlace.Banner;
    if (id.contains("Interstitial")) return AdPlace.Interstitial;
    if (id.contains("InterstitialVideo")) return AdPlace.InterstitialVideo;
    return AdPlace.Rewarded;
  }*/

  static void _updateState(AdPlace place, AdState state,
      [Ad? ad, AdError? error]) {
    _placements[place] = state;
    onUpdate?.call(place, state);
    if (state.order > 0)
      Analytics.ad(state.order, place.type, place.name, "admob");
    debugPrint("Ads ==> $place ${state.toString()} ${error ?? ''}");
  }

  static _waitForClose(AdPlace adPlace) async {
    const d = Duration(milliseconds: 300);
    while (_placements[adPlace] != AdState.Closed) await Future.delayed(d);
  }

  static void pausedApp() {
    _placements.forEach((key, value) {
      if (key != AdPlace.Banner &&
          (value == AdState.Show || value == AdState.RewardReceived))
        _updateState(key, AdState.Clicked);
    });
  }
}

enum AdState {
  Closed,
  Clicked,
  Show,
  FailedShow,
  RewardReceived,
  Request,
  Loaded,
  FailedLoad
}

extension AdExt on AdState {
  int get order {
    if (this == AdState.FailedLoad) return -1;
    return index;
  }
}

enum AdPlace { Rewarded, Interstitial, InterstitialVideo, Banner }

extension AdPlaceExt on AdPlace {
  String get name {
    switch (this) {
      case AdPlace.Banner:
        return "Banner_${Ads.platform}";
      case AdPlace.Interstitial:
        return "Interstitial_${Ads.platform}";
      case AdPlace.InterstitialVideo:
        return "InterstitialVideo_${Ads.platform}";
      case AdPlace.Rewarded:
        return "Rewarded_${Ads.platform}";
    }
  }

  String get id {
    switch (this) {
      case AdPlace.Banner:
        return "${Ads.prefix}9761457956";
      case AdPlace.Interstitial:
        return "${Ads.prefix}6937186747";
      case AdPlace.InterstitialVideo:
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
        return GAAdType.OfferWall;
      case AdPlace.InterstitialVideo:
        return GAAdType.Interstitial;
      case AdPlace.Banner:
        return GAAdType.Banner;
    }
  }

  int get threshold {
    if (this == AdPlace.InterstitialVideo) return 3;
    if (this == AdPlace.Banner) return 5;
    return 0;
  }
}
