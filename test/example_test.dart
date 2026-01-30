/*
 * Copyright 2025-2026 Infradise Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

  // Use recursive: true to include all subdirectories under `example`
  for (var entity in exampleDir.listSync(recursive: true)) {
    // Only consider Dart files
    if (entity is File && entity.path.endsWith('.dart')) {
      final tags = <String>['example'];

      // Cluster II - Failover, Redirection
      // Skip these specific examples
      if (entity.path.endsWith('cluster_redirection_example.dart') ||
          entity.path.endsWith('cluster_failover_stress_test.dart')) {
        // tags.add('skip_example');
        continue;
      }

      // Cluster I, No-auth
      // Run each Dart example as a separate test
      test('Run ${entity.path}', () async {
        final result = await Process.run(
          'dart',
          [entity.path],
        );

        // Expect the process to exit with code 0, otherwise show stderr
        expect(result.exitCode, 0, reason: result.stderr.toString());

        // OR,
        // final stderr = result.stderr;
        // final reason = stderr is List<int> ?
        //   utf8.decode(stderr) : stderr?.toString();
        // expect(result.exitCode, 0, reason: reason);
      }, tags: tags);
    }
  }
}
