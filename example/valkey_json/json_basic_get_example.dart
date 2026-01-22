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

import 'package:valkey_client/valkey_client.dart';

ValkeyLogger logger = ValkeyLogger('JSON Basic Get Example');

void main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    // Valid usage example
    final validUserMap = {
      'name': 'Nana',
      'age': 21,
      'isStudent': false,
    };

    // Invalid usage example (reason: redundant quotations)
    final invalidUserMap = {
      '"name"': '"Alice"',
      '"age"': 30,
    };

    // Root($)
    await client.jsonSet(key: 'user:100', path: r'$', data: validUserMap);
    final expectedName = await client.jsonGet(key: 'user:100', path: r'$.name');
    logger.info('User Name (expected): $expectedName');
    // Expected output: [Nana] / Actual output: [Nana]

    await client.jsonSet(key: 'user:200', path: r'$', data: invalidUserMap);
    final unexpectedName =
        await client.jsonGet(key: 'user:200', path: r'$.name');
    logger.info('User Name (not shown): $unexpectedName');
    // Expected output: [Alice] / Actual output: []
  } on ValkeyConnectionException catch (e) {
    logger.error('❌ Connection Failed: $e');
    logger.error('Ensure a Redis or Valkey CLUSTER node is running.');
  } on ValkeyServerException catch (e) {
    logger.error('❌ Server Error: $e');
  } on ValkeyClientException catch (e) {
    logger.error('❌ Client Error: $e');
  } on FeatureNotImplementedException catch (e) {
    logger.error('❌ Feature Not Implemented: $e');
  } catch (e) {
    logger.error('❌ Unknown Error: $e');
  } finally {
    // Close all cluster connections
    logger.info('Closing all cluster connections...');
    await client.close();
  }
}
