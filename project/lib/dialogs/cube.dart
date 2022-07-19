import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/shop.dart';
import 'package:project/utils/ads.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:rive/rive.dart';

class CubeDialog extends AbstractDialog {
  static const waitingTime = 30000;
  static const showTime = 2500;
  static const autoAppearance = 3;

  static int earnedAt = 0;

  CubeDialog({Key? key})
      : super(
          DialogMode.cube,
          key: key,
          height: 300.d,
          showCloseButton: false,
          title: "cube_l".l(),
          padding: EdgeInsets.fromLTRB(16.d, 0, 16.d, 16.d),
        );
  @override
  createState() => _CubeDialogState();
}

class _CubeDialogState extends AbstractDialogState<CubeDialog> {
  @override
  void initState() {
    reward = Price.cube;
    Analytics.funnle("cube");
    Timer(const Duration(milliseconds: 600), () => Sound.play("win"));
    CubeDialog.earnedAt = DateTime.now().millisecondsSinceEpoch;
    super.initState();
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Stack(alignment: Alignment.topCenter, children: [
      SizedBox(
          width: 126.d,
          height: 126.d,
          child: const RiveAnimation.asset('anims/${Asset.prefix}character.riv',
              stateMachines: ["happyState"])),
      Positioned(
          top: 126.d,
          width: 260.d,
          child: Text("piggy_collect".l([(reward * Ads.rewardCoef).format()]),
              textAlign: TextAlign.center, style: theme.textTheme.caption)),
      buttonPayFactory(theme),
      buttonAdsFactory(theme)
    ]);
  }
}
