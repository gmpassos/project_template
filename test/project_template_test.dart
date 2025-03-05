import 'dart:convert' as dart_convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as pack_path;
import 'package:project_template/project_template.dart';
import 'package:test/test.dart';

import 'project_template_test_helper.dart';

void main() {
  group('TemplateEntry', () {
    setUp(() {});

    test('basic', () {
      var templateEntry = TemplateEntry('foo', 'file.txt', 'text', 'Hello!');

      expect(templateEntry.path, equals('foo/file.txt'));

      expect(templateEntry.isEqualsPath('foo/file.txt'), isTrue);
      expect(templateEntry.isEqualsPath('foo/file2.txt'), isFalse);

      expect(templateEntry.isEqualsDirectoryAndName('foo', 'file.txt'), isTrue);
      expect(
          templateEntry.isEqualsDirectoryAndName(['foo'], 'file.txt'), isTrue);

      expect(templateEntry.isEqualsDirectoryAndName('', 'file.txt'), isFalse);
      expect(templateEntry.isEqualsDirectoryAndName([''], 'file.txt'), isFalse);
      expect(templateEntry.isEqualsDirectoryAndName('x', 'file.txt'), isFalse);
      expect(
          templateEntry.isEqualsDirectoryAndName(['x'], 'file.txt'), isFalse);

      expect(templateEntry.isRootEntry, isFalse);

      expect(
          templateEntry.toJson(),
          equals({
            'directory': 'foo',
            'name': 'file.txt',
            'type': 'text',
            'encode': 'text',
            'content': 'Hello!',
          }));

      expect(
          templateEntry.toJsonEncoded(),
          equals(
              '{"directory":"foo","name":"file.txt","type":"text","encode":"text","content":"Hello!"}'));

      expect(templateEntry.toYAMLEncoded(), equals('''
directory: "foo"
name: "file.txt"
type: "text"
encode: "text"
content: "Hello!"
'''));

      expect(TemplateEntry.fromJson(templateEntry.toJson()),
          equals(templateEntry));

      expect(TemplateEntry.fromJsonEncoded(templateEntry.toJsonEncoded()),
          equals(templateEntry));

      expect(TemplateEntry.from(templateEntry.toJson()), equals(templateEntry));
    });

    test('root entry', () {
      var templateEntry = TemplateEntry('', 'file.txt', 'text', 'Hello!');

      expect(templateEntry.path, equals('file.txt'));

      expect(templateEntry.isEqualsPath('file.txt'), isTrue);
      expect(templateEntry.isEqualsPath('foo/file2.txt'), isFalse);

      expect(templateEntry.isEqualsDirectoryAndName('', 'file.txt'), isTrue);
      expect(templateEntry.isEqualsDirectoryAndName([], 'file.txt'), isTrue);
      expect(templateEntry.isEqualsDirectoryAndName([''], 'file.txt'), isTrue);

      expect(templateEntry.isEqualsDirectoryAndName('x', 'file.txt'), isFalse);
      expect(
          templateEntry.isEqualsDirectoryAndName(['x'], 'file.txt'), isFalse);

      expect(templateEntry.isRootEntry, isTrue);

      expect(
          templateEntry.toJson(),
          equals({
            'directory': '',
            'name': 'file.txt',
            'type': 'text',
            'encode': 'text',
            'content': 'Hello!',
          }));

      expect(
          templateEntry.toJsonEncoded(),
          equals(
              '{"directory":"","name":"file.txt","type":"text","encode":"text","content":"Hello!"}'));
    });

    test('contentBase64', () {
      var templateEntry = TemplateEntry.contentBase64('foo', 'file.txt', 'raw',
          dart_convert.base64.encode(dart_convert.utf8.encode('Hello!!!')));
      expect(
          templateEntry.toJson(),
          equals({
            'directory': 'foo',
            'name': 'file.txt',
            'type': 'raw',
            'encode': 'base64',
            'content': 'SGVsbG8hISE=',
          }));
    });

    test('resolve', () {
      var templateEntry = TemplateEntry('foo', 'file-___ID___.txt', 'text',
          'Title: ___doc/title___\n___doc/desc___');

      var variables = {
        'ID': 123,
        'doc': {
          'title': 'WOW!',
          'desc': 'Some desc...',
        }
      };
      var map = templateEntry.resolveToJsonMap(variables);

      var expectedJson = {
        'directory': 'foo',
        'name': 'file-123.txt',
        'type': 'text',
        'encode': 'text',
        'content': 'Title: WOW!\n'
            'Some desc...'
      };

      expect(map, equals(expectedJson));

      var r1 = templateEntry.resolve(variables);
      expect(r1.toJson(), equals(expectedJson));

      expect(r1 == templateEntry.resolve(variables), isTrue);
    });
  });

  group('Template', () {
    setUp(() {});

    test('basic', () {
      var template = Template();

      var templateEntry1 = TemplateEntry('', 'root.txt', 'text', 'Hi!');
      var templateEntry2 = TemplateEntry('foo', 'file1.txt', 'text', 'Hello!');
      var templateEntry3 = TemplateEntry('foo', 'file2.txt', 'text', 'World!');

      expect(template.isEmpty, isTrue);
      expect(template.isNotEmpty, isFalse);
      expect(template.entriesPaths, equals(<String>{}));

      template.addEntry(templateEntry1);
      template.addEntry(templateEntry2);
      template.addEntry(templateEntry3);

      expect(template.isEmpty, isFalse);
      expect(template.isNotEmpty, isTrue);
      expect(template.length, equals(3));

      expect(template.entries.length, equals(3));

      expect(template.entriesPaths,
          equals({'root.txt', 'foo/file1.txt', 'foo/file2.txt'}));

      expect(template.getEntryByPath('root.txt')!.path, equals('root.txt'));
      expect(template.getEntryByPath('foo/file1.txt')!.path,
          equals('foo/file1.txt'));
      expect(template.getEntryByPath('foo/file2.txt')!.path,
          equals('foo/file2.txt'));

      expect(template.getEntryByPath('foo/file3.txt'), isNull);

      expect(
          template.toJsonMap(),
          equals([
            {
              'directory': '',
              'name': 'root.txt',
              'type': 'text',
              'encode': 'text',
              'content': 'Hi!'
            },
            {
              'directory': 'foo',
              'name': 'file1.txt',
              'type': 'text',
              'encode': 'text',
              'content': 'Hello!'
            },
            {
              'directory': 'foo',
              'name': 'file2.txt',
              'type': 'text',
              'encode': 'text',
              'content': 'World!'
            }
          ]));

      var expectedJson = '['
          '{"directory":"","name":"root.txt","type":"text","encode":"text","content":"Hi!"},'
          '{"directory":"foo","name":"file1.txt","type":"text","encode":"text","content":"Hello!"},'
          '{"directory":"foo","name":"file2.txt","type":"text","encode":"text","content":"World!"}'
          ']';

      expect(template.toJsonEncoded(), equals(expectedJson));

      expect(Template.from(template.toJsonMap()) == template, isTrue);
      expect(Template.from(template.toJsonEncoded()) == template, isTrue);

      expect(
          Template.from(template.toJsonEncoded()).hashCode == template.hashCode,
          isTrue);
    });

    test('basic2', () {
      var template = Template();

      var templateEntry2 = TemplateEntry('foo', 'file1.txt', 'text', 'Hello!');
      var templateEntry3 = TemplateEntry('foo', 'file2.txt', 'text', 'World!');

      template.addEntry(templateEntry2);
      template.addEntry(templateEntry3);

      expect(template.isEmpty, isFalse);
      expect(template.isNotEmpty, isTrue);
      expect(template.length, equals(2));

      expect(template.entries.length, equals(2));

      expect(template.entriesPaths, equals({'foo/file1.txt', 'foo/file2.txt'}));

      expect(template.getEntryByPath('foo/file1.txt')!.path,
          equals('foo/file1.txt'));
      expect(template.getEntryByPath('foo/file1.txt')!.contentAsString,
          equals('Hello!'));

      expect(template.getEntryByPath('foo/file2.txt')!.path,
          equals('foo/file2.txt'));
      expect(template.getEntryByPath('foo/file2.txt')!.contentAsBytes,
          equals(dart_convert.utf8.encode('World!')));

      expect(template.getEntryByPath('foo/file3.txt'), isNull);

      expect(template.mainEntryPath, equals('foo'));

      expect(
          template.toJsonMap(),
          equals([
            {
              'directory': 'foo',
              'name': 'file1.txt',
              'type': 'text',
              'encode': 'text',
              'content': 'Hello!'
            },
            {
              'directory': 'foo',
              'name': 'file2.txt',
              'type': 'text',
              'encode': 'text',
              'content': 'World!'
            }
          ]));

      var expectedJson = '['
          '{"directory":"foo","name":"file1.txt","type":"text","encode":"text","content":"Hello!"},'
          '{"directory":"foo","name":"file2.txt","type":"text","encode":"text","content":"World!"}'
          ']';

      expect(template.toJsonEncoded(), equals(expectedJson));

      expect(Template.from(template.toJsonMap()) == template, isTrue);
      expect(Template.from(template.toJsonEncoded()) == template, isTrue);

      expect(
          Template.from(template.toJsonEncoded()).hashCode == template.hashCode,
          isTrue);
    });

    test('resolve', () {
      var template = Template([
        TemplateEntry('', '___root___.txt', 'text', 'Hi!'),
        TemplateEntry('___pack___', 'file___fid___.txt', 'text',
            '___hello___ Map: ___map/a___, ___map/b___ ; List: ___list/0___, ___list/1___'),
        TemplateEntry('', 'project_template.json', 'text',
            '{"root":{"description": "Root file"}, "pack":{"description": "Pack dir"}}')
      ]);

      var variables = {
        'fid': 123,
        'root': 'foo-project',
        'pack': 'basic',
        'hello': 'HI!',
        'map': {'a': 1, 'b': 2},
        'list': [10, 20],
      };

      expect(
          template.parseTemplateVariables(),
          equals({
            'root',
            'pack',
            'fid',
            'hello',
            'map/a',
            'map/b',
            'list/0',
            'list/1'
          }));

      expect(
          template.getManifest(),
          equals({
            'root': {'description': 'Root file'},
            'pack': {'description': 'Pack dir'}
          }));

      expect(template.getNotDefinedVariables(variables), equals([]));

      expect(
          template.getNotDefinedVariables(Map.from(variables)..remove('fid')),
          equals(['fid']));

      var map = template.resolveToJsonMap(variables);

      var expectedJson = [
        {
          'directory': '',
          'name': 'foo-project.txt',
          'type': 'text',
          'encode': 'text',
          'content': 'Hi!'
        },
        {
          'directory': 'basic',
          'name': 'file123.txt',
          'type': 'text',
          'encode': 'text',
          'content': 'HI! Map: 1, 2 ; List: 10, 20'
        }
      ];

      expect(map, equals(expectedJson));

      print('---------------------------------------');
      print(template.toYAMLEncoded());
      print('---------------------------------------');

      expect(template.toYAMLEncoded(), equals('''
- directory: ""
  name: "___root___.txt"
  type: "text"
  encode: "text"
  content: "Hi!"
- directory: "___pack___"
  name: "file___fid___.txt"
  type: "text"
  encode: "text"
  content: "___hello___ Map: ___map/a___, ___map/b___ ; List: ___list/0___, ___list/1___"
- directory: ""
  name: "project_template.json"
  type: "text"
  encode: "text"
  content: "{\\"root\\":{\\"description\\": \\"Root file\\"}, \\"pack\\":{\\"description\\": \\"Pack dir\\"}}"
'''));

      expect(template.mainEntryPath, equals(''));

      var r1 = template.resolve(variables);
      expect(r1.toJsonMap(), equals(expectedJson));

      var r2 = template.resolve(variables);
      expect(r1 == r2, isTrue);

      expect(r1.hashCode == r2.hashCode, isTrue);
    });
  });

  group('Storage', () {
    setUp(() {});

    test('basic', () async {
      var storage = StorageMemory();

      expect(storage.listFiles(), isEmpty);

      storage.addFile('foo', 'file1.txt', 'File1');
      storage.addFile('foo', 'file2.txt', 'File2');

      var files = storage.listFiles();

      expect(files.length, equals(2));

      expect(files[0].path, equals('foo/file1.txt'));
      expect(files[1].path, equals('foo/file2.txt'));

      expect(await files[0].getContentAsString(), equals('File1'));
      expect(await files[1].getContentAsString(), equals('File2'));

      expect(identical(storage.getFile('foo', 'file2.txt'), files[1]), isTrue);

      expect(storage.removeFile('foo', 'file2.txt'), isTrue);

      var files2 = storage.listFiles();
      expect(files2.length, equals(1));
      expect(files[0].path, equals('foo/file1.txt'));
    });

    test('FileType extension', () async {
      expect(FileType.getExtensionType('txt'), equals('text/plain'));
      expect(FileType.getExtensionType('text'), equals('text/plain'));
      expect(FileType.getExtensionType('html'), equals('text/html'));

      expect(FileType.getExtensionType('json'), equals('application/json'));

      expect(FileType.getExtensionType('gif'), equals('image/gif'));
      expect(FileType.getExtensionType('png'), equals('image/png'));
      expect(FileType.getExtensionType('jpeg'), equals('image/jpeg'));
      expect(FileType.getExtensionType('jpg'), equals('image/jpeg'));

      expect(
          FileType.getExtensionType('bin'), equals('application/octet-stream'));

      expect(FileType.byExtension('json').isJsonType, isTrue);
      expect(FileType.byExtension('json').isTextType, isTrue);
      expect(FileType.byExtension('json').isBinaryType, isFalse);

      expect(FileType.byExtension('png').isTextType, isFalse);
      expect(FileType.byExtension('png').isBinaryType, isTrue);
    });

    test('zip', () async {
      var zipFile = File(pack_path.join(
        getExampleDirectoryPath(),
        'template-example.zip',
      ));

      var compressed = zipFile.readAsBytesSync();

      await _testCompressed(compressed, (d) => StorageZip.fromCompressed(d));
    });

    test('tar+gzip', () async {
      var tarGzFile = File(pack_path.join(
        getExampleDirectoryPath(),
        'template-example.tar.gz',
      ));

      var compressed = tarGzFile.readAsBytesSync();

      await _testCompressed(
          compressed, (d) => StorageTarGzip.fromCompressed(d));
    });
  });
}

Future<void> _testCompressed(Uint8List compressedData,
    StorageCompressed Function(Uint8List data) decompressor) async {
  print('>> compressedData: ${compressedData.length}');

  var storage = decompressor(compressedData);

  var filesPaths = storage.listFilesPaths()..sort();
  print(filesPaths);

  var expectedFilesPaths = [
    '___project_name_dir___/.gitignore',
    '___project_name_dir___/CHANGELOG.md',
    '___project_name_dir___/README.md',
    '___project_name_dir___/analysis_options.yaml',
    '___project_name_dir___/bin/___project_name_dir___.dart',
    '___project_name_dir___/project_template.yaml',
    '___project_name_dir___/pubspec.yaml'
  ];

  expect(filesPaths, equals(expectedFilesPaths));

  var compressedData2 = await storage.compress();

  print('>> compressedData2: ${compressedData2.length}');

  var storage2 = decompressor(compressedData2);

  var filesPaths2 = storage2.listFilesPaths()..sort();
  print(filesPaths2);

  expect(filesPaths2, equals(expectedFilesPaths));
}
