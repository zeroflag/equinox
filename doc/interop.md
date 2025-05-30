# Lua Interop

Equinox doesn't have its own standard library besides the stack manipulation words and a few others for table construction.

If you want to use something like `max`, you'll need to use the Lua function `math.max`.
However, Lua functions don't use Forth's data stack to pass parameters, and many Lua functions are variadic.
Even when they aren't, there is no reliable way to check the arity of a Lua function.

Therefore, you need to tell the compiler how many parameters a function expects.

```forth
3 4 #( math.max 2 ) . \ this will print out 4
```

This will call `math.max` with 2 parameters (3 and 4).

## Alias

Typing this every time would be too verbose and error-prone, so you can define an alias for it.

```
alias: max #( math.max 2 )

3 4 max . \ this will print out 4
```

The word `alias:` can also be used to define compile-time constants.

```forth
alias: magic-number 42

magic-number . \ prints out 42
```

Some of these aliases are already predefined, such as those for common table operations, as [shown here](table.md).


## Return Value

Sometimes, a Lua function returns a result you're not interested in. For example, `table.remove` removes and returns an item from a table.
Often, you just want to delete it without doing anything with the result.

```forth
[ "a" "b" "c" ] 2 #( table.remove 2 ) \ this will remove the 2nd item "b" from the table and return it
```

In this case you would need to keep this is mind and `drop` the item every-time you use `table.remove`.
A better approach is to define an alias with number of return values set to 0.


```forth
[ "a" "b" "c" ] dup 2 #( table.remove 2 0 ) \ just remove "b" don't return it
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
     - The default is 0.
  * `#return` defines the number of return values.
     - `-1` means any (default),
     - `0`  means none, and
     - `1`  means one.

## Examples

| Operation                                          | Syntax                      |
|----------------------------------------------------|-----------------------------|
| Call Lua function (2 parameters)                   | 2 8 #( math.pow 2 )         |
| Call nullary Lua function (no parameters)          | #( os.time )                |
| Call Lua (binary) function and ignore return value | tbl 2 #( table.remove 2 0 ) |
| Call Lua (unary) method                            | #( astr:sub 1 )             |
| Property lookup                                    | math.pi                     |
|                                                    |                             |

## Lua Callbacks

Sometimes, an Equinox word is expected to be called by Lua, like the following Love2D callback.

Often, these callbacks take parameters, such as the key that has been pressed by the user.

```forth
: love.keypressed (: key :)
  key case
    $escape of quit endof
    $space  of jump endof
    drop ( key )
  endcase ;
```


Equinox provides a way to declare Lua function parameters using the words `(:` and `:)`.

Here, the Love2D framework calls our `love.keypressed` callback every time the user presses a key and passes the key's name as a parameter.
