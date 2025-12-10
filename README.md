# benchmark-template
A simple benchmark template

---

### Requirements

 * [just](https://github.com/casey/just)
 * MinGW, gcc, clang, msvc (so whatever compilers you use).
 * Python for charts.

### Usage

1. Set app name in .env file
2. run `just`

#### Just?

Uses [just](https://github.com/casey/just) extensively.

Running `just` shows a list of available options, I will try to get this up to date
with proper documentation strings it will print.

If in doubt of what a command does, read the justfile. It's mildly complicated as
far as justfiles go because command calls other command and pass along values, but
you chould be able to track down the general result.
