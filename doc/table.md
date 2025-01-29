# Tables

Lua has a single complex data structure called the Table. It can be used both as an array (sequential table) and as a hash table (dictionary/associative array).

Lua tables can be constructed and used from Equinox, but unlike in Lua, we differentiate sequential tables from hash tables syntactically.

```forth
[] \ create an empty sequential table
{} \ create an empty hash table

[ 1 2 3 ] \ create a sequential table with 1, 2 and 3

{ "key1" 4  $key2 5 } \ create a hash table with key1=4 and key2=5

```

Sequential tables or arrays are created using square brackets (`[]`), while hash tables are created with curly braces (`{}`).

The dollar (`$`) prefix can be used as a shorthand to denote a symbol, which is represented as a string that cannot contain whitespaces.

## Access

The at (`@`) word can be used to index an array or look up a value under a key in a hash table.

```forth
[ "a" "b" "c" ] 2 @ . \ prints out "b"

{ "key1" "val" } "key1" @ . \ prints out "val"
```

If the key is a symbol with no whitespaces or special characters, you can also use the dot notation.

```forth
var tbl

{ "key1" "val" } -> tbl \ assing table to variable

tbl.key1 . \ prints out "val"
```

## Update and Insert

The put (`!`) word can be used to change or insert an item into the table.

```forth
var tbl

[ "a" "x" ] -> tbl

tbl 2 "b" !

tbl inspect \ prints out [ "a" "b" ]


{ $key1 "val" } -> tbl

tbl $key1 "new-val" !
tbl $key2 "val2" !

tbl inspect \ prints out { "key1" "new-val" "key2" "val2" }

```

For hash tables, you can also use the dot notation to insert or overwrite an item if the keys are strings with no special characters or whitespaces.

```forth
{ $key1 "val" } -> tbl

"new-val" -> tbl.key1 
"val2"    -> tbl.key2

tbl inspect \ prints out { "key1" "new-val" "key2" "val2" }

```

## Key-Value Pair Syntax

You can construct a table by using names and values of variables with the following syntax:

```forth
var vx
var vy

10 -> vx
20 -> vy

{ $ vx  $ vy } inspect \ prints out { "vx" 10 "vy" 20 }

```


## Operations


| Operation       | Array                       | Table                               |
|-----------------|-----------------------------|-------------------------------------|
| Create          | [ 1 2 3 ]                   | { key1 val1 }                       |
| Append          | tbl item append             |                                     |
| Insert new      | tbl idx item insert         | value -> tbl.key or tbl key value ! |
| Overwrite       | tbl idx item !              | value -> tbl.key or tbl key value ! |
| Lookup          | tbl idx @                   | tbl.key or tbl key @                |
| Remove          | tbl idx remove              | tbl key nil !                       |
| Remove & Return | tbl idx #( table.remove 2 ) |                                     |
| Size            | tbl #                       |                                     |
