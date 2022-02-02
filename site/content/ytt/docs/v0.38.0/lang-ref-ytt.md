---

title: Built-in ytt Library
---

## General modules

### struct

See [@ytt:struct module docs](lang-ref-ytt-struct.md).

### assert

```python
load("@ytt:assert", "assert")

# stop execution and report a failure
assert.fail("expected value foo, but was {}".format(value)) # stops execution
x = data.values.env.mysql_password or assert.fail("missing env.mysql_password")

# invoke a function value, catching failure if it occurs
x, err = assert.try_to(lambda : json.decode('{"key": "value"}'))
x     # { "key" = "value" }    (i.e. dict with one entry)
err   # None

x, err = assert.try_to(lambda : json.decode("(not JSON)"))
x     # None
err   # "json.decode: invalid character '(' looking for beginning of value"
```

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
## Schema Module

See [Schema specific docs](lang-ref-ytt-schema.md).

---
## Overlay module

See [Overlay specific docs](lang-ref-ytt-overlay.md).

---
## Library module

See [Library specific docs](lang-ref-ytt-library.md).

---
## Template module

See [Template specific docs](lang-ref-ytt-template.md).
