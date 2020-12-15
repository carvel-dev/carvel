---
title: Dangerous Flags
---

There are several flags available for kapp-controller binary that are **strongly discouraged in a production setting**.

## `--dangerous-enable-pprof=true`

This flag enables [Go's pprof server](https://golang.org/pkg/net/http/pprof/) within kapp-controller process. It runs on `0.0.0.0:6060`. It allows to inspect running Go process in various ways, for example:

- list goroutines: `http://x.x.x.x/debug/pprof/goroutine?debug=2`
- collect CPU samples: `go tool pprof x.x.x.x/debug/pprof/profile?seconds=60` (useful commands: top10, tree)
