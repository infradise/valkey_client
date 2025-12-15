
3 masters and 3 replicas: 
- Run firstly this example and initially shutdown all masters. 
- Then power up the masters and shutdown all replicas.
- Check the pair (master-replica) and then shutdown the node one by one properly.

```sh
dart run example/cluster_failover_stress_test.dart
```

```log
EXPECTED OUTPUT
===============

✅ Cluster connected. Starting Stress Test...
Press Ctrl+C to stop.

❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 1 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 2 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 3 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 4 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 5 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 6 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 7 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 8 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 9 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 10 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 11 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 12 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 13 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 14 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 15 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 16 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 17 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 18 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 19 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 20 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 21 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 22 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 23 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 24 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 25 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 26 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 27 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 28 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 29 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 30 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 31 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 32 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 33 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 0 | Failed: 34 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 395 | Failed: 35 | Last: OK
❌ Operation Failed: ValkeyClientException: Cluster operation failed after 6 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60371 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60371) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60371 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60371))
[Stress Test] Success: 398 | Failed: 36 | Last: OK   ERED (1993ms)
❌ Operation Failed: ValkeyClientException: Cluster operation failed after 6 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60621 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60621) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60621 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60621))
[Stress Test] Success: 401 | Failed: 37 | Last: OK   ERED (1257ms)
❌ Operation Failed: ValkeyClientException: Cluster operation failed after 6 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60886 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60886) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60886 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 60886))
[Stress Test] Success: 401 | Failed: 38 | Last: RECOVERED (1260ms)
❌ Operation Failed: ValkeyClientException: Cluster operation failed after 6 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 61101 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 61101) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7003. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 61101 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 61101))
[Stress Test] Success: 401 | Failed: 39 | Last: RECOVERED (1258ms)
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 401 | Failed: 40 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 401 | Failed: 41 | Last: OK
❌ Operation Failed: ValkeyServerException(CLUSTERDOWN): CLUSTERDOWN The cluster is down
[Stress Test] Success: 1278 | Failed: 42 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1321 val-1321
[Stress Test] Success: 1281 | Failed: 43 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1325 val-1325
[Stress Test] Success: 1284 | Failed: 44 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1329 val-1329
[Stress Test] Success: 1286 | Failed: 45 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1332 val-1332
[Stress Test] Success: 1289 | Failed: 46 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1336 val-1336
[Stress Test] Success: 1292 | Failed: 47 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1340 val-1340
[Stress Test] Success: 1294 | Failed: 48 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1343 val-1343
[Stress Test] Success: 1294 | Failed: 49 | Last: RECOVERED (10002ms)
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1344 val-1344
[Stress Test] Success: 1296 | Failed: 50 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1347 val-1347
[Stress Test] Success: 1296 | Failed: 51 | Last: RECOVERED (10002ms)
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1348 val-1348
[Stress Test] Success: 1300 | Failed: 52 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1353 val-1353
[Stress Test] Success: 1303 | Failed: 53 | Last: OK
❌ Operation Failed: ValkeyClientException: Command timed out after 10000ms: SET stress:key:1357 val-1357
[Stress Test] Success: 1303 | Failed: 54 | Last: RECOVERED (10002ms)   Unhandled exception:
SocketException: Connection reset by peer (OS Error: Connection reset by peer, errno = 54), address = 127.0.0.1, port = 55042
```