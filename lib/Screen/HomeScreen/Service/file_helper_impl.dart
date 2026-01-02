// Implementation file for non-web platforms
import 'dart:io';

Future<void> writeFile(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
}


