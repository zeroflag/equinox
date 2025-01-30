# Modules

Just like in Lua, you can build modules using tables to store words and variables.

Contents of `mymodule.eqx`:

```forth
{ $state 10 } -> var mymodule

: mymodule:access ( -- n ) self.state ;

: mymodule:change ( n -- ) -> self.state ;

mymodule return \ make the module available 
```

Contents of `myapp.eqx`:

```forth
"mymodule.eqx" need -> var mymod \ require the module

mymod:access .  \ prints out 10

6 mymod:change  \ change state to 6

mymod:access .  \ prints out 6

```

Equinox uses the same method call syntax as Lua, denoted by a colon (`:`), where an implicit self parameter is passed to refer to the module itself.

## Classes & Objects

If you need multiple instances of the same type of object, you can simulate classes using Lua's metatable support.

The `__index` is a metatable field that allows table lookups to fall back to another table when a key is missing.

This makes it possible for multiple objects to share the same set of "methods", essentially simulating classes.

Contents of `player.eqx`:

```forth
{} -> var Player

: Player:new ( props -- instance )
  dup { $__index self } #( setmetatable 2 0 ) ;

: Player:update ( dt -- )
  dup    self.vx * self.x + -> self.x
  ( dt ) self.vy * self.y + -> self.y ;

Player return

```

Contents of `game.eqx`:

```forth
"player.eqx" need -> var Player

{ $x 0 $y 0 $vx 10 $vy 5 } Player:new -> var player1

0.3 player1:update

player1.x . \ prints out 3
player1.y . \ prints out 1.5
cr

```

Note that dot notation is used to access fields in a table. If the field is a method, it will not be called automatically.

`0.3 player1:update` is essentially the same as `0.3 player1 #( player1.update 1 )`.
