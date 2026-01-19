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

import 'package:valkey_client/valkey_client.dart' show ValkeyLogger;

ValkeyLogger logger = ValkeyLogger('Built-in Logger Example');

void main() {
  print('--- PART I. SHOW ALL MESSAGES ---');

  // This assures enabling all log levels (default: false)
  logger.setEnableValkeyLog(
      true); // Or use logger.setLogLevelFine() instead of this.

  showAllLogs(); // Show all messages regardless of log level.
  logger.setEnableValkeyLog(false);

  print('');

  print('--- PART II. SHOW ONLY MESSAGES WITH SPECIFIC LOG LEVEL ---');
  showAllLogs();
}

void showAllLogs() {
  // By default built-in logger is disabled (off)
  print('--- set OFF ---');
  messages();

  print('--- set FINE ---');
  logger.setLogLevelFine();
  messages();

  print('--- set INFO ---');
  logger.setLogLevelInfo();
  messages();

  print('--- set WARNING ---');
  logger.setLogLevelWarning();
  messages();

  print('--- set SEVERE ---');
  logger.setLogLevelSevere();
  messages();

  print('--- set ERROR ---');
  logger.setLogLevelError();
  messages();

  print('--- set OFF ---');
  logger.setLogLevelOff();
  messages();
}

void messages() {
  logger.fine('FINE messages');
  logger.warning('WARNING messages');
  logger.severe('SEVERE messages');
  logger.error('ERROR messages');
  logger.info('INFO messages');
}
