import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:numbers/dialogs/dialogs.dart';

class Rout {
  static dynamic push(BuildContext context, Widget page,
      {Color? barrierColor,
      Tween<Offset>? tween,
      bool barrierDismissible = false}) async {
    var popDuration = (page is AbstractDialog) ? (page.popDuration ?? 1) : 1;
    return await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        reverseTransitionDuration: Duration(milliseconds: popDuration),
        barrierColor:
            barrierColor ?? Theme.of(context).backgroundColor.withAlpha(230),
        barrierDismissible: barrierDismissible,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
                position: animation.drive(tween ??
                    Tween(begin: Offset(0.0, 0.08), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutExpo))),
                child: child),
        pageBuilder: (c, _, __) => page));
  }
}

extension IntExt on int {
  static final _formatter = NumberFormat('###,###,###');
  String format() {
    return _formatter.format(this);
  }

  String toTime() {
    var t = (this / 1000).round();
    var s = t % 60;
    t -= s;
    var m = ((t % 3600) / 60).round();
    t -= m * 60;
    var h = (t / 3600).floor();
    var ss = s < 10 ? "0$s" : "$s";
    var ms = m < 10 ? "0$m" : "$m";
    var hs = h < 10 ? "0$h" : "$h";
    return "$hs : $ms : $ss";
  }

  int min(int min) => this < min ? min : this;
  int max(int max) => this > max ? max : this;
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
