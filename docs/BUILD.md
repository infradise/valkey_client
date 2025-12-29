# Build instructions

## Testing

Run all unit tests and example validations tagged as `example`.  
Ensure that either a local Redis (e.g., v8.2.4) or Valkey (e.g., v9.0.0) server is running:  
- Standalone mode: default port 6379 (no authentication)  
- Cluster mode: ports 7001–7006

### Unit Tests
Run only the unit tests, excluding the example validations tagged as `example`:

```sh
dart test --exclude-tags example
```

Expected output:
```sh
00:03 +81: All tests passed!
```

### SSL Tests

#### TLS environment
```sh
# pwd: docs/testenv/[redis or valkey]
dart test ../../../test/ssl_connection_test_single_tls.dart
```

Expected output:
```sh
00:00 +2: All tests passed!
```

#### mTLS environment
```sh
# pwd: docs/testenv/[redis or valkey]
dart test ../../../test/ssl_connection_test_single_mtls.dart
```

Expected output:
```sh
00:00 +1: All tests passed!
```

### Examples
Run the example validations defined in `test/example_test.dart`:  
```sh
dart test --tags example
```

Expected output:
```sh
00:07 +13: All tests passed!
```

### Excluded Example
The files below are excluded from the automated test suite.  
Execute it separately when needed:

```sh
dart run example/cluster_redirection_example.dart
```

Expected output:
```sh
[SUCCESS 1] Node 192.168.65.254:7002 | resilience:key = val-1
...
[SUCCESS 22] Node 192.168.65.254:7002 | resilience:key = val-22
# Power-off this node.
[RETRY 23] Client error: ValkeyClientException: Cluster operation failed ...
[RETRY 24] ...
[RETRY 25] ...
# Redirected successfuly.
[SUCCESS 26] Node 192.168.65.254:7006 | resilience:key = val-26
```

```sh
dart run example/cluster_failover_stress_test.dart
```

Expected output:
```sh
# Nodes: 7003, 7005, 7006
[Stress Test] nodeStr = 192.168.65.254:7006 | Success: 27 | Failed: 0 | Last: OK
# Power-off node 7006.
❌ Operation Failed: ValkeyClientException: Cluster operation failed. 
# Nodes: 7003, 7005, 7002. The node 7002 successfully takes over 7006.
[Stress Test] nodeStr = 192.168.65.254:7005 | Success: 56 | Failed: 1 | Last: OK
```

This example runs indefinitely to simulate cluster topology changes and validate redirection resilience.  
Because it intentionally loops forever, it is not included in the automated test run.

## Check Dart Formatting

Ensure the code adheres to Dart formatting guidelines.

```sh
dart format .
```

## Analyze Code

Check for static errors, warnings, and lints to ensure code quality and adherence to Dart best practices.

```sh
dart analyze
```

## Pre-Publish Check

Verify that the package is ready for publishing without actually uploading it.

```sh
dart pub get
dart pub publish --dry-run
```

## Bump to New Version

### Edit pubspec.yaml

Update the `version` field in `pubspec.yaml` to the new version number.

```yaml
# version: 1.7.0  # Previous version
version: 1.8.0   # New version
```

### Commit the Version Bump

Commit the version change with a conventional commit message.

```
build: bump version to 1.8.0
```

## Tag the Release Locally

Create a Git tag corresponding to the new version and push it to the remote repository.

```sh
git tag v1.8.0
git push origin v1.8.0
```

## Create GitHub Release

Create a new release on GitHub. Use the tag you just created (e.g., `v1.8.0`). Copy the relevant section from `CHANGELOG.md` into the release notes.

## Publish to pub.dev

**Final Check:** Before publishing, double-check everything (version number in `pubspec.yaml`, `CHANGELOG.md` entry, successful tests, correct formatting). Ensure no sensitive information is included.

**Publish:** Once you are confident, publish the package to `pub.dev`.

```sh
dart pub publish
```