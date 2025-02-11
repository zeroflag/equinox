# Word Catalog

## Arithmetic and Logical Operations
| Word  | Description              | Stack Effect            | Immediate |
|-------|--------------------------|-------------------------|-----------|
| `+`   | Addition                 | ( n1 n2 -- sum )        | Yes       |
| `-`   | Subtraction              | ( n1 n2 -- diff )       | Yes       |
| `*`   | Multiplication           | ( n1 n2 -- prod )       | Yes       |
| `/`   | Division                 | ( n1 n2 -- quot )       | Yes       |
| `%`   | Modulo                   | ( n1 n2 -- rem )        | Yes       |
| `=`   | Equals                   | ( n1 n2 -- bool )       | Yes       |
| `!=`  | Not equals               | ( n1 n2 -- bool )       | Yes       |
| `>`   | Greater than             | ( n1 n2 -- bool )       | Yes       |
| `>=`  | Greater than or equal to | ( n1 n2 -- bool )       | Yes       |
| `<`   | Less than                | ( n1 n2 -- bool )       | Yes       |
| `<=`  | Less than or equal to    | ( n1 n2 -- bool )       | Yes       |
| `not` | Logical NOT              | ( bool -- bool' )       | Yes       |
| `and` | Logical AND              | ( bool1 bool2 -- bool ) | Yes       |
| `or`  | Logical OR               | ( bool1 bool2 -- bool ) | Yes       |
| `max` | Maximum of two values    | ( n1 n2 -- max )        | No        |
| `min` | Minimum of two values    | ( n1 n2 -- min )        | No        |

## Stack Manipulation
| Word     | Description                     | Stack Effect                        | Immediate |
|----------|---------------------------------|-------------------------------------|-----------|
| `swap`   | Swap top two items on stack     | ( x1 x2 -- x2 x1 )                  | Yes       |
| `over`   | Copy second item to top         | ( x1 x2 -- x1 x2 x1 )               | Yes       |
| `rot`    | Rotate top three items          | ( x1 x2 x3 -- x2 x3 x1 )            | Yes       |
| `-rot`   | Reverse rotate top three items  | ( x1 x2 x3 -- x3 x1 x2 )            | Yes       |
| `nip`    | Remove second item from stack   | ( x1 x2 -- x2 )                     | Yes       |
| `drop`   | Remove top item from stack      | ( x -- )                            | Yes       |
| `dup`    | Duplicate top item              | ( x -- x x )                        | Yes       |
| `2dup`   | Duplicate top two items         | ( x1 x2 -- x1 x2 x1 x2 )            | Yes       |
| `tuck`   | Copy top item below second item | ( x1 x2 -- x2 x1 x2 )               | Yes       |
| `depth`  | Get stack depth                 | ( -- n )                            | Yes       |
| `pick`   | Copy nth item to top            | ( xn ... x1 n -- xn ... x1 xn )     | Yes       |
| `roll`   | Rotate nth item to top          | ( xn ... x1 n -- x(n-1) ... x1 xn ) | Yes       |
| `adepth` | Alternative stack depth         | ( -- n )                            | Yes       |


