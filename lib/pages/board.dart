import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jtasks/database.dart';
import 'package:jtasks/models.dart';
import 'package:jtasks/objectbox.g.dart';
import 'package:jtasks/utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BoardView extends StatefulWidget {
  final Board board;

  const BoardView({Key? key, required this.board}) : super(key: key);

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  final listTitleGroup = AutoSizeGroup();

  /// Show Add Task Dialog and allows to add and save a new task
  void showAddTaskDialog(BuildContext context) async {
    final result = (await showDialog(context: context, builder: (context) => const NewTaskDialog()));
    if (result != 'Cancel') {
      final m = result as Map;
      final newTask = Task(
          name: m['name'],
          description: m['description'],
          expectedDays: m['expectedDays'],
          priority: m['priority'],
          createdTime: DateTime.now(),
          state: TaskState.open);
      // Modify the board the widget belongs, to add the new created task and save the board to box.
      // Instead of creating task and set its board target, to prevent the board related widgets stop to update.
      widget.board.tasks.add(newTask);
      obx.store.box<Board>().put(widget.board);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      // Header of board view that displays Board Name, Deadline, Daily Requirement, Progress
      header: Column(
        children: [
          Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 16)),
              const Icon(FluentIcons.storyboard),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(widget.board.name!, style: const TextStyle(fontSize: 24)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, right: 2),
                child: Text('Today', style: TextStyle(fontSize: 16)),
              ),
              if (widget.board.boardTodayStateWidget != null) widget.board.boardTodayStateWidget!
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text(
                      'Deadline: ${widget.board.expectedFinishedTime?.month}/${widget.board.expectedFinishedTime?.day}/${widget.board.expectedFinishedTime?.year}  ${widget.board.expectedFinishedTime!.compareTo(DateTime.now()) >= 0 ? 'Left Days' : 'Overdue Days'}: ${widget.board.expectedFinishedTime!.difference(todayEnd).inDays.abs()}'),
                ],
              ),
            ),
          ),
          // Display board progress bar if has tasks
          if (widget.board.totalTasksExpectedTime > 0)
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(FluentIcons.running, size: 18),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 1, right: 6),
                  child: Text('Progress:'),
                ),
                ProgressBar(
                  value: 100 * widget.board.totalFinishedTasksExpectedTime / widget.board.totalTasksExpectedTime,
                )
              ],
            ),
          //
          const Divider(),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          // Command bar that allows to add new task, analyse the board and more task related options
          CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
            compactBreakpointWidth: 768,
            primaryItems: [
              if (widget.board.startedTime == null)
                CommandBarButton(
                  icon: const Icon(FluentIcons.running),
                  label: const Text('Start'),
                  onPressed: () {
                    widget.board.startedTime = DateTime.now();
                    obx.store.box<Board>().put(widget.board);
                  },
                ),
              CommandBarButton(
                icon: const Icon(FluentIcons.add_notes),
                label: const Text('New Task'),
                onPressed: () {
                  showAddTaskDialog(context);
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.analytics_view),
                label: const Text('Analysis'),
                onPressed: () {},
              ),
            ],
            secondaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.edit),
                label: const Text('Edit'),
                onPressed: () {},
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.save_and_close),
                label: const Text('Close'),
                onPressed: () {},
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.archive),
                label: const Text('Archive'),
                onPressed: () {},
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.delete),
                label: const Text('Delete'),
                onPressed: () {
                  showDeleteConfirmDialog(
                    context: context,
                    onDelete: () {
                      Navigator.pop(context);
                      obx.store.box<Board>().remove(widget.board.id);
                    },
                    onCanceled: () => Navigator.pop(context),
                  );
                },
              ),
            ],
          ),

          // Task lists that filled the rest space
          Expanded(
            child: Provider.value(
              value: listTitleGroup,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskList(board: widget.board, taskState: TaskState.open),
                  TaskList(board: widget.board, taskState: TaskState.progress),
                  TaskList(board: widget.board, taskState: TaskState.review),
                  TaskList(board: widget.board, taskState: TaskState.finished)
                ],
              ),
            ),
          ),
          //
        ]),
      ),
    );
  }
}

class TaskList extends StatefulWidget {
  final Board board;
  final TaskState taskState;

  const TaskList({Key? key, required this.board, required this.taskState}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  var tasks = <Task>[];
  late final StreamSubscription<Query<Task>> taskQuerySubs;

  @override
  void initState() {
    super.initState();
    tasks = widget.board.tasks.where((task) => task.state == widget.taskState).toList();

    //Listen to the tasks update
    taskQuerySubs = obx.store
        .box<Task>()
        .query(Task_.board.equals(widget.board.id) & Task_.dbState.equals(widget.taskState.index))
        .watch()
        .listen((Query<Task> query) {
      setState(() {
        tasks = query.find();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    taskQuerySubs.cancel();
  }

  String getTaskStateString(TaskState state) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List Name
          ListTile(
              title: AutoSizeText(
            getTaskStateString(widget.taskState),
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            group: context.read<AutoSizeGroup>(),
          )),

          DragTarget<Task>(
            builder: (context, candidateData, rejectedData) {
              return const Divider(
                style: DividerThemeData(thickness: 4),
              );
            },
            onAccept: (Task data) {
              // Set the dragging task to corresponding state and save after dropped
              data.state = widget.taskState;
              if (widget.taskState == TaskState.progress) {
                data.startedTime = DateTime.now();
              } else if (widget.taskState == TaskState.finished) {
                data.startedTime ??= DateTime.now();
                data.closedTime = DateTime.now();
              }
              obx.store.box<Task>().put(data);
            },
            onWillAccept: (Task? data) {
              if (data != null && data.state != widget.taskState) {
                return true;
              }
              return false;
            },
          ),
          Flexible(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Draggable<Task>(
                  data: task,
                  feedback: SizedBox(
                    // height: 50,
                      width: 200,
                      child: ListTile(
                          tileColor: ButtonState.resolveWith(
                              (states) => FluentTheme.of(context).resources.subtleFillColorSecondary),
                          title: Text('${task.name}'))),
                  childWhenDragging: Transform.translate(
                    offset: const Offset(8, 0),
                    child: ListTile(
                      tileColor: ButtonState.resolveWith(
                          (states) => FluentTheme.of(context).resources.subtleFillColorTertiary),
                      title: Text('${task.name}'),
                      onPressed: () {},
                      trailing: InfoBadge(
                          source: Text(task.expectedDays.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), ''))),
                      subtitle: Text(
                          '${task.description?.substring(0, min(task.description!.length, 64))}${(task.description ?? '').length > 64 ? '...' : ''}'),
                    ),
                  ),
                  child: ListTile(
                    title: Text('${task.name}'),
                    onPressed: () {
                      Navigator.of(context).push(FluentPageRoute(
                        builder: (context) {
                          return TaskDetailPage(task: task);
                        },
                      ));
                    },
                    trailing: InfoBadge(
                        source: Text(task.expectedDays.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), ''))),
                    subtitle: Text(
                        '${task.description?.substring(0, min(task.description!.length, 64))}${(task.description ?? '').length > 64 ? '...' : ''}'),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({Key? key}) : super(key: key);

  @override
  State<NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog> {
  var taskName = TextEditingController();
  var taskDesc = TextEditingController();
  var expectedDaysController = TextEditingController();
  int priority = 0;
  var md = ScrollController();
  bool infoBarVisible = false;
  String infoBarString = '';

  bool showMarkdown = false;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
        title: const Text('New Task'),
        actions: [
          Button(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              }),
          FilledButton(
            child: const Text('Add'),
            onPressed: () {
              bool taskValid = true;
              setState(() {
                if (expectedDaysController.text.isEmpty) {
                  infoBarString = 'It is good to specify your expected days to finish the task';
                  infoBarVisible = true;
                  taskValid = false;
                }
                if (taskName.text.replaceAll(' ', '').isEmpty) {
                  infoBarString = 'A name must be specified.';
                  infoBarVisible = true;
                  taskValid = false;
                }
                if (taskValid) {
                  Navigator.pop(context, {
                    'name': taskName.text,
                    'description': taskDesc.text,
                    'expectedDays': double.parse(expectedDaysController.text),
                    'priority': priority
                  });
                }
              });
            },
          )
        ],
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (infoBarVisible)
            InfoBar(
                title: Text(infoBarString),
                severity: InfoBarSeverity.warning,
                onClose: () => setState(() {
                      infoBarVisible = false;
                    })),
          TextBox(
            controller: taskName,
            header: 'New Task Name',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              children: [
                const Text('Description'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                        message: 'Switch View Mode',
                        child: IconButton(
                            icon: const Icon(FluentIcons.switch_widget),
                            onPressed: () => setState(() {
                                  showMarkdown = !showMarkdown;
                                }))),
                    Tooltip(
                        message: 'Make Selection Bold',
                        child: IconButton(
                            icon: const Icon(FluentIcons.bold),
                            onPressed: () => setState(() {
                                  replaceTextSelectionWith(taskDesc, (selection) => '**$selection**',
                                      optionalOffset: 2);
                                }))),
                    Tooltip(
                        message: 'Make Selection Italic',
                        child: IconButton(
                            icon: const Icon(FluentIcons.italic),
                            onPressed: () =>
                                replaceTextSelectionWith(taskDesc, (selection) => '*$selection*', optionalOffset: 1))),
                    Tooltip(
                        message: 'Insert a Link',
                        child: IconButton(
                            icon: const Icon(FluentIcons.link),
                            onPressed: () {
                              replaceTextSelectionWith(taskDesc, (selection) => '[Link](https://$selection)',
                                  optionalOffset: 15);
                            })),
                    Tooltip(
                        message: 'Insert an Image',
                        child: IconButton(
                            icon: const Icon(FluentIcons.image_pixel),
                            onPressed: () async {
                              final b64 = await getImageBase64FromPasteboard();
                              if (b64 != null) {
                                replaceTextSelectionWith(taskDesc, (selection) => '![img](data:image/png;base64,$b64)');
                              }
                            })),
                    Tooltip(
                        message: 'Insert a Code Block',
                        child: IconButton(
                            icon: const Icon(FluentIcons.code),
                            onPressed: () => replaceTextSelectionWith(taskDesc, (selection) => '```\n$selection\n```',
                                optionalOffset: 4))),
                    Tooltip(
                        message: 'Prompt The Selection To Header',
                        child: IconButton(
                            icon: const Text('H'),
                            onPressed: () =>
                                replaceTextSelectionWith(taskDesc, (selection) => '# $selection', optionalOffset: 2))),
                  ],
                ),
              ],
            ),
          ),
          if (!showMarkdown)
            Flexible(
              child: TextBox(
                controller: taskDesc,
                minLines: 8,
                maxLines: null,
              ),
            ),
          if (showMarkdown)
            Flexible(
              child: Markdown(
                controller: md,
                shrinkWrap: true,
                selectable: true,
                data: taskDesc.text,
                onTapLink: (text, href, title) {
                  launchUrl(Uri.parse(href ?? ''));
                },
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextBox(
                  header: 'Expected Days',
                  controller: expectedDaysController,
                  placeholder: 'i.e 2 or 3.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  suffix: const Text('Days'),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(alignment: Alignment.topLeft, child: Text('Priority')),
                    const Padding(padding: EdgeInsets.only(bottom: 2)),
                    ComboBox<int>(
                        isExpanded: true,
                        value: priority,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              priority = value;
                            });
                          }
                        },
                        items: const [
                          ComboBoxItem(
                            value: 2,
                            child: Text('Critical'),
                          ),
                          ComboBoxItem(
                            value: 1,
                            child: Text('Major'),
                          ),
                          ComboBoxItem(
                            value: 0,
                            child: Text('Normal'),
                          ),
                          ComboBoxItem(
                            value: -1,
                            child: Text('Minor'),
                          )
                        ]),
                  ],
                ),
              ),
            ],
          )
        ]));
  }
}

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  Widget build(BuildContext context) {
    return NavigationView(
        content: Column(
          children: [
            ListTile(
              title: Text(
                  '${widget.task.name} [${widget.task.stateAsString}] [${widget.task.priorityAsString}] [Ideal ${widget.task.expectedDays} Days]',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Created Time: ${widget.task.createdTime.toString().substring(0, 16)}'),
                  if (widget.task.startedTime != null)
                    Text(
                        'Started Time: ${widget.task.startedTime.toString().substring(0, 16)} | Time Since Started: ${(DateTime.now().difference(widget.task.startedTime!).inMinutes / 1440).toStringAsFixed(2)} Days')
                  else
                    const Text('Not Started Yet'),
                  if (widget.task.closedTime != null)
                    Text(
                        'Finished At ${widget.task.closedTime.toString().substring(0, 16)} | Actual Working Time: ${(widget.task.closedTime!.difference(widget.task.startedTime!).inMinutes / 1440).toStringAsFixed(2)} Days')
                ],
              ),
              leading: const Icon(FluentIcons.task_manager),
            ),
            const Divider(),
            const ListTile(
              title: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: Icon(FluentIcons.text_document),
            ),
            Flexible(child: Markdown(data: widget.task.description ?? '', selectable: true)),
          ],
        ),
        appBar: NavigationAppBar(
            title: Text("Task ${widget.task.name}", style: const TextStyle(fontWeight: FontWeight.bold))));
  }
}
