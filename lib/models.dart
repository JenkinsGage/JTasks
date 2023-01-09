import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

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

  double get totalTasksExpectedTime => tasks.fold(0, (previousValue, task) => previousValue + task.expectedDays!);

  double get totalFinishedTasksExpectedTime {
    double finishedTime = tasks.fold(0, (previousValue, task) {
      if (task.state == TaskState.review || task.state == TaskState.finished) {
        return previousValue + task.expectedDays!;
      }
      return previousValue;
    });
    return finishedTime;
  }

  double get totalUnfinishedTasksExpectedTime => totalTasksExpectedTime - totalFinishedTasksExpectedTime;

  double get idealFinishedTime {
    return clampDouble(
        (DateTime.now().difference(expectedStartTime!).inHours / 24.0) *
            totalTasksExpectedTime /
            (expectedFinishedTime!.difference(expectedStartTime!).inHours / 24.0),
        0,
        totalTasksExpectedTime);
  }

  double get dailyRequirementTime {
    if (state == BoardState.open && startedTime != null) {
      if (DateTime.now().compareTo(expectedFinishedTime!) <= 0) {
        return max(idealFinishedTime - totalFinishedTasksExpectedTime, 0);
      }
    }
    return 0;
  }

  String get dailyRequirementTimeFormatString =>
      dailyRequirementTime.toStringAsFixed(1).replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');
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

  Task({this.id = 0,
    this.name,
    this.description,
    this.state,
    this.createdTime,
    this.closedTime,
    this.startedTime,
    this.expectedDays,
    this.priority});
}

enum TaskState { backlog, open, progress, review, finished }

enum BoardState { archived, open, closed }
