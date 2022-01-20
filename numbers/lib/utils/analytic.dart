import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:numbers/dialogs/shop.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Analytics {
  static late int variant = 1;
  static late AppsflyerSdk _appsflyerSdk;
  static late FirebaseAnalytics _firebaseAnalytics;

  static init(FirebaseAnalytics analytics) {
    _firebaseAnalytics = analytics;

    _appsflyerSdk = AppsflyerSdk(
        {"afDevKey": "af_key".l(), "afAppId": "app_id".l(), "isDebug": false});
    _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);

    GameAnalytics.setEnabledInfoLog(false);
    GameAnalytics.setEnabledVerboseLog(false);

    GameAnalytics.configureAvailableCustomDimensions01(
        ["installed", "instant"]);
    GameAnalytics.configureAvailableResourceCurrencies(["coin"]);
    GameAnalytics.configureAvailableResourceItemTypes(
        ["game", "confirm", "shop", "start"]);

    var type = "instant";
    GameAnalytics.setCustomDimension01(type);
    _appsflyerSdk.logEvent("type_$type", {});
    _firebaseAnalytics.setUserProperty(name: "buildType", value: type);

    GameAnalytics.configureAutoDetectAppVersion(true);
    GameAnalytics.initialize("ga_key".l(), "ga_secret".l());

    updateVariantIDs();
  }

  static Future<void> updateVariantIDs() async {
    var packageInfo = await PackageInfo.fromPlatform();
    var testVersion = Prefs.getString("testVersion");
    if (testVersion.isNotEmpty && testVersion != packageInfo.buildNumber) {
      return;
    }
    if (testVersion.isEmpty) {
      Prefs.setString("testVersion", packageInfo.buildNumber);
    }
    var testVariantId =
        await GameAnalytics.getRemoteConfigsValueAsString("res-dayquest", "1");
    variant = int.parse(testVariantId ?? "1");
    debugPrint("testVariantId ==> $variant");
    Price.ad = variant == 2 ? 50 : 100;
    Price.cube = variant == 2 ? 10 : 20;
    Price.piggy = variant == 2 ? 20 : 30;
    Price.tutorial = variant == 2 ? 100 : 500;
    Price.boost = variant == 2 ? 300 : 100;
    Price.revive = variant == 2 ? 300 : 100;
  }

  static Future<void> purchase(String currency, int amount, String itemId,
      String itemType, String receipt, String signature) async {
    // if (iOS) {
    //   await _firebaseAnalytics.logEcommercePurchase(
    //       currency: currency,
    //       value: amount,
    //       transactionId: signature,
    //       origin: itemId,
    //       coupon: receipt);
    // }
    var data = {
      "currency": currency,
      "cartType": "shop",
      "amount": (amount * 100),
      "itemType": itemType,
      "itemId": itemId,
      "receipt": receipt,
      "signature": signature,
    };
    GameAnalytics.addBusinessEvent(data);
  }

  static Future<void> ad(
      int action, int type, String placementID, String sdkName) async {
    var map = <String, dynamic>{
      'adAction': getAdActionName(action),
      'adType': getAdTypeName(type),
      'adPlacement': placementID,
      'adSdkName': sdkName,
    };
    _firebaseAnalytics.logEvent(name: "ads", parameters: map);

    GameAnalytics.addAdEvent({
      "adAction": action,
      "adType": type,
      "adSdkName": sdkName,
      "adPlacement": placementID
    });

    _appsflyerSdk.logEvent("ads", map);
    _appsflyerSdk.logEvent("ad_$placementID", map);
  }

  static Future<void> resource(int type, String currency, int amount,
      String itemType, String itemId) async {
    _firebaseAnalytics
        .logEvent(name: "resource_change", parameters: <String, dynamic>{
      "flowType": getResourceType(type),
      "currency": currency, //"Gems",
      "amount": amount,
      "itemType": itemType, //"IAP",
      "itemId": itemId //"Coins400"
    });

    GameAnalytics.addResourceEvent({
      "flowType": type,
      "currency": currency, //"Gems",
      "amount": amount,
      "itemType": itemType, //"IAP",
      "itemId": itemId //"Coins400"
    });
  }

  static void startProgress(String name, int round, String boost) {
    GameAnalytics.addProgressionEvent({
      "progressionStatus": GAProgressionStatus.Start,
      "progression01": name,
      "progression02": "round $round",
      "boost": boost
    });
  }

  static void endProgress(String name, int round, int score, int revives) {
    var map = {
      "progressionStatus": GAProgressionStatus.Complete,
      "progression01": name,
      "progression02": "round $round",
      "score": score,
      "revives": revives
    };
    GameAnalytics.addProgressionEvent(map);
    if (round % 3 == 0) _appsflyerSdk.logEvent("end_round", map);
  }

  static Future<void> design(String name,
      {Map<String, dynamic>? parameters}) async {
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);

    var data = parameters == null
        ? {"eventId": name}
        : {"eventId": name, "value": parameters.values.first};
    GameAnalytics.addDesignEvent(data);
  }

  static Future<void> share(String contentType, String itemId) async {
    await _firebaseAnalytics.logShare(
        contentType: contentType, itemId: itemId, method: "");

    GameAnalytics.addDesignEvent({"eventId": "share:$contentType:$itemId"});
  }

  static Future<void> setScreen(String screenName) async {
    await _firebaseAnalytics.setCurrentScreen(screenName: screenName);

    GameAnalytics.addDesignEvent({"eventId": "screen:$screenName"});
  }

  // static Future<void> setUserId(String id) async {
  //   await _firebaseAnalytics.setUserId(id);
  //   GameAnalytics.configureUserId(id);
  // }

  // static Future<void> setUserProperty(String name, String value) async {
  //   await _firebaseAnalytics.setUserProperty(name: name, value: value);
  // }

  // static Future<void> tutorialBegin() async {
  //   await _firebaseAnalytics.logTutorialBegin();
  // }

  // static Future<void> tutorialComplete() async {
  //   await _firebaseAnalytics.logTutorialComplete();
  // }
  // Future<void> _testSetAnalyticsCollectionEnabled() async {
  //   await analytics.setAnalyticsCollectionEnabled(false);
  //   await analytics.setAnalyticsCollectionEnabled(true);
  //   setMessage('setAnalyticsCollectionEnabled succeeded');
  // }

  static String getAdActionName(int action) {
    switch (action) {
      case GAAdAction.Clicked:
        return "Clicked";
      case GAAdAction.Show:
        return "Show";
      case GAAdAction.FailedShow:
        return "FailedShow";
      case GAAdAction.RewardReceived:
        return "RewardReceived";
      case GAAdAction.Request:
        return "Request";
      default:
        return "Loaded";
    }
  }

  static String getAdTypeName(int type) {
    switch (type) {
      case GAAdType.Video:
        return "Video";
      case GAAdType.RewardedVideo:
        return "RewardedVideo";
      case GAAdType.Playable:
        return "Playable";
      case GAAdType.Interstitial:
        return "Interstitial";
      case GAAdType.OfferWall:
        return "OfferWall";
      default:
        return "Banner";
    }
  }

  static String getResourceType(int type) {
    switch (type) {
      case GAResourceFlowType.Sink:
        return "Sink";
      default:
        return "Source";
    }
  }
}
