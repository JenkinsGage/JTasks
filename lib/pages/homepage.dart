import 'package:fluent_ui/fluent_ui.dart';

import 'dashboard.dart';
import 'package:jtasks/utils.dart';

class HomePage extends StatefulWidget {
  final DataWrapper data;

  const HomePage({Key? key, required this.data}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int paneIndex = 0;

  String? selectedBoard;
  var boards = <String>['Koler Dev', 'JTasks Dev'];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(title: Text("JTasks", style: TextStyle(fontWeight: FontWeight.bold))),
      pane: NavigationPane(
          header: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AutoSuggestBox<String>(
              placeholder: 'Search',
              items: boards.map((e) => AutoSuggestBoxItem(value: e, label: e)).toList(),
              onSelected: (value) {
                setState(() {
                  selectedBoard = value.label;
                });
              },
            ),
          ),
          footerItems: [
            PaneItemHeader(
              header: Row(children: [
                Tooltip(
                  message: 'Settings',
                  child: IconButton(icon: const Icon(FluentIcons.settings), onPressed: () {}),
                ),
                Tooltip(
                  message: widget.data.themeMode == ThemeMode.light ? 'Dark Mode' : 'Light Mode',
                  child: IconButton(
                      icon: widget.data.themeMode == ThemeMode.light
                          ? const Icon(FluentIcons.clear_night)
                          : const Icon(FluentIcons.sunny),
                      onPressed: () {
                        widget.data.updateThemeMode(
                            widget.data.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
                      }),
                )
              ]),
            ),
            PaneItemSeparator()
          ],
          selected: paneIndex,
          onChanged: (value) {
            setState(() {
              paneIndex = value;
            });
          },
          displayMode: PaneDisplayMode.auto,
          items: [
            PaneItem(
                icon: const Icon(FluentIcons.view_dashboard), body: const Dashboard(), title: const Text('Dashboard')),
            PaneItemSeparator(),
            PaneItemExpander(
                icon: const Icon(FluentIcons.boards),
                title: const Text('Boards'),
                items: <NavigationPaneItem>[
                      PaneItemHeader(
                          header: Row(
                        children: [
                          Expanded(child: Text('${boards.length} OPENING')),
                          IconButton(
                            icon: const Icon(FluentIcons.add_in),
                            onPressed: () {
                              setState(() {
                                boards.add('New Board');
                              });
                            },
                          )
                        ],
                      ))
                    ] +
                    boards.map((e) => buildPaneItem(e, 5)).toList() +
                    [
                      PaneItemHeader(header: Row(children: const [Text('0 CLOSED')]))
                    ],
                body: Container())
          ]),
    );
  }
}

PaneItem buildPaneItem(String title, int num) {
  return PaneItem(
      icon: const Icon(FluentIcons.storyboard),
      body: Container(),
      title: Text(title),
      infoBadge: InfoBadge(source: Text('$num')));
}
