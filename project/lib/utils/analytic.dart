import 'dart:async';

class Analytics {
  // static late int variant = 1;
  static init() {}

  static void updateVariantIDs() async {}
  
  static Future<void> purchase(String currency, double amount, String itemId,
      String itemType, String receipt, String signature) async {}

  static Future<void> ad(
      int action, int type, String placementID, String sdkName) async {}

  static Future<void> resource(int type, String currency, int amount,
      String itemType, String itemId) async {}

  static void startProgress(String name, int round, String boost) {}

  static void endProgress(String name, int round, int score, int revives) {}

  static Future<void> design(String name,
      {Map<String, dynamic>? parameters}) async {}

  static Future<void> share(String contentType, String itemId) async {}

  static Future<void> setScreen(String screenName) async {}
}
