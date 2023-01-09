import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jtasks/pages/homepage.dart';
import 'package:provider/provider.dart';

import 'database.dart';
import 'models.dart';
import 'objectbox.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  obx = await ObjectBox.create();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Use providers to provide global data
    return MultiProvider(
      providers: [
        // ThemeProvider holds the theme data
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => BoardsDataProvider(),
        )
      ],
      child: Consumer<ThemeProvider>(
        // HomePage
        child: const HomePage(),
        builder: (context, themeProvider, child) => FluentApp(
          debugShowCheckedModeBanner: false,
          // Specify theme and darkTheme
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
          themeMode: themeProvider.themeMode,
          home: child,
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }
}

class BoardsDataProvider extends ChangeNotifier {
  late List<Board> _openingBoards;

  List<Board> get openingBoards => _openingBoards;

  set openingBoards(List<Board> value) {
    _openingBoards = value;
    notifyListeners();
  }

  late List<Board> _closedBoards;

  List<Board> get closedBoards => _closedBoards;

  set closedBoards(List<Board> value) {
    _closedBoards = value;
    notifyListeners();
  }

  BoardsDataProvider() {
    // Init private boards data
    _openingBoards = obx.openingBoardsQuery.find();
    _closedBoards = obx.closedBoardsQuery.find();
    //

    // Listen to the late changes and update using setters
    obx.closedBoardsStream.listen((Query<Board> query) {
      closedBoards = query.find();
    });
    obx.openingBoardsStream.listen((Query<Board> query) {
      openingBoards = query.find();
    });
    obx.taskStream.listen((Query<Task> query) {
      // Update boards after the task updated
      closedBoards = obx.closedBoardsQuery.find();
      openingBoards = obx.openingBoardsQuery.find();
      //
    });
  }
}
