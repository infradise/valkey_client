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
  logger.info('By default built-in logger is disabled (off), '
      'you cannot see this message.');

  logger.setLogLevelInfo();
  logger.info('Now you can see this message only.');

  logger.setLogLevelOff();
  logger.info('From now on, you cannot see this message again.');
}
