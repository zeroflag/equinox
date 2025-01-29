# Lua Interop

Equinox doesn't have its own standard library besides the stack manipulation words and a few others for table construction.

If you want to use something like `max`, you'll need to use the Lua function `math.max`.
However, Lua functions don't use Forth's data stack to pass parameters, and many Lua functions are variadic.
Even when they aren't, there is no reliable way to check the arity of a Lua function.

Therefore, you need to tell the compiler how many parameters a function expects.

```forth
3 4 #( math.max 1 ) . \ this will print out 4
```

## Alias

Typing this every time would be too verbose and error-prone, so you can define an alias for it.

```
alias: max #( math.max 1 )

3 4 max . \ this will print out 4
```

The word `alias:` can also be used to define compile-time constants.

```forth
alias: magic-number 42

magic-number . \ prints out 42
```

## Table Operations

Some of these aliases are already predefined, such as those for common table operations, as shown below.

| Operation       | Array                       | Table                               |
|-----------------|-----------------------------|-------------------------------------|
| Create          | [ 1 2 3 ]                   | { key1 val1 }                       |
| Append          | tbl item append             |                                     |
| Insert new      | tbl idx item insert         | value -> tbl.key or tbl key value ! |
| Overwrite       | tbl idx item !              | value -> tbl.key or tbl key value ! |
| Lookup          | tbl idx @                   | tbl.key or tbl key @                |
| Remove          | tbl idx remove              | tbl key nil !                       |
| Remove & Return | tbl idx #( table.remove 2 ) |                                     |
| Size            | tbl size                    |                                     |

## Return Value

Sometimes, a Lua function returns a result you're not interested in. For example, `table.remove` removes and returns an item from a table.
Often, you just want to delete it without doing anything with the result.

```forth
[ "a" "b" "c" ] 2 #( table.remove 2 ) \ this will remove the 2nd item "b" from the table and return it
```

In this case you would need to keep this is mind and `drop` the item every-time you use `table.remove`.
A better approach is to define an alias with number of return values set to 0.


```forth
[ "a" "b" "c" ] dup 2 #( table.remove 2 0 ) \ just remove "b" don't return i
inspect \ this will print [ "a" "c" ]
```

The built-in alias for this is simply called `remove`.

Sometimes, a Lua function leaves multiple return values on the stack, and you're only interested in the first one. In such cases, you can set the number of return values to 1 to ignore the others.

## General Form

The general form of this syntax is as follows:

```forth
#( lua_func [arity] [#return] )
```

Where:
 * `arity` defines the number of input parameters (should be >= 0).
 * `#return` defines the number of return values.
 ** `-1` means any,
 ** `0`  means none, and
 ** `1`  means one.

## Examples

| Operation                                          | Syntax                      |
|----------------------------------------------------|-----------------------------|
| Call Lua function (2 parameters)                   | 2 8 #( math.pow 2 )         |
| Call nullary Lua function (no parameters)          | #( os.time )                |
| Call Lua (binary) function and ignore return value | tbl 2 #( table.remove 2 0 ) |
| Call Lua (unary) method                            | #( astr:sub 1 )             |
| Property lookup                                    | math.pi                     |
|                                                    |                             |

