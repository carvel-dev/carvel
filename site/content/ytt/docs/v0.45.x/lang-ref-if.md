---

title: If Statements
---

Refer to [Starlark if statement specification](https://github.com/google/starlark-go/blob/master/doc/spec.md#if-statements) for details.

- if

```yaml
#@ if True:
test1: 123
test2: 124
#@ end
```

- if (negative)

```yaml
#@ if not True:
test1: 123
#@ end
```

- single-node if

```yaml
#@ if/end True:
test1: 123
```

- if-else conditional

```yaml
#@ if True:
test1: 123
#@ else:
test2: 124
#@ end
```

- if-elif-else conditional

```yaml
#@ if True:
test2: 123
#@ elif False:
test2: 124
#@ else:
test2: 125
#@ end
```

- if-elif-else conditional boolean (and/or) \
  See [Starlark or/and operators](https://github.com/google/starlark-go/blob/master/doc/spec.md#or-and-and) for more details.


```yaml
#@ test = 123
#@ if test > 100 and test < 200:
test1: 123
#@ elif test == 100 or test == 200:
test2: 124
#@ else:
test3: 125
#@ end
```


- single line if

```yaml
#@ passwd = "..."
test1: #@ passwd if passwd else assert.fail("password must be set")
```

- implicit if

```yaml
#@ passwd = "..."
test1: #@ passwd or assert.fail("password must be set")
```
