# HASH

OPERATIONS ON THE HASH DATA TYPE

| Operations                                              | Description                                                                                                              |
|---------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| [HDEL](https://valkey.io/commands/hdel/)                | Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.                           |
| [HEXISTS](https://valkey.io/commands/hexists/)          | Determines whether a field exists in a hash.                                                                             |
| [HEXPIRE](https://valkey.io/commands/hexpire/)          | Set expiry time on hash fields.                                                                                          |
| [HEXPIREAT](https://valkey.io/commands/hexpireat/)      | Set expiry time on hash fields.                                                                                          |
| [HEXPIRETIME](https://valkey.io/commands/hexpiretime)   | Returns Unix timestamps in seconds since the epoch at which the given key's field(s) will expire                         |
| [HGET](https://valkey.io/commands/hget/)                | Returns the value of a field in a hash.                                                                                  |
| [HGETALL](https://valkey.io/commands/hgetall/)          | Returns all fields and values in a hash.                                                                                 |
| [HGETEX](https://valkey.io/commands/hgetex/)            | Get the value of one or more fields of a given hash key, and optionally set their expiration time or time-to-live (TTL). |
| [HINCRBY](https://valkey.io/commands/hincrby/)          | Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.       |
| [HINCRBYFLOAT](https://valkey.io/commands/hincrbyfloat) | Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.          |
| [HKEYS](https://valkey.io/commands/hkeys/)              | Returns all fields in a hash.                                                                                            |
| [HLEN](https://valkey.io/commands/hlen/)                | Returns the number of fields in a hash.                                                                                  |
| [HMGET](https://valkey.io/commands/hmget/)              | Returns the values of all fields in a hash.                                                                              |
| [HMSET](https://valkey.io/commands/hmset/)              | Sets the values of multiple fields.                                                                                      |
| [HPERSIST](https://valkey.io/commands/hpersist/)        | Remove the existing expiration on a hash key's field(s).                                                                 |
| [HPEXPIRE](https://valkey.io/commands/hpexpire/)        | Set expiry time on hash object.                                                                                          |
| [HPEXPIREAT](https://valkey.io/commands/hpexpireat/)    | Set expiration time on hash field.                                                                                       |
| [HPEXPIRETIME](https://valkey.io/commands/hpexpiretime) | Returns the Unix timestamp in milliseconds since Unix epoch at which the given key's field(s) will expire.               |
| [HPTTL](https://valkey.io/commands/hpttl/)              | Returns the remaining time to live in milliseconds of a hash key's field(s) that have an associated expiration.          |
| [HRANDFIELD](https://valkey.io/commands/hrandfield/)    | Returns one or more random fields from a hash.                                                                           |
| [HSCAN](https://valkey.io/commands/hscan/)              | Iterates over fields and values of a hash.                                                                               |
| [HSET](https://valkey.io/commands/hset/)                | Creates or modifies the value of a field in a hash.                                                                      |
| [HSETEX](https://valkey.io/commands/hsetex/)            | Set the value of one or more fields of a given hash key, and optionally set their expiration time.                       |
| [HSETNX](https://valkey.io/commands/hsetnx/)            | Sets the value of a field in a hash only when the field doesn't exist.                                                   |
| [HSTRLEN](https://valkey.io/commands/hstrlen/)          | Returns the length of the value of a field.                                                                              |
| [HTTL](https://valkey.io/commands/httl/)                | Returns the remaining time to live (in seconds) of a hash key's field(s) that have an associated expiration.             |
| [HVALS](https://valkey.io/commands/hvals/)              | Returns all values in a hash.                                                                                            |

© Valkey contributors. For more details, see https://valkey.io/commands/#hash.