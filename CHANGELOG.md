## 1.1.1

- Fix usage of `archive: ^4.0.4`.

- sdk: '>=3.6.0 <4.0.0'

- path: ^1.9.1
- args: ^2.6.0
- collection: ^1.19.0
- yaml: ^3.1.3
- yaml_writer: ^2.1.0
- async_extension: ^1.2.14
- archive: ^4.0.4

- lints: ^5.1.1
- test: ^1.25.15
- dependency_validator: ^5.0.2
- coverage: ^1.11.1

## 1.1.0

Dart 3.3.0 compatibility fixes.

- path: ^1.9.0
- args: ^2.4.2
- collection: ^1.18.0
- yaml: ^3.1.2
- yaml_writer: ^2.0.0
- async_extension: ^1.2.5
- archive: ^3.4.10

- lints: ^3.0.0
  - lint fixes. 
- test: ^1.25.2
- dependency_validator: ^3.2.3
- coverage: ^1.7.2

## 1.0.2

- Library `project_template_cli`:
  - CLI Command classes can be used in other projects now
- Improved CLI tests.
- Added `template-example.json` and `template-example.yaml`.
- `README.md`: added template format description and CLI Library usage.

## 1.0.1

- Added `StorageCompressed`:
  - Zip: StorageZip
  - Tar+Gzip: StorageTarGzip
- CLI:
  - Added support for `.zìp`, `.tar.gz` and `.tar` files. 
- Improved `README.md` CLI commands description.
- archive: ^3.1.2

## 1.0.0

- CLI support.
  - create, info, prepare. 
- Template files support (YAML and JSON).
- Template manifest support.
- Initial version.
