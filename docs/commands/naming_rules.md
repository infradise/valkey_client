
# Lists

# Naming Conventions

This document outlines the coding standards and naming conventions used in the `valkey_client` package. We prioritize **readability** and **semantic clarity** over rigid abbreviation splitting.

## 1. General Style Rules

We adhere to standard Dart conventions with specific patterns for command implementations.

| Component      | Style        | Example                        |
|:---------------|:-------------|:-------------------------------|
| **File Names** | `snake_case` | `h_get.dart`, `bl_pop.dart`    |
| **Extensions** | `PascalCase` | `HGetCommand`, `BlPopCommand`  |
| **Methods**    | `camelCase`  | `hGet(...)`, `blPop(...)`      |
| **Mixins**     | `PascalCase` | `HashCommands`, `ListCommands` |

## 2. Command Abbreviation Logic (List Commands)

Redis/Valkey commands often use concatenated abbreviations (e.g., `BLPOP`, `RPUSHX`).
Instead of splitting every single character, we group them by **semantic meaning** to preserve the context of the operation.

### Key Prefixes & Suffixes

| Abbr  | Full Meaning        | Description                                        | Usage Example    |
|:------|:--------------------|:---------------------------------------------------|:-----------------|
| **B** | **B**locking        | Blocks connection until data is available.         | `BLPOP`, `BRPOP` |
| **L** | **L**eft / **L**ist | Head of the list (Left) or the List itself.        | `LPUSH`, `LLEN`  |
| **R** | **R**ight           | Tail of the list.                                  | `RPUSH`, `RPOP`  |
| **M** | **M**ulti           | Operations involving multiple keys or elements.    | `LMPOP`          |
| **X** | E**x**ists          | Operation executes only if the key already exists. | `LPUSHX`         |

### Grouping Strategy for File Names

When naming files, we group these prefixes into recognizable units:

1.  **Blocking Operations (`bl`, `br`)**
    * `BL` and `BR` are treated as single semantic units.
    * Example: `BLPOP` → `bl_pop.dart` (Not `b_l_pop.dart`)

2.  **Multi-List Operations (`lm`, `blm`)**
    * `LM` (List Multi) and `BLM` (Blocking List Multi) are grouped.
    * Example: `LMPOP` → `lm_pop.dart`

3.  **Conditional Suffix (`_x`)**
    * The `X` suffix is always separated to highlight the "If Exists" condition.
    * Example: `LPUSHX` → `l_push_x.dart`

4.  **Directional Composition**
    * Composite commands like `RPOPLPUSH` are split by action direction.
    * Example: `RPOPLPUSH` → `r_pop_l_push.dart` (Right Pop + Left Push)

## 3. Command Mapping Examples

Below is the mapping table for List commands, demonstrating how standard commands translate to our file and method structure.

| Command        | File Name (`snake_case`) | Extension Name (`PascalCase`) | Method Name (`camelCase`) |
|:---------------|:-------------------------|:------------------------------|:--------------------------|
| **BLMOVE**     | `bl_move.dart`           | `BlMove`                      | `blMove`                  |
| **BLMPOP**     | `blm_pop.dart`           | `BlmPop`                      | `blmPop`                  |
| **BLPOP**      | `bl_pop.dart`            | `BlPop`                       | `blPop`                   |
| **BRPOP**      | `br_pop.dart`            | `BrPop`                       | `brPop`                   |
| **BRPOPLPUSH** | `br_pop_l_push.dart`     | `BrPopLPush`                  | `brPopLPush`              |
| **LINDEX**     | `l_index.dart`           | `LIndex`                      | `lIndex`                  |
| **LINSERT**    | `l_insert.dart`          | `LInsert`                     | `lInsert`                 |
| **LLEN**       | `l_len.dart`             | `LLen`                        | `lLen`                    |
| **LMOVE**      | `l_move.dart`            | `LMove`                       | `lMove`                   |
| **LMPOP**      | `lm_pop.dart`            | `LmPop`                       | `lmPop`                   |
| **LPOP**       | `l_pop.dart`             | `LPop`                        | `lPop`                    |
| **LPOS**       | `l_pos.dart`             | `LPos`                        | `lPos`                    |
| **LPUSH**      | `l_push.dart`            | `LPush`                       | `lPush`                   |
| **LPUSHX**     | `l_push_x.dart`          | `LPushX`                      | `lPushX`                  |
| **LRANGE**     | `l_range.dart`           | `LRange`                      | `lRange`                  |
| **LREM**       | `l_rem.dart`             | `LRem`                        | `lRem`                    |
| **LSET**       | `l_set.dart`             | `LSet`                        | `lSet`                    |
| **LTRIM**      | `l_trim.dart`            | `LTrim`                       | `lTrim`                   |
| **RPOP**       | `r_pop.dart`             | `RPop`                        | `rPop`                    |
| **RPOPLPUSH**  | `r_pop_l_push.dart`      | `RPopLPush`                   | `rPopLPush`               |
| **RPUSH**      | `r_push.dart`            | `RPush`                       | `rPush`                   |
| **RPUSHX**     | `r_push_x.dart`          | `RPushX`                      | `rPushX`                  |