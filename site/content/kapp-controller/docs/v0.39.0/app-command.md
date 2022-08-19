---
aliases: [/kapp-controller/docs/latest/app-command]
title: App Command Reference
---

## Overview
The app commands let users observe and interact with Apps conveniently.

## Listing apps
The `kctrl app list` command can be used to list apps.
```bash
$ kctrl app list
```
Supported flags:
- `-A`, `--all-namespaces` _boolean_, List apps in all namespaces
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

## Geting details for an app
The `kctrl app get` command can be used to get details for an app.
```bash
$ kctrl app get -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

## Observe status of an app
The `kctrl app status` command allows users to observe the status of the app with information from the last reconciliation. The command tails and streams app status updates till the app reconciles or fails if the command is run while the app is reconciling.
```bash
$ kctrl app status -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--ignore-not-exists` _boolean_, Keep following app if it does not exist

## Pause reconciliation of an app
The `kctrl app pause` command allows pausing of periodic recopnciliation of an app.
```bash
$ kctrl app pause -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)

## Trigger reconciliation of an app
The `kctrl app kick` command can be used to trigger reconciliation of a command and tail the app status till it reconciles if desired. It can also be used to restart periodic reconciliation for a paused app.
```bash
$ kctrl app kick -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--wait` _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

## Delete an app
The `kctrl app delete` command can be used to delete an app.
```bash
$ kctrl app delete -a simple-app
```
Supported flags:
- `-a`, `--app` _string_, Set app name (required)
- `-n`, `--namespace` _string_, Specified namespace ($KCTRL_NAMESPACE or default from kubeconfig)
- `--noop` _boolean_, Ignore resources created by the app and delete the custom resource itself
- `--wait` _boolean_, Wait for reconciliation to complete (default true)
- `--wait-check-interval` _duration_, Amount of time to sleep between checks while waiting (default 1s)
- `--wait-timeout` _duration_, Maximum amount of time to wait in wait phase (default 5m0s)

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
