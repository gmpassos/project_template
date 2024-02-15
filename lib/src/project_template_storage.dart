import 'dart:convert' as dart_convert;
import 'dart:typed_data';

import 'package:async_extension/async_extension.dart';
import 'package:path/path.dart' as pack_path;
import 'package:project_template/project_template.dart';

abstract class Storage {
  String toAbsoluteDirectory(String directory);

  String toRelativeDirectory(String absoluteDirectory);

  Set<Pattern> ignorePaths = <Pattern>{};

  Set<Pattern> ignoreFiles = <Pattern>{};

  bool isIgnoredPath(String path) {
    for (var p in ignorePaths) {
      if (p is RegExp) {
        if (p.hasMatch(path)) {
          return true;
        }
      } else {
        if (p == path) {
          return true;
        }
      }
    }

    return false;
  }

  bool isIgnoredFile(String path) {
    var pathParts = pack_path.split(path);
    var fileName = pathParts.last;

    for (var p in ignoreFiles) {
      if (p is RegExp) {
        if (p.hasMatch(fileName)) {
          return true;
        }
      } else {
        if (p == fileName) {
          return true;
        }
      }
    }

    return false;
  }

  Future<Template> loadTemplate() {
    var files = listFiles();
    return Template.fromFiles(files);
  }

  List<FileStorage> listFiles() => listFilesImpl()
      .where((f) => !isIgnoredPath(f.path) && !isIgnoredFile(f.path))
      .toList();

  List<FileStorage> listFilesImpl();

  List<String> listFilesPaths() => listFiles().map((f) => f.path).toList();

  FutureOr<Uint8List> readFileContent(String directoryPath, String name);

  FutureOr<String> getFileType(String directoryPath, String name) {
    var idx = name.lastIndexOf('.');
    var ext = idx >= 0 ? name.substring(idx + 1).toLowerCase().trim() : '';
    return FileType.getExtensionType(ext);
  }

  FutureOr<String?> saveFileContent(
      String directoryPath, String name, Uint8List content);
}

class FileStorage {
  final Storage storage;

  final String directoryAbsolute;

  final String name;

  FileStorage.absolute(this.storage, this.directoryAbsolute, this.name);

  FileStorage.relative(Storage storage, String directory, String name)
      : this.absolute(storage, storage.toAbsoluteDirectory(directory), name);

  factory FileStorage.fromAbsolutePath(Storage storage, String path) {
    var parts = pack_path.split(path);
    var name = parts.removeLast();
    var dir = pack_path.joinAll(parts);
    return FileStorage.absolute(storage, dir, name);
  }

  factory FileStorage.fromRelativePath(Storage storage, String path) {
    var parts = pack_path.split(path);
    var name = parts.removeLast();
    var dir = pack_path.joinAll(parts);
    return FileStorage.relative(storage, dir, name);
  }

  static String buildPath(String directory, String name) =>
      pack_path.join(directory, name);

  String get directory => storage.toRelativeDirectory(directoryAbsolute);

  String get path => pack_path.join(directory, name);

  FutureOr<String> getType() => storage.getFileType(directory, name);

  Uint8List? _bytes;

  FutureOr<Uint8List> getContentAsBytes() {
    if (_bytes == null) {
      return storage.readFileContent(directory, name).resolveMapped((content) {
        _bytes = content;
        return content;
      });
    }
    return _bytes!;
  }

  FutureOr<String> getContentAsString() async {
    var bytes = await getContentAsBytes();
    return dart_convert.utf8.decode(bytes);
  }

  FutureOr<String?> saveAt(String rootPath) {
    var dirPath = pack_path.join(rootPath, directory);
    return getContentAsBytes().resolveMapped((content) {
      return storage.saveFileContent(dirPath, name, content);
    });
  }

  @override
  String toString() {
    return 'FileStorage{directory: $directory, name: $name}';
  }
}

class _MemoryFileStore extends FileStorage {
  final dynamic content;

  _MemoryFileStore.relative(
      super.storage, super.directory, super.name, this.content)
      : super.relative();

  @override
  FutureOr<Uint8List> getContentAsBytes() async {
    if (content is Uint8List) {
      return content;
    } else {
      var s = await getContentAsString();
      var data = dart_convert.utf8.encode(s);
      return Uint8List.fromList(data);
    }
  }

  @override
  FutureOr<String> getContentAsString() async {
    if (content is String) {
      return content;
    } else {
      var bytes = await getContentAsBytes();
      return dart_convert.utf8.decode(bytes);
    }
  }
}

class StorageMemory extends Storage {
  @override
  String toAbsoluteDirectory(String directory) => directory;

  @override
  String toRelativeDirectory(String absoluteDirectory) => absoluteDirectory;

  final Map<String, _MemoryFileStore> _files = <String, _MemoryFileStore>{};

  @override
  List<FileStorage> listFilesImpl() => _files.values.toList();

  void addFile(String directory, String name, dynamic content) {
    var file = _MemoryFileStore.relative(this, directory, name, content);
    _files[file.path] = file;
  }

  FileStorage? getFile(String directory, String name) {
    var path = FileStorage.buildPath(directory, name);
    return _files[path];
  }

  bool removeFile(String directory, String name) {
    var path = FileStorage.buildPath(directory, name);
    return _files.remove(path) != null;
  }

  String _resolveFilePath(String directoryPath, String name) {
    var filePath = pack_path.join(directoryPath, name);
    return filePath;
  }

  @override
  FutureOr<Uint8List> readFileContent(String directoryPath, String name) {
    var filePath = _resolveFilePath(directoryPath, name);
    var file = _files[filePath]!;
    return file.getContentAsBytes();
  }

  @override
  FutureOr<String?> saveFileContent(
      String directoryPath, String name, Uint8List content) {
    var filePath = _resolveFilePath(directoryPath, name);
    var file = _MemoryFileStore.relative(this, directoryPath, name, content);
    _files[filePath] = file;
    return filePath;
  }

  @override
  String toString() {
    return 'StorageMemory{files: $_files}';
  }
}

/// Base class for File type.
class FileType {
  /// The type of this File (lower-case and trimmed).
  final String type;

  FileType(String type) : type = type.trim().toLowerCase();

  FileType.byExtension(String ext) : this(getExtensionType(ext));

  bool get isJsonType =>
      type == 'application/json' || type == 'text/json' || type == 'json';

  bool get isJavaScriptType =>
      type == 'application/javascript' ||
      type == 'text/javascript' ||
      type == 'javascript';

  bool get isImageType => type.startsWith('image');

  bool get isVideoType => type.startsWith('video');

  bool get isAudioType => type.startsWith('audio');

  bool get isFontType => type.startsWith('font');

  bool get isTextType =>
      type.startsWith('text') || isJsonType || isJavaScriptType;

  bool get isBinaryType =>
      !isTextType &&
      (isImageType ||
          isVideoType ||
          isAudioType ||
          isFontType ||
          type.startsWith('application'));

  static String getExtensionType(String ext) {
    ext = ext.trim().toLowerCase();

    switch (ext) {
      case 'txt':
      case 'text':
      case 'gitignore':
        return 'text/plain';
      case 'css':
        return 'text/css';
      case 'htm':
      case 'html':
        return 'text/html';

      case 'js':
        return 'text/javascript';
      case 'json':
        return 'application/json';

      case 'md':
        return 'text/markdown';

      case 'yml':
      case 'yaml':
        return 'text/yaml';

      case 'csv':
        return 'text/csv';

      case 'dart':
        return 'text/dart';

      case 'java':
        return 'text/java';

      case 'sh':
        return 'text/shell';

      case 'gif':
        return 'image/gif';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'svg':
        return 'image/svg+xml';

      case 'weba':
        return 'audio/webm';
      case 'webm':
        return 'video/webm';
      case 'webp':
        return 'image/webp';

      case 'woff':
        return 'font/woff';
      case 'woff2':
        return 'font/woff2';
      case 'otf':
        return 'font/otf';
      case 'ttf':
        return 'font/ttf';

      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'mpeg':
        return 'video/mpeg';

      case 'oga':
        return 'audio/ogg';
      case 'ogv':
        return 'video/ogg';
      case 'ogx':
        return 'application/ogg';

      case 'opus':
        return 'audio/opus';

      case 'aac':
        return 'audio/aac';

      case 'avi':
        return 'video/x-msvideo';

      case 'pdf':
        return 'application/pdf';

      case 'tar':
        return 'application/x-tar';
      case 'zip':
        return 'application/zip';
      case 'gz':
        return 'application/gzip';
      case 'bz':
        return 'application/x-bzip';
      case 'bz2':
        return 'application/x-bzip2';
      case 'rar':
        return 'application/vnd.rar';

      case 'jar':
        return 'application/java-archive';

      default:
        return 'application/octet-stream';
    }
  }
}
