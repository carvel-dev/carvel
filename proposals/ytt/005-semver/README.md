---
title: "Semver support in the standard library"
authors: [ "Max Brauer <mbrauer@vmware.com>" ]
status: "draft"
approvers: [ "Dmitriy Kalinin <dkalinin@vmware.com>", "John Ryan <ryanjo@vmware.com>" ]
---

# Semver

## Problem Statement

Configuration authors frequently encounter strings which denote the version of a
software. [Semantic versioning](https://semver.org/) is a widely adopted scheme for versioning
software. In this proposal the term "semver" is used both for _the_ scheme itself as well _an_ instance of a version.

A semantic version is a string, e.g. `3.2.12`, `0.23.0-beta`, `1.99.2-next+build.5`, which contains structured
information about the version. Configuration authors may want
to read a version's constituents, mutate them and compare different versions. For example, when authoring `ytt`
templates:

* I want to assert that a given string is a well-formed semver.
* I want to change a semver's representation from string to a data structure of my choice, e.g. object or array.
* I want to compare semvers, e.g. expect a given version to be larger than a known version.
* I want to (de,in)crement the major, minor and/or patch version of a semver.
* I want to add, change or remove a semver's prerelease identifier or metadata.

Starlark's standard library provides the means to achieve this. However, it sets a high bar and burdens configuration
authors to write boilerplate code for common, industry standard operations.

## Terminology / Concepts

A semantic version encodes different properties about the version in a string of the
form `<major>.<minor>.<patch>(-<pre-release>)(+<metadata>)`.

Semantic versions are strictly sortable.

For its full specification refer to [Semantic versioning](https://semver.org/).

## Proposal

The proposal is to include a built-in `@ytt:semver` library. Configuration authors can then load it and programmatically
work with strings representing semvers.

The semver library contains means for turning a semver string into a structured representation. This can result in an
error in the case of a malformed semver. If the operation succeeds, it returns a `struct` representing the semver.

Now, it is possible to read the _major_, _minor_, _patch_ versions as integers, as well as the _pre-release_
version and _build metadata_ as a strings. This enables authors to change its representation at will.

It is also possible to programmatically construct a semver `struct` by providing _major_, _minor_, _patch_ versions as
required integers, as well as the _pre-release_ version and _build metadata_ as optional strings. This enables authors
to construct semvers either from values known in advance or which are received in a representation other than a semver.

Given two semver `structs`, they can be compared. This enables authors to test if a semver is large or small enough,
or whether it is within a range.

For its implementation, the suggestion is to use [blang/semver](https://github.com/blang/semver). It is a
well-established module, contains an API to address all conceivable case and is already used by Carvel's `vendir` for
its `tools sort-semver` subcommand.

### Goals and Non-goals

* Enable configuration authors to programmatically work with semvers out-of-the-box.

* Education around and proliferation of the semver scheme is not considered to be `ytt`'s responsibility.

### Specification / Use Cases

#### semver·version

`semver.version([major=int, minor=int, patch=int, prerelease=string, metadata=string])` returns a struct representing a
semantic version. The fields `major`, `minor` and `patch` are strings and default to `0`. The fields `prerelease` and
`metadata` are strings and default to `None`. If any of the arguments are of the wrong type or contain forbidden
characters, it is a dynamic error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version()                                        #! 0.0.0
#@ semver.version(1, 2, 3)                                 #! 1.2.3
#@ semver.version(1, 2, 3, "beta")                         #! 1.2.3-beta
#@ semver.version(1, 2, 3, metadata="build.5")             #! 1.2.3+build.5
#@ semver.version(1, 2, 3, "next", "nightly")              #! 1.2.3-next+nightly
#@ semver.version(minor=1, prerelease="alpha")             #! 0.1.0-alpha
#@ semver.version(1, 2, -5)                                #! ⚡️ error
#@ semver.version(prerelease="$send-ytt-coins$")           #! ⚡️ error
#@ semver.version(meta="__dunder-score")                   #! ⚡️ error
```

Use cases:

```yaml
#@ load("@ytt:semver", "semver")
#@ load("@ytt:yaml", "yaml")
#@ load("@ytt:json", "json")
#@ load("@ytt:assert", "assert")

#@ v = semver.version(1, 2, 3)
#@ d = dict(major=v.major, minor=v.minor, patch=v.patch, prerelease=v.prerelease, metadata=v.metadata) 

--- #@ d

---
version.yaml: #@ yaml.encode(d)
version.json: #@ json.encode(d)

#@ d.update(major=d["major"]+1)
#@ next_major = semver.version(**d)

#@ if v.prerelease:
#@   assert.fail("Sorry, we don't do prereleases") 
#@ end

#@ forbidden = ["nightly", "dev"]
#@ if v.metadata in forbidden:
#@   assert.fail("Sorry, that version is forbidden") 
#@ end
```

#### semver·from_str

`semver.from_str(s)` parses `s` as a semantic version and returns its `semver.version()` struct representation. If `s`
is malformed, it is a dynamic error.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.from_str("1.2.3")                                #! semver.version(1, 2, 3)
#@ semver.from_str("1.2.3-pre")                            #! semver.version(1, 2, 3, "pre")
#@ semver.from_str("1.2.3+meta")                           #! semver.version(1, 2, 3, metadata="meta")
#@ semver.from_str("1.2.3-pre+meta")                       #! semver.version(1, 2, 3, "pre", "meta")
#@ semver.from_str("1.2.-5")                               #! ⚡️ error
#@ semver.from_str("Homer Simpson")                        #! ⚡️ error
```

#### version·cmp

`version.cmp(other)` compares two semantic versions and returns `0` if they are equal, `-1` if `other` is greater
and `1` if other is smaller. If `other` is not a `version` struct, it is a dynamic error.

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

All of `version.eq(version)`, `version.lt(version)`, `version.lte(version)`, `version.gt(version)`
and `version.gte(version)` compare `version` with `other` and return `True` if the operator holds and `False` otherwise.
If `other` is not a `version` struct, it is a dynamic error.

```yaml
#@ load("@ytt:data", "data")
#@ load("@ytt:semver", "semver")
#@ load("@ytt:assert", "assert")

#@ v1_2_3 = semver.version(1, 2, 3)
#@ given_version = semver.from_str(data.values.version)

---
cool_config: nice
#@ if/end given_version.lt(v1_2_3)
ye_olde_confyg: they don't make 'em like this any more

#@ if given_version.gte(semver.version(10, 20, 30))
#@   assert.fail("Sorry, but that's too hot for us")
#@ end
```

#### version·to_str

`version.to_str()` returns the string representation of the `version` struct.

```yaml
#@ load("@ytt:semver", "semver")

#@ semver.version().to_str()                               #! "0.0.0"
#@ semver.version(1, 2, 3).to_str()                        #! "1.2.3"
#@ semver.version(1, 2, 3, "beta").to_str()                #! "1.2.3-beta"
#@ semver.version(1, 2, 3, metadata="build.5").to_str()    #! "1.2.3+build.5"
#@ semver.version(1, 2, 3, "next", "nightly").to_str()     #! "1.2.3-next+nightly"
#@ semver.version(minor=1, prerelease="alpha").to_str()    #! "0.1.0-alpha"
```

Use cases:

```yaml
#@ load("@ytt:semver", "semver")

#@ all_the_minor_versions = [semver.version(minor=i).to_str() for i in range(10)]
---
allowed_versions: #@ all_the_minor_versions
```

### Other Approaches Considered

* A Github-hosted Starlark library like `awesome-ytt/semver` containing a similar API could be fetched with `vendir` and
  then loaded. This wouldn't in reach for the widest possible spectrum of configuration authors. It would require to
  reimplement what existing, established Go modules already have done.

## Open Questions

* There's a host of conceivable additional operations available for semver, e.g. test against range, sort list of
  versions, bumping, etc. It is debatable if that should be part of the standard library. Testing against a range and
  sorting are likelier candidates for a standard library. Bumping is possible with the primitives presented.
* Maybe configuration authors would benefit from a `version.to_dict()`(or even `version.to_list()`
  and `version.to_tuple()`) to ease the transformation into a serializable data structure. On the other hand, at least
  in the case of `version.to_dict()` the author may disagree with the keys.

## Answered Questions
