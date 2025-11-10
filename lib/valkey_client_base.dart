import 'dart:async';

import 'package:valkey_client/src/cluster_info.dart';
import 'package:valkey_client/valkey_commands_base.dart';
export 'package:valkey_client/src/cluster_info.dart'
    show ClusterNodeInfo, ClusterSlotRange;

/// Represents a message received from a subscribed channel or pattern.
class ValkeyMessage {
  /// The channel the message was sent to.
  ///
  /// This is `null` if the message was received via a pattern subscription (`pmessage`).
  final String? channel;

  /// The message payload.
  final String message;

  /// The pattern that matched the channel (only for `pmessage`).
  ///
  /// This is `null` if the message was received via a channel subscription (`message`).
  final String? pattern;

  ValkeyMessage({this.channel, required this.message, this.pattern});

  @override
  String toString() {
    if (pattern != null) {
      return 'ValkeyMessage{pattern: $pattern, channel: $channel, message: $message}';
    } else {
      return 'Message{channel: $channel, message: $message}';
    }
  }
}

/// Represents an active subscription to channels or patterns.
///
/// Returned by `subscribe()` and `psubscribe()`.
class Subscription {
  /// A broadcast stream that emits messages received on the subscribed channels/patterns.
  ///
  /// Listen to this stream to receive `ValkeyMessage` objects.
  final Stream<ValkeyMessage> messages;

  /// A [Future] that completes when the initial subscription to all requested
  /// channels/patterns is confirmed by the server.
  ///
  /// You MUST `await` this future *before* publishing messages to ensure
  /// the subscription is active.
  ///
  /// ```dart
  /// final sub = client.subscribe(['my-channel']);
  /// await sub.ready; // Wait for confirmation
  /// await publisher.publish('my-channel', 'hello');
  /// ```
  final Future<void> ready;

  Subscription(this.messages, this.ready);
}

/// The abstract base class for a Valkey client.
///
/// This interface defines the public API for interacting with a Valkey/Redis server.
/// It covers core commands, key management, transactions, and Pub/Sub.
abstract class ValkeyClientBase implements ValkeyCommandsBase {
  // --- Connection & Admin ---

  /// A [Future] that completes once the connection and authentication (if required)
  /// are successfully established.
  ///
  /// Use this to wait for the client to be ready after calling `connect()`:
  /// ```dart
  /// client.connect();
  /// await client.onConnected;
  /// print('Client is connected!');
  /// ```
  ///
  /// Throws a [ValkeyClientException] if accessed before `connect()` is called
  /// or if the connection attempt failed.
  Future<void> get onConnected;

  /// Connects to the Valkey server.
  ///
  /// If [host], [port], [username], or [password] are provided,
  /// they will override the default values set in the constructor.
  ///
  /// Throws a [ValkeyConnectionException] if the socket connection fails
  /// (e.g., connection refused) or if authentication fails (e.g., wrong password).
  Future<void> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  });

  /// Closes the connection to the server.
  ///
  /// This cancels any active subscriptions and cleans up resources.
  Future<void> close();

  /// Executes a raw command.
  ///
  /// Note: This is a low-level method. Prefer using the specific command
  /// methods (e.g., `get`, `set`) when available.
  ///
  /// This method should NOT be used for Pub/Sub management commands
  /// (`SUBSCRIBE`, `UNSUBSCRIBE`, etc.), as they are handled differently.
  Future<dynamic> execute(List<String> command);

  /// PINGs the server.
  ///
  /// Returns 'PONG' if no [message] is provided, otherwise returns the [message].
  /// Throws a [ValkeyServerException] if an error occurs.
  Future<String> ping([String? message]);

  // ---
  // Common Commands (See `ValkeyCommandsBase`)
  // ---

  // --- Pub/Sub ---

  /// Posts a [message] to the given [channel].
  ///
  /// Returns the number of clients that received the message.
  Future<int> publish(String channel, String message);

  /// Subscribes the client to the specified [channels].
  ///
  /// Returns a [Subscription] object containing:
  /// 1. `messages`: A `Stream<ValkeyMessage>` to listen for incoming messages.
  /// 2. `ready`: A `Future<void>` that completes when the server confirms
  ///    subscription to all requested channels.
  ///
  /// You MUST `await subscription.ready` before assuming the subscription is active.
  ///
  /// Throws a [ValkeyClientException] if mixing channel and pattern subscriptions.
  Subscription subscribe(List<String> channels);

  /// Unsubscribes the client from the given [channels], or all channels if none are given.
  ///
  /// The [Future] completes when the server confirms the unsubscription.
  Future<void> unsubscribe([List<String> channels = const []]);

  /// Subscribes the client to the given [patterns] (e.g., "log:*").
  ///
  /// Returns a [Subscription] object (see `subscribe` for details).
  /// You MUST `await subscription.ready` before assuming the subscription is active.
  ///
  /// Throws a [ValkeyClientException] if mixing channel and pattern subscriptions.
  Subscription psubscribe(List<String> patterns);

  /// Unsubscribes the client from the given [patterns], or all patterns if none are given.
  ///
  /// The [Future] completes when the server confirms the unsubscription.
  Future<void> punsubscribe([List<String> patterns = const []]);

  /// Lists the currently active channels.
  ///
  /// [pattern] is an optional glob-style pattern.
  /// Returns an empty list if no channels are active.
  Future<List<String?>> pubsubChannels([String? pattern]);

  /// Returns the number of subscribers for the specified [channels].
  ///
  /// Returns a `Map` where keys are the channel names
  /// and values are the number of subscribers.
  Future<Map<String, int>> pubsubNumSub(List<String> channels);

  /// Returns the number of subscriptions to patterns.
  Future<int> pubsubNumPat();

  // --- Cluster ---

  /// Fetches the cluster topology information from the server.
  ///
  /// Returns a list of [ClusterSlotRange] objects, describing which
  /// slots are mapped to which master and replica nodes.
  Future<List<ClusterSlotRange>> clusterSlots();

  // --- Transactions ---

  /// Marks the start of a transaction block.
  ///
  /// Subsequent commands will be queued by the server until `exec()` is called.
  /// Returns 'OK'.
  Future<String> multi();

  /// Executes all commands queued after `multi()`.
  ///
  /// Returns a `List<dynamic>` of replies for each command in the transaction.
  /// Returns `null` if the transaction was aborted (e.g., due to a `WATCH` failure).
  /// Throws a [ValkeyServerException] (e.g., `EXECABORT`) if the transaction
  /// was discarded due to a command syntax error within the `MULTI` block.
  Future<List<dynamic>?> exec();

  /// Discards all commands queued after `multi()`.
  ///
  /// Returns 'OK'.
  Future<String> discard();
}

/// Holds all configuration options for creating a new connection.
///
/// Used by [ValkeyPool] to create new client instances.
class ValkeyConnectionSettings {
  final String host;
  final int port;
  final String? username;
  final String? password;

  /// The maximum duration to wait for a response to any command.
  /// Defaults to 10 seconds.
  final Duration commandTimeout;

  ValkeyConnectionSettings({
    this.host = '127.0.0.1',
    this.port = 6379,
    this.username,
    this.password,
    this.commandTimeout = const Duration(seconds: 10),
  });
}
