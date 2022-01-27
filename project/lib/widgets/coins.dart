import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';

class Coins extends StatefulWidget {
  static change(int value,
      [String? itemType,
      String? itemId,
      double? targetX,
      double? targetY]) async {
    if (value == 0) return;
    if (value > 0) {
      await effect(value, x: targetX, y: targetY);
    } else {
      Pref.coin.increase(value);
    }
  }

  static effect(int value, {double? x, double? y, int? duraion}) async {
    Coins._onStart.last.call(value, x, y, duraion);
    await Future.delayed(Duration(milliseconds: Coins.duration));
  }

  static final List<Function(int, double?, double?, int?)> _onStart = [];
  static int duration = 0;
  final String source;
  final Function? onTap;
  final bool clickable;
  final double? left;
  final double? top;
  final double? height;

  const Coins(this.source,
      {Key? key,
      this.onTap,
      this.clickable = false,
      this.left,
      this.top,
      this.height})
      : super(key: key);
  @override
  _CoinsState createState() => _CoinsState();
}

class _CoinsState extends State<Coins> with TickerProviderStateMixin {
  int _value = 0;
  late final _controller = AnimationController(vsync: this);
  late final _punchController = AnimationController(vsync: this);
  late var _x = _getAnimation(0, 0, 0.5, 0.8, Curves.easeInSine);
  late var _y = _getAnimation(0, 0, 0.5, 0.8, Curves.easeInExpo);
  late final _alpha = _getAnimation(0.0, 1.0, 0.05, 0.2, Curves.ease);
  late final _sizeIn = _getAnimation(0.0, 64.d, 0, 0.2, Curves.easeOutBack);
  late final _sizeOut = _getAnimation(74.d, 30.d, 0.6, 0.9, Curves.easeInSine);
  late final _opacity = _getAnimation(1, 0, 0.9, 1.0, Curves.ease);
  late final _padding = EdgeInsetsTween(
    begin: const EdgeInsets.only(left: 0),
    end: EdgeInsets.only(left: 66.d),
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.25, curve: Curves.easeOutBack)));

  static final _defaultTop = 32.d;
  static final _defaultLeft = 66.d;
  late final double _height = widget.height ?? 52.d;

  Animation<double> _getAnimation(double begin, double end,
      double intervalBegin, double intervalEnd, Curve curve) {
    return Tween<double>(begin: begin, end: end).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(intervalBegin, intervalEnd, curve: curve)));
  }

  @override
  void initState() {
    Coins._onStart.add(_onCoinStart);
    debugPrint("Coins initState ==> ${Coins._onStart.length}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Pref.tutorMode.value == 0) return const SizedBox();
    return AnimatedBuilder(builder: _buildAnimation, animation: _controller);
  }

  void _onCoinStart(int value, double? x, double? y, int? duration) {
    final d = duration ?? 1500;
    final w = Device.size.width;
    final h = Device.size.height;
    final l = (widget.left ?? _defaultLeft) + 26.d;
    final t = (widget.top ?? _defaultTop) + 4.d;
    _x = _getAnimation(w * 0.38, x ?? l, 0.5, 0.8, Curves.easeInSine);
    _y = _getAnimation(h * 0.5, y ?? t, 0.5, 0.8, Curves.easeInExpo);
    Coins.duration = (d * 0.8).round();
    _value = value;
    _controller.reset();
    _controller.animateTo(1, duration: Duration(milliseconds: d));
    Sound.play("coin");
    Timer(Duration(milliseconds: Coins.duration), () {
      if (x == null) {
        _punchController.value = 1;
        _punchController.animateTo(0,
            duration: Duration(milliseconds: d - Coins.duration));
        Pref.coin.increase(value);
      }
      Sound.play("coins");
    });
  }

  // This function is called each time the controller "ticks" a new frame.
  // When it runs, all of the animation's values will have been
  // updated to reflect the controller's current value.
  Widget _buildAnimation(BuildContext context, Widget? child) {
    var theme = Theme.of(context);
    var text = Pref.coin.value.format();

    return Stack(alignment: Alignment.center, children: [
      Positioned(
          top: widget.top ?? _defaultTop,
          left: widget.left ?? _defaultLeft,
          height: _height - _punchController.value * 8.d,
          child: Hero(
              tag: "coin",
              child: BumpedButton(
                  content: Row(children: [
                SVG.show("coin", 32.d),
                Expanded(
                    child: Text(text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyText2!.copyWith(
                            fontSize: text.length > 5 ? 17.d : 22.d))),
                widget.clickable
                    ? Text("+  ",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.button)
                    : const SizedBox()
              ])))),
      Positioned(
          left: _x.value - 30.d,
          top: _y.value + _sizeOut.value * 0.14,
          child: Opacity(
              opacity: _opacity.value,
              child: Padding(
                  padding: _padding.value,
                  child: Opacity(
                      opacity: _alpha.value,
                      child: Text("+$_value",
                          style: theme.textTheme.headline2!
                              .copyWith(fontSize: _sizeOut.value * 0.5)))))),
      Positioned(
          top: _y.value,
          left: _x.value - _sizeIn.value * 0.5,
          child: Opacity(
              opacity: _opacity.value,
              child: Container(
                  width: _sizeIn.value,
                  alignment: Alignment.center,
                  child: SizedBox(
                      height: _sizeOut.value, child: SVG.show("coin", 72.d)))))
    ]);
  }

  @override
  void dispose() {
    Coins._onStart.remove(_onCoinStart);
    debugPrint("Coins dispose ==> ${Coins._onStart.length}");
    _punchController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
