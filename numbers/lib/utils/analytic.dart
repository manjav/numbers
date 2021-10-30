import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gameanalytics_sdk/gameanalytics.dart';
import 'dart:async';

class Analytics {
  static late FirebaseAnalytics _firebaseAnalytics;

  static AppsflyerSdk appsflyerSdk = AppsflyerSdk({
    "afDevKey": "YBThmUqaiHZYpiSwZ3GQz4",
    "afAppId": "game.block.puzzle.drop.the.number.merge",
    "isDebug": false
  });

  static void init(FirebaseAnalytics analytics) {
    _firebaseAnalytics = analytics;

    GameAnalytics.setEnabledInfoLog(false);
    GameAnalytics.setEnabledVerboseLog(false);

    GameAnalytics.configureAvailableCustomDimensions01(
        ["installed", "instant"]);
    // GameAnalytics.configureAvailableCustomDimensions02(["whale", "dolphin"]);
    // GameAnalytics.configureAvailableCustomDimensions03(["horde", "alliance"]);
    GameAnalytics.configureAvailableResourceCurrencies(["coin"]);
    GameAnalytics.configureAvailableResourceItemTypes(
        ["game", "confirm", "shop", "start"]);

    GameAnalytics.setCustomDimension01("instant");
    GameAnalytics.configureAutoDetectAppVersion(true);
    GameAnalytics.initialize("2c9380c96ef57f01f353906b341a21cc",
        "275843fe2b762882e938a16d6b095d7661670ee9");

    appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);
  }

  static Future<void> purchase(String currency, double amount, String itemId,
      String itemType, String receipt, String signature) async {
    // if (iOS) {
    //   await _firebaseAnalytics.logEcommercePurchase(
    //       currency: currency,
    //       value: amount,
    //       transactionId: signature,
    //       origin: itemId,
    //       coupon: receipt);
    // }

    GameAnalytics.addBusinessEvent({
      "currency": currency,
      "amount": (amount * 100),
      "itemType": itemType,
      "itemId": itemId,
      "cartType": "end_of_level",
      "receipt": receipt,
      "signature": signature,
    });
  }

  static Future<void> ad(int action, int type, String placementID,
      [String sdkName = "unityads"]) async {
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

    appsflyerSdk.logEvent("ads", map);
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
    if (round % 3 == 0) appsflyerSdk.logEvent("end_round", map);
  }

  static Future<void> design(String name,
      {Map<String, dynamic>? parameters}) async {
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);

    var value = parameters == null ? "" : parameters.values.first;
    GameAnalytics.addDesignEvent({"eventId": name, "value": value});
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
