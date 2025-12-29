# Testing for Redis

## Standalone/Sentinel environments
```sh
docker run --name my-redis -p 6379:6379 redis:latest
```

## Cluster environment
```sh
docker compose -f redis_macos.yaml up --force-recreate
```

## OpenSSL

```sh
mkdir -p tests/tls
openssl req -x509 -newkey rsa:4096 -keyout tests/tls/redis.key -out tests/tls/redis.crt -days 365 -nodes -subj '/CN=localhost'
# chmod 644 tests/tls/*
```

## TLS environment
```sh
docker run --name redis-ssl-tls \
  -v $(pwd)/tests/tls:/tls \
  -p 6380:6379 \
  redis:latest \
  --tls-port 6379 \
  --port 0 \
  --tls-cert-file /tls/redis.crt \
  --tls-key-file /tls/redis.key \
  --tls-ca-cert-file /tls/redis.crt \
  --tls-auth-clients no
```

## mTLS environment
```sh
docker run --name redis-ssl-mtls \
  -v $(pwd)/tests/tls:/tls \
  -p 6380:6379 \
  redis:latest \
  --tls-port 6379 \
  --port 0 \
  --tls-cert-file /tls/redis.crt \
  --tls-key-file /tls/redis.key \
  --tls-ca-cert-file /tls/redis.crt \
  --tls-auth-clients yes
```