# Valkey JSON

OPERATIONS ON THE JSON DATA TYPE

| Operations     | Description |
|----------------|-------------|
| JSON.ARRAPPEND | Append one or more values to the array values at the path. |
| JSON.ARRINDEX  | Search for the first occurrence of a scalar JSON value in arrays located at the specified path. Indices out of range are adjusted. |
| JSON.ARRINSERT | Insert one or more values into an array at the given path before the specified index. |
| JSON.ARRLEN    | Get length of the array at the path. |
| JSON.ARRPOP    | Remove and returns the element at the given index. Popping an empty array returns null. |
| JSON.ARRTRIM   | Trim the array at the path so that it becomes subarray [start, end], both inclusive. |
| JSON.CLEAR     | Clear the arrays or an object at the specified path. |
| JSON.DEBUG     | Reports information. Supported subcommands are: MEMORY, DEPTH, FIELDS, HELP |
| JSON.DEL       | Delete the JSON values at the specified path in a document key. |
| JSON.FORGET    | An alias of JSON.DEL. |
| JSON.GET       | Get the serialized JSON at one or multiple paths. |
| JSON.MGET      | Get serialized JSONs at the path from multiple document keys. Return null for non-existent key or JSON path. |
| JSON.MSET      | Set multiple JSON values at the path to multiple keys. |
| JSON.NUMINCRBY | Increment the number values at the path by a given number. |
| JSON.NUMMULTBY | Multiply the numeric values at the path by a given number. |
| JSON.OBJKEYS   | Retrieve the key names from the objects at the specified path. |
| JSON.OBJLEN    | Get the number of keys in the object at the specified path.
| JSON.RESP      | Return the JSON value at the given path in Redis Serialization Protocol (RESP). |
| JSON.SET       | Set JSON values at the specified path. |
| JSON.STRAPPEND | Append a string to the JSON strings at the specified path. |
| JSON.STRLEN    | Get the length of the JSON string values at the specified path. |
| JSON.TOGGLE    | Toggle boolean values between true and false at the specified path. |
| JSON.TYPE      | Report the type of the values at the given path. |

© Valkey contributors. For more details, see https://valkey.io/commands/#json.