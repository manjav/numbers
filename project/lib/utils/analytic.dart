import 'dart:async';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';

class Analytics {
  static late int variant = 1;
  static late AppsflyerSdk _appsflyerSdk;
  static late FirebaseAnalytics _firebaseAnalytics;

  static final _funnelConfigs = {
    "adinterstitial": [1],
    "adrewardedad": [1, 4, 10, 20, 30],
    "adbannerclick": [1, 5, 10, 20],
    "round_end": [1, 2, 4, 8],
    "big6": [1],
    "big7": [1],
    "big10": [1],
  };

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
    _firebaseAnalytics.setUserProperty(name: "build_type", value: type);

    GameAnalytics.configureAutoDetectAppVersion(true);
    GameAnalytics.initialize("ga_key".l(), "ga_secret".l());

    updateVariantIDs();
  }

  static Future<void> updateVariantIDs() async {
    var testVersion = Prefs.getString("testVersion");
    var version = "app_version".l();
    if (testVersion.isNotEmpty && testVersion != version) {
      return;
    }
    if (testVersion.isEmpty) {
      Prefs.setString("testVersion", version);
    }
    var testName = "source-sink";
    var variantId =
        await GameAnalytics.getRemoteConfigsValueAsString(testName, "1");
    variant = int.parse(variantId ?? "1");
    debugPrint("testVariantId ==> $variant");
    if (variant == 2) {
      Price.ad = 40; //50 //100
      Price.big = 5; //10 //20
      Price.cube = 5; //10 //20
      Price.piggy = 10; //20 //40
      Price.record = 5; //10 //20
      Price.tutorial = 200; //400
      Price.boost = 300; // 200 //100
      Price.revive = 300; //200 //100
    }

    _firebaseAnalytics.setUserProperty(name: "test_name", value: testName);
    _firebaseAnalytics.setUserProperty(name: "test_variant", value: variantId);
  }

  static Future<void> purchase(
      String currency,
      double amount,
      String itemId,
      String itemType,
      String receipt,
      PurchaseVerificationData verificationData) async {
    var signature = verificationData.source;
    var localVerificationData = verificationData.localVerificationData;

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

    if (Platform.isAndroid) {
      _appsflyerSdk.validateAndLogInAppAndroidPurchase("shop_base64".l(),
          signature, localVerificationData, amount.toString(), currency, null);
    } else {
      await _firebaseAnalytics.logPurchase(
          currency: currency,
          value: amount,
          transactionId: signature,
          coupon: receipt);
    }

    if (itemId == "no_ads") {
      _appsflyerSdk.logEvent("purchase_no_ads", data);
    }
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

  static funnle(String name) {
    var step = Prefs.increase(name, 1);

    // Unique events
    if (_funnelConfigs.containsKey(name)) {
      var values = _funnelConfigs[name];

      for (var value in values!) {
        if (value == step) {
          _funnle("${name}_$step");
          break;
        }
      }
      return;
    }
    _funnle(name, step);
  }

  static _funnle(String name, [int step = -1]) {
    // print("_funnle $name  value $value");
    design(name, parameters: {"step": step});
    _appsflyerSdk.logEvent(name, {"step": step});
  }

  static Future<void> design(String name,
      {Map<String, dynamic>? parameters}) async {
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);

    var data = {"eventId": name};
    if (parameters != null) {
      for (var k in parameters.keys) {
        data[k] = parameters[k].toString();
      }
    }
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
