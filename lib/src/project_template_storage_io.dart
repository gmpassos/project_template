import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as pack_path;

import 'project_template_storage.dart';

class StorageIO extends Storage {
  Directory root;

  StorageIO(Directory root) : root = root.absolute;

  StorageIO.directory(Directory parent, String subPath)
      : this(Directory(pack_path.join(parent.path, subPath)));

  @override
  String toAbsoluteDirectory(String directory) =>
      pack_path.join(root.path, directory);

  @override
  String toRelativeDirectory(String absoluteDirectory) {
    var rootParts = pack_path.split(root.path);
    var dirParts = pack_path.split(absoluteDirectory);

    for (var i = 0; i < rootParts.length; ++i) {
      var p = rootParts[i];

      if (dirParts.first == p) {
        dirParts.removeAt(0);
      } else {
        throw StateError(
            'Not an absolute path from this storage: `$absoluteDirectory` NOT AT `$root`');
      }
    }

    var refPath = pack_path.joinAll(dirParts);
    return refPath;
  }

  @override
  List<FileStorage> listFilesImpl() {
    var files = root.listSync(recursive: true);
    var list = files
        .where((f) => !isIgnoredPath(f.path) && !isIgnoredFile(f.path))
        .map((f) => FileSystemEntity.isDirectorySync(f.path)
            ? null
            : FileStorage.fromAbsolutePath(this, f.path))
        .whereType<FileStorage>()
        .toList();
    return list;
  }

  File _resolveFile(String directoryPath, String name) {
    var filePath = pack_path.join(root.path, directoryPath, name);
    var file = File(filePath);
    return file;
  }

  @override
  Future<Uint8List> readFileContent(String directoryPath, String name) {
    var file = _resolveFile(directoryPath, name);
    return file.readAsBytes();
  }

  @override
  Future<bool> saveFileContent(
      String directoryPath, String name, Uint8List content) async {
    var file = _resolveFile(directoryPath, name);
    try {
      await file.writeAsBytes(content);
      return true;
    } catch (e, s) {
      print(e);
      print(s);
      return false;
    }
  }

  @override
  String toString() {
    return 'StorageIO{root: $root}';
  }
}
