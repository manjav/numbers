import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';

class Components {
  static Widget scores(ThemeData theme, {Function()? onTap}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Hero(
        tag: "score",
        child: GestureDetector(
            onTap: onTap,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text("${Pref.record.value.format()}",
                    style:
                        theme.textTheme.headline5!.copyWith(letterSpacing: -1)),
                SizedBox(width: 3.d),
                SVG.show("record", 20.d),
                SizedBox(width: 4.d),
              ])
            ])));
  }

  static Widget stats(ThemeData theme, {Function()? onTap}) {
    if (Pref.tutorMode.value == 0) return SizedBox();
    return Hero(
        tag: "stats",
        child: SizedBox(
            width: 50.d,
            child: BumpedButton(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 10),
                content: GestureDetector(
                    onTap: onTap, child: SVG.show("profile", 48.d)))));
  }

  static Widget confetty(ConfettiController controller) {
    return ConfettiWidget(
        gravity: 0.5,
        maxBlastForce: 50,
        numberOfParticles: 20,
        emissionFrequency: 0.05,
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple
        ],
        createParticlePath: drawStar);
  }

  /// A custom Path to paint stars.
  static Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  static slider(ThemeData theme, int min, int value, int max, {Widget? icon}) {
    var label = "$value / $max";
    var hasIcon = icon != null;
    var round = Radius.circular(12.d);
    return Stack(alignment: Alignment.centerLeft, children: [
      Positioned(
          left: hasIcon ? 26.d : 0,
          right: 0,
          bottom: 6.d,
          top: 6.d,
          child: Container(
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topRight: round,
                      bottomRight: round,
                      bottomLeft: hasIcon ? Radius.zero : round,
                      topLeft: hasIcon ? Radius.zero : round),
                  child: LinearProgressIndicator(value: value / max)),
              decoration: badgeDecoration())),
      icon ?? SizedBox(),
      Positioned(
          left: hasIcon ? 32.d : 4.d,
          right: 4.d,
          child: Text(label,
              style: theme.textTheme.subtitle2, textAlign: TextAlign.center))
    ]);
  }

  static Decoration badgeDecoration({double? cornerRadius, Color? color}) {
    return BoxDecoration(
        boxShadow: [
          BoxShadow(
              blurRadius: 3.d, color: Colors.black, offset: Offset(0.5.d, 1.d))
        ],
        color: color ?? Colors.pink[700],
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(cornerRadius ?? 12.d)));
  }
}
