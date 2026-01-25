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

import 'dart:convert';

import 'package:valkey_client/valkey_client.dart';

ValkeyLogger logger = ValkeyLogger('JSON Array Price and Multi Example');

void main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    // Check environment before running logic
    if (!await client.isJsonModuleLoaded()) {
      logger.info('❌ Error: JSON module is NOT loaded on this server.');
      // logger.info('   Please install valkey-json or redis-stack.');
      return;
    } else {
      logger.info('✅ JSON module detected. Ready to go!');
    }

    await runArrayPriceExamples(client);
    await runArrayMultiExamples(client);
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

Future<void> runArrayPriceExamples(ValkeyClient client) async {
  const productKey1 = 'product:1';
  const productKey2 = 'product:2';
  const rootPath = r'$';
  const pricePath = r'$.price';
  const vatPath = r'$.vat';

  dynamic currentPrice;
  dynamic currentVat;

  await client.jsonSet(
      key: productKey1,
      path: rootPath,
      data: jsonEncode({'id': 1, 'name': 'Widget', 'price': 1000}));

  await client.jsonNumIncrBy(key: productKey1, path: pricePath, value: 100);

  // Current Price
  currentPrice = await client.jsonGet(key: productKey1, path: pricePath);
  logger.info('$productKey1 $pricePath = $currentPrice');

  await client.jsonSet(
      key: productKey2,
      path: rootPath,
      data: {'id': 2, 'name': 'Widget', 'price': 2000});

  // Current Price
  currentPrice = await client.jsonGet(key: productKey2, path: pricePath);
  logger.info('$productKey2 $pricePath = $currentPrice');

  await client.jsonSet(
    key: productKey2,
    path: vatPath,
    data: 200, // This is integer
    // data: jsonEncode(200) // This is string
  );

  // Current VAT
  currentVat = await client.jsonGet(key: productKey2, path: vatPath);
  logger.info('$productKey2 $vatPath = $currentVat');

  await client.jsonNumIncrBy(key: productKey2, path: pricePath, value: 1000);

  // Current Price
  currentPrice = await client.jsonGet(key: productKey2, path: pricePath);
  logger.info('$productKey2 $pricePath = $currentPrice');

  await client.jsonNumIncrBy(key: productKey2, path: vatPath, value: 100);

  // Current VAT
  currentVat = await client.jsonGet(key: productKey2, path: vatPath);
  logger.info('$productKey2 $vatPath = $currentVat');

  await client.jsonNumMultBy(key: productKey2, path: vatPath, value: 2);

  // Current VAT
  currentVat = await client.jsonGet(key: productKey2, path: vatPath);
  logger.info('$productKey2 $vatPath = $currentVat');

  await client.jsonNumMultBy(key: productKey2, path: pricePath, value: 2);

  // Current Price
  currentPrice = await client.jsonGet(key: productKey2, path: pricePath);
  logger.info('$productKey2 $pricePath = $currentPrice');
}

Future<void> runArrayMultiExamples(ValkeyClient client) async {
  await client.jsonMSet(entries: [
    // Using Helper Class
    const JsonMSetEntry(key: 'doc:1', path: r'$', value: {'a': 1}),
    const JsonMSetEntry(key: 'doc:2', path: r'$', value: {'a': 2}),
  ]);

  // Retrieves root object ($) from doc:1 and doc:2
  final docs = await client.jsonMGet(keys: ['doc:1', 'doc:2'], path: r'$');
  logger.info(docs.toString());
  // docs -> [{'a': 1}, {'a': 2}]
}
