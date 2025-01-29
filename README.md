## Equinox - Forth Programming Language That Targets Lua 🖖

```forth
 _____            _                   _____          _   _     
| ____|__ _ _   _(_)_ __   _____  __ |  ___|__  _ __| |_| |__  
|  _| / _` | | | | | '_ \ / _ \ \/ / | |_ / _ \| '__| __| '_ \ 
| |__| (_| | |_| | | | | | (_) >  <  |  _| (_) | |  | |_| | | |
|_____\__, |\__,_|_|_| |_|\___/_/\_\ |_|  \___/|_|   \__|_| |_|
         |_|

: fibonacci 0 1 rot 0 do 2dup + loop ;

10 fibonacci .s
```

### Install

```bash
$ luarocks install equinox
```

Start the REPL

```bash
$ equinox
```

Compile and execute a file:

```bash
$ equinox file.eqx
```

### Design goals

* Compiles directly to (optimized) Lua source code
* Modeless with no interpretation mode
* Uses Lua call semantics, no return stack
* Lua table and array support 
* Fixes Lua's accidental global problem
* Seamless [Love2D](https://love2d.org/) and [TIC-80](https://tic80.com/) integration
* Self-hosted compiler (eventually)

<img src="logo/logo.png" alt="logo" width="300"/>

#### Lua table operations

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

#### Lua interop

| Operation                                          | Syntax                      |
|----------------------------------------------------|-----------------------------|
| Call Lua function (2 parameters)                   | 2 8 #( math.pow 2 )         |
| Call nullary Lua function (no parameters)          | #( os.time )                |
| Call Lua (binary) function and ignore return value | tbl 2 #( table.remove 2 0 ) |
| Call Lua (unary) method                            | #( astr:sub 1 )             |
| Property lookup                                    | math.pi                     |
|                                                    |                             |

![{master}](https://github.com/zeroflag/equinox/actions/workflows/makefile.yml/badge.svg) 
