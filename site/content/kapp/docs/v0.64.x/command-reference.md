---
aliases: [/kapp/docs/latest/command-reference]
title: Command Reference
---

## App Commands
App commands provides options to deploy, delete, inspect and list apps.

### deploy
The `kapp deploy` command can be used to deploy resources as a single app to your cluster.

```bash
# Deploy app 'app1' based on config files in config/
$ kapp deploy -a app1 -f config/

# Deploy app 'app1' while showing full text diff
$ kapp deploy -a app1 -f config/ --diff-changes

# Deploy app 'app1' based on remote file
$ kapp deploy -a app1 \
    -f https://github.com/...download/v0.6.0/crds.yaml \
    -f https://github.com/...download/v0.6.0/release.yaml
```

##### Supported flags:
Common flags:
- `-a`, `--app` _string_, Set app name (or label selector) (format: name, label:key=val, !key)
- `-c`, `--diff-changes` _boolean_, Show changes
- `-f`, `--file`, _strings_, Set file (format: /tmp/foo, https://..., -) (can repeat)
- `-n`, `--namespace` _string_,  Specified namespace ($KAPP_NAMESPACE or default from kubeconfig)

Diff Flags:
- `--diff-against-last-applied`, _boolean_, Show changes against last applied copy when possible (default true)
- `-c`, `--diff-changes` _boolean_, Show changes
- `--diff-changes-yaml`, _boolean_, Print YAML to be applied
- `--diff-context`, _int_, Show number of lines around changed lines (default 2)
- `--diff-exit-status`, _boolean_, Return specific exit status based on number of changes
- `--diff-filter` _string_, Set changes filter (example: {"and":[{"ops":["update"]},{"existingResource":{"kinds":["Deployment"]}]})
- `--diff-line-numbers`, _boolean_, Show line numbers (default true)
- `--diff-mask`, _boolean_, Apply masking rules (default true)
- `--diff-run`, _boolean_, Show diff and exit successfully without any further action
- `--diff-summary`, _boolean_, Show diff summary (default true)
- `--diff-ui-alpha`, _boolean_, Start UI server to inspect changes (alpha feature)

Apply flags:
- `--apply-check-interval`, _duration_, Amount of time to sleep between applies (default 1s)
- `--apply-concurrency`, _int_, Maximum number of concurrent apply operations (default 5)
- `--apply-default-update-strategy`, _string_, Change default update strategy
- `--apply-exit-status`, _boolean_, Return specific exit status based on number of changes
- `--apply-ignored`, _boolean_, Set to apply ignored changes
- `--apply-timeout`, _duration_, Maximum amount of time to wait in apply phase (default 15m0s)
- `--dangerous-allow-empty-list-of-resources`, _boolean_, Allow to apply empty set of resources (same as running kapp delete)
- `--dangerous-override-ownership-of-existing-resources`, _boolean_, Steal existing resources from another app
- `--dangerous-ownership-override-allowed-apps`, _strings_, Specify existing apps in the same namespace that existing resources can be stolen from

Wait flags:
- `--wait`, _boolean_, Set to wait for changes to be applied (default true)
- `--wait-check-interval`, _duration_,  Amount of time to sleep between checks while waiting (default 3s)
- `--wait-concurrency`, _int_, Maximum number of concurrent wait operations (default 5)
- `--wait-ignored`, _boolean_, Set to wait for ignored changes to be applied
- `--wait-resource-timeout`, _duration_, Maximum amount of time to wait for a resource in wait phase (0s means no timeout)
- `--wait-timeout`, _duration_,  Maximum amount of time to wait in wait phase (default 15m0s)

Resource Filter Flags:
- `--filter`, _string_, Set filter (example: {"and":[{"not":{"resource":{"kinds":["foo%"]}}},{"resource":{"kinds":["!foo"]}}]})
- `--filter-age`, _string_, Set age filter (example: 5m-, 500h+, 10m-)
- `--filter-kind`, _strings_, Set kinds filter (example: Pod) (can repeat)
- `--filter-kind-name`, _strings_, Set kind-name filter (example: Pod/controller) (can repeat)
- `--filter-kind-ns`, _strings_, Set kind-namespace filter (example: Pod/, Pod/knative-serving) (can repeat)
- `--filter-kind-ns-name`, _strings_, Set kind-namespace-name filter (example: Deployment/knative-serving/controller) (can repeat)
- `--filter-labels`, _strings_, Set label filter (example: x=y)
- `--filter-name`, _strings_, Set name filter (example: controller) (can repeat)
- `--filter-ns`, _strings_. Set namespace filter (example: knative-serving) (can repeat)

Resource Validation Flags:
- `--allow-all-ns`, _boolean_, Set to allow all namespaces for resources (does not apply to the app itself)
- `--allow-check`, _boolean_, Enable client-side allowing
- `--allow-cluster`, _boolean_, Set to allow cluster level for resources (does not apply to the app itself)
- `--allow-ns`, _strings_, Set allowed namespace for resources (does not apply to the app itself)

Resource Mangling Flags:
- `--into-ns`, _string_, Place resources into namespace
- `--map-ns`, _strings_, Map resources from one namespace into another (could be specified multiple times)

Logs Flags:
- `--logs`, _boolean_, Show logs from Pods annotated as 'kapp.k14s.io/deploy-logs' (default true)
- `--logs-all`, _boolean_, Show logs from all Pods

Available/Other Flags:
- `--app-changes-max-to-keep`, _int_, Maximum number of app changes to keep (default 200)
- `--app-metadata-file-output`, _string_, Set filename to write app metadata
- `--dangerous-disable-gk-scoping`, _boolean_, Disable scoping of resource searching to used GroupKinds
- `--dangerous-ignore-failing-api-services`, _boolean_, Allow to ignore failing APIServices
- `--dangerous-scope-to-fallback-allowed-namespaces`, _boolean_, Scope resource searching to fallback allowed namespaces
- `--default-label-scoping-rules`, _boolean_, Use default label scoping rules (default true)
- `--existing-non-labeled-resources-check`, _boolean_, Find and consider existing non-labeled resources in diff (default true)
- `--existing-non-labeled-resources-check-concurrency`, _int_, Concurrency to check for existing non-labeled resources (default 100)
- `--exit-early-on-apply-error`, _boolean_, Exit quickly on apply failure (default true)
- `--exit-early-on-wait-error`, _boolean_, Exit quickly on wait failure (default true)
- `-h`, `--help`, _boolean_, help for deploy
- `--labels`, _strings_, Set app label (format: key=val, key=) (can repeat)
- `-p`, `--patch`, _boolean_, Add or update existing resources only, never delete any
- `--prev-app`, _string_, Set previous app name
- `--sort`, _boolean_, Sort by namespace, name, etc. (default true)
- `--tty`, _boolean_, Force TTY-like output (default true)

### inspect
The `kapp inspect` command can be used inspect the resources present in an app.

```bash
# Inspect app 'app1' 
$ kapp inspect -a app1
```

Supported flags:
- `-a`, `--app`, _string_, Set app name (or label selector) (format: name, label:key=val, !key)
- `--dangerous-disable-gk-scoping`, _boolean_, Disable scoping of resource searching to used GroupKinds
- `--dangerous-ignore-failing-api-services`, _boolean_, Allow to ignore failing APIServices
- `--dangerous-scope-to-fallback-allowed-namespaces`, _boolean_, Scope resource searching to fallback allowed namespaces
- `--filter`, _string_, Set filter (example: {"and":[{"not":{"resource":{"kinds":["foo%"]}}},{"resource":{"kinds":["!foo"]}}]})
- `--filter-age`, _string_, Set age filter (example: 5m-, 500h+, 10m-)
- `--filter-kind`, _strings_, Set kinds filter (example: Pod) (can repeat)
- `--filter-kind-name`, _strings_, Set kind-name filter (example: Pod/controller) (can repeat)
- `--filter-kind-ns`, _strings_, Set kind-namespace filter (example: Pod/, Pod/knative-serving) (can repeat)
- `--filter-kind-ns-name`, _strings_, Set kind-namespace-name filter (example: Deployment/knative-serving/controller) (can repeat)
- `--filter-labels`, _strings_, Set label filter (example: x=y)
- `--filter-name`, _strings_, Set name filter (example: controller) (can repeat)
- `--filter-ns`, _strings_, Set namespace filter (example: knative-serving) (can repeat)
- `-h`, `--help`, _boolean_, help for inspect
- `--managed-fields`, _boolean_ Keep the metadata.managedFields when printing objects
- `-n`, `--namespace`, _string_, Specified namespace ($KAPP_NAMESPACE or default from kubeconfig)
- `--raw`, _boolean_ Output raw YAML resource content
- `--status`, _boolean_ Output status content
- `-t`, `--tree`, _boolean_ Tree view
- `--tty`, _boolean_ Force TTY-like output

### list
The `kapp list` command can be used to list resources present on the cluster.

```bash
$ kapp list
```

Supported flags:
- `-A`, `--all-namespaces`, _boolean_, List apps in all namespaces
- `--filter-age`, _string_, Set age filter (example: 5m-, 500h+, 10m-)
- `--filter-labels`, _strings_, Set label filter (example: x=y)
- `-h`, `--help`, _boolean_, help for list
- `-n`, `--namespace`, _string_, Specified namespace ($KAPP_NAMESPACE or default from kubeconfig)
- `--tty`, _boolean_, Force TTY-like output

### logs
The `kapp list` command can be used to print app's pod logs.

```bash
# Follow all pod logs in app 'app1'
$ kapp logs -a app1 -f

# Show logs from pods that start with 'web'
$ kapp logs -a app1 -f -m web%
```

Supported flags:
- `-a`, `--app`, _string_, Set app name (or label selector) (format: name, label:key=val, !key)
- `-c`, `--container-name`, _strings_, Set container name to filter logs (% acts as wildcard, e.g. 'app%') (can repeat)
- `--container-tag`, _boolean_, Include container tag (default true)
- `-f`, `--follow`, _boolean_, As new pods are added, new pod logs will be printed
- `-h`, `--help`, _boolean_, help for logs
- `--lines`, _int_, Limit to number of lines (use -1 to remove limit) (default 10)
- `-n`, `--namespace`, _string_, Specified namespace ($KAPP_NAMESPACE or default from kubeconfig)
- `-m`, `--pod-name`, _string_, Set pod name to filter logs (% acts as wildcard, e.g. 'app%')
- `--tty`, _boolean_, Force TTY-like output

### delete
The `kapp delete` command can be used to delete an app from your cluster.

```bash
$ kapp delete -a app1
```

Supported flags:
- `-a`, `--app`, _string_, Set app name (or label selector) (format: name, label:key=val, !key)
- `--apply-check-interval`, _duration_, Amount of time to sleep between applies (default 1s)
- `--apply-concurrency`, _int_, Maximum number of concurrent apply operations (default 5)
- `--apply-default-update-strategy`, _string_, Change default update strategy
- `--apply-exit-status`, _boolean_, Return specific exit status based on number of changes
- `--apply-ignored`, _boolean_, Set to apply ignored changes
- `--apply-timeout`, _duration_, Maximum amount of time to wait in apply phase (default 15m0s)
- `--dangerous-disable-gk-scoping`, _boolean_, Disable scoping of resource searching to used GroupKinds
- `--dangerous-ignore-failing-api-services`, _boolean_, Allow to ignore failing APIServices
- `--dangerous-scope-to-fallback-allowed-namespaces`, _boolean_, Scope resource searching to fallback allowed namespaces
- `--diff-against-last-applied`, _boolean_, Show changes against last applied copy when possible (default true)
- `-c`, `--diff-changes`, _boolean_, Show changes
- `--diff-changes-yaml`, _boolean_, Print YAML to be applied
- `--diff-context`, _int_, Show number of lines around changed lines (default 2)
- `--diff-exit-status`, _boolean_, Return specific exit status based on number of changes
- `--diff-filter`, _string_,  Set changes filter (example: {"and":[{"ops":["update"]},{"existingResource":{"kinds":["Deployment"]}]})
- `--diff-line-numbers`, _boolean_, Show line numbers (default true)
- `--diff-mask`, _boolean_, Apply masking rules (default true)
- `--diff-run`, _boolean_, Show diff and exit successfully without any further action
- `--diff-summary`, _boolean_, Show diff summary (default true)
- `--diff-ui-alpha`, _boolean_, Start UI server to inspect changes (alpha feature)
- `--exit-early-on-apply-error`, _boolean_, Exit quickly on apply failure (default true)
- `--exit-early-on-wait-error`, _boolean_, Exit quickly on wait failure (default true)
- `--filter`, _string_, Set filter (example: {"and":[{"not":{"resource":{"kinds":["foo%"]}}},{"resource":{"kinds":["!foo"]}}]})
- `--filter-age`, _string_, Set age filter (example: 5m-, 500h+, 10m-)
- `--filter-kind`, _strings_, Set kinds filter (example: Pod) (can repeat)
- `--filter-kind-name`, _strings_, Set kind-name filter (example: Pod/controller) (can repeat)
- `--filter-kind-ns`, _strings_, Set kind-namespace filter (example: Pod/, Pod/knative-serving) (can repeat)
- `--filter-kind-ns-name`, _strings_, Set kind-namespace-name filter (example: Deployment/knative-serving/controller) (can repeat)
- `--filter-labels`, _strings_, Set label filter (example: x=y)
- `--filter-name`, _strings_, Set name filter (example: controller) (can repeat)
- `--filter-ns`, _strings_, Set namespace filter (example: knative-serving) (can repeat)
- `-h`, `--help`, _boolean_, help for delete
- `-n`, `--namespace`, _string_, Specified namespace ($KAPP_NAMESPACE or default from kubeconfig)
- `--prev-app`, _string_, Set previous app name
- `--tty`, _boolean_, Force TTY-like output (default true)
- `--wait`, _boolean_, Set to wait for changes to be applied (default true)
- `--wait-check-interval`, _duration_, Amount of time to sleep between checks while waiting (default 3s)
- `--wait-concurrency`, _int_, Maximum number of concurrent wait operations (default 5)
- `--wait-ignored`, _boolean_, Set to wait for ignored changes to be applied (default true)
- `--wait-resource-timeout`, _duration_,  Maximum amount of time to wait for a resource in wait phase (0s means no timeout)
- `--wait-timeout`, _duration_,  Maximum amount of time to wait in wait phase (default 15m0s)

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

## Environment variables

Environment Variables:
 - `FORCE_COLOR`: set to `1` to force colors to the printed. Useful to preserve colors when piping output such as in `kctrl app list --tty --all-namespaces |& less -R`
