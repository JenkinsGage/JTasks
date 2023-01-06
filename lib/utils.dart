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

void showDeleteConfirmDialog(
    {required BuildContext context, required VoidCallback onDelete, VoidCallback? onCanceled}) async {
  final result = await showDialog(
      context: context,
      builder: (context) => ContentDialog(
            title: const Text('Do you really want to delete it?'),
            content: const Text("This action can't be reverted. Just close it or store it is preferred."),
            actions: [
              FilledButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context, 'Cancel');
                    if (onCanceled != null) {
                      onCanceled();
                    }
                  }),
              Button(
                  onPressed: () {
                    Navigator.pop(context, 'Delete');
                    onDelete();
                  },
                  child: const Text('Delete'))
            ],
          ));
}
