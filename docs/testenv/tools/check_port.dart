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

import 'dart:io';

void usage() {
  print('Usage: dart script.dart <start_port> <end_port>');
  print('Example: dart script.dart 7001 7006');
  exit(1);
}

Future<void> printOutput(int port, String status, String output) async {
  print('Checking port $port... $status');
  if (output.isNotEmpty) {
    final pidResult = await Process.run(
      'bash',
      ['-c', "lsof -nP | grep ':$port' | awk '{print \$2}' | sort -u"],
    );
    final pid = pidResult.stdout.toString().trim();
    if (pid.isNotEmpty) {
      final procResult = await Process.run('ps', ['-p', pid, '-o', 'comm=']);
      print(procResult.stdout.toString().trim());
    }
    print('');
  }
}

Future<void> checkPorts(int start, int end) async {
  if (start > end) {
    print('Error: start_port must be <= end_port.');
    usage();
  }

  for (var port = start; port <= end; port++) {
    final result = await Process.run('lsof', ['-i', ':$port']);
    final output = result.stdout.toString().trim();
    final status = output.isNotEmpty ? 'in use' : 'available';
    await printOutput(port, status, output);
  }
}

void detectOS() {
  final os = Platform.operatingSystem;
  String osType;
  switch (os) {
    case 'linux':
      osType = 'Linux';
      break;
    case 'macos':
      osType = 'macOS';
      break;
    case 'windows':
      osType = 'Windows';
      break;
    default:
      osType = 'UNKNOWN';
  }

  if (osType == 'macOS') {
    noticeToMacOS();
  } else if (osType == 'UNKNOWN') {
    print('Error: Unsupported Operating System. Terminating script.');
    exit(1);
  }
}

void noticeToMacOS() {
  print(
      'On macOS, port 7000 is reserved by the system (ControlCenter/AirPlay).');
  print('Please start your Valkey cluster from port 7001 instead.');
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    usage();
  }

  detectOS();

  final start = int.tryParse(args[0]);
  final end = int.tryParse(args[1]);

  if (start == null || end == null) {
    print('Error: Ports must be numeric.');
    usage();
  }

  await checkPorts(start!, end!);
}
