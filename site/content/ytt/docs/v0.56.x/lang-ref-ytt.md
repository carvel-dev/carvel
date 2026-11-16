---
aliases: [/ytt/docs/latest/lang-ref-ytt]
title: Built-in ytt Library
---

## General modules

### assert

See [@ytt:assert module docs](lang-ref-ytt-assert.md).

### data

See [Data Values](ytt-data-values.md) reference for more details

```python
load("@ytt:data", "data")

data.values # struct that has input values

# relative to current package
data.list()                # ["template.yml", "data/data.txt"]
data.read("data/data.txt") # "data-txt contents"

# relative to library root (available in v0.27.1+)
data.list("/")              # list files 
data.read("/data/data.txt") # read file
```

### ip

Parse and inspect Internet Protocol values.

(available in v0.37.0+)

```python
load("@ytt:ip", "ip")

# Parse IP addresses...
addr = ip.parse_addr("192.0.2.1")
addr.is_ipv4()    # True
addr.is_ipv6()    # False
addr.string()     # "192.0.2.1"

addr = ip.parse_addr("2001:db8::1")
addr.is_ipv4()    # False
addr.is_ipv6()    # True
addr.string()     # "2001:db8::1"

# Parse CIDR notation into an IP Address and IP Network...
addr, net = ip.parse_cidr("192.0.2.1/24")
addr.string()         # "192.0.2.1"
addr.is_ipv4()        # True
addr.is_ipv6()        # False
net.string()          # "192.0.2.0/24"
net.addr().string()   # "192.0.2.1"
net.addr().is_ipv4()  # True
net.addr().is_ipv6()  # False

addr, net = ip.parse_cidr("2001:db8::1/96")
addr.string()         # "2001:db8::1"
addr.is_ipv4()        # False
addr.is_ipv6()        # True
net.string()          # "2001:db8::/96"
net.addr().string()   # "2001:db8::"
net.addr().is_ipv4()  # False
net.addr().is_ipv6()  # True
```

### math

Module math is a Starlark module of math-related functions and constants.

> ⚠️ **Non-Deterministic Results** \
> The functions in this module do not guarantee bit-identical results across CPU architectures.
> Using one or more of these functions may produce different output on different machines.


The module defines the following functions:

_(All functions accept both int and float values as arguments.)_

```python
math.ceil(x)         # the ceiling of x, the smallest integer greater than or equal to x.
math.copysign(x, y)  # a value with the magnitude of x and the sign of y.
math.fabs(x)         # the absolute value of x as float.
math.floor(x)        # the floor of x, the largest integer less than or equal to x.
math.mod(x, y)       # the floating-point remainder of x/y. The magnitude of the result is less than y and its sign agrees with that of x.
math.pow(x, y)       # x**y, the base-x exponential of y.
math.remainder(x, y) # the IEEE 754 floating-point remainder of x/y.
math.round(x)        # the nearest integer, rounding half away from zero.

math.exp(x)      # e raised to the power x, where e = 2.718281… is the base of natural logarithms.
math.sqrt(x)     # the square root of x.

math.acos(x)     # the arc cosine of x, in radians.
math.asin(x)     # the arc sine of x, in radians.
math.atan(x)     # the arc tangent of x, in radians.
math.atan2(y, x) # atan(y / x), in radians.
                 # The result is between -pi and pi.
                 # The vector in the plane from the origin to point (x, y) makes this angle with the positive X axis.
                 # The point of atan2() is that the signs of both inputs are known to it, so it can compute the correct
                 # quadrant for the angle.
                 # For example, atan(1) and atan2(1, 1) are both pi/4, but atan2(-1, -1) is -3*pi/4.

math.cos(x)      # the cosine of x, in radians.
math.hypot(x, y) # the Euclidean norm, sqrt(x*x + y*y). This is the length of the vector from the origin to point (x, y).
math.sin(x)      # the sine of x, in radians.
math.tan(x)      # the tangent of x, in radians.

math.degrees(x)  # Converts angle x from radians to degrees.
math.radians(x)  # Converts angle x from degrees to radians.

math.acosh(x) # the inverse hyperbolic cosine of x.
math.asinh(x) # the inverse hyperbolic sine of x.
math.atanh(x) # the inverse hyperbolic tangent of x.
math.cosh(x)  # the hyperbolic cosine of x.
math.sinh(x)  # the hyperbolic sine of x.
math.tanh(x)  # the hyperbolic tangent of x.

math.log(x, base) # the logarithm of x in the given base, or natural logarithm by default.

math.gamma(x) # the Gamma function of x.

math.e  # The base of natural logarithms, approximately 2.71828.
math.pi # The ratio of a circle's circumference to its diameter, approximately 3.14159.
```

### regexp

```python
load("@ytt:regexp", "regexp")

regexp.match("[a-z]+[0-9]+", "__hello123__") # True

regexp.replace("[a-z]+[0-9]+", "__hello123__", "foo")                 # __foo__
regexp.replace("(?i)[a-z]+[0-9]+", "__hello123__HI456__", "bye")      # __bye__bye__
regexp.replace("([a-z]+)[0-9]+", "__hello123__bye123__", "$1")        # __hello__bye__
regexp.replace("[a-z]+[0-9]+", "__hello123__", lambda s: str(len(s))) # __8__

# example of passing the "dot matches newline" flag and using replace to extract a single match from a multiline input string
input_str = "\\ multline string\n\nconst (\n\t// Value is what we want to scrape\n\tValue = 12\n)\n\nfunc main() {..."
regexp.replace("(?s).*Value = ([0-9]+).*", input_str, "$1") # 12
```

See the [RE2 docs](https://github.com/google/re2/wiki/Syntax) for more on regex syntax. Note that flags such as multiline mode are passed in the pattern string as in the [golang regexp library](https://pkg.go.dev/regexp/syntax).

When calling `replace` you can pass either a string or a lambda function as the third parameter. When given a string, `$` symbols are expanded, so that `$1` expands to the first submatch. When given a lambda function, the match is directly replaced by the result of the function.

While `match` and `replace` are currently the only regexp verbs supported, it is possible to mimic `find` by using `replace` to replace all its input with a capture group (see example above).

### struct

See [@ytt:struct module docs](lang-ref-ytt-struct.md).

### url

```python
load("@ytt:url", "url")

url.path_segment_encode("part part")   # "part%20part"
url.path_segment_decode("part%20part") # "part part"

url.query_param_value_encode("part part") # "part+part"
url.query_param_value_decode("part+part") # "part part"

url.query_params_encode({"x":["1"],"y":["2","3"],"z":[""]}) # "x=1&y=2&y=3&z="
url.query_params_decode("x=1&y=2&y=3;z")    # (DEPRECATED)  # {"x":["1"],"y":["2","3"],"z":[""]} 
url.query_params_decode("x=1&y=2&y=3&z")                    # {"x":["1"],"y":["2","3"],"z":[""]}

u = url.parse("http://alice:secret@example.com")
u.string()                 # "http://alice:secret@example.com"
u.user.name                # "alice"
u.user.password            # "secret"
u.user.string()            # "alice:secret"
u.without_user().string()  # "http://example.com"
```

As of v0.38.0, including semicolons in query strings is deprecated behavior.
Allowing semicolons in query strings can [lead to cache poisoning attacks](https://snyk.io/blog/cache-poisoning-in-popular-open-source-packages/). Authors should use ampersands (i.e. `&`) exclusively to separate parameters.

### version

`load("@ytt:version", "version")` (see [version module doc](lang-ref-ytt-version.md))

---
## Hashing modules

### md5

```python
load("@ytt:md5", "md5")

md5.sum("data") # "8d777f385d3dfec8815d20f7496026dc"
```

### sha256

```python
load("@ytt:sha256", "sha256")

sha256.sum("data") # "3a6eb0790f39ac87c94f3856b2dd2c5d110e6811602261a9a923d3bb23adc8b7"
```

---
## Serialization modules

### base64

```python
load("@ytt:base64", "base64")

base64.encode("regular")      # "cmVndWxhcg=="
base64.decode("cmVndWxhcg==") # "regular"
```

### json

```python
load("@ytt:json", "json")

json.encode({"a": [1,2,3,{"c":456}], "b": "str"})
json.encode({"a": [1,2,3,{"c":456}], "b": "str"}, indent=3)

json.decode('{"a":[1,2,3,{"c":456}],"b":"str"}')
```
As of v0.35.0, `json.encode()` with `indent` argument encodes result in multi-line string.

### toml

As of v0.38.0.

```python
load("@ytt:toml", "toml")

toml.encode({"a": [1,2,3,456], "b": "str"})  # 'a = [1, 2, 3, 456]\nb = "str"'
toml.encode({"metrics": {"address":"", "grpc_histogram": False}}, indent=4)
  # '[metrics]\n    address = ""\n    grpc_histogram = false\n'

toml.decode("[plugins]\n  [plugins.cgroups]\n    no_prometheus = false")
  # {"plugins": {"cgroups": {"no_prometheus": False}}}
```


### yaml

```python
load("@ytt:yaml", "yaml")

yaml.encode({"a": [1,2,3,{"c":456}], "b": "str"})
yaml.decode('{"a":[1,2,3,{"c":456}],"b":"str"}')
```

---
## Library module

See [Library specific docs](lang-ref-ytt-library.md).

---
## Overlay module

See [Overlay specific docs](lang-ref-ytt-overlay.md).

---
## Schema Module

See [Schema specific docs](lang-ref-ytt-schema.md).

---
## Template module

See [Template specific docs](lang-ref-ytt-template.md).
