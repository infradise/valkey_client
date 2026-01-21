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

ValkeyLogger logger = ValkeyLogger('JSON Example');

void main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    await runJsonObjectMapExample(client);
    await runJsonArrayListExample(client);
    await runNestedJsonObjectExample(client);
    await runComplexJsonExample(client);
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

// Example: JSON Object (Map)
Future<void> runJsonObjectMapExample(ValkeyClient client) async {
  final userMap = {
    'name': 'Alice',
    'age': 30,
    'isStudent': false,
  };

  // Root($)
  await client.jsonSet(key: 'user:100', path: r'$', data: userMap);
  logger.info('✅ Saved User Data');

  final result = await client.jsonGet('user:100');
  logger.info('User Result: $result');
  // {name: Alice, age: 30, isStudent: false}

  final name = await client.jsonGet('user:100', r'$.name');
  logger.info('User Name: $name'); // [Alice]
}

// Example: JSON Array (List)
Future<void> runJsonArrayListExample(ValkeyClient client) async {
  final fruits = [
    'apple',
    'banana',
    'cherry',
  ];

  // Root($)
  await client.jsonSet(key: 'fruits', path: r'$', data: fruits);
  logger.info('✅ Saved Fruits');

  final fruitResult = await client.jsonGet('fruits');
  logger.info('Fruit Result: $fruitResult'); // [apple, banana, cherry]

  final firstFruit = await client.jsonGet('fruits', r'$[0]');
  logger.info('First Fruit: $firstFruit'); // [apple]
}

// Example: Nested JSON Object (User Profile with US Address - Miami Beach)
Future<void> runNestedJsonObjectExample(ValkeyClient client) async {
  // Scenario: Storing a developer's profile who lives in a vacation spot
  // (Miami Beach, FL).
  // Giving developers a refreshing vibe with "Ocean Drive" address!
  final userProfile = {
    'username': 'dev_ops_master',
    'contact': {
      'email': 'admin@tech-example.com',
      'phone': '+1-305-555-0123', // 305 is the iconic area code for Miami
    },
    'address': {
      'state': 'FL', // Florida
      'city': 'Miami Beach',
      'zipcode': '33139', // South Beach area
      'details': {
        'street': '1020 Ocean Drive', // Famous street with Art Deco hotels
        'suite': 'Penthouse A' // A nice touch for a developer's dream home
      }
    }
  };

  // 1. Save the entire data to the root path
  await client.jsonSet(key: 'user:profile:1001', path: r'$', data: userProfile);
  logger.info('✅ Saved User Profile (Miami Beach Vibe)');

  // 2. Retrieve data from a nested field (City)
  // Path: $.address.city
  final city = await client.jsonGet('user:profile:1001', r'$.address.city');
  logger.info('City: $city'); // ["Miami Beach"]

  // 3. Retrieve data from a deeply nested field (Street Name)
  // Path: $.address.details.street
  final street =
      await client.jsonGet('user:profile:1001', r'$.address.details.street');
  logger.info('Street: $street'); // ["1020 Ocean Drive"]

  // 4. Update a specific nested field only (Update Email)
  // Modifying the contact email without rewriting the entire profile.
  await client.jsonSet(
      key: 'user:profile:1001',
      path: r'$.contact.email',
      data: 'support@tech-example.com');
  final newEmail =
      await client.jsonGet('user:profile:1001', r'$.contact.email');
  logger.info('Updated Email: $newEmail'); // ["support@tech-example.com"]
}

// Example: Complex JSON Example (Server Cluster Configuration & Status)
Future<void> runComplexJsonExample(ValkeyClient client) async {
  // Scenario: Managing a microservices cluster configuration and node status.
  // This represents a typical backend use case for configuration management.
  final clusterConfig = {
    'service_id': 'svc_auth_v2',
    'environment': 'production',
    'deployment': {
      'region': 'us-east-1',
      'strategy': 'blue-green',
      'replicas': 5
    },
    'feature_flags': ['mfa_enabled', 'rate_limiting', 'audit_logging'],
    'active_nodes': [
      // List of objects representing server nodes
      // e.g., five-nine or three-nine
      {'node_id': 'node-01', 'status': 'healthy', 'uptime': 99.999},
      {'node_id': 'node-02', 'status': 'degraded', 'uptime': 95.995},
      {'node_id': 'node-03', 'status': 'healthy', 'uptime': 99.998}
    ]
  };

  // 1. Save cluster configuration
  await client.jsonSet(key: 'config:svc_auth', path: r'$', data: clusterConfig);
  logger.info('✅ Saved Cluster Configuration');

  // 2. Retrieve a value inside a nested object (Deployment Region)
  final region =
      await client.jsonGet('config:svc_auth', r'$.deployment.region');
  logger.info('Region: $region'); // ["us-east-1"]

  // 3. Retrieve a simple value from a list (First feature flag)
  // Path: $.feature_flags[0] -> Access the element at index 0
  final firstFlag =
      await client.jsonGet('config:svc_auth', r'$.feature_flags[0]');
  logger.info('First Feature Flag: $firstFlag'); // ["mfa_enabled"]

  // 4. Retrieve a field value from an object inside a list (Status of
  //    the first node)
  // Path: $.active_nodes[0].status
  final firstNodeStatus =
      await client.jsonGet('config:svc_auth', r'$.active_nodes[0].status');
  logger.info('First Node Status: $firstNodeStatus'); // ["healthy"]

  // 5. (Advanced) Extract uptime from all nodes
  // Path: $.active_nodes[*].uptime -> Select 'uptime' from ALL nodes
  final allUptimes =
      await client.jsonGet('config:svc_auth', r'$.active_nodes[*].uptime');
  logger.info('All Node Uptimes: $allUptimes'); // [99.9, 95.5, 99.8]
}
