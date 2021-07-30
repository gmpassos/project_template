import 'dart:convert' as dart_convert;

import 'package:project_template/project_template.dart';
import 'package:test/test.dart';

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
directory: 'foo'
name: 'file.txt'
type: 'text'
encode: 'text'
content: 'Hello!'
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
          dart_convert.base64.encode('Hello!!!'.codeUnits));
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

    test('resolve', () {
      var template = Template([
        TemplateEntry('', '___root___.txt', 'text', 'Hi!'),
        TemplateEntry('___pack___', 'file___fid___.txt', 'text',
            '___hello___ Map: ___map/a___, ___map/b___ ; List: ___list/0___, ___list/1___')
      ]);

      var variables = {
        'root': 'foo-project',
        'pack': 'basic',
        'hello': 'HI!',
        'map': {'a': 1, 'b': 2},
        'list': [10, 20],
      };

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
          'name': 'file.txt',
          'type': 'text',
          'encode': 'text',
          'content': 'HI! Map: 1, 2 ; List: 10, 20'
        }
      ];

      expect(map, equals(expectedJson));

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

    test('basic', () async {
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
  });
}
