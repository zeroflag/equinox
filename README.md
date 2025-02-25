## Equinox - Forth Programming Language That Targets Lua 🌑

![{master}](https://github.com/zeroflag/equinox/actions/workflows/makefile.yml/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/zeroflag/equinox/badge.svg?branch=master&kill_cache=2)](https://coveralls.io/github/zeroflag/equinox?branch=master)

```forth
 _____            _                   _____          _   _     
| ____|__ _ _   _(_)_ __   _____  __ |  ___|__  _ __| |_| |__  
|  _| / _` | | | | | '_ \ / _ \ \/ / | |_ / _ \| '__| __| '_ \ 
| |__| (_| | |_| | | | | | (_) >  <  |  _| (_) | |  | |_| | | |
|_____\__, |\__,_|_|_| |_|\___/_/\_\ |_|  \___/|_|   \__|_| |_|
         |_|

: fibonacci ( n -- .. ) 0 1 rot 0 do 2dup + loop ;

10 fibonacci .s
```

## 🌕 Design goals

* Compiles directly to (optimized) Lua source code.
* Modeless with no interpretation mode, no return stack.
* Lua table and array support.
* Fixes Lua's accidental global problem.
* GameDev support via [Love2D](https://love2d.org/) and [TIC-80](https://tic80.com/) (later).
* Self-hosted compiler (later).

## 🚀 Install

```bash
$ luarocks install equinox
```

The easiest way to install Equinox is by using Lua's package manager, [Luarocks](https://luarocks.org/).

Equinox requires Lua 5.1 or later.

### 💻 Start the REPL

```bash
$ equinox
```

<img src="imgs/fib.gif" alt="fib" />


If you're a first-time Forth user, I suggest you start with the built-in tutorial.

In the REPL, type:

```
load-file tutorial
```

### Compile and execute a file:

```bash
$ equinox file.eqx
```

### Embed Into Lua Project

* For Love2D sample project see this repository: [VimSnake](https://github.com/zeroflag/vimsnake).

## ☕ Syntax That Fits on a Coffee Bean

```forth
 \ only numbers, words and strings/symbols
  1.25 "aString" $aSymbol .. ( concat ) # ( length ) * 
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

## 👍 Why Equinox?

Popular retro gaming platforms like the [TIC-80](https://tic80.com/) tiny computer and 2D game engines like [Love2D](https://love2d.org/) usually use [Lua](https://www.lua.org/) for scripting. 

While Lua's a cool, lightweight language, it doesn’t quite give you that old-school game dev vibe. Forth, on the other hand, really brings you back to the golden age of gaming with that nostalgic feel.

Lua has some questionable semantics, like how a simple typo can accidentally create a global variable when you wanted to modify a local one. Equinox fixes this problem by preventing accidental creation of globals.

Unlike Lua, Equinox syntactically distinguishes between sequential tables `[]` and hash maps `{}`. While the underlying data structure is the same, this differentiation helps make the code easier to read, in my opinion.

## ⛔ Why Not Equinox?

Equinox is a Forth that uses postfix notation and a stack to manage the parameters of words. This is quite different from how mainstream programming languages work and look. Some people might find this style unusual or hard to read. 

While I believe Forth helps make people better programmers by teaching them to value simplicity and break down definitions into small, manageable pieces (which is more of a must than an option), I’m fully aware it’s not for everyone.

Equinox is generally slower than Lua, mainly due to the stack operations. While the compiler uses various optimization rules to minimize these operations, it's still in its early phase, so the end result is often slower compared to a pure Lua counterpart.

However, this performance difference is expected to improve in the future.

## Differences from Other Forth Languages

 * Equinox can leverage Lua's high-level data structure, the table, which can be used as an array or a dictionary.
 * `!` (put) and `@` (at) are used for table access and modification, rather than variable assignment.
 * You can use control structures such as `if`, `then`, as well as loops, outside of word definitions because Equinox does not have an interpretation mode.
 * String literals are supported at the syntax level and are denoted with double quotes (`"`).
 * Equinox doesn't have a dedicated return stack (no `>r`, `r>` words), but it has an auxiliary stack that can be used similarly (`a>`, `>a`).
 * `DO` loops use Lua local variables internally instead of the return stack, so no `unloop` is needed for an early exit.
 * `DO` loops have safer semantics as they check the condition before entering the loop, so `1 1 do i . loop` won't do anything.
 * Equinox doesn't have its own standard library besides the stack manipulation words and a few others for table construction, so you need to use Lua functions.
 * The majority of the Equinox words are macros (immediate words), including the arithmetic operators and stack manipulation words.
 * In the current version user defined immediate words are not supported.

## 📝 Documentation
 * [Core](doc/core.md)
 * [Variables](doc/vars.md)
 * [Lua Interop](doc/interop.md)
 * [Table Operations](doc/table.md)
 * [Modules & Objects](doc/modules.md)
 * [Catalogue](doc/catalogue.md)
 
## The Name

The USS Equinox, `NCC-72381`, was a small, Nova class Federation science vessel that stuck in the Delta Quadrant and was (will?) destroyed in 2376.

RIP Captain Ransom and crew.

<img src="imgs/Nova001.jpg" alt="starship" width="300"/>

Source [Wikipedia](https://en.wikipedia.org/wiki/Equinox_(Star_Trek:_Voyager)).

(If you have good ASCII art or logo of a Nova-class starship, let me know, and I'll replace the Constitution one.)


