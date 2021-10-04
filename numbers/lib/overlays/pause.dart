import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

import 'all.dart';

class PauseOverlay extends StatefulWidget {
  PauseOverlay({Key? key}) : super(key: key);
  @override
  _PauseOverlayState createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Overlays.basic(context, "pause",
        height: 180.d,
        title: "Pause",
        hasClose: false,
        hasChrome: false,
        padding: EdgeInsets.only(top: 10.d),
        content: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
                height: 76.d,
                width: 146.d,
                top: 0,
                left: 0,
                child: BumpedButton(
                    onTap: () => Navigator.of(context).pop("reset"),
                    colors: TColors.green.value,
                    cornerRadius: 16.d,
                    content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SVG.icon("5", theme),
                          Text("Restart", style: theme.textTheme.headline5)
                        ]))),
            Positioned(
                height: 76.d,
                width: 146.d,
                top: 0,
                right: 0,
                child: BumpedButton(
                    onTap: () => Navigator.of(context).pop("resume"),
                    colors: TColors.blue.value,
                    cornerRadius: 16.d,
                    content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SVG.icon("4", theme),
                          Text("Continue", style: theme.textTheme.headline5)
                        ]))),
            Positioned(
                height: 76.d,
                width: 76.d,
                top: 90.d,
                left: 66.d,
                child: BumpedButton(
                    onTap: () {
                      Pref.isVibrateOff
                          .set(Pref.isVibrateOff.value == 0 ? 1 : 0);
                      setState(() {});
                    },
                    colors: TColors.orange.value,
                    cornerRadius: 16.d,
                    content: Center(
                        child: SVG.icon("${Pref.isVibrateOff.value + 6}", theme,
                            scale: 1.2)))),
            Positioned(
                height: 76.d,
                width: 76.d,
                top: 90.d,
                right: 66.d,
                child: BumpedButton(
                    onTap: () {
                      Pref.isMute.set(Pref.isMute.value == 0 ? 1 : 0);
                      setState(() {});
                    },
                    colors: TColors.yellow.value,
                    cornerRadius: 16.d,
                    content: Center(
                        child: SVG.icon("${Pref.isMute.value + 1}", theme,
                            scale: 1.2)))),
          ],
        ));
  }
}
