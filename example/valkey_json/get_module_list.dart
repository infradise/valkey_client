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

import 'package:valkey_client/src/utils/module_printer.dart'
    show printPrettyModuleList;
import 'package:valkey_client/valkey_client.dart';

ValkeyLogger logger = ValkeyLogger('Get Module List Example');

void main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  // ... Initialize client ...
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    // Check environment before running logic

    // 1. Get the structured list of modules
    final modules = await client.getModuleList();

    // 2. Print them nicely
    printPrettyModuleList(modules);

    // 3. Check specifically for JSON module using the logic
    if (await client.isJsonModuleLoaded()) {
      print('✅ JSON Module is ready!'); // JSON module detected. Ready to go!
      // Proceed with jsonSet...
    } else {
      // Error: JSON module is NOT loaded on this server.
      print('❌ JSON Module is missing.');
    }
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
