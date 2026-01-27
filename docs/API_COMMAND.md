# APIs and Commands

## Command

| Category              | Commands |
|-----------------------|------------------------------------------------------------------------|
| Connection            | `PING`, `ECHO`, `QUIT` via `close()` |
| Cluster               | `CLUSTER SLOTS`, `ASKING` |
| Strings               | `GET`, `SET`, `MGET`, `INCR`, `DECR`, `INCRBY`, `DECRBY` |
| Hashes                | `HSET`, `HGET`, `HGETALL` |
| Lists                 | `LPUSH`, `RPUSH`, `LPOP`, `RPOP`, `LRANGE` |
| Sets                  | `SADD`, `SREM`, `SMEMBERS` |
| Sorted Sets           | `ZADD`, `ZREM`, `ZRANGE` |
| Key Management        | `DEL`, `EXISTS`, `EXPIRE`, `TTL` |
| Transactions          | `MULTI`, `EXEC`, `DISCARD` |
| Full Pub/Sub          | `PUBLISH`, `SUBSCRIBE`, `UNSUBSCRIBE`, `PSUBSCRIBE`, `PUNSUBSCRIBE` |
| Pub/Sub Introspection | `PUBSUB CHANNELS`, `PUBSUB NUMSUB`, `PUBSUB NUMPAT` |
| Sharded Pub/Sub       | `SPUBLISH`, `SSUBSCRIBE`, `SUNSUBSCRIBE` |
| JSON                  | `JSON.ARRAPPEND`, `JSON.ARRINDEX`, `JSON.ARRINSERT`, `JSON.ARRLEN`, `JSON.ARRPOP`, `JSON.ARRTRIM`, `JSON.CLEAR`, `JSON.DEBUG`, `JSON.DEBUG MEMORY`, `JSON.DEBUG DEPTH`, `JSON.DEBUG FIELDS`, `JSON.DEBUG HELP`, `JSON.DEL`, `JSON.FORGET`, `JSON.GET`, `JSON.MERGE`, `JSON.MGET`, `JSON.MSET`, `JSON.NUMINCRBY`, `JSON.NUMMULTBY`, `JSON.OBJKEYS`, `JSON.OBJLEN`, `JSON.RESP`, `JSON.SET`, `JSON.STRAPPEND`, `JSON.STRLEN`, `JSON.TOGGLE`, `JSON.TYPE`|






## Public API

|Category| APIs | Modular(v3) | Status |
|---|---|----|----|
| Connection            | `ping`, `echo`, `close` | *Migrating* | |
| Cluster               | `clusterSlots`, `asking` | *Migrating* | |
| Strings               | `get`, `set`, `mGet`, `incr`, `decr`, `incrBy`, `decrBy` | *Migrating* |  |
| Hashes                | `hSet`, `hGet`, `hGetAll` | *Migrating* | |
| Lists                 | `lPush`, `rPush`, `lPop`, `rPop`, `lRange` | *Migrating* | |
| Sets                  | `sAdd`, `sRem`, `sMembers` | *Migrating* | |
| Sorted Sets           | `zAdd`, `zRem`, `zRange` | *Migrating* | |
| Key Management        | `del`, `exists`, `expire`, `ttl` | *Migrating* | |
| Transactions          | `multi`, `exec`, `discard` | *Done* | *Delegated* |
| Full Pub/Sub          | `publish`, `subscribe`, `unsubscribe`, `pSubscribe`, `pUnsubscribe` | *Migrating* | |
| Pub/Sub Introspection | `pubsubChannels`, `pubsubNumSub`, `pubsubNumPat` | *Migrating* | |
| Sharded Pub/Sub       | `sPublish`, `sSubscribe`, `sUnsubscribe` | *Migrating* | |
|JSON| `jsonArrAppend`, `jsonArrAppendEnhanced`, `jsonArrIndex`, `jsonArrIndexEnhanced`, `jsonArrInsert`, `jsonArrInsertEnhanced`, `jsonArrLen`, `jsonArrLenEnhanced`, `jsonArrPop`,`jsonArrPopEnhanced`, `jsonArrTrim`, `jsonArrTrimEnhanced`, `jsonClear`, `jsonDebug`, `jsonDel`, `jsonForget`, `jsonGet`, `jsonMerge`, `jsonMergeForce`, `jsonMGet`, `jsonMSet`, `jsonNumIncrBy`, `jsonNumMultBy`, `jsonObjKeys`, `jsonObjKeysEnhanced`, `jsonObjLen`, `jsonResp`, `jsonSet`, `jsonStrAppend`, `jsonStrAppendEnhanced`, `jsonStrLen`, `jsonStrLenEnhanced`,  `jsonToggle`, `jsonType` | *Done* | *Refactored* |

## CamelCase(v3)

| As-is          | To-be          | Status |
|----------------|----------------|--------|
| `mget`         | `mGet`         |  |
| `hset`         | `hSet`         |  |
| `hget`         | `hGet`         | *Done* |
| `hgetall`      | `hGetAll`      |  |
| `lpush`        | `lPush`        |  |
| `rpush`        | `rPush`        |  |
| `lpop`         | `lPop`         |  |
| `rpop`         | `rPop`         |  |
| `lrange`       | `lRange`       |  |
| `sadd`         | `sAdd`         |  |
| `srem`         | `sRem`         |  |
| `smembers`     | `sMembers`     |  |
| `zadd`         | `zAdd`         |  |
| `zrem`         | `zRem`         |  |
| `zrange`       | `zRange`       |  |
| `publish`      | `publish`      |  |
| `subscribe`    | `subscribe`    |  |
| `unsubscribe`  | `unsubscribe`  |  |
| `psubscribe`   | `pSubscribe`   |  |
| `punsubscribe` | `pUnsubscribe` |  |
| `spublish`     | `sPublish`     |  |
| `ssubscribe`   | `sSubscribe`   |  |
| `sunsubscribe` | `sUnsubscribe` |  |






  

 
 

  
  
 
 
 
