import 'dart:convert' as dart_convert;
import 'dart:typed_data';

import 'package:collection/collection.dart' show SetEquality;
import 'package:path/path.dart' as pack_path;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'project_template_storage.dart';

/// A Template tree.
class Template {
  static const String version = '1.0.0';

  final Set<TemplateEntry> _entries = <TemplateEntry>{};

  Template([Iterable<TemplateEntry>? entries]) {
    if (entries != null) {
      _entries.addAll(entries);
    }
  }

  static Future<Template> fromFiles(Iterable<FileStorage> files) async {
    var entriesFutures =
        files.map((f) async => await TemplateEntry.fromFile(f));
    var entries = await Future.wait(entriesFutures);
    return Template(entries);
  }

  /// A [Set] of [TemplateEntry] of this instance.
  Set<TemplateEntry> get entries => _entries.toSet();

  /// A [Set] of [TemplateEntry] paths.
  Set<String> get entriesPaths => _entries.map((e) => e.path).toSet();

  /// Returns `true` if entries are empty.
  bool get isEmpty => _entries.isEmpty;

  /// Returns `true` if entries are NOT empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns the amount of entries.
  int get length => _entries.length;

  /// The main entry path/directory.
  String? get mainEntryPath {
    if (isEmpty) return null;

    var mainDirs = _entries.map((e) => e.pathParts[0]).toSet();

    if (mainDirs.length > 1) {
      mainDirs.removeWhere((e) => e.startsWith('.'));
    }

    return mainDirs.length == 1 ? mainDirs.first : '';
  }

  /// Adds an [TemplateEntry] to this template.
  void addEntry<D>(TemplateEntry<D> entry) {
    _entries.add(entry);
  }

  /// Gets a [TemplateEntry] by [path].
  TemplateEntry? getEntryByPath(String path) {
    var pathParts = TemplateEntry.parsePathParts(path);
    if (pathParts.isEmpty) return null;

    var name = pathParts.removeLast();

    pathParts = TemplateEntry.normalizePathParts(pathParts);

    return getEntryByDirectoryAndName(pathParts, name,
        alreadyNormalizedDirectory: true);
  }

  /// Gets a [TemplateEntry] by [directory] and [name].
  TemplateEntry? getEntryByDirectoryAndName(dynamic directory, String name,
      {bool alreadyNormalizedDirectory = false}) {
    for (var e in _entries) {
      if (e.isEqualsDirectoryAndName(directory, name,
          alreadyNormalizedDirectory: alreadyNormalizedDirectory)) {
        return e;
      }
    }

    return null;
  }

  /// Resolves template variables to a new [Template] instance
  /// (without variables placeholders).
  Template resolve(Map<String, dynamic> variables) {
    var jsonMap = resolveToJsonMap(variables);
    return Template.fromJson(jsonMap);
  }

  /// Resolves template variables to a [JSON] [Map]
  List<Map<String, String>> resolveToJsonMap(Map<String, dynamic> variables,
      {Map<String, dynamic>? manifest}) {
    var manifest = getManifest() ?? <String, dynamic>{};

    checkDefinedVariables(variables, manifest: manifest);

    var jsonMap = _entries.where((e) => !e.isManifest).map((e) {
      return e.resolveToJsonMap(variables, manifest: manifest);
    }).toList();

    return jsonMap;
  }

  /// Throws a [StateError] if not all used variables are defined by [variables].
  /// Calls [getNotDefinedVariables] to determined not defined variables.
  void checkDefinedVariables(Map<String, dynamic> variables,
      {Map<String, dynamic>? manifest}) {
    var notDefinedVariables =
        getNotDefinedVariables(variables, manifest: manifest);
    if (notDefinedVariables.isNotEmpty) {
      throw StateError(
          "Not all template variables are defined: $notDefinedVariables");
    }
  }

  /// Returns a [List] of variables used in the template and not defined at [variables].
  /// Calls [parseTemplateVariables] to determined used variables.
  List<String> getNotDefinedVariables(Map<String, dynamic> variables,
      {Map<String, dynamic>? manifest}) {
    var parsedVars = parseTemplateVariables();

    manifest ??= getManifest() ?? <String, dynamic>{};

    defaultVarProvider(String varName) => manifest![varName]?['default'];

    var notDefinedVars = <String>{};

    for (var varName in parsedVars) {
      if (_getVariable(variables, varName, defaultVarProvider) == null) {
        notDefinedVars.add(varName);
      }
    }

    return notDefinedVars.toList();
  }

  /// Parses the template variables and returns them.
  Set<String> parseTemplateVariables([Set<String>? variables]) {
    variables ??= <String>{};

    for (var e in _entries) {
      e.parseTemplateVariables(variables);
    }

    return variables;
  }

  /// Returns `true` if [fileName] is a `project_template` manifest.
  ///
  /// Possible file names:
  /// - project_template.yaml
  /// - project_template.yml
  /// - project_template.json
  ///
  static bool isManifestFileName(String fileName) {
    return fileName == 'project_template.yml' ||
        fileName == 'project_template.yaml' ||
        fileName == 'project_template.json';
  }

  /// Returns the template manifest. See [isManifestFileName].
  Map<String, dynamic>? getManifest() {
    var manifest = _entries.where((e) => e.isManifest).toList();

    if (manifest.isEmpty) return null;

    manifest.sort((a, b) => a.pathParts.length.compareTo(b.pathParts.length));

    var manifestEntry = manifest.first;

    var content = manifestEntry.contentAsString;
    var ext = manifestEntry.nameExtension;

    var map = <String, dynamic>{};

    try {
      switch (ext) {
        case 'yml':
        case 'yaml':
          {
            var yaml = loadYaml(content) as YamlMap;
            map = yaml
                .map((key, value) => MapEntry<String, dynamic>('$key', value));
            break;
          }
        case 'json':
          {
            map = dart_convert.json.decode(content);
            break;
          }
        default:
          break;
      }

      return map;
    } catch (e, s) {
      print(e);
      print(s);
      return null;
    }
  }

  /// Converts to an encode YAML [String].
  String toYAMLEncoded() => _encodeYAML(toJsonMap());

  /// Converts to an encode JSON [String].
  String toJsonEncoded({bool pretty = false}) =>
      _encodeJSON(toJsonMap(), pretty);

  /// Converts to a JSON [List] of [TemplateEntry] (as JSON [Map]).
  List<Map<String, dynamic>> toJsonMap() {
    var list = _entries.map((e) => e.toJson()).toList();
    return list;
  }

  /// Constructs from a dynamic object [o].
  factory Template.from(dynamic o) {
    if (o is Template) {
      return o;
    } else if (o is Iterable) {
      return Template.fromJson(o);
    } else if (o is String) {
      var json = dart_convert.json.decode(o);
      return Template.fromJson(json as Iterable);
    }

    throw StateError("Can't handle type: $o");
  }

  /// Constructs from an encoded[json].
  factory Template.fromJsonEncoded(String json) {
    return Template.fromJson(dart_convert.json.decode(json));
  }

  /// Constructs from a [json].
  factory Template.fromJson(Iterable json) {
    var list = json
        .map((e) => (e as Map).map((key, value) => MapEntry('$key', value)))
        .map((m) => TemplateEntry.fromJson(m))
        .toList();
    return Template(list);
  }

  static final SetEquality<TemplateEntry> _entriesEquality =
      SetEquality<TemplateEntry>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Template &&
          runtimeType == other.runtimeType &&
          _entriesEquality.equals(_entries, other._entries);

  @override
  int get hashCode => _entriesEquality.hash(_entries);

  @override
  String toString() {
    return 'Template{entries: $length}';
  }

  /// Saves to template to [storage];
  Future<List<String>> saveTo(Storage storage, [String? destinySubPath]) async {
    var savedFiles = <String>[];

    for (var e in _entries) {
      var dir = e.directory;

      if (destinySubPath != null && destinySubPath.isNotEmpty) {
        dir = pack_path.join(destinySubPath, dir);
      }

      var savedFile =
          await storage.saveFileContent(dir, e.name, e.contentAsBytes);

      if (savedFile != null) {
        savedFiles.add(savedFile);
      } else {
        throw StateError("Can't save entry! entry: $e ; storage: $storage");
      }
    }

    return savedFiles;
  }
}

/// a [Template] entry.
class TemplateEntry<D> extends FileType {
  /// Parts a [path] in parts and normalizes it.
  static List<String> parsePathParts(String path) {
    var parts = pack_path.split(path);
    return normalizePathParts(parts);
  }

  /// Normalizes a path split in parts.
  static List<String> normalizePathParts(List<String> pathParts) {
    pathParts = pathParts.toList();

    for (var i = 0; i < pathParts.length; ++i) {
      var p = pathParts[i];

      if (p == '' || p == '.') {
        pathParts.removeAt(i);
      } else if (p == '..') {
        pathParts.removeAt(i);
        if (i > 0) {
          pathParts.removeAt(i - 1);
        }
      }
    }

    while (pathParts.isNotEmpty &&
        (pathParts.first == '' || pathParts.first == '.')) {
      pathParts.removeAt(0);
    }

    while (pathParts.isNotEmpty &&
        (pathParts.last == '' || pathParts.last == '.')) {
      pathParts.removeLast();
    }

    return pathParts;
  }

  /// The directory path of this entry.
  final String directory;

  /// The name of this entry.
  final String name;

  /// The content of this entry.
  final D content;

  TemplateEntry(String directory, this.name, String type, this.content)
      : directory = isRootDirectory(directory) ? '' : directory,
        super(type);

  /// Constructs with [content] as an encoded Base64.
  static TemplateEntry<Uint8List> contentBase64(
          String directory, String name, String type, String base64) =>
      TemplateEntry.contentBytes(
          directory, name, type, dart_convert.base64.decode(base64));

  /// Constructs with [content] as bytes.
  static TemplateEntry<Uint8List> contentBytes(
          String directory, String name, String type, Uint8List bytes) =>
      TemplateEntry<Uint8List>(directory, name, type, bytes);

  /// Constructs from a dynamic object [o].
  factory TemplateEntry.from(dynamic o) {
    if (o is TemplateEntry) {
      return o as TemplateEntry<D>;
    } else if (o is Map) {
      return TemplateEntry.fromJson(o as Map<String, dynamic>);
    } else if (o is String) {
      var json = dart_convert.json.decode(o);
      return TemplateEntry.fromJson(json as Map<String, dynamic>);
    }

    throw StateError("Can't handle type: $o");
  }

  /// Constructs from an encoded[json].
  factory TemplateEntry.fromJsonEncoded(String json) {
    return TemplateEntry.fromJson(dart_convert.json.decode(json));
  }

  /// Constructs from a [json].
  factory TemplateEntry.fromJson(Map<String, dynamic> json) {
    var dir = (json['directory'] ?? '') as String;
    var name = json['name'] as String;
    var type = (json['type'] ?? 'text') as String;
    var encode = (json['encode'] ?? 'text') as String;
    var content = json['content'] as String;

    if (encode == 'base64') {
      if (type == 'text') {
        var data = dart_convert.base64.decode(content);
        var text = dart_convert.utf8.decode(data);
        return TemplateEntry<String>(dir, name, type, text) as TemplateEntry<D>;
      } else {
        return TemplateEntry.contentBase64(dir, name, type, content)
            as TemplateEntry<D>;
      }
    } else {
      if (type == 'text') {
        return TemplateEntry<String>(dir, name, type, content)
            as TemplateEntry<D>;
      } else {
        return TemplateEntry<D>(dir, name, type, content as D);
      }
    }
  }

  static Future<TemplateEntry> fromFile(FileStorage file) async {
    var type = await file.getType();

    if (FileType(type).isBinaryType) {
      var content = await file.getContentAsBytes();
      return TemplateEntry(file.directory, file.name, type, content);
    } else {
      var content = await file.getContentAsString();
      return TemplateEntry(file.directory, file.name, type, content);
    }
  }

  /// Returns `true` if [directory] is a root entry directory.
  static bool isRootDirectory(String directory) {
    return directory.isEmpty || directory == '/' || directory == './';
  }

  /// Returns `true` if this entry is at root [directory] (empty directory path).
  bool get isRootEntry => directory == '';

  String? _path;

  /// Returns the path of this entry: [directory] + '/' + [name].
  String get path => _path ??= isRootEntry ? name : '$directory/$name';

  List<String>? _pathParts;

  /// Returns [path] parts.
  List<String> get pathParts => _pathParts ??= pack_path.split(path);

  /// Returns `true` if [path] matches this instances [directory] and [name].
  bool isEqualsPath(String path) {
    var parts = parsePathParts(path);
    return isEqualsPathParts(parts);
  }

  /// Returns `true` if [pathParts] matches this instances [directory] and [name].
  bool isEqualsPathParts(List<String> pathParts) {
    if (pathParts.isEmpty) return false;
    var name = pathParts.removeLast();
    return isEqualsDirectoryAndName(pathParts, name);
  }

  /// Returns `true` if [directory] and [name] matches this instance.
  bool isEqualsDirectoryAndName(dynamic directory, String name,
      {bool alreadyNormalizedDirectory = false}) {
    if (this.name != name) return false;

    if (directory is Iterable) {
      if (directory is! Iterable<String>) {
        var list = directory.map((e) => e == null ? '' : e.toString()).toList();
        directory = normalizePathParts(list);
      }

      if (directory.isEmpty) {
        return directory.isEmpty;
      }

      var dirList = directory is List<String> ? directory : directory.toList();

      if (!alreadyNormalizedDirectory) {
        dirList = normalizePathParts(dirList);
      }

      var dir = pack_path.joinAll(dirList);
      return this.directory == dir;
    } else {
      var dir = directory.toString();

      if (!alreadyNormalizedDirectory) {
        var dirList = parsePathParts(dir);
        dir = pack_path.joinAll(dirList);
      }

      return this.directory == dir;
    }
  }

  /// The file [name] extension.
  String get nameExtension {
    return parseNameExtension(name);
  }

  /// Parse a file name extension.
  static String parseNameExtension(String name) {
    var idx = name.lastIndexOf('.');
    return idx >= 0 ? name.substring(idx + 1) : '';
  }

  /// The [content] as [String].
  String get contentAsString {
    if (content is String) {
      return content as String;
    } else if (content is Uint8List) {
      return dart_convert.utf8.decode(content as Uint8List);
    } else if (content is List<int>) {
      return dart_convert.utf8.decode(content as List<int>);
    } else if (content is Iterable<int>) {
      return dart_convert.utf8.decode((content as Iterable<int>).toList());
    } else {
      return content.toString();
    }
  }

  /// The [content] as [Uint8List].
  Uint8List get contentAsBytes {
    if (content is Uint8List) {
      return content as Uint8List;
    } else if (content is List<int>) {
      return Uint8List.fromList(content as List<int>);
    } else if (content is Iterable<int>) {
      return Uint8List.fromList((content as Iterable<int>).toList());
    } else {
      var data = dart_convert.utf8.encode(content.toString());
      return Uint8List.fromList(data);
    }
  }

  /// Returns `true` if this entry file [name] is a manifest.
  /// Calls [Template.isManifestFileName].
  bool get isManifest => Template.isManifestFileName(name);

  /// Resolves entry variables to a new [TemplateEntry] instance
  /// (without variables placeholders).
  TemplateEntry<D> resolve(Map<String, dynamic> variables) {
    var jsonMap = resolveToJsonMap(variables);
    return TemplateEntry.fromJson(jsonMap);
  }

  /// Resolves entry variables to a [JSON] [Map]
  Map<String, String> resolveToJsonMap(Map<String, dynamic> variables,
      {Map<String, dynamic>? manifest}) {
    defaultVarProvider(String varName) => manifest![varName]?['default'];

    var map = {
      'directory':
          _resolveTemplateString(variables, directory, defaultVarProvider),
      'name': _resolveTemplateString(variables, name, defaultVarProvider),
      'type': _resolveTemplateString(variables, type, defaultVarProvider),
    };

    if (content is Uint8List) {
      map['encode'] = 'base64';
      map['content'] = dart_convert.base64.encode(content as Uint8List);
    } else {
      map['encode'] = 'text';
      map['content'] = _resolveTemplateString(
          variables, contentAsString, defaultVarProvider);
    }
    return map;
  }

  /// Parses the template variables and returns them.
  Set<String> parseTemplateVariables([Set<String>? variables]) {
    variables ??= <String>{};

    _parseTemplateVariables(variables, directory);
    _parseTemplateVariables(variables, name);
    _parseTemplateVariables(variables, type);

    if (content is! Uint8List) {
      _parseTemplateVariables(variables, contentAsString);
    }

    return variables;
  }

  /// Converts to an encode YAML [String].
  String toYAMLEncoded() => _encodeYAML(toJson());

  /// Converts to an encode JSON [String].
  String toJsonEncoded({bool pretty = false}) => _encodeJSON(toJson(), pretty);

  /// Converts to a JSON [Map].
  Map<String, String> toJson() {
    var encodeBase64 = content is Uint8List;

    return {
      'directory': directory,
      'name': name,
      'type': type,
      'encode': encodeBase64 ? 'base64' : 'text',
      'content': encodeBase64
          ? dart_convert.base64.encode(content as Uint8List)
          : content.toString(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateEntry &&
          runtimeType == other.runtimeType &&
          directory == other.directory &&
          name == other.name;

  @override
  int get hashCode => directory.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'TemplateEntry{directory: $directory, name: $name}';
  }
}

final RegExp _regExpTemplateVar = RegExp(r'___(\w+?(?:/\w+?)*?)___');

typedef _DefaultVarProvider = dynamic Function(String varName);

String? _getVariable(Map<String, dynamic> variables, String varName,
    _DefaultVarProvider? defaultVarValue) {
  defaultVarValue ??= (_) => null;

  if (varName.contains('/')) {
    var parts = varName.split('/');

    dynamic context = variables;

    Object? val;
    while (parts.isNotEmpty) {
      var key = parts.removeAt(0).trim();

      if (context is Map) {
        val = context[key];
      } else if (context is Iterable) {
        var idx = int.parse(key);
        val = context.elementAt(idx);
      }

      if (parts.isEmpty) {
        break;
      } else if (val == null) {
        return defaultVarValue(varName);
      }

      context = val;
    }

    return val != null ? '$val' : defaultVarValue(varName);
  } else {
    var val = variables[varName];
    return val != null ? '$val' : defaultVarValue(varName);
  }
}

void _parseTemplateVariables(Set<String> variables, String s) {
  s.replaceAllMapped(_regExpTemplateVar, (m) {
    var varName = m.group(1)!;
    variables.add(varName);
    return '';
  });
}

String _resolveTemplateString(Map<String, dynamic> variables, String s,
    _DefaultVarProvider? defaultVarValue) {
  var resolved = s.replaceAllMapped(_regExpTemplateVar, (m) {
    var varName = m.group(1)!;
    var val = _getVariable(variables, varName, defaultVarValue);
    val ??= '';
    return val;
  });

  return resolved;
}

String _encodeYAML(dynamic o) {
  return YAMLWriter().write(o);
}

String _encodeJSON(dynamic o, bool pretty) {
  if (pretty) {
    return dart_convert.JsonEncoder.withIndent('  ').convert(o);
  }
  return dart_convert.json.encode(o);
}
