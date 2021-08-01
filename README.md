# project_template

[![pub package](https://img.shields.io/pub/v/project_template.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/project_template)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/project_template)](https://app.codecov.io/gh/gmpassos/project_template)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/project_template/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/project_template/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/project_template?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/project_template/latest?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/project_template?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/project_template?logo=github&logoColor=white)](https://github.com/gmpassos/project_template/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/project_template?logo=github&logoColor=white)](https://github.com/gmpassos/project_template)
[![License](https://img.shields.io/github/license/gmpassos/project_template?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/project_template/blob/master/LICENSE)

A tool to generate project templates and file trees for any programming language or framework.

# Usage

The package can be used as a *__command-line interface (CLI)__* or as a *__Dart library__* to be imported
in other projects or other CLI tools.

## CLI

You can use the built-in command-line: `project_template`

To activate it globally:

```bash
 $> dart pub global activate project_template
```

Now you can use the CLI directly:

```bash
  $> project_template --help
```

## CLI Commands

### prepare:

Prepare a Template from a directory into a single file. The resulting file should be used by command `create`.

Prepare to a `JSON` file:

```bash
  $> project_template prepare -d example/template-example -r ".DS_Store$" -o /tmp/template-x.json
```

Prepare to a `Zip` file:

```bash
  $> project_template prepare -d example/template-example -r ".DS_Store$" -o /tmp/template-x.zip
```

* -d: The Template directory/source.
  * Source types:
    - Directory: `path/to/template-directory`
    - Zip file: `path/to/template-x.zip`
    - Tar+gZip file: `path/to/template-x.tar.gz`
    - Tar file: `path/to/template-x.tar`
* -r: A `RegExp` of a file path to ignore.
* -o: The prepared Template output file (to be used by `create` command below).
  * Output File formats:
    - JSON file: `path/to/template-x.json`
    - YAML file: `path/to/template-x.yaml`
    - Zip file: `path/to/template-x.zip`
    - Tar+gZip file: `path/to/template-x.tar.gz`
    - Tar file: `path/to/template-x.tar`

### info:

Show information about a Template (files, variables and manifest):

```bash
  $> project_template info -t /tmp/template-x.zip
```

* -t: The template path.
  * Path types:
    - Directory: `path/to/template-directory`
    - Zip file: `path/to/template-x.zip`
    - Tar+gZip file: `path/to/template-x.tar.gz`
    - Tar file: `path/to/template-x.tar`
    - JSON file: `path/to/template-x.json`
    - YAML file: `path/to/template-x.yaml`


### create: 

Create a file tree from a Template:

```bash
  $> project_template create -t /tmp/template-x.zip -p project_name_dir=foo -p project_name=Foo -p "project_description=Foo project." -p homepage=http://foo.com -o /tmp/project-x
```

* -t: The template path.
    * Path types:
        - Directory: `path/to/template-directory`
        - Zip file: `path/to/template-x.zip`
        - Tar+gZip file: `path/to/template-x.tar.gz`
        - Tar file: `path/to/template-x.tar`
        - JSON file: `path/to/template-x.json`
        - YAML file: `path/to/template-x.yaml`
* -p: A template property/variable definition.
* -o: The output directory, where the project (file tree) will be generated.

## Library Usage

Here's a simple example that loads a `Template` from a directory,
resolves/builds it (with the `variables` definitions)
and then saves it to a new directory.

```dart
import 'dart:io';

import 'package:project_template/src/project_template_storage_io.dart';

void main() async {

  var sourceDir = Directory('path/to/template-dir');
  
  // The template storage:
  var storage = StorageIO.directory(sourceDir)
    ..ignoreFiles.add('.DS_Store');

  // List files at storage:
  var files = storage.listFiles();

  // Load a Template using storage files:
  var template = await storage.loadTemplate();

  // Parse the Template files and identify the variables:
  var variables = template.parseTemplateVariables();

  // Return the Template manifest (`project_template.yaml`).
  var manifest = template.getManifest();

  // Define the variables to build a template: 
  var variables = {
    'project_name': 'Project X',
    'project_name_dir': 'project_x',
    'homepage': 'https://project-x.domain',
  };

  // Resolve/build the template:
  var templateResolved = template.resolve(variables);

  // Print all Template files as a YAML document:
  print(templateResolved.toYAMLEncoded());

  var saveDir = Directory('/path/to/workspace');
  
  // Save `templateResolved` files to `/path/to/workspace/project_x`:
  var storageSave = StorageIO.directory(saveDir);
  templateResolved.saveTo(storageSave, 'project_x');
  
}
```

See the [example] for more.

To use this library in your code, see the [API documentation][api_doc].

[api_doc]: https://pub.dev/documentation/project_template/latest/
[example]: ./example

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/project_template/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
