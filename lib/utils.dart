import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:pasteboard/pasteboard.dart';

void showDeleteConfirmDialog(
    {required BuildContext context, required VoidCallback onDelete, VoidCallback? onCanceled}) async {
  await showDialog(
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

void replaceTextSelectionWith(TextEditingController textEditingController, Function(String selection) getReplaceString,
    {int? optionalOffset}) {
  final selection = textEditingController.selection;
  if (selection.isValid) {
    final text = textEditingController.text;
    final replaceText = getReplaceString(selection.textInside(text)) as String;
    final newText = text.replaceRange(selection.start, selection.end, replaceText);
    if (!selection.isCollapsed) {
      textEditingController.value = TextEditingValue(
          text: newText, selection: TextSelection.collapsed(offset: selection.start + replaceText.length));
    } else {
      textEditingController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + (optionalOffset ?? replaceText.length)));
    }
  }
}

Future<String?> getImageBase64FromPasteboard() async {
  final imageBytes = await Pasteboard.image;
  if (imageBytes != null) {
    return base64.encode(imageBytes);
  }
  return null;
}

DateTime get todayEnd {
  var now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59);
}

DateTime get todayStart {
  var now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String get version {
  return 'Ver: Test 0.1';
}