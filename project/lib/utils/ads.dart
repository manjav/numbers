import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project/dialogs/quests.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class Ads {
  static final Map<AdPlace, MyAd> _placements = {
    AdPlace.banner: MyAd(AdPlace.banner),
    AdPlace.interstitial: MyAd(AdPlace.interstitial),
    AdPlace.interstitialVideo: MyAd(AdPlace.interstitialVideo),
    AdPlace.rewarded: MyAd(AdPlace.rewarded)
  };

  static Function(MyAd)? onUpdate;
  static String platform = Platform.isAndroid ? "Android" : "iOS";
  static const rewardCoef = 10;
  static const costCoef = 10;
  static const prefix = "ca-app-pub-5018637481206902/";
  static const maxFailedLoadAttempts = 3;
  static const AdSDK _initialSDK = AdSDK.google;
  static const AdRequest _request = AdRequest(nonPersonalizedAds: false);
  static AdSDK? selectedSDK;
  static bool showSuicideInterstitial = true;
  static RewardItem? reward;

  static init([AdSDK? sdk]) {
    selectedSDK = sdk ?? _initialSDK;
    for (var placement in _placements.values) {
      placement.sdk = selectedSDK!;
    }

    if (selectedSDK == AdSDK.google) {
      MobileAds.instance.initialize();
      _getInterstitial(AdPlace.interstitialVideo);
      _getInterstitial(AdPlace.interstitial);
      _getRewarded();
    } else if (selectedSDK == AdSDK.unity) {
      UnityAds.init(
        gameId: "4230791",
        onComplete: () {
          _getInterstitial(AdPlace.interstitialVideo);
          _getInterstitial(AdPlace.interstitial);
          _getRewarded();
        },
        onFailed: (error, message) =>
            debugPrint('UnityAds Initialization Failed: $error $message'),
      );
    }
  }

  static BannerAd _getBanner(String type, String origin, {AdSize? size}) {
    var place = AdPlace.banner;

    if (_placements[place]!.containsAd(type)) {
      return _placements[place]!.getAd(type) as BannerAd;
    }

    var _listener = BannerAdListener(
        onAdLoaded: (ad) => _updateState(place, AdState.loaded, ad),
        onAdFailedToLoad: (ad, error) {
          _updateState(place, AdState.failedLoad, ad, error.toString());
          ad.dispose();
        },
        onAdOpened: (ad) {
          Analytics.funnle("adbannerclick", origin);
          _updateState(place, AdState.clicked, ad);
        },
        onAdClosed: (ad) => _updateState(place, AdState.closed, ad),
        onAdImpression: (ad) => _updateState(place, AdState.show, ad));
    _updateState(place, AdState.request);
    return _placements[place]!.addAd(
        BannerAd(
            size: size ?? AdSize.largeBanner,
            adUnitId: place.id,
            listener: _listener,
            request: _request)
          ..load(),
        type) as BannerAd;
  }

  static Widget getBannerWidget(String type, String origin, {AdSize? size}) {
    var width = 320.d;
    var height = 50.d;
    Widget? adWidget;
    if (Ads.selectedSDK == AdSDK.unity) {
      var unityBanner = UnityBannerAd(placementId: AdPlace.banner.name);
      width = unityBanner.size.width.toDouble();
      height = unityBanner.size.height.toDouble();
      adWidget = unityBanner;
    } else {
      var banner = _getBanner(type, origin, size: size);
      width = banner.size.width.toDouble();
      height = banner.size.height.toDouble();
      adWidget = AdWidget(ad: banner);
    }

    return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16.d)),
            child: adWidget));
  }

  static void _getInterstitial(AdPlace place) {
    var myAd = _placements[place]!;

    if (myAd.sdk == AdSDK.unity) {
      _getUnityAd(place);
      return;
    }

    InterstitialAd.load(
        adUnitId: place.id,
        request: _request,
        adLoadCallback:
            InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          _updateState(place, AdState.loaded, ad);
          myAd.addAd(ad);
          ad.setImmersiveMode(true);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.failedLoad, null, error.toString());
          myAd.clearAd();
          myAd.attempts++;
          if (myAd.attempts <= maxFailedLoadAttempts) {
            _getInterstitial(place);
          }
        }));
  }

  static void _getRewarded() {
    var place = AdPlace.rewarded;
    var myAd = _placements[place]!;

    if (myAd.sdk == AdSDK.unity) {
      _getUnityAd(place);
      return;
    }

    RewardedAd.load(
        adUnitId: place.id,
        request: _request,
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(onAdLoaded: (RewardedAd ad) {
          myAd.addAd(ad);
          _updateState(place, AdState.loaded, ad);
        }, onAdFailedToLoad: (LoadAdError error) {
          _updateState(place, AdState.failedLoad, null, error.toString());
          myAd.clearAd();
          myAd.attempts++;
          if (myAd.attempts <= maxFailedLoadAttempts) {
            _getRewarded();
          } else if (_initialSDK == AdSDK.google) {
            init(AdSDK.unity); // Alternative AD SDK
          }
        }));
  }

  static bool isReady([AdPlace? place]) {
    var p = place ?? AdPlace.rewarded;
    if (p != AdPlace.rewarded) {
      if (Pref.playCount.value < p.threshold) return false;
      if (Pref.noAds.value > 0) return false;
    }
    return _placements[p]!.containsAd() &&
        _placements[p]!.state == AdState.loaded;
  }

  static showInterstitial(AdPlace place, String origin) async {
    if (Pref.noAds.value > 0) return;
    if (!isReady(place)) {
      debugPrint("Ads ==> ${place.name} is not ready.");
      return;
    }
    var myAd = _placements[place]!;

    if (selectedSDK == AdSDK.unity) {
      return await _showUnityAd(place);
    }

    var iAd = myAd.getAd() as InterstitialAd;
    iAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          _updateState(place, AdState.closed, ad);
          ad.dispose();
          _getInterstitial(place);
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          _updateState(place, AdState.failedShow, ad, error.toString());
          ad.dispose();
          _getInterstitial(place);
        },
        onAdImpression: (ad) => _updateState(place, AdState.show, ad));
    iAd.show();
    myAd.clearAd();
    await _waitForClose(place);
    Analytics.funnle("adinterstitial", origin);
  }

  static Future<RewardItem?> showRewarded(String origin) async {
    reward = null;
    if (!isReady()) {
      debugPrint("Ads ==> ${AdPlace.rewarded.name} is not ready.");
      return null;
    }

    if (selectedSDK == AdSDK.unity) {
      return await _showUnityAd(AdPlace.rewarded);
    }

    var myAd = _placements[AdPlace.rewarded]!;
    var rAd = myAd.getAd() as RewardedAd;
    rAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          _updateState(myAd.type, AdState.closed, ad);
          ad.dispose();
          _getRewarded();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          _updateState(myAd.type, AdState.failedShow, ad, error.toString());
          ad.dispose();
          _getRewarded();
        },
        onAdImpression: (ad) => _updateState(myAd.type, AdState.show, ad));
    rAd.setImmersiveMode(true);
    rAd.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      reward = rewardItem;
      _updateState(myAd.type, AdState.rewardReceived, ad);
    });
    await _waitForClose(myAd.type);
    myAd.clearAd();
    if (reward != null) {
      Quests.increase(QuestType.video, 1);
      Analytics.funnle("adrewarded", origin);
    }
    return reward;
  }

  static void _getUnityAd(AdPlace place) {
    UnityAds.load(
        placementId: place.name,
        onComplete: (placementId) {
          _updateState(place, AdState.loaded, null);
        },
        onFailed: (placementId, error, message) {
          _updateState(place, AdState.failedLoad, null, error.toString());
        });
  }

  static Future<RewardItem?> _showUnityAd(AdPlace place) async {
    UnityAds.showVideoAd(
      placementId: place.name,
      onStart: (id) => _updateState(_getPlace(id), AdState.show),
      onClick: (id) => _updateState(_getPlace(id), AdState.clicked),
      onSkipped: (id) {
        reward = RewardItem(1, AdState.closed.name);
        _updateState(_getPlace(id), AdState.closed);
        _getUnityAd(place);
      },
      onComplete: (id) {
        reward = RewardItem(1, AdState.rewardReceived.name);
        _updateState(_getPlace(id), AdState.rewardReceived);
        _getUnityAd(place);
      },
      onFailed: (id, e, messaeg) =>
          _updateState(_getPlace(id), AdState.failedShow, null, messaeg),
    );

    var p = _placements[place]!;
    p.state = AdState.show;
    const d = Duration(milliseconds: 300);
    while (p.state != AdState.closed && p.state != AdState.loaded) {
      await Future.delayed(d);
    }
    return reward!.type == AdState.rewardReceived.name ? reward : null;
  }

  static AdPlace _getPlace(String id) {
    if (id.contains("Banner")) return AdPlace.banner;
    if (id.contains("Interstitial")) return AdPlace.interstitial;
    if (id.contains("InterstitialVideo")) return AdPlace.interstitialVideo;
    return AdPlace.rewarded;
  }

  static void _updateState(AdPlace place, AdState state,
      [Ad? ad, String? error]) {
    if (!(_placements[place]!.state == AdState.loaded &&
        state != AdState.show)) {
      _placements[place]!.state = state;
    }
    onUpdate?.call(_placements[place]!);
    if (state.order > 0) {
      Analytics.ad(
          state.order, place.type, place.name, _placements[place]!.sdk.name);
    }
    debugPrint(
        "Ads ==> ${_placements[place]!.sdk} $place $state ${error ?? ''}");
  }

  static _waitForClose(AdPlace adPlace) async {
    const d = Duration(milliseconds: 300);
    while (_placements[adPlace]!.state != AdState.closed) {
      await Future.delayed(d);
    }
  }

  static void pausedApp() {
    _placements.forEach((key, value) {
      if (key != AdPlace.banner &&
          (value.state == AdState.show ||
              value.state == AdState.rewardReceived)) {
        _updateState(key, AdState.clicked);
      }
    });
  }
}

class MyAd {
  final AdPlace type;
  final Map<String, Ad> _ads = {};

  int attempts = 0;
  AdSDK sdk = AdSDK.none;
  AdState state = AdState.closed;

  MyAd(this.type);
  Ad addAd(Ad ad, [String? type = ""]) {
    attempts = 0;
    return _ads["${sdk.name}_$type"] = ad;
  }

  void clearAd() {
    _ads.clear();
  }

  Ad getAd([String? type = ""]) {
    return _ads["${sdk.name}_$type"]!;
  }

  bool containsAd([String? type = ""]) {
    if (sdk == AdSDK.unity) return true;
    return _ads.containsKey("${sdk.name}_$type");
  }
}

enum AdSDK { none, google, unity }

extension AdSDKExt on AdSDK {
  String get name {
    switch (this) {
      case AdSDK.none:
        return "none";
      case AdSDK.google:
        return "google";
      case AdSDK.unity:
        return "unity";
    }
  }
}

enum AdState {
  closed,
  clicked, //Clicked = 1;
  show, // Show = 2;
  failedShow, //FailedShow = 3;
  rewardReceived, //RewardReceived = 4;
  request, //Request = 5;
  loaded, //Loaded = 6;
  failedLoad,
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
    if (this == AdPlace.banner) return 7;
    if (this == AdPlace.interstitialVideo) return 4;
    return 0;
  }
}
