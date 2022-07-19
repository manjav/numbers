import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/dialogs/quests.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/sounds.dart';
import 'package:project/utils/utils.dart';

class QuestNotification extends StatefulWidget {
  final Quest quest;
  final double size;
  const QuestNotification(this.quest, this.size, {Key? key}) : super(key: key);
  @override
  createState() => _QuestNotificationyState();
}

class _QuestNotificationyState extends State<QuestNotification>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        upperBound: 48.d,
        duration: const Duration(milliseconds: 400));
    _controller!.addListener(() => setState(() {}));
    Future.delayed(_controller!.duration!, () {
      _controller!.animateTo(36.d, curve: Curves.easeInOutBack);
      Sound.play("bell");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return SizedBox(
        height: widget.size,
        child: Row(children: [
          SVG.show(widget.quest.type.icon, 54.d),
          SizedBox(width: 4.d),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("quest_passed".l(), style: theme.textTheme.bodyText2),
                Text(widget.quest.text, style: theme.textTheme.subtitle1),
              ])),
          Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              child: SizedBox(
                  width: _controller!.value,
                  height: _controller!.value,
                  child: SVG.show("accept", 32.d))),
        ]));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
