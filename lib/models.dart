import 'package:objectbox/objectbox.dart';

@Entity()
class Board {
  @Id()
  int id = 0;

  String? name;
  String? description;
  BoardStates? state;

  int? get dbState {
    return state?.index;
  }

  set dbState(int? value) {
    if (value == null) {
      state = null;
    } else {
      state = BoardStates.values[value];
    }
  }

  @Backlink('board')
  final tasks = ToMany<Task>();

  @Property(type: PropertyType.date)
  DateTime? createdTime;

  @Property(type: PropertyType.date)
  DateTime? closedTime;

  @Property(type: PropertyType.date)
  DateTime? openedTime;

  @Property(type: PropertyType.date)
  DateTime? expectedStartTime;

  @Property(type: PropertyType.date)
  DateTime? expectedFinishedTime;

  Board(
      {this.id = 0,
      required this.name,
      this.description,
      this.state = BoardStates.open,
      required this.createdTime,
      this.closedTime,
      this.openedTime,
      required this.expectedStartTime,
      required this.expectedFinishedTime});
}

@Entity()
class Task {
  @Id()
  int id = 0;

  String? name;
  String? description;

  final board = ToOne<Board>();

  TaskStates? state;

  int? get dbState {
    return state?.index;
  }

  set dbState(int? value) {
    if (value == null) {
      state = null;
    } else {
      state = TaskStates.values[value];
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
}

enum TaskStates { backlog, open, progress, review, finished }

enum BoardStates { archived, open, closed }
