import 'package:fluent_ui/fluent_ui.dart';
import 'package:jtasks/database.dart';
import 'package:jtasks/main.dart';
import 'package:jtasks/utils.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../widgets/board_info_dialog.dart';
import 'board.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paneIndex = 0;

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
                        BoardInfo.newBoard(context);
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
                        BoardInfo.editBoard(context, board);
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
