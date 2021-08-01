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

To prepare a Template from a directory:

```bash
  $> project_template prepare -d example/template-example -r ".DS_Store$" -o /tmp/template-x.json
```

* -d: The template directory.
* -r: A `RegExp` of a file path to ignore.
* -o: The template file, to be used by `create` command (below).

To show information about a template:

```bash
  $> project_template info -t /tmp/template-x.json
```

To create a file tree from a Template:

```bash
  $> project_template create -t /tmp/template-x.json -p project_name_dir=foo -p project_name=Foo -p "project_description=Foo project." -p homepage=http://foo.com -o /tmp/project-x
```

* -t: The template file.
* -p: A template property/variable definition.
* -o: The output directory, where the project (file tree) will be generated.

## Library Usage

A simple library usage example:

```dart
import 'package:project_template/project_template.dart';

void main() async {
  

}

```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/project_template/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
