---
title: App Command Reference
---



## Global Flags
- `--color` _boolean_, Set color output (default true)
- `--column` _string_, Filter to show only given columns
- `--debug` _boolean_, Include debug output
- `-h`, `--help` _boolean_, help for kctrl
- `--json` _boolean_, Output as JSON
- `--kube-api-burst`, _int_, Set Kubernetes API client burst limit (default 1000)
- `--kube-api-qps` _float32_, Set Kubernetes API client QPS limit (default 1000)
- `--kubeconfig` _string_, Path to the kubeconfig file ($KCTRL_KUBECONFIG),
- `--kubeconfig-context`_string_, Kubeconfig context override ($KCTRL_KUBECONFIG_CONTEXT)
- `--kubeconfig-yaml` _string_, Kubeconfig contents as YAML ($KCTRL_KUBECONFIG_YAML)
- `--tty` _boolean_, Force TTY-like output (default true)
- `-v`, `--version` _boolean_, version for kctrl
- `-y`, `--yes`, _boolean_, Assumes yes for any prompt
