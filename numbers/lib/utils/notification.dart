import 'package:flutter/material.dart';

class Notifier {
  static void init() async {}

  static Future<dynamic> onDidReceiveLocalNotification(
      int? id, String? title, String? body, String? payload) async {
    debugPrint("title $title body $body payload: $payload");
  }

  static Future<dynamic> onSelectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  }
}
