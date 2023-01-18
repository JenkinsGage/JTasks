import 'package:fluent_ui/fluent_ui.dart';
import '../models.dart';
import 'package:jtasks/database.dart';

class BoardInfo extends StatefulWidget {
  final Board? board;

  const BoardInfo({Key? key, this.board}) : super(key: key);

  static void newBoard(BuildContext context) async {
    final newBoardResult = await showDialog(
      context: context,
      builder: (context) => const BoardInfo(),
    );
    if (newBoardResult != 'Cancel') {
      final newBoardInfo = newBoardResult as List;
      final newBoard = Board(
          name: newBoardInfo[0],
          description: newBoardInfo[1],
          createdTime: DateTime.now(),
          expectedStartTime: newBoardInfo[2],
          expectedFinishedTime: newBoardInfo[3]);
      obx.store.box<Board>().put(newBoard);
    }
  }

  static void editBoard(BuildContext context, Board board) async {
    final editBoardResult = await showDialog(
      context: context,
      builder: (context) => BoardInfo(board: board),
    );
    if (editBoardResult != 'Cancel') {
      final editedBoardInfo = editBoardResult as List;
      board.name = editedBoardInfo[0];
      board.description = editedBoardInfo[1];
      board.expectedStartTime = editedBoardInfo[2];
      board.expectedFinishedTime = editedBoardInfo[3];
      obx.store.box<Board>().put(board);
    }
  }

  @override
  State<BoardInfo> createState() => _BoardInfoState();
}

class _BoardInfoState extends State<BoardInfo> {
  final boardName = TextEditingController();
  final boardDesc = TextEditingController();
  bool infoBarVisible = false;
  String infoBarString = '';
  DateTime? expectedStartTime;
  DateTime? expectedFinishedTime;

  @override
  void initState() {
    super.initState();
    if (widget.board != null) {
      boardName.text = widget.board!.name ?? '';
      boardDesc.text = widget.board!.description ?? '';
    }
    expectedStartTime = widget.board?.expectedStartTime;
    expectedFinishedTime = widget.board?.expectedFinishedTime;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.board == null
          ? 'New Board'
          : 'Edit Board ${widget.board!.name}'),
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
            header: 'Board Name',
            placeholder: 'Name',
          ),
          TextBox(
            controller: boardDesc,
            header: 'Description',
            placeholder: 'Desc',
            maxLines: null,
          ),
          const Divider(),
          DatePicker(
            selected: expectedStartTime,
            header: 'Expected Start Time',
            onChanged: (value) {
              setState(() {
                expectedStartTime =
                    DateTime(value.year, value.month, value.day);
              });
            },
          ),
          DatePicker(
            selected: expectedFinishedTime,
            header: 'Expected Finished Time',
            onChanged: (value) {
              setState(() {
                expectedFinishedTime =
                    DateTime(value.year, value.month, value.day, 23, 59, 59);
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
            child: Text(widget.board == null ? 'Add' : 'Done'),
            onPressed: () {
              bool boardValid = true;
              setState(() {
                if (expectedFinishedTime == null || expectedStartTime == null) {
                  infoBarString =
                      "You'd better plan your time well. Expected start and finished time are both required.";
                  infoBarVisible = true;
                  boardValid = false;
                } else if (expectedFinishedTime!.compareTo(expectedStartTime!) <
                    0) {
                  infoBarString =
                      'Expected finished time should not be earlier than start time';
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
                  Navigator.pop(context, [
                    boardName.text,
                    boardDesc.text,
                    expectedStartTime,
                    expectedFinishedTime
                  ]);
                }
              });
            })
      ],
    );
  }
}
