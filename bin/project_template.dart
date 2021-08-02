import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:project_template/project_template_cli.dart';

void _consolePrinter(Object? o) {
  print(o);
}

const String cliTitle = '[Project_Template/${Template.version}]';

void showVersion() {
  print('Project_Template/${Template.version} - CLI Tool');
}

void main(List<String> args) async {
  var commandRunner =
      CommandRunner<bool>('project_template', '$cliTitle - CLI Tool')
        ..addCommand(CommandInfo(cliTitle, _consolePrinter))
        ..addCommand(CommandCreate(cliTitle, _consolePrinter))
        ..addCommand(CommandPrepare(cliTitle, _consolePrinter));

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
