# EXPECTED OUTPUT

## example/valkey_json

### enhanced_paths_example.dart
```sh
[2026-01-26T23:23:36.349208] Get Enhanced Paths Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-26T23:23:36.350238] Get Enhanced Paths Example - INFO: --- JSON Enhanced Path Commands Example ---
[2026-01-26T23:23:36.350254] Get Enhanced Paths Example - INFO: 🚀 [Part 1] Array Enhanced Operations
[2026-01-26T23:23:36.352680] Get Enhanced Paths Example - INFO: 1. Initialized: {"a": [1], "b": {"c": [2]}, "d": "not_array"}
[2026-01-26T23:23:36.354860] Get Enhanced Paths Example - INFO: 2. ArrAppend Result: [2, 2, null, null]
[2026-01-26T23:23:36.356007] Get Enhanced Paths Example - INFO: 3. ArrInsert Result: [3, 3]
[2026-01-26T23:23:36.356685] Get Enhanced Paths Example - INFO: 4. ArrIndex Result : [0, 0]
[2026-01-26T23:23:36.357244] Get Enhanced Paths Example - INFO: 5. ArrLen Result   : [3, 3]
[2026-01-26T23:23:36.360060] Get Enhanced Paths Example - INFO: 6. ArrPop Result   : [3, 3]
[2026-01-26T23:23:36.360734] Get Enhanced Paths Example - INFO: 7. ArrTrim Result  : [1, 1]
[2026-01-26T23:23:36.360749] Get Enhanced Paths Example - INFO: 🚀 [Part 2] Object Enhanced Operations
[2026-01-26T23:23:36.362556] Get Enhanced Paths Example - INFO: 9. ObjKeys Result  : [[name, role], [created, active], []]
[2026-01-26T23:23:36.362573] Get Enhanced Paths Example - INFO: 🚀 [Part 3] String Enhanced Operations
[2026-01-26T23:23:36.364224] Get Enhanced Paths Example - INFO: 11. StrAppend Result: [11, 10, null]
[2026-01-26T23:23:36.365135] Get Enhanced Paths Example - INFO: 12. StrLen Result   : [11, 10]
[2026-01-26T23:23:36.365150] Get Enhanced Paths Example - INFO: Closing all cluster connections...
```

### get_module_list_example.dart
```sh
📦 Loaded Modules:
+--------+----------+------------------------------------+--------+
| NAME   | VER      | PATH                               | ARGS   |
+--------+----------+------------------------------------+--------+
| json   | 10002    | /usr/lib/valkey/libjson.so         | -      |
| search | 10000    | /usr/lib/valkey/libsearch.so       | -      |
| ldap   | 16777471 | /usr/lib/valkey/libvalkey_ldap.so  | -      |
| bf     | 10000    | /usr/lib/valkey/libvalkey_bloom.so | -      |
+--------+----------+------------------------------------+--------+

✅ JSON Module is ready!
```
OR
```sh
No modules loaded.
❌ JSON Module is missing.
[2026-01-23T01:52:04.077250] Get Module List Example - INFO: Closing all cluster connections...
```

### json_array_basic_example.dart
```sh
[2026-01-24T10:35:01.703930] JSON Array Basic Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-24T10:35:01.704868] JSON Array Basic Example - INFO: --- 🚀 JSON Array Commands Example ---
[2026-01-24T10:35:01.706383] JSON Array Basic Example - INFO: 0. Initialized: ["apple", "banana"]
[2026-01-24T10:35:01.706993] JSON Array Basic Example - INFO: 1. ARRAPPEND result: 4
[2026-01-24T10:35:01.707526] JSON Array Basic Example - INFO: 2. ARRINSERT result: 5
[2026-01-24T10:35:01.708115] JSON Array Basic Example - INFO: 3. ARRINDEX ("banana"): 2
[2026-01-24T10:35:01.708603] JSON Array Basic Example - INFO: 4. ARRLEN result: 5
[2026-01-24T10:35:01.710510] JSON Array Basic Example - INFO: 5. ARRPOP result: date
[2026-01-24T10:35:01.711088] JSON Array Basic Example - INFO: 6. ARRTRIM result: 2
[2026-01-24T10:35:01.712149] JSON Array Basic Example - INFO: ✅ Final Data: [apple, mango]
[2026-01-24T10:35:01.712179] JSON Array Basic Example - INFO: Closing all cluster connections...
```

### json_array_merge_example.dart
`Redis v8.4.0`

```sh
[2026-01-25T15:32:13.424824] JSON Array Merge Example - INFO: Connecting to server...
[2026-01-25T15:32:13.450850] JSON Array Merge Example - INFO: Connected.
[2026-01-25T15:32:13.451016] JSON Array Merge Example - INFO: Server detected: redis (version 8.4.0)
[2026-01-25T15:32:13.451031] JSON Array Merge Example - INFO: Setting initial JSON value with jsonSet...
[2026-01-25T15:32:13.452852] JSON Array Merge Example - INFO: jsonSet completed.
[2026-01-25T15:32:13.452867] JSON Array Merge Example - INFO: Value before jsonMerge (jsonGet):
[2026-01-25T15:32:13.455707] JSON Array Merge Example - INFO: {price: 1000, stock: 20}
[2026-01-25T15:32:13.455725] JSON Array Merge Example - INFO: 🚀 Calling jsonMerge...
[2026-01-25T15:32:13.456758] JSON Array Merge Example - INFO: ✅ jsonMerge completed.
[2026-01-25T15:32:13.456777] JSON Array Merge Example - INFO: Value after jsonMerge (jsonGet):
[2026-01-25T15:32:13.457425] JSON Array Merge Example - INFO: {price: 1200, stock: 50}
[2026-01-25T15:32:13.457450] JSON Array Merge Example - INFO: Value before jsonMergeForce (jsonGet):
[2026-01-25T15:32:13.457958] JSON Array Merge Example - INFO: {price: 1200, stock: 50}
[2026-01-25T15:32:13.457977] JSON Array Merge Example - INFO: 🚀 Calling jsonMergeForce...
[2026-01-25T15:32:13.458571] JSON Array Merge Example - INFO: ✅ jsonMergeForce completed.
[2026-01-25T15:32:13.458589] JSON Array Merge Example - INFO: Value after jsonMergeForce (jsonGet):
[2026-01-25T15:32:13.459042] JSON Array Merge Example - INFO: {price: 1200, stock: 50}
[2026-01-25T15:32:13.460648] JSON Array Merge Example - INFO: Client closed.
```

`Valkey v9.0.0`

```sh
[2026-01-25T15:31:49.567024] JSON Array Merge Example - INFO: Connecting to server...
[2026-01-25T15:31:49.593256] JSON Array Merge Example - INFO: Connected.
[2026-01-25T15:31:49.593418] JSON Array Merge Example - INFO: Server detected: valkey (version 9.0.0)
[2026-01-25T15:31:49.593433] JSON Array Merge Example - INFO: Setting initial JSON value with jsonSet...
[2026-01-25T15:31:49.595518] JSON Array Merge Example - INFO: jsonSet completed.
[2026-01-25T15:31:49.595533] JSON Array Merge Example - INFO: Value before jsonMerge (jsonGet):
[2026-01-25T15:31:49.598599] JSON Array Merge Example - INFO: {price: 1000, stock: 20}
[2026-01-25T15:31:49.598617] JSON Array Merge Example - INFO: 🚀 Calling jsonMerge...
[2026-01-25T15:31:49.599312] JSON Array Merge Example - INFO: ❌ jsonMerge error: Unsupported operation: jsonMerge is not supported on Valkey.
[2026-01-25T15:31:49.599342] JSON Array Merge Example - INFO: Value after jsonMerge (jsonGet):
[2026-01-25T15:31:49.600158] JSON Array Merge Example - INFO: {price: 1000, stock: 20}
[2026-01-25T15:31:49.600172] JSON Array Merge Example - INFO: Value before jsonMergeForce (jsonGet):
[2026-01-25T15:31:49.600566] JSON Array Merge Example - INFO: {price: 1000, stock: 20}
[2026-01-25T15:31:49.600579] JSON Array Merge Example - INFO: 🚀 Calling jsonMergeForce...
[2026-01-25T15:31:49.601416] JSON Array Merge Example - INFO: ❌ jsonMergeForce error: ValkeyServerException(ERR): ERR unknown command 'JSON.MERGE', with args beginning with: 'product:1' '$' '{"price":1200,"stock":50}' 
[2026-01-25T15:31:49.601432] JSON Array Merge Example - INFO: Value after jsonMergeForce (jsonGet):
[2026-01-25T15:31:49.601814] JSON Array Merge Example - INFO: {price: 1000, stock: 20}
[2026-01-25T15:31:49.603324] JSON Array Merge Example - INFO: Client closed.
```

### json_array_price_multi_example.dart
```sh
[2026-01-25T11:28:41.571728] JSON Array Price and Multi Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-25T11:28:41.578897] JSON Array Price and Multi Example - INFO: product:1 $.price = [1100]
[2026-01-25T11:28:41.580039] JSON Array Price and Multi Example - INFO: product:2 $.price = [2000]
[2026-01-25T11:28:41.580833] JSON Array Price and Multi Example - INFO: product:2 $.vat = [200]
[2026-01-25T11:28:41.581647] JSON Array Price and Multi Example - INFO: product:2 $.price = [3000]
[2026-01-25T11:28:41.582437] JSON Array Price and Multi Example - INFO: product:2 $.vat = [300]
[2026-01-25T11:28:41.583466] JSON Array Price and Multi Example - INFO: product:2 $.vat = [600]
[2026-01-25T11:28:41.584360] JSON Array Price and Multi Example - INFO: product:2 $.price = [6000]
[2026-01-25T11:28:41.586671] JSON Array Price and Multi Example - INFO: [[{a: 1}], [{a: 2}]]
[2026-01-25T11:28:41.586695] JSON Array Price and Multi Example - INFO: Closing all cluster connections...
```

### json_array_simple_example.dart
```sh
[2026-01-24T10:00:58.933517] JSON Array Simple Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-24T10:00:58.937210] JSON Array Simple Example - INFO: New Length: [5]
[2026-01-24T10:00:58.938262] JSON Array Simple Example - INFO: Index of X: [1]
[2026-01-24T10:00:58.939248] JSON Array Simple Example - INFO: Popped Value: ["b"]
[2026-01-24T10:00:58.941429] JSON Array Simple Example - INFO: Final Array: [a, X]
[2026-01-24T10:00:58.941451] JSON Array Simple Example - INFO: Closing all cluster connections...
```

### json_basic_get_example.dart
```sh
[2026-01-23T01:36:23.137143] JSON Basic Get Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-23T01:36:23.143001] JSON Basic Get Example - INFO: User Name (expected): [Nana]
[2026-01-23T01:36:23.144700] JSON Basic Get Example - INFO: User Name (not shown): []
[2026-01-23T01:36:23.144722] JSON Basic Get Example - INFO: Closing all cluster connections...
```
OR
```sh
[2026-01-23T01:53:36.111006] JSON Basic Get Example - INFO: ❌ Error: JSON module is NOT loaded on this server.
[2026-01-23T01:53:36.111841] JSON Basic Get Example - INFO: Closing all cluster connections...
```

### json_debug_type_simple_example.dart
```sh
[2026-01-26T07:12:48.359045] JSON Debug Type Simple Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-26T07:12:48.359944] JSON Debug Type Simple Example - INFO: --- 🚀 JSON Debug/Type/Toggle Examples ---
[2026-01-26T07:12:48.362817] JSON Debug Type Simple Example - INFO: Type (root): object
[2026-01-26T07:12:48.363536] JSON Debug Type Simple Example - INFO: Type (name): string
[2026-01-26T07:12:48.364160] JSON Debug Type Simple Example - INFO: Toggled isActive: 0
[2026-01-26T07:12:48.364759] JSON Debug Type Simple Example - INFO: Memory Usage: 104 bytes
[2026-01-26T07:12:48.365544] JSON Debug Type Simple Example - INFO: RESP Dump: [{, [isActive, false], [name, Valkey], [count, 10]]
[2026-01-26T07:12:48.365565] JSON Debug Type Simple Example - INFO: Closing all cluster connections...
```

### json_obj_str_simple_example.dart
```sh
[2026-01-26T05:58:44.899724] JSON Obj and Str Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-26T05:58:44.903726] JSON Obj and Str Example - INFO: Keys: [name, age]
[2026-01-26T05:58:44.904326] JSON Obj and Str Example - INFO: Obj Len: 2
[2026-01-26T05:58:44.905651] JSON Obj and Str Example - INFO: New Str Len: 11
[2026-01-26T05:58:44.906150] JSON Obj and Str Example - INFO: Str Len: 11
[2026-01-26T05:58:44.908283] JSON Obj and Str Example - INFO: Content: Hello World
[2026-01-26T05:58:44.908315] JSON Obj and Str Example - INFO: Closing all cluster connections...
```

### json_set_and_get_example.dart
```sh
[2026-01-23T01:44:22.536583] JSON Set and Get Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-23T01:44:22.539614] JSON Set and Get Example - INFO: ✅ Saved User Data
[2026-01-23T01:44:22.542779] JSON Set and Get Example - INFO: User Result: [{name: Alice, age: 30, isStudent: false}]
[2026-01-23T01:44:22.543438] JSON Set and Get Example - INFO: User Name: [Alice]
[2026-01-23T01:44:22.544036] JSON Set and Get Example - INFO: ✅ Saved Fruits
[2026-01-23T01:44:22.544446] JSON Set and Get Example - INFO: Fruit Result: [[apple, banana, cherry]]
[2026-01-23T01:44:22.545097] JSON Set and Get Example - INFO: First Fruit: [apple]
[2026-01-23T01:44:22.545964] JSON Set and Get Example - INFO: ✅ Saved User Profile (Miami Beach Vibe)
[2026-01-23T01:44:22.546377] JSON Set and Get Example - INFO: City: [Miami Beach]
[2026-01-23T01:44:22.546841] JSON Set and Get Example - INFO: Street: [1020 Ocean Drive]
[2026-01-23T01:44:22.547618] JSON Set and Get Example - INFO: Updated Email: [support@tech-example.com]
[2026-01-23T01:44:22.548737] JSON Set and Get Example - INFO: ✅ Saved Cluster Configuration
[2026-01-23T01:44:22.549821] JSON Set and Get Example - INFO: Region: [us-east-1]
[2026-01-23T01:44:22.550421] JSON Set and Get Example - INFO: First Feature Flag: [mfa_enabled]
[2026-01-23T01:44:22.550982] JSON Set and Get Example - INFO: First Node Status: [healthy]
[2026-01-23T01:44:22.551705] JSON Set and Get Example - INFO: All Node Uptimes: [99.999, 95.995, 99.998]
[2026-01-23T01:44:22.551723] JSON Set and Get Example - INFO: Closing all cluster connections...
```
OR
```sh
[2026-01-23T01:53:53.017730] JSON Set and Get Example - INFO: ❌ Error: JSON module is NOT loaded on this server.
[2026-01-23T01:53:53.018552] JSON Set and Get Example - INFO: Closing all cluster connections...
```

### object_string_example.dart
```sh
[2026-01-26T06:28:31.168686] Object and String Example - INFO: ✅ JSON module detected. Ready to go!
[2026-01-26T06:28:31.169590] Object and String Example - INFO: --- 🚀 JSON Object & String Commands Example ---
[2026-01-26T06:28:31.169610] Object and String Example - INFO: [Part 1] JSON Object Commands
[2026-01-26T06:28:31.171694] Object and String Example - INFO: 1. Initialized object: {"user": "Alice", "meta": {...}}
[2026-01-26T06:28:31.172480] Object and String Example - INFO: 2. Root Object Length: 2 (Expected: 2)
[2026-01-26T06:28:31.173469] Object and String Example - INFO: 3. Meta Object Keys: [login_count, active] (Expected: [login_count, active])
[2026-01-26T06:28:31.173590] Object and String Example - INFO: [Part 2] JSON String Commands
[2026-01-26T06:28:31.174420] Object and String Example - INFO: 4. Initialized string: "Hello"
[2026-01-26T06:28:31.174982] Object and String Example - INFO: 5. Initial String Length: 5 (Expected: 5)
[2026-01-26T06:28:31.175436] Object and String Example - INFO: 6. Length after Append: 11 (Expected: 11)
[2026-01-26T06:28:31.177782] Object and String Example - INFO: 7. Final String Content: "Hello World"
[2026-01-26T06:28:31.177814] Object and String Example - INFO: Closing all cluster connections...
```

## example

### atomic_counters_example.dart
```sh
✅ Connected to Valkey/Redis.
Initial value: 0
INCR result: 1
INCRBY 10 result: 11
DECR result: 10
DECRBY 5 result: 5
```

### built_in_logger_example.dart
```sh
--- PART I. SHOW ALL MESSAGES ---
--- set OFF ---
[2026-01-19T18:11:21.947983] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949058] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949096] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949125] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949150] Built-in Logger Example - INFO: INFO messages
--- set FINE ---
[2026-01-19T18:11:21.949174] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949183] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949190] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949197] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949204] Built-in Logger Example - INFO: INFO messages
--- set INFO ---
[2026-01-19T18:11:21.949226] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949235] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949242] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949249] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949259] Built-in Logger Example - INFO: INFO messages
--- set WARNING ---
[2026-01-19T18:11:21.949280] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949290] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949297] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949305] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949312] Built-in Logger Example - INFO: INFO messages
--- set SEVERE ---
[2026-01-19T18:11:21.949333] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949342] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949350] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949357] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949364] Built-in Logger Example - INFO: INFO messages
--- set ERROR ---
[2026-01-19T18:11:21.949387] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949396] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949403] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949411] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949418] Built-in Logger Example - INFO: INFO messages
--- set OFF ---
[2026-01-19T18:11:21.949441] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949452] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949459] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949467] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949474] Built-in Logger Example - INFO: INFO messages

--- PART II. SHOW ONLY MESSAGES WITH SPECIFIC LOG LEVEL ---
--- set OFF ---
--- set FINE ---
[2026-01-19T18:11:21.949513] Built-in Logger Example - FINE: FINE messages
[2026-01-19T18:11:21.949521] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949531] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949538] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949547] Built-in Logger Example - INFO: INFO messages
--- set INFO ---
[2026-01-19T18:11:21.949556] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949564] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949571] Built-in Logger Example - ERROR: ERROR messages
[2026-01-19T18:11:21.949577] Built-in Logger Example - INFO: INFO messages
--- set WARNING ---
[2026-01-19T18:11:21.949585] Built-in Logger Example - WARNING: WARNING messages
[2026-01-19T18:11:21.949593] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949600] Built-in Logger Example - ERROR: ERROR messages
--- set SEVERE ---
[2026-01-19T18:11:21.949609] Built-in Logger Example - SEVERE: SEVERE messages
[2026-01-19T18:11:21.949617] Built-in Logger Example - ERROR: ERROR messages
--- set ERROR ---
[2026-01-19T18:11:21.949625] Built-in Logger Example - ERROR: ERROR messages
--- set OFF ---
```

### cluster_auto_discovery_example.dart
```sh
✅ Connected to cluster node at 127.0.0.1:7001

Fetching cluster topology using CLUSTER SLOTS...
Cluster topology loaded. Found 3 slot ranges:
--------------------
  Slots: 0 - 5460
  Master: 192.168.65.254:7001 (ID: 9cb6e8f7e10d85a7a6a30f5fc17f06a5775b1805)
  Replicas:
    - 192.168.65.254:7006 (ID: 30620559f4420dd5f05308401a2c96b34362739c)
--------------------
  Slots: 5461 - 10922
  Master: 192.168.65.254:7002 (ID: 75d08706344d98c243c9579abf89a6075f39534f)
  Replicas:
    - 192.168.65.254:7004 (ID: 9a493209da40578023c314f49a1b234de045d995)
--------------------
  Slots: 10923 - 16383
  Master: 192.168.65.254:7003 (ID: e61e5a1ebab6ead786f21183d054fc239c510495)
  Replicas:
    - 192.168.65.254:7005 (ID: bdad94835d820ffc4302ea689f2bdba6c439be8e)

Closing connection...
```

### cluster_client_example.dart
```sh
Connecting to cluster...
✅ Cluster connected and slot map loaded.

Running SET command for "key:A" (Slot 9366)...
SET response: OK

Running GET command for "key:A"...
GET response: Hello from Cluster!

Running SET command for "key:B"...
SET response: OK

Running GET command for "key:B"...
GET response: Valkey rocks!

Closing all cluster connections...
```

### cluster_failover_stress_test.dart
```sh
```

### cluster_mget_example.dart
```sh
Connecting to cluster...
✅ Connected to cluster.

Setting up test data on multiple nodes...
Executing MGET for [key:A, key:B, key:C, missing_key]...
Results: [Value-A, Value-B, Value-C, null]
✅ MGET Success: Retrieved values from multiple nodes in correct order!
```

### cluster_redirection_example.dart
```sh
Connecting to cluster...
✅ Connected.

Starting Resilience & Continuous Operations Test Loop...
----------------------------------------------------------------
👉 ACTION REQUIRED: Kill the current master node to see failover!
   Run: valkey-cli -p <PORT> DEBUG SEGFAULT
----------------------------------------------------------------

👉 TIP: Now open your terminal and try these chaos actions:
   1. valkey-cli -p 7001 DEBUG SEGFAULT (Kill a node)
   2. valkey-cli --cluster reshard ... (Move slots)
   3. Watch this client recover automatically! (MOVED/ASK handling)

[SUCCESS 1] Node 192.168.65.254:7004 | resilience:key = val-1
[SUCCESS 2] Node 192.168.65.254:7004 | resilience:key = val-2
[SUCCESS 3] Node 192.168.65.254:7004 | resilience:key = val-3
[SUCCESS 4] Node 192.168.65.254:7004 | resilience:key = val-4
[SUCCESS 5] Node 192.168.65.254:7004 | resilience:key = val-5
[SUCCESS 6] Node 192.168.65.254:7004 | resilience:key = val-6
[SUCCESS 7] Node 192.168.65.254:7004 | resilience:key = val-7
[SUCCESS 8] Node 192.168.65.254:7004 | resilience:key = val-8
[SUCCESS 9] Node 192.168.65.254:7004 | resilience:key = val-9
[SUCCESS 10] Node 192.168.65.254:7004 | resilience:key = val-10
[SUCCESS 11] Node 192.168.65.254:7004 | resilience:key = val-11
[SUCCESS 12] Node 192.168.65.254:7004 | resilience:key = val-12
[SUCCESS 13] Node 192.168.65.254:7004 | resilience:key = val-13
[SUCCESS 14] Node 192.168.65.254:7004 | resilience:key = val-14
[SUCCESS 15] Node 192.168.65.254:7004 | resilience:key = val-15
[RETRY 16] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573))
[RETRY 17] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616))
[RETRY 18] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657))
[SUCCESS 19] Node 192.168.65.254:7002 | resilience:key = val-19
[SUCCESS 20] Node 192.168.65.254:7002 | resilience:key = val-20
[SUCCESS 21] Node 192.168.65.254:7002 | resilience:key = val-21
[SUCCESS 22] Node 192.168.65.254:7002 | resilience:key = val-22
[SUCCESS 23] Node 192.168.65.254:7002 | resilience:key = val-23
[SUCCESS 24] Node 192.168.65.254:7002 | resilience:key = val-24
[SUCCESS 25] Node 192.168.65.254:7002 | resilience:key = val-25
[SUCCESS 26] Node 192.168.65.254:7002 | resilience:key = val-26
```

### cluster_robustness_example.dart
```sh
✅ Connected to Cluster.

--- Testing Cluster Robustness with Sharded Pub/Sub ---
1. Subscribed to 3 sharded channels.
2. Received all messages.
3. Unsubscribed (Internal connections cleaned up).

--- Verifying Cluster Health ---
Cluster GET result: passed
✅ Cluster is healthy! v1.7.0 Pool Hardening works.
```

### cluster_sharded_pubsub_example.dart
```sh
Connecting to cluster...
✅ Connected to cluster.

--- Starting Sharded Pub/Sub (SSUBSCRIBE) ---
✅ Subscribed to channels: [shard:news:{sports}, shard:news:{tech}]
broadcasting messages via SPUBLISH...
📩 Received: [shard:news:{sports}] Lakers won the game!
📩 Received: [shard:news:{tech}] Valkey 1.6.0 released!
✅ All messages received.
Unsubscribed.
```

### cluster_ssl_cloud.dart
```sh
```

### cluster_ssl_self_signed.dart
```sh
```

### database_selection.dart
```sh
🗄️ Starting Database Selection Example...

🔍 Server Metadata Discovered:
   - Software: valkey
   - Version:  9.0.0
   - Mode:     standalone
   - Max DBs:  16

✅ Data in DB 1: app:config:mode = production

---

🗄️ Starting Database Selection Example...

🔍 Server Metadata Discovered:
   - Software: valkey
   - Version:  9.0.0
   - Mode:     cluster
   - Max DBs:  1

✅ Data in DB 1: app:config:mode = production
```

### get_currently_connected_host_info.dart
```sh
[2026-01-19T17:47:26.313725] Get Currently Connected Host Info Example - INFO: Connected host: 127.0.0.1
[2026-01-19T17:47:26.314544] Get Currently Connected Host Info Example - INFO: Connected port: 6379
[2026-01-19T17:47:26.314556] Get Currently Connected Host Info Example - INFO: Closing all cluster connections...
```

### get_server_metadata.dart
Valkey 9.0.0
```sh
[2026-01-22T01:05:04.412779] Get Server Metadata Example - INFO: Server Name: valkey
[2026-01-22T01:05:04.413595] Get Server Metadata Example - INFO: Server Version: 9.0.0
[2026-01-22T01:05:04.413623] Get Server Metadata Example - INFO: Is RedisServer: false
[2026-01-22T01:05:04.413636] Get Server Metadata Example - INFO: Is ValkeyServer: true
[2026-01-22T01:05:04.413645] Get Server Metadata Example - INFO: Closing all cluster connections...
```
Redis 8.4.0
```sh
[2026-01-22T04:13:27.121520] Get Server Metadata Example - INFO: Server Name: redis
[2026-01-22T04:13:27.122345] Get Server Metadata Example - INFO: Server Version: 8.4.0
[2026-01-22T04:13:27.122375] Get Server Metadata Example - INFO: Is RedisServer: true
[2026-01-22T04:13:27.122386] Get Server Metadata Example - INFO: Is ValkeyServer: false
[2026-01-22T04:13:27.122395] Get Server Metadata Example - INFO: Closing all cluster connections...
```

### pool_example.dart
```sh
Simulating 5 concurrent requests with a pool size of 3...
[UserA] Acquiring connection...
[UserB] Acquiring connection...
[UserC] Acquiring connection...
[UserD] Acquiring connection...
[UserE] Acquiring connection...
[UserA] Acquired! Pinging...
[UserB] Acquired! Pinging...
[UserC] Acquired! Pinging...
[UserD] Acquired! Pinging...
[UserE] Acquired! Pinging...
[UserA] Received: Hello from UserA
[UserC] Received: Hello from UserC
[UserB] Received: Hello from UserB
[UserD] Received: Hello from UserD
[UserE] Received: Hello from UserE
[UserA] Releasing connection...
[UserC] Releasing connection...
[UserB] Releasing connection...
[UserD] Releasing connection...
[UserE] Releasing connection...

All requests handled.
Pool closed.
```

### pool_smart_release_example.dart
```sh
--- Starting v1.7.0 Smart Pool Example ---

1. Performing Transaction...
   Transaction executed.
   Client released (Smart Release handled cleanup).

2. Performing Pub/Sub...
   Subscribed to channel. Client is now dirty (Stateful).
   Pub/Sub Client released (Automatically discarded & replaced).

3. Verifying Pool Health...
   Ping response: PONG (Pool is healthy!)

✅ Example finished successfully.
```

### redis_client_basic_example.dart
```sh
value
```

### replica_read_example.dart
```sh
1 Master and 2 Replicas => ReadPreference.master

🚀 Starting Replica Read & Load Balancing Example...
✅ Connected to Master and Discovered Replicas.

✍️  Writing data (Routed to Master)...

📖 Reading data (Routed to Replicas via Round-Robin)...
   [GET user:0] -> Result: value_0 -- from Master
   [GET user:1] -> Result: value_1 -- from Master
   [GET user:2] -> Result: value_2 -- from Master
   [GET user:3] -> Result: value_3 -- from Master
   [GET user:4] -> Result: value_4 -- from Master

👋 Connection closed.

---

1 Master and 2 Replicas => ReadPreference.preferReplica

🚀 Starting Replica Read & Load Balancing Example...
✅ Connected to Master and Discovered Replicas.

✍️  Writing data (Routed to Master)...

📖 Reading data (Routed to Replicas via Round-Robin)...
   [GET user:0] -> Result: value_0 -- from Replica (6381)
   [GET user:1] -> Result: value_1 -- from Replica (6380)
   [GET user:2] -> Result: value_2 -- from Replica (6381)
   [GET user:3] -> Result: value_3 -- from Replica (6380)
   [GET user:4] -> Result: value_4 -- from Replica (6381)

👋 Connection closed.

---

1 Master and 2 Replicas => ReadPreference.replicaOnly

🚀 Starting Replica Read & Load Balancing Example...
✅ Connected to Master and Discovered Replicas.

✍️  Writing data (Routed to Master)...

📖 Reading data (Routed to Replicas via Round-Robin)...
   [GET user:0] -> Result: value_0 -- from Replica (6381)
   [GET user:1] -> Result: value_1 -- from Replica (6380)
   [GET user:2] -> Result: value_2 -- from Replica (6381)
   [GET user:3] -> Result: value_3 -- from Replica (6380)
   [GET user:4] -> Result: value_4 -- from Replica (6381)

👋 Connection closed.
```

### sharded_pubsub_example.dart
```sh
Connecting to standalone server...
✅ Connected (Subscriber & Publisher).

--- Starting Sharded Pub/Sub (Standalone) ---
Subscribing to [shard:updates:{user1}, shard:updates:{user2}]...
✅ Subscription active.
Publishing messages via SPUBLISH...
📩 Received: [shard:updates:{user1}] User 1 logged in
📩 Received: [shard:updates:{user2}] User 2 updated profile
✅ All messages received.
Unsubscribed.
```

### simple_example.dart
```sh
Hello, Valkey!
```

### simple_pool_example.dart
```sh
Hello from ValkeyPool!
```

### valkey_client_example.dart
```sh
See `docs/test_results/valkey_client_example.md`
```

### valkey_ssl_cloud.dart
```sh
```

### valkey_ssl_self_signed.dart
```sh
🔒 [Dev] Connecting to Standalone SSL (Self-Signed)...
  ✅ Connected securely!
  Value: works
  📤 PING -> 📥 PONG
  📤 GET ssl_key -> 📥 Hello Secure World

OR

🔒 [Dev] Connecting to Standalone SSL (Self-Signed)...
  ⚠️ Ignoring certificate error for: /CN=localhost
  ✅ Connected securely!
  Value: works
  📤 PING -> 📥 PONG
  📤 GET ssl_key -> 📥 Hello Secure World
```

---

## test

### atomic_counters_test.dart
```sh
00:00 +1: All tests passed!
```

### cluster_hash_test.dart
```sh
00:00 +4: All tests passed!
```

### cluster_slot_map_test.dart
```sh
00:00 +0: ClusterSlotMap updateSlot should correctly modify the node for a specific slot
[2025-12-16T00:06:57.570657] ClusterSlotMap - INFO: key = robustness_check
[2025-12-16T00:06:57.573907] ClusterSlotMap - INFO: slot = 16173
[2025-12-16T00:06:57.575253] ClusterSlotMap - INFO: key = robustness_check
[2025-12-16T00:06:57.575288] ClusterSlotMap - INFO: slot = 16173
[2025-12-16T00:06:57.576458] ClusterSlotMap - INFO: key = foo
[2025-12-16T00:06:57.576499] ClusterSlotMap - INFO: slot = 12182
[2025-12-16T00:06:57.576531] ClusterSlotMap - INFO: key = foo
[2025-12-16T00:06:57.576553] ClusterSlotMap - INFO: slot = 12182
00:00 +1: All tests passed!
```

### cluster_slots_parser_test.dart
```sh
00:00 +6: All tests passed!
```

### database_selection_test.dart
```sh
```

### example_test.dart
```sh
```

### replica_read_test.dart
```sh
```

### sharded_pubsub_test.dart
```sh
00:00 +0: SPUBLISH should execute without error
SPUBLISH sent successfully. Receivers: 0
00:00 +1: All tests passed!
```

### ssl_connection_test_single_and_cluster.dart
```sh
```

### ssl_connection_test_single_mtls.dart
```sh
```

### ssl_connection_test_single_ssl_and_mtls.dart
```sh
```

### ssl_connection_test_single_tls.dart
```sh
```

### valkey_client_sharded_test.dart
```sh
# for both modes (Standalone and Cluster)

00:00 +0: ValkeyClient Sharded Pub/Sub ssubscribe receives messages published via spublish
Subscribing to shard-channel:{1}...
Publishing to shard-channel:{1}...
Received message on shard-channel:{1}: Hello Sharding
00:00 +1: All tests passed!
```

### valkey_client_test.dart
```sh
00:00 +41: ValkeyClient Pub/Sub should receive messages on subscribed channel
TEST: Waiting for subscription ready...
TEST: Subscription ready!
TEST Publishing message 1...
TEST received: Hello from test 1
TEST Publishing message 2...
TEST received: Hello from test 2
TEST Waiting for message 1...
TEST Received message 1 OK
TEST Waiting for message 2...
TEST Received message 2 OK
00:03 +56: All tests passed!
```

### valkey_cluster_client_test.dart
```sh
00:00 +3: All tests passed!
```

### valkey_cluster_redirection_test.dart
```sh
00:00 +1: All tests passed!
```

### valkey_cluster_sharded_test.dart
```sh
00:00 +0: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster: Subscribing to [shard:channel:{a}, shard:channel:{b},
                         shard:channel:{c}]...
Cluster: Subscription READY.
Cluster: Publishing messages...
Cluster Received: [shard:channel:{a}] msg-a
Cluster Received: [shard:channel:{b}] msg-b
Cluster Received: [shard:channel:{c}] msg-c
✅ All messages received from multiple shards!
00:00 +1: All tests passed!
```

### valkey_pool_test.dart
```sh
00:00 +6: All tests passed!
```
