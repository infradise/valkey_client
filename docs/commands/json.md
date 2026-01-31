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

# JSON

| valkey_client                   | Redis                                                                         | Valkey                                                                     |
|---------------------------------|-------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| `jsonArrAppend`                 | [JSON.ARRAPPEND](https://redis.io/docs/latest/commands/json.arrappend/)       | [JSON.ARRAPPEND](https://valkey.io/commands/json.arrappend/)               |
| `jsonArrAppendEnhanced`         |                                                                               |                                                                            |
| `jsonArrIndex`                  | [JSON.ARRINDEX](https://redis.io/docs/latest/commands/json.arrindex/)         | [JSON.ARRINDEX](https://valkey.io/commands/json.arrindex/)                 |
| `jsonArrIndexEnhanced`          |                                                                               |                                                                            |
| `jsonArrInsert`                 | [JSON.ARRINSERT](https://redis.io/docs/latest/commands/json.arrinsert/)       | [JSON.ARRINSERT](https://valkey.io/commands/json.arrinsert/)               |
| `jsonArrInsertEnhanced`         |                                                                               |                                                                            |
| `jsonArrLen`                    | [JSON.ARRLEN](https://redis.io/docs/latest/commands/json.arrlen/)             | [JSON.ARRLEN](https://valkey.io/commands/json.arrlen/)                     |
| `jsonArrLenEnhanced`            |                                                                               |                                                                            |
| `jsonArrPop`                    | [JSON.ARRPOP](https://redis.io/docs/latest/commands/json.arrpop/)             | [JSON.ARRPOP](https://valkey.io/commands/json.arrpop/)                     |
| `jsonArrPopEnhanced`            |                                                                               |                                                                            |
| `jsonArrTrim`                   | [JSON.ARRTRIM](https://redis.io/docs/latest/commands/json.arrtrim/)           | [JSON.ARRTRIM](https://valkey.io/commands/json.arrtrim/)                   |
| `jsonArrTrimEnhanced`           |                                                                               |                                                                            |
| `jsonClear`                     | [JSON.CLEAR](https://redis.io/docs/latest/commands/json.clear/)               | [JSON.CLEAR](https://valkey.io/commands/json.clear/)                       |
| ~~`jsonDebug`~~                 | [JSON.DEBUG](https://redis.io/docs/latest/commands/json.debug/)               | [JSON.DEBUG](https://valkey.io/commands/json.debug/)                       |
| `jsonDebugDepth`                |                                                                               | [JSON.DEBUG DEPTH](https://valkey.io/commands/json.debug/)                 |
| `jsonDebugFields`               |                                                                               | [JSON.DEBUG FIELDS](https://valkey.io/commands/json.debug/)                |
| `jsonDebugHelp`                 | [JSON.DEBUG HELP](https://redis.io/docs/latest/commands/json.debug-help/)     | [JSON.DEBUG HELP](https://valkey.io/commands/json.debug/)                  |
| `jsonDebugKeyTableCheck`        |                                                                               | [JSON.DEBUG KEYTABLE-CHECK](https://valkey.io/commands/json.debug/)        |
| `jsonDebugKeyTableCorrupt`      |                                                                               | [JSON.DEBUG KEYTABLE-CORRUPT](https://valkey.io/commands/json.debug/)      |
| `jsonDebugKeyTableDistribution` |                                                                               | [JSON.DEBUG KEYTABLE-DISTRIBUTION](https://valkey.io/commands/json.debug/) |
| `jsonDebugMaxDepthKey`          |                                                                               | [JSON.DEBUG MAX-DEPTH-KEY](https://valkey.io/commands/json.debug/)         |
| `jsonDebugMaxSizeKey`           |                                                                               | [JSON.DEBUG MAX-SIZE-KEY](https://valkey.io/commands/json.debug/)          |
| `jsonDebugMemory`               | [JSON.DEBUG MEMORY](https://redis.io/docs/latest/commands/json.debug-memory/) | [JSON.DEBUG MEMORY](https://valkey.io/commands/json.debug/)                |
| `jsonDebugTestSharedApi`        |                                                                               | [JSON.DEBUG TEST-SHARED-API](https://valkey.io/commands/json.debug/)       |
| `jsonDel`                       | [JSON.DEL](https://redis.io/docs/latest/commands/json.del/)                   | [JSON.DEL](https://valkey.io/commands/json.del/)                           |
| `jsonForget`                    | [JSON.FORGET](https://redis.io/docs/latest/commands/json.forget/)             | [JSON.FORGET](https://valkey.io/commands/json.forget/)                     |
| `jsonGet`                       | [JSON.GET](https://redis.io/docs/latest/commands/json.get/)                   | [JSON.GET](https://valkey.io/commands/json.get/)                           |
| `jsonMerge`                     | [JSON.MERGE](https://redis.io/docs/latest/commands/json.merge/)               |                                                                            |
| `jsonMergeForce`                |                                                                               |                                                                            |
| `jsonMGet`                      | [JSON.MGET](https://redis.io/docs/latest/commands/json.mget/)                 | [JSON.MGET](https://valkey.io/commands/json.mget/)                         |
| `jsonMSet`                      | [JSON.MSET](https://redis.io/docs/latest/commands/json.mset/)                 | [JSON.MSET](https://valkey.io/commands/json.mset/)                         |
| `jsonNumIncrBy`                 | [JSON.NUMINCRBY](https://redis.io/docs/latest/commands/json.numincrby/)       | [JSON.NUMINCRBY](https://valkey.io/commands/json.numincrby/)               |
| `jsonNumMultBy`                 | [JSON.NUMMULTBY](https://redis.io/docs/latest/commands/json.nummultby/)       | [JSON.NUMMULTBY](https://valkey.io/commands/json.nummultby/)               |
| `jsonObjKeys`                   | [JSON.OBJKEYS](https://redis.io/docs/latest/commands/json.objkeys/)           | [JSON.OBJKEYS](https://valkey.io/commands/json.objkeys/)                   |
| `jsonObjKeysEnhanced`           |                                                                               |                                                                            |
| `jsonObjLen`                    | [JSON.OBJLEN](https://redis.io/docs/latest/commands/json.objlen/)             | [JSON.OBJLEN](https://valkey.io/commands/json.objlen/)                     |
| `jsonResp`                      | [JSON.RESP](https://redis.io/docs/latest/commands/json.resp/)                 | [JSON.RESP](https://valkey.io/commands/json.resp/)                         |
| `jsonSet`                       | [JSON.SET](https://redis.io/docs/latest/commands/json.set/)                   | [JSON.SET](https://valkey.io/commands/json.set/)                           |
| `jsonStrAppend`                 | [JSON.STRAPPEND](https://redis.io/docs/latest/commands/json.strappend/)       | [JSON.STRAPPEND](https://valkey.io/commands/json.strappend/)               |
| `jsonStrAppendEnhanced`         |                                                                               |                                                                            |
| `jsonStrLen`                    | [JSON.STRLEN](https://redis.io/docs/latest/commands/json.strlen/)             | [JSON.STRLEN](https://valkey.io/commands/json.strlen/)                     |
| `jsonStrLenEnhanced`            |                                                                               |                                                                            |
| `jsonToggle`                    | [JSON.TOGGLE](https://redis.io/docs/latest/commands/json.toggle/)             | [JSON.TOGGLE](https://valkey.io/commands/json.toggle/)                     |
| `jsonType`                      | [JSON.TYPE](https://redis.io/docs/latest/commands/json.type/)                 | [JSON.TYPE](https://valkey.io/commands/json.type/)                         |