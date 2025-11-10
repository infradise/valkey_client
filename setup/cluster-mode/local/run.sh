# 3 masters for local development and test environment
docker run -it --net local_valkey-net valkey/valkey \
  valkey-cli --cluster create \
  127.0.0.1:7001 \
  127.0.0.1:7002 \
  127.0.0.1:7003 \
  --cluster-replicas 0

# OUTPUT:
# >>> Performing hash slots allocation on 3 node(s)...
# Primary[0] -> Slots 0 - 5460
# Primary[1] -> Slots 5461 - 10922
# Primary[2] -> Slots 10923 - 16383
# M: HASH1 valkey-7000:7000
#    slots:[0-5460] (5461 slots) master
# M: HASH2 valkey-7001:7001
#    slots:[5461-10922] (5462 slots) master
# M: HASH3 valkey-7002:7002
#    slots:[10923-16383] (5461 slots) master
# Can I set the above configuration? (type 'yes' to accept): yes
# >>> Nodes configuration updated
# >>> Assign a different config epoch to each node
# >>> Sending CLUSTER MEET messages to join the cluster
# Waiting for the cluster to join

# >>> Performing Cluster Check (using node valkey-7000:7000)
# M: HASH1 valkey-7000:7000
#    slots:[0-5460] (5461 slots) master
# M: HASH2 192.120.0.3:7002
#    slots:[10923-16383] (5461 slots) master
# M: HASH3 192.120.0.2:7001
#    slots:[5461-10922] (5462 slots) master
# [OK] All nodes agree about slots configuration.
# >>> Check for open slots...
# >>> Check slots coverage...
# [OK] All 16384 slots covered.