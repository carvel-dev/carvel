---
title: "Semver support in the standard library"
authors: ["Max Brauer <mbrauer@vmware.com>"]
status: "draft"
approvers: ["Dmitriy Kalinin <dkalinin@vmware.com>", "John Ryan <ryanjo@vmware.com>"]
---

# Semver

- [Semver](#semver)
  - [Problem Statement](#problem-statement)
  - [Terminology / Concepts](#terminology--concepts)
  - [Proposal](#proposal)
    - [Goals](#goals)
    - [Non-goals](#non-goals)
    - [Specification](#specification)
      - [semver·version](#semverversion)
      - [semver·from_str](#semverfrom_str)
      - [version·to_str](#versionto_str)
      - [version·cmp](#versioncmp)
      - [version·(eq, lt, lte, gt, gte)](#versioneq-lt-lte-gt-gte)
      - [version·(next_major, next_minor, next_patch)](#versionnext_major-next_minor-next_patch)
      - [semver·range](#semverrange)
      - [range·contains](#rangecontains)
      - [range·to_str](#rangeto_str)
    - [Use Cases](#use-cases)
      - [Data value validation](#data-value-validation)
      - [_kapp-controller_'s _Downward_ API](#kapp-controllers-downward-api)
      - [Drive releases with _conventional commits_](#drive-releases-with-conventional-commits)
    - [Considered Alternatives](#considered-alternatives)
  - [Open Questions](#open-questions)
  - [Answered Questions](#answered-questions)

## Problem Statement

Configuration authors frequently encounter strings which denote the version of a software.
[Semantic versioning](https://semver.org/) is a widely adopted scheme for versioning software. In this proposal the term
"semver" is used both for _the_ scheme itself as well _an_ instance of a version.

A semantic version is a string, e.g. `3.2.12`, `0.23.0-beta`, `1.99.2-next+build.5`, which contains structured
information about the version. Configuration authors may want to read a version's constituents, mutate them and compare
different versions. For example, when authoring `ytt` templates:

- I want to assert that a given string is a well-formed semver.
- I want to access a semver's components so that I can easily change its representation.
- I want to compare semvers, e.g. expect a given version to be larger than a known version.
- I want to (de,in)crement the major, minor and/or patch version of a semver.
- I want to add, change or remove a semver's prerelease identifier or build metadata.

Starlark's standard library provides the means to achieve this. However, it sets a high bar and burdens configuration
authors to write boilerplate code for common, industry standard operations.

## Terminology / Concepts

A semantic version encodes different properties about the version in a string of the form
`<major>.<minor>.<patch>(-<pre-release>)(+<build>)`.

Semantic versions can be sorted based on [precedence](https://semver.org/#spec-item-11).

For its full specification refer to [Semantic versioning](https://semver.org/).

## Proposal

The proposal is to include a built-in `@ytt:semver` library. Configuration authors can then load it and programmatically
work with strings representing semantic verssions.

The library contains means for turning a semver string into a structured representation. This can result in an error in
the case of a malformed semver. If the operation succeeds, it returns a `struct` representing the semver.

Now, it is possible to read the _major_, _minor_, _patch_ versions as integers, as well as the _pre-release_ version and
_build metadata_ as a strings. This enables authors to change its representation at will.

It is also possible to programmatically construct a semver `struct` by providing _major_, _minor_, _patch_ versions as
required integers, as well as the _pre-release_ version and _build metadata_ as optional strings. This enables authors
to construct semvers either from values known in advance or which are received in a representation other than a semver.

Given two semver `structs`, they can be compared. This enables authors to test if a semver is large or small enough, or
whether it is within a range.

For its implementation, the suggestion is to use [k14s/semver](https://github.com/k14s/semver), a Carvel-owned fork of
[blang/semver](https://github.com/blang/semver) It is a well-established module, contains an API to address all
conceivable case and is already used by Carvel's `vendir` for its `tools sort-semver` subcommand.

### Goals

- Enable configuration authors to programmatically work with semvers out-of-the-box.
- Use and promote terminology and APIs consistent with existing concepts in other Carvel tools, e.g. _kapp-controller_'s [constraints](https://carvel.dev/kapp-controller/docs/develop/package-consumer-concepts/#constraints)
- Where other Carvel tools deviate from the semver spec, be consistent with them, e.g. _vendir_'s [semver](https://carvel.dev/vendir/docs/v0.31.0/versions/#semver) constraint

### Non-goals

- Education around and proliferation of the semver scheme is not considered to be `ytt`'s responsibility.

### Specification

As is the case for all `ytt` libraries, it can be loaded by YAML-embedded or pure _Starlark_ programs:

```yaml
#! config.yaml
#@ load("@ytt:semver", "semver")
```

```star
# config.star
load("@ytt:semver", "semver")
```

#### semver·version

`semver.version([major=int, minor=int, patch=int, prerelease=string, build=string])` returns a struct representing a
semantic version. The fields `major`, `minor` and `patch` are strings and default to `0`. The fields `prerelease` and
`build` are strings and default to `None`. If any of the arguments are of the wrong type or contain forbidden
characters, it is a dynamic error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version()                                        #! 0.0.0
#@ semver.version(1, 2, 3)                                 #! 1.2.3
#@ semver.version(1, 2, 3, "beta")                         #! 1.2.3-beta
#@ semver.version(1, 2, 3, build="build.5")                #! 1.2.3+build.5
#@ semver.version(1, 2, 3, "next", "nightly")              #! 1.2.3-next+nightly
#@ semver.version(minor=1, prerelease="alpha")             #! 0.1.0-alpha
#@ semver.version(1, 2, -5)                                #! ⚡️ error
#@ semver.version(prerelease="$send-ytt-coins$")           #! ⚡️ error
#@ semver.version(meta="__dunder-score")                   #! ⚡️ error
```

#### semver·from_str

`semver.from_str(s)` parses `s` as a semantic version and returns its `semver.version()` struct representation. If `s`
is malformed, it is a dynamic error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.from_str("1.2.3")                                #! semver.version(1, 2, 3)
#@ semver.from_str("1.2.3-pre")                            #! semver.version(1, 2, 3, "pre")
#@ semver.from_str("1.2.3+meta")                           #! semver.version(1, 2, 3, build="meta")
#@ semver.from_str("1.2.3-pre+meta")                       #! semver.version(1, 2, 3, "pre", "meta")
#@ semver.from_str("1.2.-5")                               #! ⚡️ error
#@ semver.from_str("Homer Simpson")                        #! ⚡️ error
```

#### version·to_str

`version.to_str()` returns the string representation of the `version` struct.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version().to_str()                               #! "0.0.0"
#@ semver.version(1, 2, 3).to_str()                        #! "1.2.3"
#@ semver.version(1, 2, 3, "beta").to_str()                #! "1.2.3-beta"
#@ semver.version(1, 2, 3, build="build.5").to_str()    #! "1.2.3+build.5"
#@ semver.version(1, 2, 3, "next", "nightly").to_str()     #! "1.2.3-next+nightly"
#@ semver.version(minor=1, prerelease="alpha").to_str()    #! "0.1.0-alpha"
```

#### version·cmp

`version.cmp(other)` compares two semantic versions and returns `0` if they are equal, `-1` if `other` is greater and
`1` if other is smaller. If `other` is not a `version` struct, it is a dynamic error.

Usage of `version.(eq, lt, lte, gt, gte)` is recommended instead. However, there may be cases where a numeric return
value is preferred.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version().cmp(semver.version())                  #! 0
#@ semver.version(1).cmp(semver.version(2))                #! -1
#@ semver.version(1, 2, 3).cmp(semver.version(2, 0, 3))    #! 1
#@ semver.version(1, 2, 3).cmp(dict())                     #! ⚡️ error
```

#### version·(eq, lt, lte, gt, gte)

All of `version.eq(version)`, `version.lt(version)`, `version.lte(version)`, `version.gt(version)` and
`version.gte(version)` compare `version` with `other` and return `True` if the operator holds and `False` otherwise. If
`other` is not a `version` struct, it is a dynamic error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version().eq(semver.version())                                            #! True
#@ semver.from_str("1.2.3-pre+build")).eq(semver.version(1, 2, 3, "pre", "build"))  #! True
#@ semver.version(1, 2, 3).eq(semver.version(3, 2, 1))                              #! False
#@ semver.version(1, 2, 3).lt(semver.version(3, 2, 1))                              #! True
#@ semver.version(1, 2, 3).lt(semver.version(1, 2, 3))                              #! False
#@ semver.version(1, 2, 3).lte(semver.version(3, 2, 1))                             #! True
#@ semver.version(1, 2, 3).lte(semver.version(1, 2, 3))                             #! True
#@ semver.version(1, 2, 3).lte(semver.version(1, 0, 0))                             #! False
#@ semver.version(3, 2, 1).gt(semver.version(1, 2, 3))                              #! True
#@ semver.version(3, 2, 1).gt(semver.version(4, 0, 0))                              #! False
#@ semver.version(3, 2, 1).gte(semver.version(1, 2, 3))                             #! True
#@ semver.version(3, 2, 1).gte(semver.version(3, 2, 1))                             #! True
#@ semver.version(3, 2, 1).gte(semver.version(4, 0, 0))                             #! False
```

#### version·(next_major, next_minor, next_patch)

All of `version.next_major()`, `version.next_minor()` and `version.next_patch()` return a new `version` and bump the
respective components. Existing `prerelease` and `build` are reset.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.from_str("1.2.3").next_patch()                   #! semver.version(1, 2, 4)
#@ semver.from_str("1.2.3").next_minor()                   #! semver.version(1, 3, 0)
#@ semver.from_str("1.2.3").next_major()                   #! semver.version(2, 0, 0)
#@ semver.from_str("1.2.3-alpha").next_major()             #! semver.version(2, 0, 0)
#@ semver.from_str("1.2.3+nightly").next_minor()           #! semver.version(1, 3, 0)
#@ semver.from_str("1.2.3-beta+dev").next_patch()          #! semver.version(1, 2, 4)
```

#### semver·range

`semver.range(range=string)` returns a struct representing a range of semantic versions. The struct has no fields. If
the range argument is not a `string` or cannot be parsed as a range of semantic versions, it is a dynamic error.

Valid ranges are all strings which are accepted by
[range.ParseRange](https://pkg.go.dev/github.com/k14s/semver/v4?utm_source=godoc#ParseRange) without
error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.range("<1.0.0")                                  #! less than 1.0.0
#@ semver.range("<=1.0.0")                                 #! less than or equal 1.0.0
#@ semver.range(">1.0.0")                                  #! larger than 1.0.0
#@ semver.range(">=1.0.0")                                 #! larger than or equal 1.0.0
#@ semver.range("1.0.0")                                   #! equal 1.0.0
#@ semver.range("=1.0.0")                                  #! equal 1.0.0
#@ semver.range("==1.0.0")                                 #! equal 1.0.0
#@ semver.range("!1.0.0")                                  #! not equal 1.0.0
#@ semver.range("!=1.0.0")                                 #! not equal 1.0.0
#@ semver.range(">1.0.0 <2.0.0")                           #! between 1.0.0 and 2.0.0
#@ semver.range(">1.0.0 <3.0.0 !2.0.3-beta.2")             #! between 1.0.0 and 3.0.0 but not equal 2.0.3-beta.2
#@ semver.range("<2.0.0 || >=3.0.0")                       #! less than 2.0.0 or larger than or equal 3.0.0
#@ semver.range(">1.0.0 <2.0.0 || >3.0.0 !4.2.1")          #! ...
#@ semver.range("~1.2.3")                                  #! ⚡️ error
#@ semver.range("not a range")                             #! ⚡️ error
```

#### range·contains

`range.contains(version=version)` returns `True` if `range` contains the given `version` and `False` otherwise.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.range("<1.0.0").contains(semver.from_str("0.1.0))                               #! True
#@ semver.range("<1.0.0").contains(semver.from_str("1.0.0))                               #! False
#@ semver.range(">1.0.0 <2.0.0").contains(semver.from_str("1.23.45))                      #! True
#@ semver.range(">1.0.0 <3.0.0 !2.0.3-beta.2").contains(semver.from_str("2.0.3-beta.2"))  #! False
#@ semver.range(">1.0.0 <3.0.0 !2.0.3-beta.2").contains(semver.from_str("2.0.3"))         #! True
```

#### range·to_str

`range.to_str()` returns the initially given string representation of `range`.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.range("<1.0.0").to_str()                          #! "<1.0.0"
#@ semver.range(">=1.0.0").to_str()                         #! ">=1.0.0"
#@ semver.range("1.0.0").to_str()                           #! "1.0.0"
#@ semver.range("=1.0.0").to_str()                          #! "=1.0.0"
#@ semver.range("==1.0.0").to_str()                         #! "==1.0.0"
#@ semver.range(">1.0.0 <2.0.0").to_str()                   #! ">1.0.0 <2.0.0"
#@ semver.range(">1.0.0 <3.0.0 !2.0.3-beta.2").to_str()     #! ">1.0.0 <3.0.0 !2.0.3-beta.2"
```

### Use Cases

**todo** collect ^ use cases here and make them prettier, and more specific

The presented use cases demonstrate the proposed API's utility in different templating scenarios.
The scenarios aspire to be representative but not exhaustive of all conveivable applications.

#### Data value validation

Use `@ytt:semver` to validate and constrain a data value which represents a semantic version.

```yaml
#! schema.yaml

#@ load("@ytt:data", "data")
#@ load("@ytt:semver", "semver")
#@ load("@ytt:assert", "assert")

#@ compatible_versions = semver.range("<3.0.0 >=2.0.0 !2.5.3")

#@ def is_semver(s):
#@   """Returns True if s is a semantic version and an error otherwise."""
#@   _, err = assert.try_to(lambda: semver.from_str(s))
#@   return True if err == Null else err
#@ end

#@ def is_compatible(v):
#@   """Returns True if v is within the allowed range and optionally a release candidate, but not a pre-release. Returns False otherwise."""
#@   return compatible_versions.contains(v) and (v.prerelease == "rc" or !v.prerelease)
#@ end

#@schema/title "The version"
#@schema/desc "The version to use must be a compatible semantic version"
#@schema/validation ("is_semver", is_semver), ("is_compatible", is_compatible)
version: ""
```

#### _kapp-controller_'s _Downward_ API

Consume _kapp-controller_'s _Downward_ API and conditionally template Kubernetes resources.

```yaml
#! app.yaml

apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: my-app
  namespace: my-app
spec:
  serviceAccountName: my-app-sa
  template:
  - ytt:
      inline:
        valuesFrom:
          - downwardAPI:
              items:
                name: kubernetes_version
                kubernetesVersion: {}
        paths:
          deployment.yaml: #! ...
          service.yaml: #! ...
          ingress.yaml: |
            #@ load("@ytt:data", "data")
            #@ load("@ytt:semver", "semver")

            #! The Ingress API graduated to stable in Kubernetes 1.19.
            #@ stable_ingress_kubernetes_versions = semver.range(">=1.19.0")
            #@ kubernetes_version = semver.from_str(data.values.kubernetes_version)
            #@ use_stable_ingress = stable_ingress_kubernetes_versions.contains(kubernetes_version)

            ---
            #@ if use_stable_ingress:
            apiVersion: networking.k8s.io/v1
            #@ else
            apiVersion: networking.k8s.io/v1beta1
            #@ end
            kind: Ingress
            #! ...
  #! ...
```

#### Drive releases with _conventional commits_

Release software by templating _kapp-controller_ packaging resources driven with [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#summary)

```yaml
#! release.yaml

#@ load("@ytt:data", "data")
#@ load("@ytt:semver", "semver")
#@ load("@ytt:assert", "assert")

#@ last_version = semver.from_str(data.values.version)

#! Detect the semantic change
#@ has_fixes = False
#@ has_features = False
#@ has_breaking_changes = False
#@ for commit in data.values.new_commits:
#@   if commit.startswith("feat: "):
#@     if commit.count("BREAKING CHANGE: "):
#@       has_breaking_changes = True
#@     else
#@       has_features = True
#@     end
#@   elif commit.startswith("fix: "):
#@     has_fixes = True
#@   end
#@ end

#! Bump next version accordingly
#@ if has_breaking_changes:
#@   next_version = last_version.next_major()
#@ elif has_features:
#@   next_version = last_version.next_minor()
#@ elif has_fixes:
#@   next_version = last_version.next_patch()
#@ else:
#@   assert.fail("No changes since last release")
#@ end

#! If prerelease, increment prerelease "build.x" identifier
#@ if data.values.prerelease:
#@   prerelease = data.values.prerelease
#@   separator = "."
#@   counter = 1
#@   if last_version.prerelease:
#@     prerelease, _, counter_str = last_version.build.partition(separator)
#@     counter = int(counter_str)+1
#@   end
#@   next_version.prerelease = "{}{}{}".format(prerelease, separator, counter)
#@ end

---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: #@ "my-package.example.com.{}".format(next_version.to_str())
  namespace: my-packages
spec:
  refName: my-package.example.com
  version: #@ next_version.to_str()
  # ...

---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: my-package-install
  namespace: my-packages
spec:
  packageRef:
    refName: my-package.example.com
    versionSelection:
      constraints: #@ next_version.to_str()
      #@ if/end next_version.prerelease:
      prereleases: {}
  # ...
```

```shell
# Release 1.2.4-build.1
ytt \
  --filename release.yaml \
  --data-value last_version=1.2.3 \
  --data-value prerelease=beta \
  --data-value-file new_commits=only_fixes.yaml
```

```shell
# Release 2.0.0
ytt \
  --filename release.yaml \
  --data-value last_version=1.2.3-alpha.15 \
  --data-value prerelease="" \
  --data-value-file new_commits=breaking_changes.yaml
```

### Considered Alternatives

- A Github-hosted Starlark library like `awesome-ytt/semver` containing a similar API could be fetched with `vendir` and
  then loaded. This wouldn't in reach for the widest possible spectrum of configuration authors. It would require to
  reimplement what existing, established Go modules already have done.

## Open Questions

- Should we prefer the term `constraint` over `range` as it might be more consistent with other Carvel tools?
- There's a host of conceivable additional operations for semver, e.g. sorting list of versions, bumping
  prereleases (1.2.3-build.5 → 1.2.3-build.6), etc. It is debatable if that should be part of the built-in library. If
  the primitives provided by the library are expressive enough, then authors should be able to cover these use cases by
  themselves.
- Maybe configuration authors would benefit from a `version.to_dict()`(or even `version.to_list()` and
  `version.to_tuple()`) to ease the transformation into a serializable data structure. On the other hand, at least in
  the case of `version.to_dict()` the author may disagree with the keys.

## Answered Questions
