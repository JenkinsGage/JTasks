import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

import 'utils.dart';

@Entity()
class Board {
  @Id()
  int id = 0;

  String? name;
  String? description;
  BoardState? state;

  int? get dbState {
    return state?.index;
  }

  set dbState(int? value) {
    if (value == null) {
      state = null;
    } else {
      state = BoardState.values[value];
    }
  }

  @Backlink('board')
  final tasks = ToMany<Task>();

  @Property(type: PropertyType.date)
  DateTime? createdTime;

  @Property(type: PropertyType.date)
  DateTime? closedTime;

  @Property(type: PropertyType.date)
  DateTime? startedTime;

  @Property(type: PropertyType.date)
  DateTime? expectedStartTime;

  @Property(type: PropertyType.date)
  DateTime? expectedFinishedTime;

  Board(
      {this.id = 0,
      required this.name,
      this.description,
      this.state = BoardState.open,
      required this.createdTime,
      this.closedTime,
      this.startedTime,
      required this.expectedStartTime,
      required this.expectedFinishedTime});

  double get totalTasksExpectedTime => tasks.fold(
      0, (previousValue, task) => previousValue + task.expectedDays!);

  double get totalFinishedTasksExpectedTime {
    double finishedTime = tasks.fold(0, (previousValue, task) {
      if (task.state == TaskState.review || task.state == TaskState.finished) {
        return previousValue + task.expectedDays!;
      }
      return previousValue;
    });
    return finishedTime;
  }

  double get totalUnfinishedTasksExpectedTime =>
      totalTasksExpectedTime - totalFinishedTasksExpectedTime;

  double get idealFinishedTime {
    return clampDouble(
        (todayEnd.difference(expectedStartTime!).inMinutes) *
            totalTasksExpectedTime /
            (expectedFinishedTime!.difference(expectedStartTime!).inMinutes),
        0,
        totalTasksExpectedTime);
  }

  double get dailyRequirementTime {
    if (state == BoardState.open && startedTime != null) {
      return max(idealFinishedTime - totalFinishedTasksExpectedTime, 0);
    }
    return 0;
  }

  String get dailyRequirementTimeFormatString => dailyRequirementTime
      .toStringAsFixed(1)
      .replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');

  Widget? get boardTodayStateWidget {
    // infoBadge that displays daily requirement, alarm and check
    late final Widget? infoBadge;
    if (state == BoardState.open) {
      if (startedTime != null) {
        infoBadge = dailyRequirementTime > 0
            ? InfoBadge(
                source: Text(dailyRequirementTimeFormatString),
                color: DateTime.now().isBefore(expectedFinishedTime!)
                    ? null
                    : Colors.yellow,
              )
            : Icon(FluentIcons.skype_check, color: Colors.green, size: 18);
      } else {
        infoBadge = DateTime.now().isBefore(expectedStartTime!)
            ? const Icon(FluentIcons.timer, size: 18)
            : const Icon(FluentIcons.event_date_missed12, size: 18);
      }
    } else {
      infoBadge = null;
    }
    return infoBadge;
  }
}

@Entity()
class Task {
  @Id()
  int id = 0;

  String? name;
  String? description;

  final board = ToOne<Board>();

  TaskState? state;

  int? get dbState {
    return state?.index;
  }

  set dbState(int? value) {
    if (value == null) {
      state = null;
    } else {
      state = TaskState.values[value];
    }
  }

  @Property(type: PropertyType.date)
  DateTime? createdTime;

  @Property(type: PropertyType.date)
  DateTime? closedTime;

  @Property(type: PropertyType.date)
  DateTime? startedTime;

  double? expectedDays;

  int? priority;

  Task(
      {this.id = 0,
      this.name,
      this.description,
      this.state,
      this.createdTime,
      this.closedTime,
      this.startedTime,
      this.expectedDays,
      this.priority});

  String get priorityAsString {
    Map<int, String> map = {
      -1: 'Minor',
      0: 'Normal',
      1: 'Major',
      2: 'Critical'
    };
    return map[priority!]!;
  }

  String get stateAsString {
    switch (state) {
      case TaskState.backlog:
        return 'Backlog';
      case TaskState.open:
        return 'Open';
      case TaskState.progress:
        return 'Progress';
      case TaskState.review:
        return 'Review';
      case TaskState.finished:
        return 'Finished';
      default:
        return '';
    }
  }
}

enum TaskState { backlog, open, progress, review, finished }

enum BoardState { archived, open, closed }
