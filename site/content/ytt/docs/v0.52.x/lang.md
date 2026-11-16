---

title: Language
---

## Overview

Templating language used in `ytt` is a slightly modified version of [Starlark](https://github.com/google/starlark-go/blob/master/doc/spec.md). Following modifications were made:

- requires `end` keyword for block closing
  - hence no longer whitespace sensitive (except new line breaks)
- does not allow use of `pass` keyword

See [full Starlark specification](https://github.com/google/starlark-go/blob/master/doc/spec.md#contents) for detailed reference.

## Types

- NoneType: `None` (equivalent to null in other languages)
- Bool: `True` or `False`
- Integer: `1`
- Float: `1.1`
- [String](lang-ref-string.md): `"string"` 
- [List](lang-ref-list.md): `[1, 2, {"a":3}]`
- Tuple: `(1, 2, "a")`
- [Dictionary](lang-ref-dict.md): `{"a": 1, "b": "b"}`
- [Struct](lang-ref-structs.md): `struct.make(field1=123, field2="val2")`
- [YAML fragment](lang-ref-yaml-fragment.md)
- [Annotation](lang-ref-annotation.md): `@name arg1,arg2,keyword_arg3=123`

## Control flow

- [If conditional](lang-ref-if.md)
- [For loop](lang-ref-for.md)
- [Function](lang-ref-def.md)
