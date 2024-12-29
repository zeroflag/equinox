# Equinox
Forth Programming Language, hosted by Lua. 

### Design goals

* Compiles directly to Lua source code
* Modeless with no interpretation mode
* Uses Lua call semantics, no return stack
* Lua table and array support 
* Seamless Love2D integration

<img src="logo/logo.png" alt="logo" width="300"/>

Lua table operations

| Operation       | Array                  | Table             |
|-----------------|------------------------|-------------------|
| Create          | [ 1 2 3 ]              | #[ :key1 :val1 ]# |
| Append          | tbl item append        |                   |
| Insert          | tbl idx item insert    | tbl key value put |
| Lookup          | tbl idx at             | tbl key at        |
| Remove          | tbl idx remove         | tbl key nil put   |
| Remove & Return | tbl idx table.remove/2 |                   |
| Size            | tbl size               |                   |

![{master}](https://github.com/zeroflag/equinox/actions/workflows/makefile.yml/badge.svg) 
