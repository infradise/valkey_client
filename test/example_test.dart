// This file runs all example/*.dart files as tests.
// Usage:
//   dart test --tags example
//     → Runs only the tests tagged as "example" (i.e., executes example/*.dart files).
//
//   dart test --exclude-tags example
//     → Runs all other tests while excluding those tagged as "example".
//
// Add or modify example Dart files in the /example directory,
// and they will be automatically validated here.

import 'dart:io';
import 'package:test/test.dart';

void main() {
  final exampleDir = Directory('example');
  for (var entity in exampleDir.listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final tags = <String>['example'];

      if (entity.path.endsWith('cluster_redirection_example.dart')) {
        // tags.add('skip_example');
        continue;
      }

      test('Run ${entity.path}', () async {
        final result = await Process.run(
          'dart',
          [entity.path],
        );
        expect(result.exitCode, 0, reason: result.stderr);
      }, tags: tags);
    }
  }
}
