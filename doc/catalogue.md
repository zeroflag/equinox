# Word Catalog

## Arithmetic and Logical Operations

| Word  | Description              | Stack Effect              | Immediate |
|-------|--------------------------|---------------------------|-----------|
| `+`   | Addition                 | `( n1 n2 -- sum )`        | Yes       |
| `-`   | Subtraction              | `( n1 n2 -- diff )`       | Yes       |
| `*`   | Multiplication           | `( n1 n2 -- prod )`       | Yes       |
| `/`   | Division                 | `( n1 n2 -- quot )`       | Yes       |
| `%`   | Modulo                   | `( n1 n2 -- rem )`        | Yes       |
| `=`   | Equals                   | `( n1 n2 -- bool )`       | Yes       |
| `!=`  | Not equals               | `( n1 n2 -- bool )`       | Yes       |
| `>`   | Greater than             | `( n1 n2 -- bool )`       | Yes       |
| `>=`  | Greater than or equal to | `( n1 n2 -- bool )`       | Yes       |
| `<`   | Less than                | `( n1 n2 -- bool )`       | Yes       |
| `<=`  | Less than or equal to    | `( n1 n2 -- bool )`       | Yes       |
| `not` | Logical NOT              | `( bool -- bool' )`       | Yes       |
| `and` | Logical AND              | `( bool1 bool2 -- bool )` | Yes       |
| `or`  | Logical OR               | `( bool1 bool2 -- bool )` | Yes       |
| `max` | Maximum of two values    | `( n1 n2 -- max )`        | No        |
| `min` | Minimum of two values    | `( n1 n2 -- min )`        | No        |

## Stack Manipulation

| Word     | Description                     | Stack Effect                          | Immediate |
|----------|---------------------------------|---------------------------------------|-----------|
| `swap`   | Swap top two items on stack     | `( x1 x2 -- x2 x1 )`                  | Yes       |
| `over`   | Copy second item to top         | `( x1 x2 -- x1 x2 x1 )`               | Yes       |
| `rot`    | Rotate top three items          | `( x1 x2 x3 -- x2 x3 x1 )`            | Yes       |
| `-rot`   | Reverse rotate top three items  | `( x1 x2 x3 -- x3 x1 x2 )`            | Yes       |
| `nip`    | Remove second item from stack   | `( x1 x2 -- x2 )`                     | Yes       |
| `drop`   | Remove top item from stack      | `( x -- )`                            | Yes       |
| `dup`    | Duplicate top item              | `( x -- x x )`                        | Yes       |
| `2dup`   | Duplicate top two items         | `( x1 x2 -- x1 x2 x1 x2 )`            | Yes       |
| `tuck`   | Copy top item below second item | `( x1 x2 -- x2 x1 x2 )`               | Yes       |
| `depth`  | Get stack depth                 | `( -- n )`                            | Yes       |
| `pick`   | Copy nth item to top            | `( xn ... x1 n -- xn ... x1 xn )`     | Yes       |
| `roll`   | Rotate nth item to top          | `( xn ... x1 n -- x(n-1) ... x1 xn )` | Yes       |
| `adepth` | Aux stack depth                 | `( -- n )`                            | Yes       |
| `>a`     | Move top item to aux stack      | `( n -- )`                            | Yes       |
| `a>`     | Move top of aux to data stack   | `( -- n )`                            | Yes       |

## IO

| Word   | Description                           | Stack Effect | Immediate |
|--------|---------------------------------------|--------------|-----------|
| `.`    | Print out top of the stack            | `( x --  )`  | Yes       |
| `emit` | Display a character by its ASCII code | `( n --  )`  | Yes       |
| `cr`   | Print out a new line                  | `( --  )`    | Yes       |

## Control Structures

| Word      | Description                                         | Stack Effect              | Immediate |
|-----------|-----------------------------------------------------|---------------------------|-----------|
| `if`      | Conditional branch start                            | `( bool -- )`             | Yes       |
| `then`    | End an `if` block                                   | `( -- )`                  | Yes       |
| `else`    | Alternate branch in `if`                            | `( -- )`                  | Yes       |
| `begin`   | Start of a loop                                     | `( -- )`                  | Yes       |
| `again`   | Infinite loop (for `begin`)                         | `( -- )`                  | Yes       |
| `until`   | Loop condition check (for `begin`)                  | `( bool -- )`             | Yes       |
| `while`   | Loop condition check (for `begin`)                  | `( bool -- )`             | Yes       |
| `repeat`  | End a `while` loop                                  | `( -- )`                  | Yes       |
| `case`    | Start of a case statement                           | `( x -- )`                | Yes       |
| `of`      | Case match clause                                   | `( x1 x2 -- )`            | Yes       |
| `endof`   | End of a case clause                                | `( -- )`                  | Yes       |
| `endcase` | End of case statement                               | `( -- )`                  | Yes       |
| `do`      | Start of a counted loop                             | `( limit start -- )`      | Yes       |
| `loop`    | End of a counted loop                               | `( -- )`                  | Yes       |
| `ipairs:` | Iterate over array pairs                            | `( array --  )`           | Yes       |
| `pairs:`  | Iterate over hash-table pairs                       | `( hash-tbl -- )`         | Yes       |
| `iter:`   | Iterate over an iterable                            | `( iterable -- )`         | Yes       |
| `to:`     | Start a counted loop                                | `( start limit -- )`      | Yes       |
| `step:`   | Start a counted loop with a step                    | `( start limit step -- )` | Yes       |
| `end`     | End a `to:` `step:` `pairs:` `ipairs:` `iter:` loop | `( -- )`                  | Yes       |
| `exit`    | Exit from a word definition                         | `( -- )`                  | Yes       |
| `exec`    | Run an execution token (function ref.)              | `( xt -- )`               | Yes       |

## Defining

| Word        | Description                                     | Stack Effect | Immediate |
|-------------|-------------------------------------------------|--------------|-----------|
| `:`         | Define a new word                               | `( -- )`     | Yes       |
| `::`        | Define a new local word                         | `( -- )`     | Yes       |
| `;`         | End word definition                             | `( -- )`     | Yes       |
| `var`       | Define a new variable (preferred over `global`) | `( -- )`     | Yes       |
| `global`    | Define a new global variable                    | `( -- )`     | Yes       |
| `->`        | Assign value to a variable                      | `( x -- )`   | Yes       |
| `alias:`    | Define an alias                                 | `( -- )`     | Yes       |
| `recursive` | Make a word recursive                           | `( -- )`     | Yes       |
| `(:`        | Define parameters for a Lua callback            | `( -- )`     | Yes       |
| `:)`        | End of Lua callback parameter list              | `( -- )`     | Yes       |
| \`          | Get the execution token of a word               | `( -- xt )`  | Yes       |

## Table Operations


| Word     | Description                       | Stack Effect                   | Immediate | Example                       |
|----------|-----------------------------------|--------------------------------|-----------|-------------------------------|
| `[]`     | Empty sequential table            | `( -- table )`                 | No        |                               |
| `{}`     | Empty hash table                  | `( -- table )`                 | No        |                               |
| `[`      | Start creating a sequential table | `( -- )`                       | No        | `[ 1 2 dup * 3 ]`             |
| `]`      | End creating a sequential table   | `( ... -- table )`             | No        |                               |
| `{`      | Start creating a hash table       | `( -- )`                       | No        | `{ :x 10 :y 20 }`             |
| `}`      | End creating a hash table         | `( ... -- table )`             | No        |                               |
| `@`      | Look up by index / key            | `( table key/index -- value )` | No        | `array 3 @`     `tbl $x @`    |
| `!`      | Put/Update element into a table   | `( table key/index value -- )` | No        | `array 1 30 !`  `tbl $x 30 !` |
| `append` | Append to a sequential table      | `( table value --  )`          | No        |                               |
| `insert` | Insert into a sequential table    | `( table index value --  )`    | No        |                               |
| `remove` | Remove element from table         | `( table key -- )`             | No        |                               |
| `#`      | Size of a sequential table        | `( table -- n )`               | Yes       |                               |

## Modules

| Word     | Description                                | Stack Effect        | Immediate | Example                     |
|----------|--------------------------------------------|---------------------|-----------|-----------------------------|
| `need`   | Require a module                           | `( str -- module )` | Yes       | `"dkjson" need -> var json` |
| `return` | Export a module / Return from Lua function | `( x -- )`          | Yes       |                             |

## Misc

| Word   | Description       | Stack Effect   | Immediate |
|--------|-------------------|----------------|-----------|
| `>str` | Convert to string | `( n -- str )` | No        |
| `>num` | Convert to number | `( str -- n )` | No        |

## Debugging

| Word           | Description                          | Stack Effect   | Immediate |
|----------------|--------------------------------------|----------------|-----------|
| `.s`           | Print out the stack (REPL only)      | `( -- )`       | No        |
| `clear`        | Clear the data stack (REPL only)     | `( .. -- )`    | No        |
| `inspect`      | Print out a table (REPL only)        | `( x -- )`     | No        |
| `see`          | Decompiles a word                    | `( -- )`       | Yes       |
| `words`        | Show availale words                  | `( -- )`       | Yes       |
| `=assert`      | Check if the top two items are equal | `( x1 x2 -- )` | No        |
| `assert-true`  | Check if top of the stack is true    | `( bool -- )`  | No        |
| `assert-false` | Check if top of the stack is false   | `( bool -- )`  | No        |

