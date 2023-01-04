import 'package:fluent_ui/fluent_ui.dart';

class DataWrapper {
  ValueChanged<ThemeMode>? onThemeModeChanged;

  ThemeMode themeMode;

  DataWrapper({this.themeMode = ThemeMode.light, this.onThemeModeChanged});

  void updateThemeMode(ThemeMode themeMode) {
    this.themeMode = themeMode;

    if (onThemeModeChanged != null) {
      onThemeModeChanged!(themeMode);
    }
  }
}
