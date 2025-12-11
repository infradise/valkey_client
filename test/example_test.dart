import 'dart:io';
import 'package:test/test.dart';

void main() {
  final exampleDir = Directory('example');
  for (var entity in exampleDir.listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      test('Run ${entity.path}', () async {
        final result = await Process.run(
          'dart',
          [entity.path],
        );
        expect(result.exitCode, 0, reason: result.stderr);
      });
    }
  }
}
