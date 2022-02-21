import 'dart:math';

import 'package:flutter/material.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';
import 'package:project/widgets/coins.dart';
import 'package:project/widgets/components.dart';
import 'package:project/widgets/punchbutton.dart';

class QuestsDialog extends AbstractDialog {
  QuestsDialog({Key? key})
      : super(
          DialogMode.quests,
          key: key,
          title: "quests_l".l(),
        );
  @override
  _QuestsDialogState createState() => _QuestsDialogState();
}

class _QuestsDialogState extends AbstractDialogState<QuestsDialog> {
  @override
  Widget chromeFactory(ThemeData theme, double width) {
    var theme = Theme.of(context);
    var list = Quests.list.values.toList();
    var hasChrome = widget.hasChrome ?? true;
    return Container(
        width: 340.d,
        height: 384.d,
        padding: widget.padding ?? EdgeInsets.all(8.d),
        decoration: hasChrome
            ? BoxDecoration(
                shape: BoxShape.rectangle,
                color: theme.dialogTheme.backgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(24.d)))
            : null,
        child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: Quests.list.length,
            itemBuilder: (c, i) => _itemBuilder(theme, list[i])));
  }

  Widget _itemBuilder(ThemeData theme, Quest quest) {
    return Container(
        height: 92.d,
        decoration: ButtonDecor(
            quest.isDone ? TColors.orange.value : TColors.whiteFlat.value,
            12.d,
            true,
            false),
        padding: EdgeInsets.fromLTRB(12.d, 4.d, 12.d, 4.d),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(left: 0, child: SVG.show(quest.type.icon, 54.d)),
          Positioned(
              top: quest.isDone ? 0 : 12.d,
              right: 44,
              left: 62,
              child: Text(quest.text, style: theme.textTheme.subtitle2)),
          quest.isDone
              ? PunchButton(
                  colors: TColors.green.value,
                  content: Text(
                    "collect_l".l(),
                    style: theme.textTheme.headline5,
                    textAlign: TextAlign.center,
                  ),
                  bottom: 12.d,
                  width: 132.d,
                  height: 44.d,
                  onTap: () => _collect(quest))
              : Positioned(
                  width: 132.d,
                  height: 32.d,
                  bottom: 12.d,
                  child: Components.slider(
                      theme, quest.min, quest.value, quest.max)),
          Positioned(
              right: 0,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SVG.show("coin", 32.d),
                    Text("x${quest.reward}", style: theme.textTheme.subtitle2)
                  ]))
        ]));
  }

  void _collect(Quest quest) {
    quest.levelUp();
    setState(() {});
  }
}

class Quests {
  static Function(Quest)? onQuestComplete;
  static Map<QuestType, Quest> list = {};

  static void init() {
    _addQuest(QuestType.merges);
    _addQuest(QuestType.removeone);
    _addQuest(QuestType.video);
    _addQuest(QuestType.ce11);
  }

  static bool get hasCompleted {
    var quests = list.values;
    for (var quest in quests) {
      if (quest.isDone) return true;
    }
    return false;
  }

  static void _addQuest(QuestType type) {
    list[type] = Quest(type, type.level, value: type.value);
  }

  static void increase(QuestType type, int value) {
    if (value == 0) return;
    var quest = list[type];
    var key = "q_${type.name}";
    var res = Prefs.getInt(key) + value;
    Prefs.setInt(key, res, true);
    quest!.value = res;
    if (!quest.notified && res >= quest.max) {
      quest.notified = true;
      onQuestComplete?.call(quest);
    }
  }
}

class Quest {
  int value = 0;
  int level;
  final QuestType type;
  bool notified = false;

  Quest(this.type, this.level, {this.value = 0}) {
    notified = isDone;
  }

  bool get isDone => value >= max;

  String get text => ("quest_" + type.name).l([max.toString()]);

  void levelUp() {
    Coins.change(reward, "quest", type.name);
    level++;
    Prefs.setInt("q_l_${type.name}", level, true);
    notified = false;
  }

  int get max {
    return _getCheckpoint(type, level + 1);
  }

  int get min {
    if (level == 0) return 0;
    return _getCheckpoint(type, level);
  }

  static int _getCheckpoint(QuestType type, int stage) {
    switch (type) {
      case QuestType.ce11:
        return pow(2, stage).toInt();
      case QuestType.merges:
        return pow(2, stage + 6).toInt();
      case QuestType.removeone:
        return pow(2, stage).toInt();
      case QuestType.video:
        return pow(2, stage).toInt();
    }
  }

  int get reward {
    switch (type) {
      case QuestType.ce11:
        return (level + 1) * 100;
      case QuestType.merges:
        return (level + 1) * 100;
      case QuestType.removeone:
        return pow(2, level).toInt() * 100;
      case QuestType.video:
        return (level + 1) * 50;
    }
  }
}

enum QuestType { ce11, merges, removeone, video }

extension QuestTypeExt on QuestType {
  String get name {
    switch (this) {
      case QuestType.ce11:
        return "ce11";
      case QuestType.merges:
        return "merges";
      case QuestType.removeone:
        return "removeone";
      case QuestType.video:
        return "video";
    }
  }

  String get icon {
    switch (this) {
      case QuestType.ce11:
        return "ce11";
      case QuestType.merges:
        return "merge";
      case QuestType.removeone:
        return "boostRemoveOne";
      case QuestType.video:
        return "tv";
    }
  }

  int get value => Prefs.getInt("q_$name");
  int get level => Prefs.getInt("q_l_$name");
}

/*
Complete All Quests
*/
