# Testing for Redis

## Standalone/Sentinel environments
```sh
docker run --name my-redis -p 6379:6379 redis:latest
```

## Cluster environment
```sh
docker compose -f redis_macos.yaml up --force-recreate
```
