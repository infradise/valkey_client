# Testing for Valkey

## Standalone/Sentinel environments
```sh
docker run --name my-valkey -p 6379:6379 valkey/valkey:latest
```

## Cluster environment
```sh
docker compose -f valkey_macos.yaml up --force-recreate
```
