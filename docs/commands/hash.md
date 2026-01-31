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

# HASH

| valkey_client  | Redis                                                               | Valkey                                                  |
|----------------|---------------------------------------------------------------------|---------------------------------------------------------|
| `hDel`         | [HDEL](https://redis.io/docs/latest/commands/hdel/)                 | [HDEL](https://valkey.io/commands/hdel/)                |
| `hExists`      | [HEXISTS](https://redis.io/docs/latest/commands/hexists/)           | [HEXISTS](https://valkey.io/commands/hexists/)          |
| `hExpire`      | [HEXPIRE](https://redis.io/docs/latest/commands/hexpire/)           | [HEXPIRE](https://valkey.io/commands/hexpire/)          |
| `hExpireAt`    | [HEXPIREAT](https://redis.io/docs/latest/commands/hexpireat/)       | [HEXPIREAT](https://valkey.io/commands/hexpireat/)      |
| `hExpireTime`  | [HEXPIRETIME](https://redis.io/docs/latest/commands/hexpiretime/)   | [HEXPIRETIME](https://valkey.io/commands/hexpiretime)   |
| `hGet`         | [HGET](https://redis.io/docs/latest/commands/hget/)                 | [HGET](https://valkey.io/commands/hget/)                |
| `hGetAll`      | [HGETALL](https://redis.io/docs/latest/commands/hgetall/)           | [HGETALL](https://valkey.io/commands/hgetall/)          |
| `hGetDel`      | [HGETDEL](https://redis.io/docs/latest/commands/hgetdel/)           |                                                         |
| `hGetEx`       | [HGETEX](https://redis.io/docs/latest/commands/hgetex/)             | [HGETEX](https://valkey.io/commands/hgetex/)            |
| `hIncrBy`      | [HINCRBY](https://redis.io/docs/latest/commands/hincrby/)           | [HINCRBY](https://valkey.io/commands/hincrby/)          |
| `hIncrByFloat` | [HINCRBYFLOAT](https://redis.io/docs/latest/commands/hincrbyfloat/) | [HINCRBYFLOAT](https://valkey.io/commands/hincrbyfloat) |
| `hKeys`        | [HKEYS](https://redis.io/docs/latest/commands/hkeys/)               | [HKEYS](https://valkey.io/commands/hkeys/)              |
| `hLen`         | [HLEN](https://redis.io/docs/latest/commands/hlen/)                 | [HLEN](https://valkey.io/commands/hlen/)                |
| `hMGet`        | [HMGET](https://redis.io/docs/latest/commands/hmget/)               | [HMGET](https://valkey.io/commands/hmget/)              |
| `hMSet`        | ~~[HMSET](https://redis.io/docs/latest/commands/hmset/)~~           | [HMSET](https://valkey.io/commands/hmset/)              |
| `hPersist`     | [HPERSIST](https://redis.io/docs/latest/commands/hpersist/)         | [HPERSIST](https://valkey.io/commands/hpersist/)        |
| `hPExpire`     | [HPEXPIRE](https://redis.io/docs/latest/commands/hpexpire/)         | [HPEXPIRE](https://valkey.io/commands/hpexpire/)        |
| `hPExpireAt`   | [HPEXPIREAT](https://redis.io/docs/latest/commands/hpexpireat/)     | [HPEXPIREAT](https://valkey.io/commands/hpexpireat/)    |
| `hPExpireTime` | [HPEXPIRETIME](https://redis.io/docs/latest/commands/hpexpiretime/) | [HPEXPIRETIME](https://valkey.io/commands/hpexpiretime) |
| `hPTtl`        | [HPTTL](https://redis.io/docs/latest/commands/hpttl/)               | [HPTTL](https://valkey.io/commands/hpttl/)              |
| `hRandField`   | [HRANDFIELD](https://redis.io/docs/latest/commands/hrandfield/)     | [HRANDFIELD](https://valkey.io/commands/hrandfield/)    |
| `hScan`        | [HSCAN](https://redis.io/docs/latest/commands/hscan/)               | [HSCAN](https://valkey.io/commands/hscan/)              |
| `hSet`         | [HSET](https://redis.io/docs/latest/commands/hset/)                 | [HSET](https://valkey.io/commands/hset/)                |
| `hSetEx`       | [HSETEX](https://redis.io/docs/latest/commands/hsetex/)             | [HSETEX](https://valkey.io/commands/hsetex/)            |
| `hSetNx`       | [HSETNX](https://redis.io/docs/latest/commands/hsetnx/)             | [HSETNX](https://valkey.io/commands/hsetnx/)            |
| `hStrLen`      | [HSTRLEN](https://redis.io/docs/latest/commands/hstrlen/)           | [HSTRLEN](https://valkey.io/commands/hstrlen/)          |
| `hTtl`         | [HTTL](https://redis.io/docs/latest/commands/httl/)                 | [HTTL](https://valkey.io/commands/httl/)                |
| `hVals`        | [HVALS](https://redis.io/docs/latest/commands/hvals/)               | [HVALS](https://valkey.io/commands/hvals/)              |