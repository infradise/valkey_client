<!--
Copyright 2025-2026 Infradise Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# PUBSUB

| valkey_client         | Redis                                                                               | Valkey                                                                   |
|-----------------------|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `psubscribe`          | [PSUBSCRIBE](https://redis.io/docs/latest/commands/psubscribe/)                     | [PSUBSCRIBE](https://valkey.io/commands/psubscribe/)                     |
| `publish`             | [PUBLISH](https://redis.io/docs/latest/commands/publish/)                           | [PUBLISH](https://valkey.io/commands/publish/)                           |
| `pubsubChannels`      | [PUBSUB CHANNELS](https://redis.io/docs/latest/commands/pubsub-channels/)           | [PUBSUB CHANNELS](https://valkey.io/commands/pubsub-channels/)           |
| `pubsubNumPat`        | [PUBSUB NUMPAT](https://redis.io/docs/latest/commands/pubsub-numpat/)               | [PUBSUB NUMPAT](https://valkey.io/commands/pubsub-numpat/)               |
| `pubsubNumSub`        | [PUBSUB NUMSUB](https://redis.io/docs/latest/commands/pubsub-numsub/)               | [PUBSUB NUMSUB](https://valkey.io/commands/pubsub-numsub/)               |
|                       | [PUBSUB SHARDCHANNELS](https://redis.io/docs/latest/commands/pubsub-shardchannels/) | [PUBSUB SHARDCHANNELS](https://valkey.io/commands/pubsub-shardchannels/) |
|                       | [PUBSUB SHARDNUMSUB](https://redis.io/docs/latest/commands/pubsub-shardnumsub/)     | [PUBSUB SHARDNUMSUB](https://valkey.io/commands/pubsub-shardnumsub/)     |
| `punsubscribe`        | [PUNSUBSCRIBE](https://redis.io/docs/latest/commands/punsubscribe/)                 | [PUNSUBSCRIBE](https://valkey.io/commands/punsubscribe/)                 |
| `spublish`            | [SPUBLISH](https://redis.io/docs/latest/commands/spublish/)                         | [SPUBLISH](https://valkey.io/commands/spublish/)                         |
| `ssubscribe`          | [SSUBSCRIBE](https://redis.io/docs/latest/commands/ssubscribe/)                     | [SSUBSCRIBE](https://valkey.io/commands/ssubscribe/)                     |
| `subscribe`           | [SUBSCRIBE](https://redis.io/docs/latest/commands/subscribe/)                       | [SUBSCRIBE](https://valkey.io/commands/subscribe/)                       |
| `sunsubscribe`        | [SUNSUBSCRIBE](https://redis.io/docs/latest/commands/sunsubscribe/)                 | [SUNSUBSCRIBE](https://valkey.io/commands/sunsubscribe/)                 |
| `unsubscribe`         | [UNSUBSCRIBE](https://redis.io/docs/latest/commands/unsubscribe/)                   | [UNSUBSCRIBE](https://valkey.io/commands/unsubscribe/)                   |