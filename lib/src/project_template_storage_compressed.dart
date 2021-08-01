import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as pack_path;

import 'project_template_storage.dart';

/// A [StorageMemory] with `Zip` capabilities.
///
/// - Uses [ZipDecoder] and [ZipEncoder].
///
class StorageZip extends StorageCompressed {
  static _StorageCompressorZip _instantiateCompressor(s) =>
      _StorageCompressorZip(s);

  StorageZip() : super(_instantiateCompressor);

  /// Constructs a [StorageZip] from a [compressedData] (in `Zip`).
  StorageZip.fromCompressed(Uint8List compressedData)
      : super(_instantiateCompressor, compressedData: compressedData);

  /// Constructs a [StorageZip] from a [archive].
  StorageZip.fromArquive(Archive archive)
      : super(_instantiateCompressor, archive: archive);
}

class _StorageCompressorZip extends _StorageCompressor {
  _StorageCompressorZip(StorageMemory storage) : super(storage);

  @override
  String get algorithm => 'Zip';

  @override
  Archive decompressArquive(Uint8List compressedArquive) =>
      ZipDecoder().decodeBytes(compressedArquive);

  @override
  bool isValidCompressionLevel(int compressionLevel) =>
      compressionLevel >= 0 && compressionLevel <= 9;

  @override
  List<int> compressArquiveFiles(OutputStream output, int compressionLevel,
      List<ArchiveFile> arquiveFiles) {
    if (compressionLevel < 0) {
      compressionLevel = 0;
    }

    checkCompressionLevel(compressionLevel);

    var zipEncoder = ZipEncoder();
    zipEncoder.startEncode(output, level: compressionLevel);

    for (var f in arquiveFiles) {
      zipEncoder.addFile(f);
    }

    zipEncoder.endEncode();
    var bytes = output.getBytes();

    return bytes;
  }
}

/// A [StorageMemory] with `Tar` and `Tar+Gzip` capabilities.
///
/// - Uses [TarDecoder] and [TarEncoder].
/// - If compressed also uses [GZipEncoder] and [GZipDecoder].
///
class StorageTarGzip extends StorageCompressed {
  static _StorageCompressorTarGzip _instantiateCompressor(s) =>
      _StorageCompressorTarGzip(s);

  StorageTarGzip() : super(_instantiateCompressor);

  /// Constructs a [StorageTarGzip] from a [compressedData] (in `Tar` or `Tar+Gzip`).
  StorageTarGzip.fromCompressed(Uint8List compressedData)
      : super(_instantiateCompressor, compressedData: compressedData);

  /// Constructs a [StorageTarGzip] from a [archive].
  StorageTarGzip.fromArquive(Archive archive)
      : super(_instantiateCompressor, archive: archive);
}

class _StorageCompressorTarGzip extends _StorageCompressor {
  _StorageCompressorTarGzip(StorageMemory storage) : super(storage);

  @override
  String get algorithm => 'Tar+Gzip';

  @override
  Archive decompressArquive(Uint8List data) {
    try {
      var tarData = GZipDecoder().decodeBytes(data);
      return TarDecoder().decodeBytes(tarData);
    } catch (e) {
      return TarDecoder().decodeBytes(data);
    }
  }

  @override
  bool isValidCompressionLevel(int compressionLevel) =>
      compressionLevel >= 0 && compressionLevel <= 9;

  @override
  List<int> compressArquiveFiles(OutputStream output, int compressionLevel,
      List<ArchiveFile> arquiveFiles) {
    var tarEncoder = TarEncoder();

    tarEncoder.start(output);

    for (var f in arquiveFiles) {
      tarEncoder.add(f);
    }

    tarEncoder.finish();

    var tarData = output.getBytes();

    if (compressionLevel <= 0) {
      return tarData;
    }

    checkCompressionLevel(compressionLevel);

    var gZipEncoder = GZipEncoder();
    var bytes = gZipEncoder.encode(tarData, level: compressionLevel)!;
    return bytes;
  }
}

abstract class StorageCompressed extends StorageMemory {
  late final _StorageCompressor _compressor;

  StorageCompressed(
      _StorageCompressor Function(StorageCompressed storage)
          compressorInstantiator,
      {Uint8List? compressedData,
      Archive? archive}) {
    _compressor = compressorInstantiator(this);

    if (compressedData != null) {
      addCompressedData(compressedData);
    }

    if (archive != null) {
      addArchive(archive);
    }
  }

  void addCompressedData(Uint8List compressedData) {
    var arquive = _compressor.decompressArquive(compressedData);
    addArchive(arquive);
  }

  void addArchive(Archive arquive) {
    for (var f in arquive) {
      addArquiveFile(f);
    }
  }

  // Call [addFile] using [f] parameters.
  bool addArquiveFile(ArchiveFile arquiveFile) {
    if (!arquiveFile.isFile) return false;

    var pathParts = pack_path.split(arquiveFile.name);

    var name = pathParts.removeLast();
    var dir = pack_path.joinAll(pathParts);
    final content = arquiveFile.content as List<int>;

    addFile(dir, name, content);

    return true;
  }

  Future<Uint8List> compress({int compressionLevel = 4}) async {
    return _compressor.compressArquive(compressionLevel: compressionLevel);
  }
}

abstract class _StorageCompressor {
  final StorageMemory storage;

  _StorageCompressor(this.storage);

  String get algorithm;

  /// Calls [addFile] using [arquiveFile] parameters.
  bool addArquiveFile(ArchiveFile arquiveFile) {
    if (!arquiveFile.isFile) return false;

    var pathParts = pack_path.split(arquiveFile.name);

    var name = pathParts.removeLast();
    var dir = pack_path.joinAll(pathParts);
    final content = arquiveFile.content as List<int>;

    storage.addFile(dir, name, content);

    return true;
  }

  Future<List<ArchiveFile>> listArquiveFiles() async {
    var files = storage.listFiles();

    var list = <ArchiveFile>[];

    for (var e in files) {
      var content = await e.getContentAsBytes();

      var archiveFile = ArchiveFile(e.path, content.length, content);
      archiveFile.compress = true;

      list.add(archiveFile);
    }

    return list;
  }

  Archive decompressArquive(Uint8List compressedArquive);

  bool isValidCompressionLevel(int compressionLevel);

  void checkCompressionLevel(int compressionLevel) {
    if (!isValidCompressionLevel(compressionLevel)) {
      throw StateError(
          "Invalid compression level `$compressionLevel` for `$algorithm` algorithm!");
    }
  }

  Future<Uint8List> compressArquive({int compressionLevel = 4}) async {
    var arquiveFiles = await listArquiveFiles();
    var output = OutputStream();

    var bytes = compressArquiveFiles(output, compressionLevel, arquiveFiles);

    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  List<int> compressArquiveFiles(OutputStream output, int compressionLevel,
      List<ArchiveFile> arquiveFiles);
}
