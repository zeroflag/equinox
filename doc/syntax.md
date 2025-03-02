# Syntax

Equinox syntax consists of numbers, words, and strings/symbols:

* Number: `1.23`
* String: `"Hello World\n"`
* Symbol: `$key`
* Word: `emit`

The language also supports dot (`.`) notation for property lookup (e.g.: `math.pi`) and colon (`:`) notation for method calls (e.g.: `astr:upper`).

```forth
  1.25 "aString" $aSymbol .. ( concat ) # ( length ) * 
```

Table literals are *not* part of the syntax; they are defined as Forth words.

```forth
[ 1 2 ]
{ $key 123 }
```

The same is true for comments:

```
 \ single line comment
 ( comment ) 
```

#### Example:

```forth
alias: 2^n 2 swap #( math.pow 2 1 )

: sum-of-pows ( -- n ) 0 10 0 do i 2^n + loop ;
 
var map
{ $key [ 1 2 "apple" sums-of-pows ] } -> map

map.key 3 @ . \ prints out 1023
map.key 1 42 !

\ define a Lua callback
: love.keypressed (: key :)
  key $escape = if #( os.exit ) then ;
```

