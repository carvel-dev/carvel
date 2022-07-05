---
title: Assert Module
---

## Overview

`ytt`'s Assert module allows users to make assertions about their templates and stop execution if desired. 

## Functions

The `@ytt:assert` module provides several built-in assertion functions.
To use these functions, include the `@ytt:assert` module:

```python
#@ load("@ytt:assert", "assert")
```

### assert.equals()
 - Checks equality of the two arguments provided, stops execution if values are not equal.
```python
load("@ytt:assert", "assert")

assert.equals("not", "equal") # stops execution
```

### assert.fail()
- Stops execution and reports a failure.
- Takes a single string argument used as the failure message, this can be formatted with available values.
```python
load("@ytt:assert", "assert")

assert.fail("custom failure message")
assert.fail("expected value foo, but was {}".format(value))
x = data.values.env.mysql_password or assert.fail("missing env.mysql_password")
```

### assert.max()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

- Checks that values are less than or equal to the maximum value.
- `x = assert.max(4)` returns an object, `x`, that can `x.check()` if values are less than or equal to 4.
- Is able to compare numbers, strings, lists, dictionaries, and [YAML fragments](lang-ref-yaml-fragment).
```python
load("@ytt:assert", "assert")

assert.max(4).check(3)

assert.max(4).check(5) # stops execution
```

### assert.max_len()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

- Checks that values have length less than or equal to the maximum length.
- Maximum length argument is an integer.
- `x = assert.max_len(4)` creates an object, `x` that can `check()` if the length of values are less than or equal to 4.
- Checks the length of strings, lists, dictionaries, and [YAML fragments](lang-ref-yaml-fragment).
```python
load("@ytt:assert", "assert")

assert.max_len(4).check({'foo': 0, 'bar': 1})

assert.max(4)_len.check("123.45.67.89") # stops execution
```

### assert.min()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

- Checks that values are greater than or equal to the minimum value.
- `x = assert.min(2)` returns an object, `x`, that can `x.check()` if values are greater than or equal to 2.
- Is able to compare numbers, strings, lists, dictionaries, and [YAML fragments](lang-ref-yaml-fragment).
```python
load("@ytt:assert", "assert")

assert.min(2).check(5)

assert.min(2).check(1) # stops execution
```

### assert.min_len()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

 - Checks that values have length greater than or equal to the minimum length.
 - Minimum length argument is an integer. 
 - `x = assert.min_len(1)` creates an object, `x` that can `check()` if the length of values are greater than or equal to 1.
 - Checks the length of strings, lists, dictionaries, and [YAML fragments](lang-ref-yaml-fragment).
```python
load("@ytt:assert", "assert")

assert.min_len(1).check(["some","list","of","values"])

assert.min_len(1).check("") # stops execution
```

### assert.not_null()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

 - Checks that a value is not null or none.
```python
load("@ytt:assert", "assert")

v = None
assert.not_null(v) # stops execution
# is syntactic sugar for
assert.not_null().check(v) # stops execution
```

### assert.one_not_null()

> ⚠️ **This function is part of the experimental "validations" feature.\
> ⚠️ Its interface and behavior are subject to change.** \
> _To enable this feature, see [Blog: "Preview of ytt Validations"](/blog/ytt-validations-preview/)._

- Checks that a dictionary's value has one and only one not-null item.
```python
load("@ytt:assert", "assert")

assert.one_not_null({"foo": 1, "bar": None})

v = {"foo": 1, "bar": 2}
assert.one_not_null(v) # stops execution
# is syntactic sugar for
assert.one_not_null().check(v) # stops execution
```

### assert.try_to()
- Invokes a function, catching failure if one occurs.
- Takes single function as argument.
- Returns the return value of function, or the error if one occurs.
```python
load("@ytt:assert", "assert")

x, err = assert.try_to(lambda : json.decode('{"key": "value"}'))
x     # { "key" = "value" }    (i.e. dict with one entry)
err   # None

x, err = assert.try_to(lambda : json.decode("(not JSON)"))
x     # None
err   # "json.decode: invalid character '(' looking for beginning of value"
```