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
import 'dart:async';
import 'package:valkey_client/valkey_client.dart';

// var cfg = const Config();
// cfg = cfg.copyWith(allowRedisOnlyJsonMerge: true);

ValkeyLogger logger = ValkeyLogger('JSON Array Merge Example');

Future<void> main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  // final client = ValkeyClient(
  //   host: '127.0.0.1',
  //   port: 6379,
  // );

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6380,
  );

  final client = ValkeyClient.fromSettings(settings);

  // Connect to server first
  try {
    logger.info('Connecting to server...');
    await client.connect();
    logger.info('Connected.');
  } catch (e) {
    logger.info('Failed to connect: $e');
    return;
  }

  // Detect server type and version for accurate logging
  var serverLabel = 'server';
  try {
    final name = await client.getServerName();
    final version = await client.getServerVersion();
    final isValkey = await client.isValkeyServer();
    final isRedis = await client.isRedisServer();

    if (name != null && name.isNotEmpty) {
      serverLabel = name;
    } else if (isValkey) {
      serverLabel = 'Valkey';
    } else if (isRedis) {
      serverLabel = 'Redis';
    }

    if (version != null && version.isNotEmpty) {
      logger.info('Server detected: $serverLabel (version $version)');
    } else {
      logger.info('Server detected: $serverLabel');
    }
  } catch (e) {
    // If detection fails, keep generic label but log the error
    logger.info('Server detection error: $e');
  }

  const key = 'product:1';
  const path = r'$';
  const initialPayload = {'price': 1000, 'stock': 20};
  const mergePayload = {'price': 1200, 'stock': 50};

  // Set initial JSON value
  try {
    logger.info('Setting initial JSON value with jsonSet...');
    await client.jsonSet(key: key, path: path, data: initialPayload);
    logger.info('jsonSet completed.');
  } catch (e) {
    logger.info('❌ jsonSet error: $e');
  }

  // Show value before jsonMerge
  try {
    logger.info('Value before jsonMerge (jsonGet):');
    final beforeMerge = await client.jsonGet(key: key, path: path);
    logger.info(beforeMerge.toString());
  } catch (e) {
    logger.info('❌ jsonGet before jsonMerge error: $e');
  }

  // Call jsonMerge
  try {
    logger.info('🚀 Calling jsonMerge...');
    await client.jsonMerge(key: key, path: path, data: mergePayload);
    logger.info('✅ jsonMerge completed.');
  } catch (e) {
    logger.info('❌ jsonMerge error: $e');
  }

  // Show value after jsonMerge
  try {
    logger.info('Value after jsonMerge (jsonGet):');
    final afterMerge = await client.jsonGet(key: key, path: path);
    logger.info(afterMerge.toString());
  } catch (e) {
    logger.info('❌ jsonGet after jsonMerge error: $e');
  }

  // Show value before jsonMergeForce
  try {
    logger.info('Value before jsonMergeForce (jsonGet):');
    final beforeMergeForce = await client.jsonGet(key: key, path: path);
    logger.info(beforeMergeForce.toString());
  } catch (e) {
    logger.info('❌ jsonGet before jsonMergeForce error: $e');
  }

  // Call jsonMergeForce
  try {
    logger.info('🚀 Calling jsonMergeForce...');
    await client.jsonMergeForce(key: key, path: path, data: mergePayload);
    logger.info('✅ jsonMergeForce completed.');
  } catch (e) {
    logger.info('❌ jsonMergeForce error: $e');
  }

  // Show value after jsonMergeForce
  try {
    logger.info('Value after jsonMergeForce (jsonGet):');
    final afterMergeForce = await client.jsonGet(key: key, path: path);
    logger.info(afterMergeForce.toString());
  } catch (e) {
    logger.info('❌ jsonGet after jsonMergeForce error: $e');
  }

  // Close client connection cleanly
  try {
    await client.close();
    logger.info('Client closed.');
  } catch (e) {
    logger.info('❌ Error while closing client: $e');
  }
}
