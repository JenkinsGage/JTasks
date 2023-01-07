import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jtasks/main.dart';
import 'package:jtasks/models.dart';
import 'package:jtasks/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class BoardView extends StatefulWidget {
  final Board board;

  const BoardView({Key? key, required this.board}) : super(key: key);

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
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
          state: TaskStates.open);
      widget.board.tasks.add(newTask);
      obx.store.box<Board>().put(widget.board);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Column(
        children: [
          Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 16)),
              const Icon(FluentIcons.storyboard),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(widget.board.name!, style: const TextStyle(fontSize: 24)),
              )
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                  'Deadline: ${widget.board.expectedFinishedTime?.month}/${widget.board.expectedFinishedTime?.day}/${widget.board.expectedFinishedTime?.year}  ${widget.board.expectedFinishedTime!.compareTo(DateTime.now()) >= 0 ? 'Left Days' : 'Overdue Days'}: ${widget.board.expectedFinishedTime!.difference(DateTime.now()).inDays.abs()}'),
            ),
          ),
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
              if (widget.board.openedTime == null)
                CommandBarButton(
                  icon: const Icon(FluentIcons.accept),
                  label: const Text('Start'),
                  onPressed: () {
                    widget.board.state = BoardStates.open;
                    widget.board.openedTime = DateTime.now();
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskList(board: widget.board, taskState: TaskStates.open),
                TaskList(board: widget.board, taskState: TaskStates.progress),
                TaskList(board: widget.board, taskState: TaskStates.review),
                TaskList(board: widget.board, taskState: TaskStates.finished)
              ],
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
  final TaskStates taskState;

  const TaskList({Key? key, required this.board, required this.taskState}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  var tasks = <Task>[];

  @override
  void initState() {
    super.initState();
    tasks = widget.board.tasks.where((task) => task.state == widget.taskState).toList();
  }

  String getTaskStateString(TaskStates state) {
    switch (state) {
      case TaskStates.backlog:
        return 'Backlog';
      case TaskStates.open:
        return 'Open';
      case TaskStates.progress:
        return 'Progress';
      case TaskStates.review:
        return 'Review';
      case TaskStates.finished:
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
          ListTile(title: Text(getTaskStateString(widget.taskState), style: const TextStyle(fontSize: 16))),
          const Divider(
            style: DividerThemeData(thickness: 4),
          ),
          Flexible(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text('${task.name}'),
                  onPressed: () {},
                  trailing:
                      InfoBadge(source: Text(task.expectedDays.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), ''))),
                  subtitle: Text(
                      '${task.description?.substring(0, min(task.description!.length, 64))}${(task.description ?? '').length > 64 ? '...' : ''}'),
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
                            value: -1,
                            child: Text('Minor'),
                          ),
                          ComboBoxItem(
                            value: 0,
                            child: Text('Normal'),
                          ),
                          ComboBoxItem(
                            value: 1,
                            child: Text('Major'),
                          ),
                          ComboBoxItem(
                            value: 2,
                            child: Text('Critical'),
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
