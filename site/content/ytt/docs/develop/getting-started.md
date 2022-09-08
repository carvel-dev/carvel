---
title: Getting Started
toc: "true"
---

## 


basically, YAML with Python*

example template

```yaml
#@ app = "frontend"
---
metadata:
  name: #@ app + "-service"
```

YAML as in this is a real YAML document with comments

ignoring the comments:

```yaml
---
metadata:
  name: null
```

ytt reads the comments as code
so a variable `app` is set to the string `"frontend"`
and the value for `name:` gets set to `app + "-service"`.

when evaluated,
```yaml
---
metadata:
  name: frontend-service
```

Flow control weaves _into_ the YAML:

```yaml
#@ debug = False
#@ app = "frontend"
---
metadata:
  name: #@ app + "-service"
spec:
  #@ if debug:
  logLevel: trace
  #@ end
  containers:
    #@ for img in ["nginx", "redis"]
    - name: #@ img
      image: #@ img + ":latest"
    #@ end
```

since `debug` is `False` (note Python*'s literal for false has a capital 'F'), `logLevel:` won't be included in the evaluated doc.
and our `for` loop iterates over that list containing two strings, producing two items.

```yaml
---
metadata:
  name: frontend-service
spec:
  containers:
    - name: nginx
      image: nginx:latest
    - name: redis
      image: redis:latest
```

