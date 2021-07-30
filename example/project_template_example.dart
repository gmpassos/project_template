import 'dart:io';

import 'package:project_template/src/project_template_storage_io.dart';

void main() async {
  var currentDir = Directory.current;
  var subDir = 'template-example';

  if (!currentDir.path.endsWith('example')) {
    subDir = 'example/$subDir';
  }

  var storage = StorageIO.directory(currentDir, subDir)
    ..ignoreFiles.add('.DS_Store');

  print(storage);

  var files = storage.listFiles();

  for (var file in files) {
    print('- $file \t-> ${file.directoryAbsolute}');
  }

  var template = await storage.loadTemplate();

  var templateVariables = template.parseTemplateVariables();

  print('Variables: $templateVariables');

  print('----------------------------------------------------');
  print(template.toYAMLEncoded());

  var templateResolved = template.resolve({'project_name': 'console_simple'});

  print('----------------------------------------------------');
  print(templateResolved.toYAMLEncoded());
}
