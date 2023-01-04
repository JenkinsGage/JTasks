import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jtasks/pages/homepage.dart';
import 'utils.dart';

void main() {
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
