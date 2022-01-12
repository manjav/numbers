import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/coins.dart';
import 'package:numbers/widgets/punchbutton.dart';

class DailyDialog extends AbstractDialog {
  DailyDialog()
      : super(
          DialogMode.daily,
          title: "daily_l".l(),
        );
  @override
  _DailyDialogState createState() => _DailyDialogState();
}

class _DailyDialogState extends AbstractDialogState<DailyDialog> {
  @override
  Widget chromeFactory(ThemeData theme, double width) {
    var theme = Theme.of(context);
    Days.init();
    var hasChrome = widget.hasChrome ?? true;
    return Column(children: [
      Container(
          width: 344.d,
          height: 300.d,
          padding: widget.padding ?? EdgeInsets.all(8.d),
          decoration: hasChrome
              ? BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: theme.dialogTheme.backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(24.d)))
              : null,
          child: GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 3,
              crossAxisSpacing: 2.d,
              mainAxisSpacing: 1.d,
              childAspectRatio: 1,
              children: List.generate(
                  Days.list.length, (i) => _itemBuilder(theme, Days.list[i])))),
      SizedBox(height: 12.d),
      Text("daily_d".l(),
          style: Themes.style(Colors.white, 14.d), textAlign: TextAlign.center),
      TimeWidget("daily_t".l(), () => setState(() {}))
    ]);
  }

  Widget _itemBuilder(ThemeData theme, Day day) {
    return Container(
        height: 120.d,
        decoration: ButtonDecor(
            day.state == DayState.collectable
                ? TColors.blue.value
                : TColors.whiteFlat.value,
            12.d,
            true,
            false),
        child: Stack(alignment: Alignment.center,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Positioned(
                  top: 4.d,
                  right: 4.d,
                  left: 4.d,
                  height: 36.d,
                  child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(bottom: 3.d),
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          shape: BoxShape.rectangle,
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.d))),
                      child: Text(day.text, style: theme.textTheme.subtitle1))),
              _lineItem(theme, day)
            ]));
  }

  _lineItem(ThemeData theme, Day day) {
    if (day.state == DayState.collected)
      return Positioned(bottom: 20.d, child: SVG.show("accept", 40.d));
    var waiting = day.state == DayState.waiting;
    var content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("${day.reward}",
          style:
              waiting ? theme.textTheme.bodyText2 : theme.textTheme.subtitle1),
      SizedBox(width: 1.d),
      SVG.show("coin", waiting ? 19.d : 15.d),
    ]);
    if (waiting) return Positioned(bottom: 26.d, child: content);
    return PunchButton(
        content: content,
        padding: EdgeInsets.only(bottom: 4.d),
        width: 86.d,
        height: 44.d,
        bottom: 12.d,
        colors: TColors.orange.value,
        onTap: () => _collect(day));
  }

  _collect(Day day) {
    day.state = DayState.collected;
    Pref.dayCount.set(day.index + 1);
    Coins.change(day.reward, "daily", "${day.index}");
    setState(() {});
  }
}

class TimeWidget extends StatefulWidget {
  final String label;
  final Function callback;
  TimeWidget(this.label, this.callback);
  @override
  _TimeWidgetState createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  Timer? _timer;
  int remaining = 0;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    remaining = Days.remaining;
    if (remaining <= 0) {
      _timer = null;
      return SizedBox(height: 54.d);
    }

    if (_timer == null)
      _timer = Timer.periodic(const Duration(milliseconds: 999), _onTimerTick);

    return Column(children: [
      SizedBox(height: 12.d),
      Text(widget.label,
          style: Themes.style(Colors.white, 14.d), textAlign: TextAlign.center),
      Text(remaining.toTime(), style: theme.textTheme.headline5)
    ]);
  }

  void _onTimerTick(Timer timer) {
    if (remaining < 2000) {
      timer.cancel();
      _timer = null;
      widget.callback.call();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class Days {
  static const DAY_LEN = 86400000;
  static List<Day> list = [];

  static bool collectable = false;
  static int get remaining =>
      (Pref.dayFirst.value + (Pref.dayCount.value + 1) * DAY_LEN) -
      DateTime.now().millisecondsSinceEpoch;

  static init() {
    var dayFirst = Pref.dayFirst.value;
    var dayCount = Pref.dayCount.value;
    var millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    var diff = millisecondsSinceEpoch - (dayFirst + dayCount * DAY_LEN);
    if (diff > DAY_LEN * 2) {
      Pref.dayFirst.set(millisecondsSinceEpoch - DAY_LEN);
      Pref.dayCount.set(dayCount = 0);
    }
    collectable = (diff < DAY_LEN * 2 && diff > DAY_LEN) || dayCount == 0;
    list.clear();
    for (var i = 0; i < 90; i++) {
      list.add(Day(
          i,
          i < dayCount
              ? DayState.collected
              : (i == dayCount && collectable
                  ? DayState.collectable
                  : DayState.waiting)));
    }
  }
}

enum DayState { waiting, collectable, collected }

class Day {
  final int index;
  DayState state;
  Day(this.index, this.state);
  int get reward => 50 * (index + 1);
  String get text => "day_l".l([index + 1]);
}
