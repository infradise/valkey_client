# Testing for Valkey

## Standalone/Sentinel environments
```sh
docker run --name my-valkey -p 6379:6379 valkey/valkey:latest
```

## JSON environment

Valkey JSON, Valkey Bloom, Valkey Search, LDAP

```sh
# Valkey 9.0.0
docker run --name valkey-json-test -p 6379:6379 valkey/valkey-bundle:latest
```

OR

```sh
docker run --name my-valkey -p 6379:6379 valkey/valkey:8.1.0
# from [Docker image](https://hub.docker.com/r/valkey/valkey/)
```

## Sentinel environment

```
docker compose -f replica_read_m1r2.yaml -p valkey-sentinel-nonssl up --force-recreate
```

## Cluster environment

## Non-SSL
```sh
docker compose -f valkey_macos.yaml -p valkey-cluster-nonssl up --force-recreate
# -d: background
```

### SSL(TLS/mTLS)
```sh
docker compose -f valkey_macos_tls.yaml -p valkey-cluster-ssl up --force-recreate
# -d: background
```


## OpenSSL

```sh
mkdir -p tests/tls
openssl req -x509 -newkey rsa:4096 -keyout tests/tls/valkey.key -out tests/tls/valkey.crt -days 365 -nodes -subj '/CN=localhost'
# chmod 644 tests/tls/*
```

## TLS environment
```sh
docker run --name valkey-ssl-tls \
  -v $(pwd)/tests/tls:/tls \
  -p 6380:6379 \
  valkey/valkey:latest \
  --tls-port 6379 \
  --port 0 \
  --tls-cert-file /tls/valkey.crt \
  --tls-key-file /tls/valkey.key \
  --tls-ca-cert-file /tls/valkey.crt \
  --tls-auth-clients no
```

## mTLS environment
```sh
docker run --name valkey-ssl-mtls \
  -v $(pwd)/tests/tls:/tls \
  -p 6381:6379 \
  valkey/valkey:latest \
  --tls-port 6379 \
  --port 0 \
  --tls-cert-file /tls/valkey.crt \
  --tls-key-file /tls/valkey.key \
  --tls-ca-cert-file /tls/valkey.crt \
  --tls-auth-clients yes
```