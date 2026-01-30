# HASH

OPERATIONS ON THE HASH DATA TYPE

| Operations   | Description |
|--------------|-------------|
| HDEL         | Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain. |
| HEXISTS      | Determines whether a field exists in a hash. |
| HEXPIRE      | Set expiry time on hash fields. |
| HEXPIREAT    | Set expiry time on hash fields. |
| HEXPIRETIME  | Returns Unix timestamps in seconds since the epoch at which the given key's field(s) will expire |
| HGET         | Returns the value of a field in a hash. |
| HGETALL      | Returns all fields and values in a hash. |
| HGETEX       | Get the value of one or more fields of a given hash key, and optionally set their expiration time or time-to-live (TTL).  |
| HINCRBY      | Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.  |
| HINCRBYFLOAT | Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.  |
| HKEYS        | Returns all fields in a hash. |
| HLEN         | Returns the number of fields in a hash.  |
| HMGET        | Returns the values of all fields in a hash.  |
| HMSET        | Sets the values of multiple fields.  |
| HPERSIST     | Remove the existing expiration on a hash key's field(s).  |
| HPEXPIRE     | Set expiry time on hash object.  |
| HPEXPIREAT   | Set expiration time on hash field.  |
| HPEXPIRETIME | Returns the Unix timestamp in milliseconds since Unix epoch at which the given key's field(s) will expire.  |
| HPTTL        | Returns the remaining time to live in milliseconds of a hash key's field(s) that have an associated expiration.  |
| HRANDFIELD   | Returns one or more random fields from a hash. |
| HSCAN        | Iterates over fields and values of a hash. |
| HSET         | Creates or modifies the value of a field in a hash. |
| HSETEX       | Set the value of one or more fields of a given hash key, and optionally set their expiration time. |
| HSETNX       | Sets the value of a field in a hash only when the field doesn't exist. |
| HSTRLEN      | Returns the length of the value of a field. |
| HTTL         | Returns the remaining time to live (in seconds) of a hash key's field(s) that have an associated expiration. |
| HVALS        | Returns all values in a hash. |

© Valkey contributors. For more details, see https://valkey.io/commands/#hash.