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

import 'dart:collection' show Queue;

import '../../annotations.dart' show protected;

export 'extensions.dart';

/// Mixin to support Redis-JSON and Valkey-JSON commands.
/// This mixin ensures compatibility with the existing `execute` method
/// by converting all parameters to Strings before sending.
mixin TransactionCommands {
  // [Interface Definition]
  // The class using this mixin must implement these methods and getters.

  /// Sends a command to the server.
  /// The interface for sending commands to the Redis/Valkey server.
  Future<dynamic> execute(List<String> command);

  /// Checks if the connected server is Redis.
  Future<bool> isRedisServer();

  /// Checks if the connected server is Valkey.
  Future<bool> isValkeyServer();

  @protected
  bool _isInTransaction = false;

  final Queue<List<String>> _transactionQueue = Queue();

  bool get isInTransaction => _isInTransaction;

  void setTransactionStateInternal(bool isStarted) {
    _isInTransaction = isStarted;
  }

  void clearTransactionQueueInternal() {
    _transactionQueue.clear();
  }

  void queueCommandInternal(List<String> command) {
    _transactionQueue.add(command);
  }

  List<List<String>> getTransactionQueueInternal() =>
      _transactionQueue.toList();
}
