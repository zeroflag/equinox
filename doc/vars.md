# Variables

Equinox supports both global and local variables, but unlike Lua, both require declaration.

Local variables are restricted to the specific block in which they're declared, but that scope can span an entire file.

## Vars

Below, the scope of variable `x` extends across the entire file, while the scope of variable `y` is limited to `my-word`.

```forth
\ declared at top level
var x

...

: my-word
  \ declared within a word
  var y
  ... ;

```

Values can be assigned to variables using the `->` word

```forth
12 -> x
x . \ prints out 12

```

To fetch the value of a variable, you don't need any special words; simply typing its name is enough.

A shorthand for declaring and initializing a variable in one step: `value -> var name`.


```forth
20 -> var v1
```

The above program is translated to the following Lua code:

```lua
local v1 = 20
```

If you assign a value to a variable that hasn't been previously declared, you'll get an error.

You can simulate parameters with locals in the following way:

```forth
: length -> var z -> var y -> var x
  x square y square + z square + sqrt ;

```

## Globals

Globals are accessible throughout the entire program, but globals in Lua are known for their slowness relative to locals.

Since top-level locals (`vars`) can be accessed throughout the entire file, globals are rarely needed.

```forth
global g1

12 -> g1
```

The above program is translated to the following Lua code:

```lua
g1 = nil
g1 = 12
```
