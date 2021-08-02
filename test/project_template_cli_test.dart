import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as pack_path;
import 'package:project_template/project_template_cli.dart';
import 'package:test/test.dart';

import 'project_template_test_helper.dart';

const String executableName = 'project_template_test';
const String executableDesc = 'Test - CLI Tool';
const String cliTitle = '[TestCLI]';

void main() {
  group('CommandInfo', () {
    setUp(() {});

    CommandRunner createCommandRunner(List<String> consoleOutput) =>
        CommandRunner<bool>(executableName, executableDesc)
          ..addCommand(CommandInfo(cliTitle, (o) => consoleOutput.add('$o')));

    test('info -h', () async {
      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      var argsLine = 'info -h';

      var ok = (await commandRunner.runArgsLine(argsLine)) ?? false;
      var fullConsole = console.join('\n');
      //print(fullConsole);

      expect(ok, isFalse);

      expect(fullConsole, contains(cliTitle));
      expect(fullConsole, contains(executableName));

      expect(fullConsole, contains('info'));
    });

    test('info example/template-example', () async {
      var exampleDir = getExampleDirectoryPath();

      var templatePath = '$exampleDir/template-example';

      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      await _testCommandInfoTemplate(commandRunner, console, templatePath, 8);
    });

    test('info example/template-example.zip', () async {
      var exampleDir = getExampleDirectoryPath();

      var templatePath = '$exampleDir/template-example.zip';

      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      await _testCommandInfoTemplate(commandRunner, console, templatePath, 7);
    });

    test('info example/template-example.tar.gz', () async {
      var exampleDir = getExampleDirectoryPath();

      var templatePath = '$exampleDir/template-example.tar.gz';

      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      await _testCommandInfoTemplate(commandRunner, console, templatePath, 7);
    });
  });

  group('CommandPrepare', () {
    setUp(() {});

    CommandRunner createCommandRunner(List<String> consoleOutput) =>
        CommandRunner<bool>(executableName, executableDesc)
          ..addCommand(
              CommandPrepare(cliTitle, (o) => consoleOutput.add('$o')));

    test('prepare -h', () async {
      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      var argsLine = 'prepare -h';

      var ok = (await commandRunner.runArgsLine(argsLine)) ?? false;
      var fullConsole = console.join('\n');
      //print(fullConsole);

      expect(ok, isFalse);

      expect(fullConsole, contains(cliTitle));
      expect(fullConsole, contains(executableName));

      expect(fullConsole, contains('prepare'));
    });

    test('prepare example/template-example .zip', () async {
      await _testPrepareTemplate(createCommandRunner, 'zip', 'Zip');
    });

    test('prepare example/template-example .tar.gz', () async {
      await _testPrepareTemplate(createCommandRunner, 'tar.gz', 'tar+Gzip');
    });

    test('prepare example/template-example .tar', () async {
      await _testPrepareTemplate(createCommandRunner, 'tar', 'tar');
    });

    test('prepare example/template-example .json', () async {
      await _testPrepareTemplate(createCommandRunner, 'json', 'JSON');
    });

    test('prepare example/template-example .yaml', () async {
      await _testPrepareTemplate(createCommandRunner, 'yaml', 'YAML');
    });
  });

  group('CommandCreate', () {
    setUp(() {});

    CommandRunner createCommandRunner(List<String> consoleOutput) =>
        CommandRunner<bool>(executableName, executableDesc)
          ..addCommand(CommandCreate(cliTitle, (o) => consoleOutput.add('$o')));

    test('create -h', () async {
      var console = <String>[];
      var commandRunner = createCommandRunner(console);

      var argsLine = 'create -h';

      var ok = (await commandRunner.runArgsLine(argsLine)) ?? false;
      var fullConsole = console.join('\n');
      //print(fullConsole);

      expect(ok, isFalse);

      expect(fullConsole, contains(cliTitle));
      expect(fullConsole, contains(executableName));

      expect(fullConsole, contains('create'));
    });

    test('create example/template-example .zip -> zip', () async {
      await _testCreateProject(createCommandRunner, 'zip', 'zip');
    });

    test('create example/template-example .tar.gz -> .tar.gz', () async {
      await _testCreateProject(createCommandRunner, 'tar.gz', 'tar.gz');
    });

    test('create example/template-example zip -> dir', () async {
      await _testCreateProject(createCommandRunner, 'zip', '');
    });

    test('create example/template-example dir -> zip', () async {
      await _testCreateProject(createCommandRunner, '', 'zip');
    });

    test('create example/template-example json -> zip', () async {
      await _testCreateProject(createCommandRunner, 'json', 'zip');
    });

    test('create example/template-example yaml -> zip', () async {
      await _testCreateProject(createCommandRunner, 'yaml', 'zip');
    });

    test('create example/template-example .zip -> zip [no properties error]',
        () async {
      await _testCreateProject(createCommandRunner, 'zip', 'zip', true);
    });
  });
}

Future<void> _testCommandInfoTemplate(CommandRunner<dynamic> commandRunner,
    List<String> console, String templatePath, int entriesSize) async {
  var argsLine = 'info -t $templatePath';

  print('COMMAND: $argsLine');

  var ok = (await commandRunner.runArgsLine(argsLine)) ?? false;

  var fullConsole = console.join('\n');
  //print(fullConsole);

  expect(ok, isTrue);

  expect(fullConsole, contains(cliTitle));

  expect(fullConsole, contains('TEMPLATE:'));
  expect(fullConsole, contains(templatePath));

  expect(fullConsole, contains('ENTRIES($entriesSize)'));
  expect(fullConsole, contains('___project_name_dir___/pubspec.yaml'));

  expect(fullConsole, contains('TEMPLATE VARIABLES:'));
  expect(fullConsole, contains('project_name_dir'));
  expect(fullConsole, contains('project_name'));

  expect(fullConsole, contains('MANIFEST:'));
  expect(fullConsole, contains('default: '));
}

Future<void> _testPrepareTemplate(
    CommandRunner<dynamic> Function(List<String> consoleOutput)
        createCommandRunner,
    String ext,
    String format) async {
  var exampleDir = getExampleDirectoryPath();

  var directoryPath = '$exampleDir/template-example';

  var tempDir = Directory.systemTemp.createTempSync('project_template-test');

  var templateOutput = pack_path.join(tempDir.path, 'test-template.$ext');

  var console = <String>[];
  var commandRunner = createCommandRunner(console);

  await _testCommandPrepareTemplate(
      commandRunner, console, directoryPath, templateOutput, 8, format);
}

Future<void> _testCommandPrepareTemplate(
    CommandRunner<dynamic> commandRunner,
    List<String> console,
    String directoryPath,
    String outputPath,
    int entriesSize,
    String format) async {
  var argsLine = 'prepare -d $directoryPath -o $outputPath';

  print('COMMAND: $argsLine');

  var ok = (await commandRunner.runArgsLine(argsLine)) ?? false;

  var fullConsole = console.join('\n');
  //print(fullConsole);

  expect(ok, isTrue);

  expect(fullConsole, contains(cliTitle));

  expect(fullConsole, contains('TEMPLATE:'));
  expect(fullConsole, contains(directoryPath));

  expect(fullConsole, contains('ENTRIES($entriesSize)'));
  expect(fullConsole, contains('___project_name_dir___/pubspec.yaml'));

  expect(fullConsole, contains('TEMPLATE VARIABLES:'));
  expect(fullConsole, contains('project_name_dir'));
  expect(fullConsole, contains('project_name'));

  expect(fullConsole, contains('MANIFEST:'));
  expect(fullConsole, contains('default: '));

  expect(fullConsole, contains('Format: $format'));

  expect(fullConsole, contains('Saved Template> '));
  expect(fullConsole, contains('path: $outputPath'));

  File(outputPath).deleteSync();
}

Future<void> _testCreateProject(
    CommandRunner<dynamic> Function(List<String> consoleOutput)
        createCommandRunner,
    String templateExt,
    String outputExt,
    [bool noProperties = false]) async {
  var exampleDir = getExampleDirectoryPath();

  var templatePath = '$exampleDir/template-example';
  if (templateExt.isNotEmpty) templatePath += '.$templateExt';

  var tempDir =
      Directory.systemTemp.createTempSync('project_template-test').absolute;

  var templateOutput = pack_path.join(tempDir.path, 'test-project-out');
  if (outputExt.isNotEmpty) templateOutput += '.$outputExt';

  var properties = {
    'project_name_dir': 'test_project',
    'project_name': 'Test Project',
    'homepage': 'http://test.domain',
  };

  // Force no properties error:
  if (noProperties) {
    properties.clear();
  }

  var entriesSize = 6;

  // Templates `template-example/`, `template-example.json` and
  // `template-example.yaml` have a `.DS_Store` entry:
  if (templateExt == '' || templateExt == 'json' || templateExt == 'yaml') {
    entriesSize++;
  }

  var console = <String>[];
  var commandRunner = createCommandRunner(console);

  await _testCommandCreateProject(commandRunner, console, templatePath,
      properties, templateOutput, entriesSize, tempDir);

  tempDir.deleteSync();
}

Future<void> _testCommandCreateProject(
    CommandRunner<dynamic> commandRunner,
    List<String> console,
    String templatePath,
    Map<String, String> properties,
    String outputPath,
    int entriesSize,
    Directory directoryScope) async {
  var args = 'create -t $templatePath -o $outputPath'.splitArgs();

  for (var e in properties.entries) {
    args.add('-p');
    args.add('${e.key}=${e.value}');
  }

  print('COMMAND: ${args.join(' ')}');

  var ok = (await commandRunner.run(args)) ?? false;

  var fullConsole = console.join('\n');
  print(fullConsole);

  var noPropertiesError = properties.isEmpty;

  if (noPropertiesError) {
    expect(ok, isFalse);
  } else {
    expect(ok, isTrue);
  }

  expect(fullConsole, contains(cliTitle));

  expect(fullConsole, contains('TEMPLATE:'));
  expect(fullConsole, contains(templatePath));

  expect(fullConsole, contains('TEMPLATE VARIABLES:'));
  expect(fullConsole, contains('project_name_dir'));
  expect(fullConsole, contains('project_name'));

  expect(fullConsole, contains('MANIFEST:'));
  expect(fullConsole, contains('default: '));

  if (noPropertiesError) {
    expect(fullConsole, contains('[ERROR]	Missing properties:'));
  } else {
    expect(fullConsole, contains('DEFINED PROPERTIES:'));

    for (var e in properties.entries) {
      expect(fullConsole, contains('- ${e.key}: ${e.value}'));
    }

    expect(fullConsole, contains('SAVED FILES($entriesSize)'));
    expect(fullConsole, contains('test_project/bin/test_project.dart'));

    expect(fullConsole, contains('Template generated at: $outputPath'));
  }

  print('\n========================');
  print('** Test Cleanup:');

  if (FileSystemEntity.isDirectorySync(outputPath)) {
    deleteDirectory(directoryScope, Directory(outputPath), recursive: true);
  } else {
    deleteFile(directoryScope, File(outputPath));
  }
}

extension _StringExtension on String {
  List<String> splitArgs() => split(RegExp(r'\s+'));
}

extension _CommandRunnerExtension<T> on CommandRunner<T> {
  Future<T?> runArgsLine(String argsLine) => run(argsLine.splitArgs());
}
