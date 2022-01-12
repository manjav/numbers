import 'package:flutter/cupertino.dart';
import 'package:numbers/utils/utils.dart';

import 'buttons.dart';

// ignore: must_be_immutable
class PunchButton extends StatefulWidget {
  final bool? isEnable;
  final Widget? content;
  final EdgeInsets? padding;
  final List<Color>? colors;
  final Function()? onTap;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final double? cornerRadius;
  final Widget? errorMessage;
  final int? punchGap;
  final int? punchSpeed;
  bool isPlaying = true;

  PunchButton(
      {Key? key,
      this.onTap,
      this.isEnable,
      this.content,
      this.padding,
      this.colors,
      this.left,
      this.top,
      this.right,
      this.bottom,
      this.width,
      this.height,
      this.errorMessage,
      this.punchGap,
      this.punchSpeed,
      this.cornerRadius})
      : super(key: key);
  @override
  _PunchButtonState createState() => _PunchButtonState();
}

class _PunchButtonState extends State<PunchButton>
    with TickerProviderStateMixin {
  AnimationController? animation;

  void initState() {
    super.initState();
    animation = AnimationController(
        vsync: this,
        upperBound: 4.d,
        duration: Duration(milliseconds: widget.punchSpeed ?? 70));
    animation!.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        animation!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        await Future.delayed(Duration(seconds: widget.punchGap ?? 2));
        animation?.forward();
      }
    });
    animation!.addListener(() {
      setState(() {});
    });

    if (widget.isEnable ?? true) animation!.forward();
  }

  @override
  Widget build(BuildContext context) {
    var v = widget.isPlaying ? animation!.value : 0;
    return Positioned(
        left: widget.left == null ? null : widget.left! - v,
        top: widget.top == null ? null : widget.top! - v,
        right: widget.right == null ? null : widget.right! - v,
        bottom: widget.bottom == null ? null : widget.bottom! - v,
        width: widget.width == null ? null : widget.width! + v * 2,
        height: widget.height == null ? null : widget.height! + v * 2,
        child: BumpedButton(
            colors: widget.colors,
            content: widget.content,
            cornerRadius: widget.cornerRadius,
            errorMessage: widget.errorMessage,
            isEnable: widget.isEnable,
            onTap: widget.onTap,
            padding: widget.padding));
  }

  @override
  void dispose() {
    animation!.dispose();
    super.dispose();
  }
}
