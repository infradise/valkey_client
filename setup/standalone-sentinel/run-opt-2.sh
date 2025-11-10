docker run --name my-valkey-auth -p 6379:6379 valkey/valkey:latest \
  --requirepass "my-super-secret-password"