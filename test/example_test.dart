/*
 * Copyright 2026 Infradise Inc.
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
  for (var entity in exampleDir.listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final tags = <String>['example'];

      // Cluster II - Failover, Redirection
      if (entity.path.endsWith('cluster_redirection_example.dart') ||
          entity.path.endsWith('cluster_failover_stress_test.dart') ||
          // Auth: SSL/TLS
          entity.path.endsWith('cluster_ssl_cloud.dart') ||
          entity.path.endsWith('cluster_ssl_self_signed.dart') ||
          entity.path.endsWith('valkey_ssl_cloud.dart') ||
          entity.path.endsWith('valkey_ssl_self_signed.dart')) {
        // tags.add('skip_example');
        continue;
      }

      // Cluster I, No-auth
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
