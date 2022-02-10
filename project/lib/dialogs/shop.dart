import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';

class Price {
  static int ad = 50;
  static int big = 10;
  static int cube = 10;
  static int piggy = 20;
  static int record = 10;
  static int tutorial = 100;

  static int boost = 200;
  static int revive = 200;
}

class ShopDialog extends AbstractDialog {
  const ShopDialog({Key? key})
      : super(
          DialogMode.shop,
          key: key,
        );
}
