# Equinox
Forth Programming Language, hosted by Lua. 

<img src="logo/logo.png" alt="logo" width="300"/>

Lua table operations

| Operation       | Array                       | Table             |
|-----------------|-----------------------------|-------------------|
| Create          | [ 1 2 3 ]                   | #[ :key1 :val1 ]# |
| Append          | tbl item table.insert!2     |                   |
| Prepend         | tbl 1 item table.insert!3   |                   |
| Insert          | tbl idx item table.insert!3 | tbl key value put |
| Lookup          | tbl idx at                  | tbl key at        |
| Remove          | tbl idx table.remove!2      | tbl key nil put   |
| Remove & Return | tbl idx table.remove/2      |                   |
| Size            | tbl size                    |                   |

![{master}](https://github.com/zeroflag/equinox/actions/workflows/makefile.yml/badge.svg) 
