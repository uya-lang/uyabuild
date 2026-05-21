# Phase 1 DSL Grammar

## Scope

This document describes the Phase 1 `uya.build` grammar and the subset that is currently implemented by the bootstrap `uyabuild` binary.

Phase 1 covers:

- root `workspace {}` blocks
- `config "name" {}` blocks
- `use <rule-pack>`
- `include "path-or-glob"`
- target declarations such as `cxx.library "//pkg:name" {}`
- string, bool, list, map, identifier, and call expressions
- `glob(...)` expansion for string-list fields
- `select(...)` preservation in typed IR

## Lexical Rules

- Whitespace is insignificant outside string literals.
- `# ...` starts a line comment.
- Strings use double quotes with `\\`, `\"`, `\n`, `\r`, and `\t` escapes.
- Identifiers use `[A-Za-z_][A-Za-z0-9_]*`.
- Dotted identifiers are parsed as `ident ( "." ident )*`.

## Grammar

```ebnf
file            = { decl } ;

decl            = workspace_decl
                | config_decl
                | use_decl
                | include_decl
                | target_decl ;

workspace_decl  = "workspace" block ;
config_decl     = "config" string block ;
use_decl        = "use" dotted_ident ;
include_decl    = "include" string ;
target_decl     = dotted_ident string block ;

block           = "{" { field } "}" ;
field           = ident "=" expr ;

expr            = string
                | bool
                | list
                | map
                | ident_or_call ;

ident_or_call   = dotted_ident [ "(" [ expr { "," expr } ] ")" ] ;
list            = "[" [ expr { "," expr } ] "]" ;
map             = "{" [ map_entry { "," map_entry } ] "}" ;
map_entry       = ( ident | string ) "=" expr ;

dotted_ident    = ident { "." ident } ;
string          = "\"" { char } "\"" ;
bool            = "true" | "false" ;
```

## Structural Rules

- `workspace {}` may only appear in the root `uya.build`.
- Root `uya.build` is the authoritative graph entrypoint in Phase 1.
- `uya.toml` is optional and currently only imports `[workspace]` keys:
  - `name`
  - `default`
  - `strict`
- If a `uya.toml` workspace key overlaps with `uya.build`, the values must match.

## Label Rules

Supported label forms:

- absolute: `//pkg:name`
- root package: `//:name`
- package-relative: `:name`
- relative package path: `subpkg:name`
- implicit local target name: `name`

All target references are normalized to canonical `//pkg:name` form during analysis.

## Built-in Rule Schemas

Phase 1 validates the following built-in kinds:

- `cxx.library`
- `cxx.binary`
- `node.workspace`
- `node.app`
- `oci.image`
- `legacy.shell`
- `task`

Common validated fields:

- `deps`
- `tags`
- `visibility`

Notable field typing:

- label fields become canonical labels in IR
- string-list fields may contain `glob(...)`
- scanner-style fields such as `discover` accept call expressions

## Typed IR Notes

`uyabuild plan --json` emits the Phase 1 typed IR snapshot with:

- workspace metadata
- loaded files
- imported rule packs
- configs
- normalized targets
- provider metadata
- typed attrs

This IR is the stable output boundary between Phase 1 analysis and later planner/executor phases.
