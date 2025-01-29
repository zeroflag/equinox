# Core

The core of the language is very small, as most of the library functions come from Lua.

Equinox supports the usual stack manipulation words like `dup`, `drop`, `swap`, `2dup`, `nip`, `rot`, `-rot`, `over`, `tuck`, and `pick`, as well as two additional words for accessing the aux stack: `>a` and `a>`.

Traditional Forth control structures are supported, as well as some newer constructs.

## Conditional 

The words `if`, `else`, and `then` work the same way as in other Forth dialects.

```forth
2 1 > if "ok" else "no" then

2 1 > if "ok" then

```

A switch-case-like construct is also supported:

```forth
5
case
  1 of "Monday" . endof
  2 of "Tuesday" . endof
  3 of "Wednesday" . endof
  4 of "Thursday" . endof
  5 of "Friday" . endof
  6 of "Saturday" . endof
  7 of "Sunday" . endof
  "Unknown day: " .
endcase

\ this will print out Friday
```

If none of the conditions in the branches are met, the value is left on the stack in the default branch.

## Loops

### Do Loop

`Do` loops in Equinox look like those in traditional Forth dialects, but they are implemented differently.

```forth
10 1 do i . loop \ prints out 1 2 3 4 5 6 7 8 9
```

Unlike in a traditional Forth dialect, where the loop variable `i` is allocated on the return stack, Equinox translates this loop into a regular for loop in Lua and names the loop variable `i`.

```forth

: tst 10 1 do i . loop ;

see tst

function tst()
stack:push(10)
stack:push(1)
for i=stack:pop(),stack:pop() - 1 do
stack:push(i)
io.write(tostring(stack:pop()))
io.write(" ")
end
end
```

This also means that the condition is checked at the beginning of the loop, before entering the body. 
Therefore, if the `limit` is smaller than the `start`, the loop won’t be executed.

Another consequence is that you can freely do an early return (`exit`) from the loop without worrying about `unlooping` the return stack.

You can nest up to three levels of `DO` loops, with the loop variables named `i`, `j`, and `k`, respectively.

```forth
[]
1000 1 do
  1000 1 do
    i j * palindrom? if
      dup i j * append
    then
  loop
loop
```

### Begin

The `begin` word supports three different loop types: `begin` - `until`, `begin` - `again`, and `begin` - `while` - `repeat`.

```
begin <loop-body> <bool> until
begin <loop-body> again
begin .. <bool> while <loop-body> repeat
```

For example:

```forth
5
begin
  dup 0 >=
while
  dup . 1 -
repeat
drop
\ prints out 5 4 3 2 1 0
```

```forth
5
begin
  dup .
  1 - dup
0 < until
drop
\ prints out 5 4 3 2 1 0
```

```forth
0
begin
  dup 5 < if 1 + else dup * exit then
again

\ leaves 25 on the stack

```

### New-Stle Loops

Equinox is equipped with four new-style loops as well.

#### To Loop

`to:` and `step:` are more generalized for loops that allow you to name the loop variable.

```forth
<start> <limit> to: <name>
  <body>
end
```

For example:

```forth
1 10 to: idx
  idx .
end
\ prints out 1 2 3 4 5 6 7 8 9 10
```

In the example above, we chose `idx` as the loop variable name.

Unlike with `do` loops this type of loop expect the parameters in the opposite order thereofre it looks more like a for loop in other languges.

The `limit` is *inclusive*, so the loop will exit when idx is greater than 10.

#### Step Loop

`step:` works similarly, but it also allows you to specify the increment.

```forth
<start> <limit> to: <name>
  <body>
end
```

For example:

```forth
10 1 -1 step: idx
  idx .
end
\ prints out 10 9 8 7 6 5 4 3 2 1
```

#### Ipairs Loop

The `ipairs:` loop allows you to iterate over a sequential table.

```forth
<table> ipairs: <name1> <name2>
  <body>
end
```

Where `name1` is the loop variable for the current index, and `name2` is the loop variable containing the current element of the table.

For example:

```forth
[ 10 20 30 ] ipairs: idx elem
  idx . elem . cr
end
\ prints out
\ 1 10
\ 2 20
\ 3 30
```

#### Pairs Loop

The `pairs:` loop works similarly to `ipairs:` but it is for traversing a hash table (key value pairs).


```forth
<table> pairs: <name1> <name2>
  <body>
end
```

For example:

```forth
{ $k1 10  $k2 20  $k3 30 } pairs: key val
  key . val . cr
end
\ prints out
\ k1 10
\ k2 20
\ k3 30
```
