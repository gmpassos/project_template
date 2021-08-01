import 'dart:async';
import 'dart:convert' as dart_convert;
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as pack_path;
import 'package:args/command_runner.dart';
import 'package:project_template/project_template.dart';
import 'package:project_template/src/project_template_storage_io.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

void _log(String ns, String message) {
  print('## [$ns]\t$message');
}

const String cliTitle = '[Project_Template/${Template.version}]';

void main(List<String> args) async {
  var commandRunner =
      CommandRunner<bool>('project_template', '$cliTitle - CLI Tool')
        ..addCommand(CommandInfo())
        ..addCommand(CommandCreate())
        ..addCommand(CommandPrepare());

  commandRunner.argParser.addFlag('version',
      abbr: 'v', negatable: false, defaultsTo: false, help: 'Show version.');

  {
    var argsResult = commandRunner.argParser.parse(args);

    if (argsResult['version']) {
      showVersion();
      return;
    }
  }

  var ok = (await commandRunner.run(args)) ?? false;

  exit(ok ? 0 : 1);
}

void showVersion() {
  print('Project_Template/${Template.version} - CLI Tool');
}

abstract class CommandBase extends Command<bool> {
  final _argParser = ArgParser(allowTrailingOptions: false);

  @override
  ArgParser get argParser => _argParser;

  @override
  String get usage {
    var s = super.usage;
    return '$cliTitle\n\n($name) :: $s';
  }

  int get parametersStartIndex => 0;

  List<String>? _parameters;

  List<String> get parameters {
    if (_parameters == null) {
      var list = argResults!.rest;
      var startIndex = parametersStartIndex;
      if (list.length <= startIndex) return <String>[];
      _parameters = list.sublist(startIndex).toList();
    }
    return _parameters!;
  }

  String? getParameter(int index, [String? def]) {
    var params = parameters;
    return index < params.length ? params[index] : def;
  }

  bool hasError = false;

  void showError(String message) {
    _log('ERROR', message);
    hasError = true;
  }

  void showErrorOptionNotProvided(String option) {
    showError('Option `$option` not provided.');
  }

  String readFile(String filePath) => File(filePath).readAsStringSync();
}

abstract class CommandTemplateBase extends CommandBase {
  CommandTemplateBase({bool allowIgnoreOptions = true}) {
    if (allowIgnoreOptions) {
      argParser.addMultiOption(
        'ignore',
        abbr: 'i',
        help: 'Ignore a path from template directory.',
        valueHelp: 'dir/file.txt',
      );

      argParser.addMultiOption(
        'regexp',
        abbr: 'r',
        help: 'Ignore a path by `RegExp` from template directory.',
        valueHelp: r'\.txt$',
      );
    }
  }

  List<String>? get argIgnore => argResults!['ignore'];

  List<String>? get argRegExp => argResults!['regexp'];

  List<RegExp> parseRegExp() {
    var list = argRegExp ?? <String>[];
    return list.map((r) => RegExp(r)).toList();
  }

  void showTemplateInfos(Template template) {
    var templateVariables = template.parseTemplateVariables();

    print('\nTEMPLATE VARIABLES:\n  ${templateVariables.join(', ')}');

    var manifest = template.getManifest();

    if (manifest != null) {
      print('\nMANIFEST:');

      print(
        YAMLWriter()
            .write(manifest)
            .split(RegExp(r'[\r\n]'))
            .map((l) => '  $l')
            .join('\n'),
      );
    }
  }

  Future<Template> loadTemplate(String templatePath,
      {List<String>? ignorePath, List<Pattern>? ignoreRegexp}) async {
    var templatePathLC = templatePath.toLowerCase();

    if (templatePathLC.endsWith('.json')) {
      var data = readFile(templatePath);
      var json = dart_convert.json.decode(data);
      return Template.fromJson(json);
    } else if (templatePathLC.endsWith('.yaml') ||
        templatePathLC.endsWith('.yml')) {
      var data = readFile(templatePath);
      var yaml = loadYaml(data);
      return Template.fromJson(yaml);
    } else if (templatePathLC.endsWith('.zip')) {
      var file = File(templatePath);
      var storage = StorageZip.fromCompressed(file.readAsBytesSync());
      return await _loadTemplateFromStorage(
          storage, templatePath, ignorePath, ignoreRegexp);
    } else if (templatePathLC.endsWith('.tar') ||
        templatePathLC.endsWith('.tar.gz')) {
      var file = File(templatePath);
      var storage = StorageTarGzip.fromCompressed(file.readAsBytesSync());
      return await _loadTemplateFromStorage(
          storage, templatePath, ignorePath, ignoreRegexp);
    } else {
      var storage = StorageIO.directoryPath(templatePath);
      return await _loadTemplateFromStorage(
          storage, storage.root.path, ignorePath, ignoreRegexp);
    }
  }

  Future<Template> _loadTemplateFromStorage(Storage storage, String storagePath,
      List<String>? ignorePath, List<Pattern>? ignoreRegexp) async {
    if (ignorePath != null) {
      storage.ignorePaths.addAll(ignorePath);
    }

    if (ignoreRegexp != null) {
      storage.ignorePaths.addAll(ignoreRegexp);
    }

    print('');

    if (storage.ignorePaths.isNotEmpty) {
      print('-- Template ignorePaths(${storage.ignorePaths.length}):');
      for (var e in storage.ignorePaths) {
        print('   $e');
      }
      print('');
    }

    print('-- Loading template:\n   $storagePath');

    return await storage.loadTemplate();
  }
}

class CommandInfo extends CommandTemplateBase {
  @override
  final String description = 'Show information about a Template.';

  @override
  final String name = 'info';

  CommandInfo() : super(allowIgnoreOptions: false) {
    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Template to use.',
      valueHelp:
          './template_dir|template.yaml|template.json|template.zip|template.tar.gz',
    );
  }

  String? get argTemplate => argResults!['template'];

  @override
  FutureOr<bool> run() async {
    var templatePath = argTemplate;

    if (templatePath == null) {
      showErrorOptionNotProvided('template');
    }

    if (hasError) {
      return false;
    }

    print(cliTitle);

    print('\nTEMPLATE:\n  $templatePath');

    var template = await loadTemplate(templatePath!);

    var entriesPaths = template.entriesPaths;

    print('\nENTRIES(${entriesPaths.length}):');

    for (var e in entriesPaths) {
      print('  > $e');
    }

    showTemplateInfos(template);

    return true;
  }
}

class CommandCreate extends CommandTemplateBase {
  @override
  final String description =
      'Create/build a project (file tree) from a Template.';

  @override
  final String name = 'create';

  CommandCreate() {
    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Template to use.',
      valueHelp:
          './template_dir|template.yaml|template.json|template.zip|template.tar.gz',
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory.',
    );

    argParser.addMultiOption(
      'property',
      abbr: 'p',
      help: 'Define a template property/variable.',
      valueHelp: 'varName=X',
    );
  }

  String? get argTemplate => argResults!['template'];

  String? get argOutput => argResults!['output'];

  List<String>? get argProperties => argResults!['property'];

  Map<String, String> parseProperties() {
    var list = argProperties ?? <String>[];

    var entries = list.map((e) {
      var idx = e.indexOf('=');
      String k, v;
      if (idx >= 0) {
        k = e.substring(0, idx);
        v = e.substring(idx + 1);
      } else {
        k = e;
        v = 'true';
      }

      return MapEntry(k, v);
    });

    return Map.fromEntries(entries);
  }

  @override
  FutureOr<bool> run() async {
    var templatePath = argTemplate;
    var output = argOutput;
    var ignore = argIgnore;
    var regexp = parseRegExp();
    var properties = parseProperties();

    if (templatePath == null || templatePath.isEmpty) {
      showErrorOptionNotProvided('template');
    }

    late Directory outputDir;
    if (output == null || output.isEmpty) {
      showErrorOptionNotProvided('output');
    } else {
      outputDir = Directory(output).absolute;
      if (outputDir.existsSync()) {
        showError('Output directory already exists: $output');
      }
    }

    if (properties.isEmpty) {
      _log('WARNING',
          'Empty template properties. Use `-p varName=X` to define properties/variables.');
    }

    if (hasError) {
      return false;
    }

    print(cliTitle);

    print('\nTEMPLATE:\n  $templatePath');

    var template = await loadTemplate(templatePath!,
        ignorePath: ignore, ignoreRegexp: regexp);

    showTemplateInfos(template);

    print('\nDEFINED PROPERTIES:');

    for (var e in properties.entries) {
      print('  - ${e.key}: ${e.value}');
    }

    var notPresentVars = template.getNotDefinedVariables(properties);

    if (notPresentVars.isNotEmpty) {
      print('');
      _log('ERROR', 'Missing properties: ${notPresentVars.join(', ')}');
      return false;
    }

    print('\nOUTPUT:\n  ${outputDir.path}');

    print('\n-- Resolving template...');
    var resolvedTemplate = template.resolve(properties);

    outputDir.createSync(recursive: true);

    var storage = StorageIO(outputDir);

    var savedFiles = await resolvedTemplate.saveTo(storage);

    print('\nSAVED FILES(${savedFiles.length}):');
    for (var f in savedFiles) {
      print('  > $f');
    }

    var mainEntryPath = resolvedTemplate.mainEntryPath;

    print('\n-- mainEntryPath: $mainEntryPath');

    print('\n-- Template generated at: ${storage.root.path}');

    print('');

    return true;
  }
}

class CommandPrepare extends CommandTemplateBase {
  @override
  final String description =
      'Prepare a Template directory to a YAML or JSON template file.';

  @override
  final String name = 'prepare';

  CommandPrepare() {
    argParser.addOption(
      'directory',
      abbr: 'd',
      help: 'Template source directory.',
      valueHelp: './template_source_dir|template.zip|template.tar.gz',
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Template output file.',
      valueHelp: 'template.yaml|template.json|template.zip|template.tar.gz',
    );
  }

  String? get argDirectory => argResults!['directory'];

  String? get argOutput => argResults!['output'];

  @override
  FutureOr<bool> run() async {
    var directory = argDirectory;
    var output = argOutput;
    var ignore = argIgnore;
    var regexp = parseRegExp();

    if (directory == null) {
      showErrorOptionNotProvided('directory');
    }

    if (output == null) {
      showErrorOptionNotProvided('output');
    }

    File outputFile = File(output!).absolute;

    if (outputFile.existsSync()) {
      showError("Output File already exists: $outputFile");
    }

    if (hasError) {
      return false;
    }

    print(cliTitle);

    print('\nTEMPLATE:\n  $directory');

    var template = await loadTemplate(directory!,
        ignorePath: ignore, ignoreRegexp: regexp);

    print('\nENTRIES(${template.length}):');
    for (var e in template.entriesPaths) {
      print('  > $e');
    }

    showTemplateInfos(template);

    var ext = TemplateEntry.parseNameExtension(output).toLowerCase();

    dynamic encoded;
    String format;
    if (ext == 'yml' || ext == 'yaml') {
      encoded = template.toYAMLEncoded();
      format = 'YAML';
    } else if (ext == 'zip') {
      var storage = StorageZip();
      await template.saveTo(storage);
      encoded = await storage.compress();
      format = 'Zip';
    } else if (ext == 'tar') {
      var storage = StorageTarGzip();
      await template.saveTo(storage);
      encoded = await storage.compress(compressionLevel: 0);
      format = 'tar';
    } else if (ext == 'gz') {
      var storage = StorageTarGzip();
      await template.saveTo(storage);
      encoded = await storage.compress();

      var pathParts = pack_path.split(outputFile.path);
      if (!pathParts.last.toLowerCase().endsWith('tar.gz')) {
        _log('WARNING', 'Output file without `tar.gz` extension!');
      }

      format = 'tar+Gzip';
    } else {
      encoded = template.toJsonEncoded(pretty: true);
      format = 'JSON';
    }

    print('\n-- Format: $format');

    if (encoded is String) {
      outputFile.writeAsStringSync(encoded);
    } else {
      outputFile.writeAsBytesSync(encoded);
    }

    print(
        '\n-- Saved Template> size: ${outputFile.lengthSync()} ; path: ${outputFile.path}\n');

    return true;
  }
}
