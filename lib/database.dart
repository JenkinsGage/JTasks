import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    // Prepare database directory and path
    late final String databasePath;
    if (Platform.isAndroid) {
      // Android: Database is saved in /storage/emulated/0/JTasks/JTasks/Database
      databasePath = "/storage/emulated/0/JTasks/";
    } else {
      // Else: Database is saved in Document/JTasks/Database
      databasePath = (await getApplicationDocumentsDirectory()).path;
    }
    final dbDir = Directory(p.join(databasePath, 'JTasks', 'Database'));
    // Recursively to create the directory if not existed
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }
    //

    final store = await openStore(directory: dbDir.path);
    return ObjectBox._create(store);
  }
}

Future<bool> checkStoragePermission() async {
  if (!Platform.isAndroid) {
    // If not android platform, the permission is already granted
    return true;
  } else {
    // Else try to get the permission
    Permission storagePermission = Permission.manageExternalStorage;
    final status = await storagePermission.status;
    if (status != PermissionStatus.granted) {
      final result = await storagePermission.request();
      if (result == PermissionStatus.granted) {
        // Successfully granted
        return true;
      }
    } else {
      // If already granted
      return true;
    }
  }
  return false;
}
