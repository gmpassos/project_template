import 'dart:io';

import 'package:project_template/src/project_template_storage_io.dart';
import 'package:yaml_writer/yaml_writer.dart';

void main() async {
  var currentDir = Directory.current.absolute;

  var exampleDir = currentDir.path.endsWith('example')
      ? currentDir
      : Directory('${currentDir.path}/example');

  assert(
      exampleDir.existsSync(), "Can't resolve example directory: $exampleDir");

  var templateDir = 'template-example';

  var storage = StorageIO.directory(exampleDir, templateDir)
    ..ignoreFiles.add('.DS_Store');

  print(storage);

  print('----------------------------------------------------');

  var files = storage.listFiles();

  for (var file in files) {
    print('- $file \t-> ${file.directoryAbsolute}');
  }

  print('----------------------------------------------------');

  var template = await storage.loadTemplate();

  var templateVariables = template.parseTemplateVariables();

  print('Variables:\n  $templateVariables\n');

  var manifest = template.getManifest();

  print('Manifest:\n');

  print(
    YamlWriter()
        .write(manifest)
        .split(RegExp(r'[\r\n]'))
        .map((l) => '  $l')
        .join('\n'),
  );

  print('----------------------------------------------------');

  print(template.toYAMLEncoded());

  print('----------------------------------------------------');

  var variables = {
    'project_name': 'Console Simple',
    'project_name_dir': 'console_simple',
    'homepage': 'https://console-simple.domain',
  };

  var templateResolved = template.resolve(variables);

  print(templateResolved.toYAMLEncoded());

  //// Save `templateResolved` to `example/template-generated`:
  // var storageSave = StorageIO.directory(exampleDir);
  // templateResolved.saveTo(storageSave, 'template-generated');
}
