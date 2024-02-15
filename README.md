# project_template

[![pub package](https://img.shields.io/pub/v/project_template.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/project_template)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/project_template)](https://app.codecov.io/gh/gmpassos/project_template)
[![Dart CI](https://github.com/gmpassos/project_template/actions/workflows/dart.yml/badge.svg?branch=master)](https://github.com/gmpassos/project_template/actions/workflows/dart.yml)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/project_template?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/project_template/latest?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/project_template?logo=git&logoColor=white)](https://github.com/gmpassos/project_template/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/project_template?logo=github&logoColor=white)](https://github.com/gmpassos/project_template/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/project_template?logo=github&logoColor=white)](https://github.com/gmpassos/project_template)
[![License](https://img.shields.io/github/license/gmpassos/project_template?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/project_template/blob/master/LICENSE)

A tool to generate project templates and file trees for any programming language or framework.

# Template Format

To define a template just declare a file tree where variables will be in the format
`___VAR_NAME___`. Variables will be detected in file paths and
in file contents.

Example of a Template file tree:
```
___project_name_dir___/.gitignore
___project_name_dir___/bin/___project_name_dir___.dart
___project_name_dir___/CHANGELOG.md
___project_name_dir___/project_template.yaml
___project_name_dir___/pubspec.yaml
___project_name_dir___/README.md
```

Content example for the `README.md` entry above:

```markdown
# ___project_name___

___project_description___

## Usage

CLI:

`$> ___project_name_dir___ -h`

## See Also

- ___homepage___

```

## Project Manifest

You can declare a project manifest at `project_template.yaml`:

```yaml
project_name:
  description: The name of the project.
  example: Simple App

project_name_dir:
  description: The project directory name.
  example: simple_app

project_description:
  description: The project description for `pubspec.yaml`.
  example: A simple project.
  default: A project from template.
```

- Variables with a `default` value won't be mandatory when
  using the CLI command `create`.

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
    - Zip file: `path/to/template-x.zip`
    - Tar+gZip file: `path/to/template-x.tar.gz`
    - Tar file: `path/to/template-x.tar`
    - JSON file: `path/to/template-x.json`
    - YAML file: `path/to/template-x.yaml`

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

Create/build a file tree from a Template:

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
* -o: The output directory/zip/tar.gz (where the resolve project file tree will be generated).
    * Output types:
        - Directory: `path/to/template-directory`
        - Zip file: `path/to/template-x.zip`
        - Tar+gZip file: `path/to/template-x.tar.gz`
        - Tar file: `path/to/template-x.tar`

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

## CLI Library Usage

The CLI classes, based on [Command][args_command] (used with [CommandRunner][args_command_runner]) of package [args][pack_args],
are also exposed to be integrated with other projects and other CLI tools.

Here's an example of a `tool-x` using `project_template_cli`:

```dart
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:project_template/project_template_cli.dart';

void _consolePrinter(Object? o) {
  print(o);
}

const String cliTitle = '[Tool-X/${Template.version}]';

void main(List<String> args) async {
  
  var commandRunner =
      CommandRunner<bool>('tool-x', '$cliTitle - CLI Tool')
        ..addCommand(CommandInfo(cliTitle, _consolePrinter))
        ..addCommand(CommandCreate(cliTitle, _consolePrinter))
        ..addCommand(CommandPrepare(cliTitle, _consolePrinter));
  
  var ok = await commandRunner.run(args) ;

  exit(ok ? 0 : 1);
}
```

[pack_args]: https://pub.dev/packages/args
[args_command]: https://pub.dev/documentation/args/latest/command_runner/Command-class.html
[args_command_runner]: https://pub.dev/documentation/args/latest/command_runner/CommandRunner-class.html

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/project_template/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
