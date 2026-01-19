# Shard

Shard is a programming language designed for declarative builds and configuration of the Amethyst Operating System.

Shard is a...

- declarative
- functional
- lazy
- dynamically typed

language majorly inspired by Nix and NixOS. It is however not intended to copy `nix`. Shard shares many core principles but adds other language features upon them and is implemented as a minimal and easily embedable standalone library.

## Examples

Hello World:
```nix
"Hello, World"
```

Fibonacci:
```nix
let fibonacci = n: if n < 2 
        then n 
        else (fibonacci (n - 1)) + (fibonacci (n - 2));
in fibonacci 30
```

Pattern matching:
```nix
case x of
    v if v == 42     => "nice";
    _ :: float | int => "numeric";
    { n, ... }       => "n=${n}";
    v                => "other: " + (builtins.typeOf v)
```

Foreign function interface (using the `builtins_ext` system extension)
```nix
let
    dl = system.dlOpen null;

    puts = xs :: string: let
        f = system.dlSym dl "puts" $ with builtins;
            ffi.cFunc ffi.cInt [ (ffi.cPointer $ ffi.cChar) ];
        in f xs;
in puts "Hello, World"
```

There are a few example programs in the `examples/` directory

## TODO

- stack-overflow detection and handling in the evaluator
- `==` and `!=` for lists and sets

## Building

There are no dependencies other that `libc` to the pure implementation of shard. Optionally, you may use the `gcboehm` library for a more performant garbage collector and `libffi` for ffi capabilities of the `shard` runner.

To build `libshard` and the `shard` asdf, just run `make` in this directory:

```sh
$ make
```

If successful, the interpreter binary will be placed in `build/shard`. It can be invoked using `./build/shard <file.shard>`

There are other make targets available that build the respective programs in the shard ecosystem: `all`, `libshard`, `test`, ...

To use `gcboehm`, define `SHARD_USE_GCBOEHM=1` in the `CFLAGS` environment variable.

To enable the foreign function interface, define `SHARD_ENABLE_FFI=1` in the `CFLAGS` environment variable.

A "fully-equipped" shard build therefore can be built using:

```sh
$ make CFLAGS='-DSHARD_USE_GCBOEHM=1 -DSHARD_ENABLE_FFI=1'
```

## Testing

Unit test files can be found in the `tests/` directory. These are run by `tests/runner.c`, which you can invoke using

```sh
$ make test
```

Please be sure to always update and add unit tests as needed.

## Editor Support

* Vim: Include `shard.vim` in your vim configuration using the following code:

```vim
autocmd BufRead,BufNewFile *.shard set filetype=shard
autocmd Syntax shard runtime! shard.vim
```

* Other: TODO!

## Language Overview

|  Shard code           | Description    |
|-----------------------|----------------|
| *Basic values*        |                |
| `true` , `false`      | Boolean values |
| `null`                | Null value     |
| 69, 420               | Integer values |
| 3.1415                | Float values   |
| `"Hello, World"`      | String literal |
| `"foo ${bar}"`        | String interpolation |
| `/path`, `~/path`, `./path` | Absolute and relative path literals |
| `<path>`              | Shard search path |
| *Compound values*     |                   |
| `{ x = 69; y = 420; }` | Attribute Sets   |
| `{ x.y = 42; }`       | Nested attribute sets |
| `rec { x = 34; y = x + 35; }` | Recursive attribute sets |
| `[ "foo" "bar" "baz" ]` | Linked lists
| *Prefix Operators*     |               |
| `-number`              | Numeric negation |
| `!boolean`             | Logical not      |
| *Infix Operators*      |              |
| `bool \|\| bool`       | Logical or |
| `bool && bool`         | Logical and |
| `bool -> bool`         | Logical implication |
| `expr == expr`         | Equality |
| `expr != expr`         | Inequality |
| `expr > expr`, `expr < expr`, `expr >= expr`, `expr <= expr` | Relational comparison (greater than, less than, ...)
| `set // set`          | Attribute  set combination |
| `set ? attr`          | Attribute check |
| `set . attr [or value]` | Attribute selection |
| `list ++ list`        | List append   |
| `expr + expr`         | Numerical or textual (string) addition |
| `expr - expr`         | Subtraction   |
| `expr * expr`         | Multiplication |
| `expr / expr`         | Division |
| `func1 >> func2`, `func1 << func2` | Function composition |
| `func expr`           | Function call |
| *Control Structures*  |               |
| `if bool then "yes" else "no"` | Conditional/Ternary expression |
| `case value of ...`   | Case (`switch`) expression |
| `assert value; "pass"` | Assertion check |
| `let x = 34; y = 35; in x + y` | Let bindings |
| `with set; value`     | With expression -> Bind all attributes in a set to the current scope |
| `case x of a => b; c => d` | Pattern matching expression, where `a`, `c` are patterns and `b`, `d` are the returned expressions |
| *Functions*           |           |
| `x: x + 1`            | Function definition (where `x` is a pattern) |
| `x: y: x + y`         | Curried function definition |
| *Patterns*            |                       |
| `{ x, y }`            | Set destructuring |
| `{ x ? "foo" }`       | Default attribute value |
| `{ x, ... }`          | Ignored additional attributes |
| `{ x, ... } @ args`   | Whole set binding to `args` |
| `x if x == ???`       | If guards |
| `x :: int \| float`   | Type selection |
| `_`                   | Default case |
| *Builtins*            |           |
| TODO                  |           |

## License

Shard is a part of the [Amethyst Operating System](https://github.com/spydr06/amethyst) and is therefore licensed under the [MIT license](LICENSE).

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

