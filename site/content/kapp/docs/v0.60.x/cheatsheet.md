---
aliases: [/kapp/docs/latest/cheatsheet]
title: Cheatsheet
---


## List

List all app in the cluster (across all namespaces)

```bash
kapp ls -A
```

Show only specific columns while listing apps

```bash
kapp ls --column=namespace,name,label
```

## Deploy

Deploy app named `app1` with configuration from `config/`:

```bash
kapp deploy -a app1 -f config/ -c
```

Deploy app named `app1` with configuration piped in (see alternative that does not require `--yes` next):

```bash
ytt -f config/ | kapp deploy -a app1 -f- -c -y
```

Deploy app named `app1` with configuration generated inline and with confirmation dialog:

```bash
kapp deploy -a app1 -f <(ytt -f config/ )
```

Show more diff context when reviewing changes during deploy:

```bash
kapp deploy -a app1 -f config/ -c --diff-context=10
```

Show diff and exit successfully (without applying any changes):

```bash
kapp deploy -a app1 -f config/ --diff-run
```

Show logs from all app `Pods` throughout deploy:

```bash
kapp deploy -a app1 -f config/ --logs-all
```

Rewrite all resources to specify `app1-ns` namespace:

```bash
kapp deploy -a app1 -f config/ --into-ns app1-ns
```

## Inspect

Show summary of all resources in app `app1`:

```bash
kapp inspect -a app1
```

Show summary organized as a tree of all resources in app `app1`:

```bash
kapp inspect -a app1 --tree
```

Show status subresources for each resource in app `app1`:

```bash
kapp inspect -a app1 --status
```

Show all resources in the cluster:

```bash
kapp inspect -a 'label:'
```

Show all resources in particular namespace (note that it currently does namespace filtering client-side):

```bash
kapp inspect -a 'label:' --filter-ns some-ns
```

Show all resources labeled `tier=web` in the cluster:

```bash
kapp inspect -a 'label:tier=web'
```

Show all `Deployment` resources in the cluster **not** managed by kapp:

```bash
kapp inspect -a 'label:!kapp.k14s.io/app' --filter-kind Deployment
```

## Delete

Delete resources under particular label (in this example deleting resources associated with some app):

```bash
kapp delete -a 'label:kapp.k14s.io/app=1578599579922603000'
```

## Environment variables

Environment Variables:
 - `FORCE_COLOR`: set to `1` to force colors to the printed. Useful to preserve colors when piping output such as in `kapp list --all-namespaces  --tty |& less -R`

## Misc

See which labels are used in your cluster (add `--values` to see label values):

```bash
kapp tools list-labels
```

Shows app labels that are still present in the cluster (could be combined with delete command below):
  
```bash
kapp tools list-labels --values --tty=false | grep kapp.k14s.io/app
```

Delete all app changes older than 500h (v0.12.0+):

```bash
kapp deploy -a label:kapp.k14s.io/is-app-change --filter-age 500h+ --dangerous-allow-empty-list-of-resources --apply-ignored
```

