import 'dart:async';
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
  static final Map<AdPlace, AdState> _placements = {};

  static Function(AdPlace, AdState)? onUpdate;
  static String platform = Platform.isAndroid ? "Android" : "iOS";
  static const rewardCoef = 10;
  static const isSupportAdMob = true;
  static const isSupportUnity = false;
  static const prefix = "ca-app-pub-5018637481206902/";
  static const maxFailedLoadAttempts = 3;
  static const AdRequest _request = AdRequest(nonPersonalizedAds: false);
  static final Map<String, Ad> _ads = {};
  static final Map<AdPlace, int> _attempts = {
    AdPlace.interstitial: 0,
    AdPlace.interstitialVideo: 0,
    AdPlace.rewarded: 0
  };
  static bool showSuicideInterstitial = true;
  static RewardItem? reward;

  static init() {
    if (isSupportAdMob) {
      MobileAds.instance.initialize();
      Timer(const Duration(seconds: 3), () {
        _getInterstitial(AdPlace.interstitialVideo);
        _getInterstitial(AdPlace.interstitial);
        _getRewarded();
      });
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
    var place = AdPlace.banner;
    var name = place.name + "_" + type;
    if (_ads.containsKey(name)) return _ads[name]! as BannerAd;
    var _listener = BannerAdListener(
        onAdLoaded: (ad) => _updateState(place, AdState.loaded, ad),
        onAdFailedToLoad: (ad, error) {
          _updateState(place, AdState.failedLoad, ad, error);
          ad.dispose();
        },
        onAdOpened: (ad) => _updateState(place, AdState.clicked, ad),
        onAdClosed: (ad) => _updateState(place, AdState.closed, ad),
        onAdImpression: (ad) => _updateState(place, AdState.show, ad));
    _updateState(place, AdState.request);
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
          _updateState(place, AdState.loaded, ad);
          _ads[place.name] = ad;
          _attempts[place] = 0;
          ad.setImmersiveMode(true);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.failedLoad, null, error);
          _attempts[place] = _attempts[place]! + 1;
          _ads.remove(place.name);
          if (_attempts[place]! <= maxFailedLoadAttempts) {
            _getInterstitial(place);
          }
        }));
  }

  static void _getRewarded() {
    var place = AdPlace.rewarded;
    RewardedAd.load(
        adUnitId: place.id,
        request: _request,
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(onAdLoaded: (RewardedAd ad) {
          _ads[place.name] = ad;
          _attempts[place] = 0;
          _updateState(place, AdState.loaded, ad);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.failedLoad, null, error);
          _ads.remove(place.name);
          _attempts[place] = _attempts[place]! + 1;
          if (_attempts[place]! <= maxFailedLoadAttempts) _getRewarded();
        }));
  }

  static bool isReady([AdPlace? place]) {
    var _place = place ?? AdPlace.rewarded;
    if (_place != AdPlace.rewarded) {
      if (Pref.playCount.value < _place.threshold) return false;
      if (Pref.noAds.value > 0) return false;
    }
    return _placements.containsKey(_place) &&
        _placements[_place] == AdState.loaded;
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
          _updateState(place, AdState.closed, ad);
          ad.dispose();
          _getInterstitial(place);
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          _updateState(place, AdState.failedShow, ad, error);
          ad.dispose();
          _getInterstitial(place);
        },
        onAdImpression: (ad) => _updateState(place, AdState.show, ad));
    _ad.show();
    _ads.remove(place.name);
    await _waitForClose(place);
  }

  static Future<RewardItem?> showRewarded() async {
    reward = null;
    var place = AdPlace.rewarded;
    if (!_ads.containsKey(place.name)) {
      debugPrint("Ads ==> attempt to show ${place.name} before loaded.");
      return null;
    }
    var _ad = _ads[place.name] as RewardedAd;
    _ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          _updateState(place, AdState.closed, ad);
          ad.dispose();
          _getRewarded();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          _updateState(place, AdState.failedShow, ad, error);
          ad.dispose();
          _getRewarded();
        },
        onAdImpression: (ad) => _updateState(place, AdState.show, ad));
    _ad.setImmersiveMode(true);
    _ad.show(onUserEarnedReward: (RewardedAd ad, RewardItem rewardItem) {
      reward = rewardItem;
      _updateState(place, AdState.rewardReceived, ad);
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
    if (state.order > 0) {
      Analytics.ad(state.order, place.type, place.name, "admob");
    }
    debugPrint("Ads ==> $place ${state.toString()} ${error ?? ''}");
  }

  static _waitForClose(AdPlace adPlace) async {
    const d = Duration(milliseconds: 300);
    while (_placements[adPlace] != AdState.closed) {
      await Future.delayed(d);
    }
  }

  static void pausedApp() {
    _placements.forEach((key, value) {
      if (key != AdPlace.banner &&
          (value == AdState.show || value == AdState.rewardReceived)) {
        _updateState(key, AdState.clicked);
      }
    });
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
  String get name {
    switch (this) {
      case AdPlace.banner:
        return "Banner_${Ads.platform}";
      case AdPlace.interstitial:
        return "Interstitial_${Ads.platform}";
      case AdPlace.interstitialVideo:
        return "InterstitialVideo_${Ads.platform}";
      case AdPlace.rewarded:
        return "Rewarded_${Ads.platform}";
    }
  }

  String get id {
    switch (this) {
      case AdPlace.banner:
        return "${Ads.prefix}9761457956";
      case AdPlace.interstitial:
        return "${Ads.prefix}6937186747";
      case AdPlace.interstitialVideo:
        return "${Ads.prefix}4317559580";
      case AdPlace.rewarded:
        return "${Ads.prefix}2812906224";
    }
  }

  int get type {
    switch (this) {
      case AdPlace.banner:
        return GAAdType.Banner;
      case AdPlace.interstitial:
        return GAAdType.OfferWall;
      case AdPlace.interstitialVideo:
        return GAAdType.Interstitial;
      case AdPlace.rewarded:
        return GAAdType.RewardedVideo;
    }
  }

  int get threshold {
    if (this == AdPlace.banner) return 5;
    if (this == AdPlace.interstitialVideo) return 3;
    return 0;
  }
}
