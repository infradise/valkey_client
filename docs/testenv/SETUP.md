
## How To Setup Standalone/Sentinel/Cluster

This section describe how to install a `Valkey` or `Redis` Server on your local environment.

### Kubernetes: Local Setup

1. Run [Rancher Desktop](https://rancherdesktop.io/) to set up a local `Kubernetes` cluster.
2. In **Android Studio** or a **JetBrains IDE**:  
   - Go to **Plugin > Visualkube Jet > Cluster Manager**  
   - Connect one or more `Kubernetes` clusters  
   - Navigate to **Helm > Charts**  
   - Search for `redis`, `redis-cluster`, `valkey`, or `valkey-cluster`  
   - Install and choose a target cluster
3. In **Android Studio** or a **JetBrains IDE**:  
   - Go to **Plugin > Keyscope > Cluster Manager**  
   - Add a connection and choose **Standalone**, **Cluster**, or **Sentinel** mode  
   - Double‑click your `myRedis` or `myValkey` server  
   - Double‑click **Database**  
   - Double‑click a **Key type**  
   - Click keys to view their values

### Docker: Local Standalone Setup

This client requires a running `Valkey` or `Redis` server to connect to. For local development and testing, we strongly recommend using Docker.

1.  Install a container environment like [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2.  Start a [Valkey](https://hub.docker.com/r/valkey/valkey) or [Redis](https://hub.docker.com/_/redis) server instance by running one of the following commands in your terminal:

**Option 1: No Authentication (Default)**

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis -p 6379:6379 redis:latest
```

**Option 2: With Password Only**
(This sets the password for the `default` user. Use with `username: null` in the client.)

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey-auth -p 6379:6379 valkey/valkey:latest \
  --requirepass "my-super-secret-password"

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis-auth -p 6379:6379 redis:latest \
  --requirepass "my-super-secret-password"
```

**Option 3: With Username and Password (ACL)**
(This sets the password for the `default` user. Use with `username: 'default'` in the client.)

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey-acl -p 6379:6379 valkey/valkey:latest \
  --user default --pass "my-super-secret-password"

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis-acl -p 6379:6379 redis:latest \
  --user default --pass "my-super-secret-password"
```

  * Valkey/Redis 6+ uses ACLs. The `default` user exists by default. To create a new user instead, simply change `--user default` to `--user my-user`.

*(Note: The '-d' flag runs the container in "detached" mode (in the background). You can remove it if you want to see the server logs directly in your terminal.)*


### Docker Compose: Local Cluster Setup

The **Usage (Group 3)** examples require a running Valkey Cluster or Redis Cluster.

Setting up a cluster on Docker Desktop (macOS/Windows) is notoriously complex due to the networking required for NAT (mapping internal container IPs to `127.0.0.1`).

To solve this and encourage contributions, the GitHub repository provides a pre-configured, one-command setup file.

**File Location:**

  * [`setup/cluster-mode/prod/valkey_macos.yaml`](https://github.com/infradise/valkey_client/blob/main/setup/cluster-mode/prod/valkey_macos.yaml)
  * [`setup/cluster-mode/prod/redis_macos.yaml`](https://github.com/infradise/valkey_client/blob/main/setup/cluster-mode/prod/redis_macos.yaml)

Each provided YAML file is a Docker Compose configuration that launches a 6-node (3 Master, 3 Replica) cluster. It is already configured to handle all IP announcement (e.g., `--cluster-announce-ip`) and networking challenges automatically.

**How to Run the Cluster:**

1.  Download the `valkey_macos.yaml` or `redis_macos.yaml` file from the repository.
2.  In your terminal, navigate to the file's location.
3.  To start the cluster, run one of the following commands:
    ```sh
    # To start Valkey Cluster
    docker compose -f valkey_macos.yaml up --force-recreate

    # To start Redis Cluster
    docker compose -f redis_macos.yaml up --force-recreate
    ```
4.  Wait for the `cluster-init` service to log `✅ Cluster is stable and all slots are covered!`.

Your 6-node cluster is now running on `127.0.0.1:7001-7006`, and you can successfully run the **Usage (Group 3)** examples.

**Note:** This configuration starts from port `7001` (instead of the common `7000`) because port 7000 is often reserved by the macOS Control Center (AirPlay Receiver) service.