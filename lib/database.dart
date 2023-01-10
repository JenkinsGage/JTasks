import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'objectbox.g.dart';

/// objectBox is the entry of database that contains a store property which stored the boxes of all the models.
/// It is initialized in main function before runApp()
late ObjectBox obx;

/// ObjectBox wrapper that holds the store of boxes and provides a create method and useful queries
class ObjectBox {
  /// The Store of this app.
  late final Store store;

  late final Query<Board> openingBoardsQuery;
  late final Query<Board> closedBoardsQuery;

  late final Stream<Query<Board>> openingBoardsStream;
  late final Stream<Query<Board>> closedBoardsStream;
  late final Stream<Query<Task>> taskStream;

  ObjectBox._create(this.store) {
    openingBoardsQuery = store.box<Board>().query(Board_.dbState.equals(1)).build();
    closedBoardsQuery = store.box<Board>().query(Board_.dbState.equals(2)).build();
    openingBoardsStream = store.box<Board>().query(Board_.dbState.equals(1)).watch();
    closedBoardsStream = store.box<Board>().query(Board_.dbState.equals(2)).watch();
    taskStream = store.box<Task>().query().watch();
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    // Prepare database directory
    late final String databasePath;
    if (Platform.isAndroid) {
      // Android: Database is saved in /storage/emulated/0/Android/data/com.metagstudios.app.jtasks/files/JTasks/Database
      databasePath = (await getExternalStorageDirectory())!.path;
    } else {
      // Else: Database is saved in /Document/JTasks/Database
      databasePath = (await getApplicationDocumentsDirectory()).path;
    }
    final dbDir = Directory(p.join(databasePath, 'JTasks', 'Database'));
    //

    // Recursively to create the directory if not existed
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }

    final store = await openStore(directory: dbDir.path);
    return ObjectBox._create(store);
  }
}
