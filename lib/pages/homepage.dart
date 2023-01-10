import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:jtasks/database.dart';
import 'package:jtasks/main.dart';
import 'package:jtasks/utils.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'board.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paneIndex = 0;

  /// Show AddBoard Dialog and allow to create and save a new board
  void showAddBoardDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const NewBoardDialog(),
    );
    if (result != 'Cancel') {
      // Create the board from returned dialog values
      final newBoardDetails = result as List;
      final newBoard = Board(
          name: newBoardDetails[0],
          description: newBoardDetails[1],
          createdTime: DateTime.now(),
          expectedStartTime: newBoardDetails[2],
          expectedFinishedTime: newBoardDetails[3]);
      // Save the new board to db
      obx.store.box<Board>().put(newBoard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer<BoardsDataProvider>(
      builder: (context, boardsDataProvider, child) {
        // Construct the boards pane item list
        List<NavigationPaneItem> boardsPaneItems = <NavigationPaneItem>[
              PaneItemHeader(
                header: Row(
                  children: [
                    Expanded(child: Text('${boardsDataProvider.openingBoards.length} OPENING')),
                    IconButton(
                      icon: const Icon(FluentIcons.add_in),
                      onPressed: () {
                        showAddBoardDialog(context);
                      },
                    )
                  ],
                ),
              )
            ] +
            boardsDataProvider.openingBoards.map((e) => buildPaneBoardItem(e)).toList() +
            [
              PaneItemHeader(header: Row(children: [Text('${boardsDataProvider.closedBoards.length} CLOSED')]))
            ] +
            boardsDataProvider.closedBoards.map((e) => buildPaneBoardItem(e)).toList();
        //

        return NavigationView(
          appBar: NavigationAppBar(
              automaticallyImplyLeading: false,
              title: Text("JTasks |$version", style: const TextStyle(fontWeight: FontWeight.bold))),
          pane: NavigationPane(
              // Search Bar
              autoSuggestBox: AutoSuggestBox<int>(
                placeholder: 'Search',
                // TODO: Allow searching for everything including closed boards, task names, description...
                items: boardsDataProvider.openingBoards
                        .map((e) => AutoSuggestBoxItem(value: e.id, label: e.name!))
                        .toList() +
                    boardsDataProvider.closedBoards
                        .map((e) => AutoSuggestBoxItem(value: e.id, label: e.name!))
                        .toList(),
                // TODO: Switch board after select the searched item
                onSelected: (id) {},
              ),
              // Options of settings and switch theme mode
              footerItems: [
                PaneItemHeader(
                  header: Row(children: [
                    Tooltip(
                      message: 'Settings',
                      child: IconButton(icon: const Icon(FluentIcons.settings), onPressed: () {}),
                    ),
                    Tooltip(
                      message: themeProvider.themeMode == ThemeMode.light ? 'Dark Mode' : 'Light Mode',
                      child: IconButton(
                          icon: themeProvider.themeMode == ThemeMode.light
                              ? const Icon(FluentIcons.clear_night)
                              : const Icon(FluentIcons.sunny),
                          onPressed: () {
                            themeProvider.themeMode =
                                (themeProvider.themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
                          }),
                    )
                  ]),
                ),
                PaneItemSeparator()
              ],
              //
              selected: paneIndex,
              onChanged: (value) {
                setState(() {
                  paneIndex = value;
                });
              },
              displayMode: PaneDisplayMode.auto,
              items: [
                // Dashboard pane
                PaneItem(
                    icon: const Icon(FluentIcons.view_dashboard),
                    body: const Dashboard(),
                    title: const Text('Dashboard')),
                PaneItemSeparator(),
                // Boards pane
                PaneItemExpander(
                    icon: const Icon(FluentIcons.boards),
                    title: const Text('Boards'),
                    items: boardsPaneItems,
                    body: Container())
              ]),
        );
      },
    );
  }
}

/// Build pane item according to the board instance
PaneItem buildPaneBoardItem(Board board) {
  FlyoutController optionsController = FlyoutController();

  return PaneItem(
      icon: const Icon(FluentIcons.storyboard),
      body: BoardView(board: board),
      title: Text(board.name!),
      trailing: Flyout(
        controller: optionsController,
        content: (BuildContext context) {
          return FlyoutContent(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlyoutListTile(
                      text: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Allow user to edit the board info
                      },
                      icon: const Icon(FluentIcons.edit)),
                  if (board.state == BoardState.open)
                    FlyoutListTile(
                        text: const Text('Close'),
                        onPressed: () {
                          Navigator.pop(context);
                          board.state = BoardState.closed;
                          obx.store.box<Board>().put(board);
                        },
                        icon: const Icon(FluentIcons.save_and_close)),
                  FlyoutListTile(
                      text: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(context);
                        showDeleteConfirmDialog(
                            context: context,
                            onDelete: () {
                              // Delete board and the related tasks
                              board = obx.store.box<Board>().get(board.id)!;
                              obx.store.box<Task>().removeMany(board.tasks.map((element) => element.id).toList());
                              obx.store.box<Board>().remove(board.id);
                              //
                            });
                      },
                      icon: const Icon(FluentIcons.delete)),
                ],
              ));
        },
        child: IconButton(icon: const Icon(FluentIcons.more), onPressed: optionsController.open),
      ),
      // Trailing info badge shows the ideal time need to progress today
      infoBadge: board.boardTodayStateWidget);
}

class NewBoardDialog extends StatefulWidget {
  const NewBoardDialog({Key? key}) : super(key: key);

  @override
  State<NewBoardDialog> createState() => _NewBoardDialogState();
}

class _NewBoardDialogState extends State<NewBoardDialog> {
  var boardName = TextEditingController();
  var boardDesc = TextEditingController();
  bool infoBarVisible = false;
  String infoBarString = '';
  DateTime? expectedStartTime;
  DateTime? expectedFinishedTime;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('New Board'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (infoBarVisible)
            InfoBar(
              title: Text(infoBarString),
              severity: InfoBarSeverity.warning,
              onClose: () => setState(() {
                infoBarVisible = false;
              }),
            ),
          TextBox(
            controller: boardName,
            header: 'New Board Name',
            placeholder: 'Name',
          ),
          TextBox(
            controller: boardDesc,
            header: 'Description',
            placeholder: 'Desc',
            maxLines: null,
          ),
          const m.PopupMenuDivider(),
          DatePicker(
            selected: expectedStartTime,
            header: 'Expected Start Time',
            onChanged: (value) {
              setState(() {
                expectedStartTime = DateTime(value.year, value.month, value.day, 0, 0, 0);
              });
            },
          ),
          DatePicker(
            selected: expectedFinishedTime,
            header: 'Expected Finished Time',
            onChanged: (value) {
              setState(() {
                expectedFinishedTime = DateTime(value.year, value.month, value.day, 23, 59, 59);
              });
            },
          )
        ],
      ),
      actions: [
        Button(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            }),
        FilledButton(
            child: const Text('Add'),
            onPressed: () {
              bool boardValid = true;
              setState(() {
                if (expectedFinishedTime == null || expectedStartTime == null) {
                  infoBarString =
                      "You'd better plan your time well. Expected start and finished time are both required.";
                  infoBarVisible = true;
                  boardValid = false;
                } else if (expectedFinishedTime!.compareTo(expectedStartTime!) < 0) {
                  infoBarString = 'Expected finished time should not be earlier than start time';
                  infoBarVisible = true;
                  boardValid = false;
                }
                if (boardName.text.isEmpty) {
                  setState(() {
                    infoBarString = 'A valid board name is required.';
                    infoBarVisible = true;
                    boardValid = false;
                  });
                }
                if (boardValid) {
                  Navigator.pop(context, [boardName.text, boardDesc.text, expectedStartTime, expectedFinishedTime]);
                }
              });
            })
      ],
    );
  }
}
