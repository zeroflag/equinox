# Equinox
Forth Programming Language, hosted by Lua. 

Work in progress.

### Design goals

* Compiles directly to (optimized) Lua source code
* Modeless with no interpretation mode
* Uses Lua call semantics, no return stack
* Lua table and array support 
* Seamless Love2D integration
* Self-hosted compiler (eventually)

<img src="logo/logo.png" alt="logo" width="300"/>

#### Lua table operations

| Operation       | Array                  | Table                 |
|-----------------|------------------------|-----------------------|
| Create          | [ 1 2 3 ]              | { key1 val1 }         |
| Append          | tbl item append        |                       |
| Insert new      | tbl idx item insert    | tbl key value put     |
| Overwrite       | tbl idx item put       | tbl key value put     |
| Lookup          | tbl idx at             | tbl.key or tbl key at |
| Remove          | tbl idx remove         | tbl key nil put       |
| Remove & Return | tbl idx table.remove/2 |                       |
| Size            | tbl size               |                       |

#### Lua interop

| Operation                                 | Syntax               |
|-------------------------------------------|----------------------|
| Call Lua function (2 parameters)          | 2 8 math.pow/2       |
| Call nullary Lua function (no parameters) | os.time              |
| Call Lua function and ignore return value | tbl 2 table.remove!2 |
| Call Lua object method                    | 2 astr:sub/1         |
| Property lookup                           | math.pi@             |

![{master}](https://github.com/zeroflag/equinox/actions/workflows/makefile.yml/badge.svg) 
