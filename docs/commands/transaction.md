<!--
Copyright 2025-2026 Infradise Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# TRANSACTION

| valkey_client | Redis                                                     | Valkey                                         |
|---------------|-----------------------------------------------------------|------------------------------------------------|
| `discard`     | [DISCARD](https://redis.io/docs/latest/commands/discard/) | [DISCARD](https://valkey.io/commands/discard/) |
| `exec`        | [EXEC](https://redis.io/docs/latest/commands/exec/)       | [EXEC](https://valkey.io/commands/exec/)       |
| `multi`       | [MULTI](https://redis.io/docs/latest/commands/multi/)     | [MULTI](https://valkey.io/commands/multi/)     |
| `unwatch`     | [UNWATCH](https://redis.io/docs/latest/commands/unwatch/) | [UNWATCH](https://valkey.io/commands/unwatch/) |
| `watch`       | [WATCH](https://redis.io/docs/latest/commands/watch/)     | [WATCH](https://valkey.io/commands/watch/)     |