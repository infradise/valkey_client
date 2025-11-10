# 3 master + 3 replica for production-like environment
# docker run -it --net valkey-net valkey/valkey \
#   valkey-cli --cluster create \
#   valkey-7000:7000 valkey-7001:7001 valkey-7002:7002 \
#   valkey-7003:7003 valkey-7004:7004 valkey-7005:7005 \
#   --cluster-replicas 1

echo "Waiting for all 6 cluster nodes to be ready..."

# Wait for each node''s port to be open
for port in 7001 7002 7003 7004 7005 7006; do
  host="valkey-${port}"
  echo "Waiting for ${host}:${port}..."

  # Keep trying to connect until success
  until valkey-cli -h ${host} -p ${port} ping > /dev/null 2>&1; do
    echo "Node ${host} not ready yet, retrying in 1s..."
    sleep 1
  done
  echo "${host} is ready!"
done

echo "All nodes are up. Creating cluster..."
sleep 2 # Final short delay for good measure

# Now run the create command
echo "Yes" | valkey-cli --cluster create \
  valkey-7001:7001 \
  valkey-7002:7002 \
  valkey-7003:7003 \
  valkey-7004:7004 \
  valkey-7005:7005 \
  valkey-7006:7006 \
  --cluster-replicas 1
'