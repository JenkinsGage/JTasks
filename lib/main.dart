import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jtasks/pages/homepage.dart';
import 'utils.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'objectbox.g.dart';

// objectBox is the entry of database that contains a store property which stored the boxes of all the models.
// It is initialized in main function before runApp()
late ObjectBox objectBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DataWrapper data;

  void _onThemeModeChanged(ThemeMode themeMode) {
    setState(() {});
  }

  @override
  void initState() {
    data = DataWrapper(onThemeModeChanged: _onThemeModeChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.light,
          accentColor: Colors.teal,
          iconTheme: const IconThemeData(size: 24),
          fontFamily: GoogleFonts.notoSans().fontFamily),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.teal,
          scaffoldBackgroundColor: const Color(0x040054ff),
          iconTheme: const IconThemeData(size: 24, color: Colors.white),
          fontFamily: GoogleFonts.notoSans().fontFamily),
      themeMode: data.themeMode,
      home: HomePage(
        data: data,
      ),
    );
  }
}

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, "JTasks"));
    return ObjectBox._create(store);
  }
}
