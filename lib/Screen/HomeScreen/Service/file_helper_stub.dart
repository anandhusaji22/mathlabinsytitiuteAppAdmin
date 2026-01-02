// Stub file for web - file operations not available
// This file is used when compiling for web

Future<void> writeFile(String path, List<int> bytes) async {
  // Web doesn't support file system writes
  throw UnsupportedError('File writes are not supported on web platform');
}

