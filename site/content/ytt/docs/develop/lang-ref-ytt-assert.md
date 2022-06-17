---
title: Assert Module
---

## Overview

`ytt`'s Assert module allows users to make assertions about their templates and stop execution if desired. 

## Functions

The `@ytt:assert` module provides several built-in assertion functions. 
You can define custom assertion functions written in starlark and run using ___. 

To use these functions, include the `@ytt:assert` module:

```python
#@ load("@ytt:assert", "assert")
```


### assert.fail
 - Stops execution and reports a failure.
 - Takes a single string argument used as the failure message, this can be formatted with available values.
```python
assert.fail("custom failure message")
assert.fail("expected value foo, but was {}".format(value))
x = data.values.env.mysql_password or assert.fail("missing env.mysql_password")
```

### assert.try_to
 - Invokes a function, catching failure if one occurs.
 - Takes single function as argument.
 - Returns the return value of function, or the error if one occurs.
```python
x, err = assert.try_to(lambda : json.decode('{"key": "value"}'))
x     # { "key" = "value" }    (i.e. dict with one entry)
err   # None

x, err = assert.try_to(lambda : json.decode("(not JSON)"))
x     # None
err   # "json.decode: invalid character '(' looking for beginning of value"
```


### assert.equals
 - Checks equality of the two arguments provided, stops execution if values are not equal.
```python
assert.equals("not", "equal") # stops execution
```

### assert.min
 - Checks that values are greater than or equal to the minimum value.
 - `x = assert.min(2)` returns an object, `x`, that can `x.check()` if values are greater than or equal to 2.
 - Is able to compare numbers, strings, lists, dictionaries, and starlark fragments.
```python
assert.min(2).check(5)

assert.min(2).check(1) # stops execution
```

### assert.max
- Checks that values are less than or equal to the maximum value.
- `x = assert.max(4)` returns an object, `x`, that can `x.check()` if values are less than or equal to 4.
- Is able to compare numbers, strings, lists, dictionaries, and starlark fragments.
```python
assert.max(4).check(3)

assert.max(4).check(5) # stops execution
```

### assert.min_length
 - Checks that values have length greater than or equal to the minimum length.
 - Minimum length argument is an integer. 
 - `x = assert.min_length(1)` creates an object, `x` that can `check()` if the length of values are greater than or equal to 1.
 - Checks the length of strings, lists, dictionaries, and starlark fragments.
```python
assert.min_length(1).check(["some","list","of","values"])

assert.min_length(1).check("") # stops execution
```

### assert.max_length
- Checks that values have length less than or equal to the maximum length.
- Maximum length argument is an integer.
- `x = assert.max_length(4)` creates an object, `x` that can `check()` if the length of values are less than or equal to 4.
- Checks the length of strings, lists, dictionaries, and starlark fragments.
```python
assert.max_length(4).check({'foo': 0, 'bar': 1})

assert.max(4)_length.check("123.45.67.89") # stops execution
```

### assert.not_null
 - Checks that a value is not null or none.
```python
v = None
assert.not_null(v) # stops execution
# is syntactic sugar for
assert.not_null().check(v) # stops execution
```
