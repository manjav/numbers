import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class Rout {
  static dynamic push(BuildContext context, Widget page,
      {Color? barrierColor, bool barrierDismissible = false}) async {
    return await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        reverseTransitionDuration: Duration(milliseconds: 200),
        barrierColor:
            barrierColor ?? Theme.of(context).backgroundColor.withAlpha(230),
        barrierDismissible: barrierDismissible,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
                position: animation.drive(
                    Tween(begin: Offset(0.0, 0.08), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutExpo))),
                child: child),
        pageBuilder: (BuildContext context, _, __) => page));
  }
}

extension IntExt on int {
  static final _formatter = NumberFormat('###,###,###');
  String format() {
    return _formatter.format(this);
  }
}

class SVG {
  static SvgPicture show(String name, double size) {
    return SvgPicture.asset("assets/images/$name.svg", width: size);
  }

  static Text icon(String name, ThemeData theme, {double? scale}) {
    if (scale != null)
      return Text(name,
          style: theme.textTheme.overline!
              .copyWith(fontSize: theme.textTheme.overline!.fontSize! * scale));
    return Text(name, style: theme.textTheme.overline);
  }
}

extension Device on double {
  static double ratio = 1;
  static double aspectRatio = 1;
  static Size size = Size.zero;
  double get d => this * Device.ratio;
}

extension DeviceI on int {
  double get d => this * Device.ratio;
}
