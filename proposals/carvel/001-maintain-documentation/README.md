---
title: "Maintaining Carvel Documentation"
authors: [ "John Ryan <ryanjo@vmware.com>" ]
status: "accepted"
approvers: [ "Aaron Hurley <ahurley@vmware.com>", "Helen George <hskgeo@vmware.com>", "Vibhas Kumar <vibkumar@vmware.com>"]
---

# Maintaining Carvel Documentation

## Problem Statement

As we evolve our tools, we want to keep our documentation up-to-date. That said,
not all users will be using the latest version of our tools.

Currently, the Carvel teams maintain a single version of documentation for each tool. With this scheme,
- PRs to docs that describe pre-release features are held back adding complexity to that contribution process.
- to determine if the description/advice is applicable to their situation, users must "caveat" parts of what they read with mentions of when the feature was introduced or changed in what version (so-called "version caveats").
  - digesting version caveats risks additional cognitive load for the reader:
    - https://carvel.dev/kapp/docs/latest/apply-ordering/#overview
    - https://carvel.dev/kapp/docs/latest/config/
    - https://carvel.dev/ytt/docs/latest/lang-ref-ytt-library/
  - at the time of writing, there are 101 version caveats across the current document set in the Hugo-based site.

**What's needed is a consistent scheme for maintaining our set of documentation that is easy to navigate, easy to search, and easy to maintain — across a range of versions of our tools.**


## Terminology / Concepts

- version caveat — a note or parenthetical that indicates that the behavior of some feature changed around a specific version.

## Proposal

- [Goals and Non-goals](#goals-and-non-goals)
- [Specification / Use Cases](#specification--use-cases)
  - [Freezing a Documentation Set](#freezing-a-documentation-set)
  - [Use Case: Carvel Team Deprecates a Feature](#use-case-carvel-team-deprecates-a-feature)
  - [Use Case: Carvel Team Releases a Patch of an Existing Release](#use-case-carvel-team-releases-a-patch-of-an-existing-release)
  - [Use Case: User Navigates into Documentation (current version)](#use-case-user-navigates-into-documentation-current-version)
  - [Use Case: User Follows a Deep Link into Documentation (previous version)](#use-case-user-follows-a-deep-link-into-documentation-previous-version)
  - [Use Case: User Searches within Documentation](#use-case-user-searches-within-documentation)
  - [Consideration: Playgrounds](#consideration-playgrounds)
- [Other Approaches Considered](#other-approaches-considered)
  - [Two Versions of Documentation](#two-versions-of-documentation)
  - [Multiple Live Versions of Documentation](#multiple-live-versions-of-documentation)

### Goals and Non-goals

**Goals:**
- make it easy for users to know what set of features are available
  to them, given the version of the tool they are using
- optimize for the user using the current version of the tools
- provide a consistent experience across all Carvel tools
- keep it easy for contributors to update documentation

**Non-Goals**
- make it easy to determine which version a given feature was introduced.

### Specification / Use Cases

Carry multiple versions of documentation, one for each [major/minor release](#use-case-carvel-team-releases-a-patch-of-an-existing-release) of the tool:
- only the "latest" version and the "pre-release" versions are actively maintained
- all other versions are [frozen](#freezing-a-documentation-set).
  
Maintenance Flow:

1. **Development** — as new features are developed, the corresponding documentation goes in the
  `develop` directory.
2. **Release** — when a new version of the tool is released:
   1. the `develop` version is renamed with the new version number (e.g. `v0.32.0`)
   2. this version of the docs are configured as the "latest" version
   3. this version is copied to a new `develop`.
    
#### Freezing a Documentation Set

When a version of documentation is "frozen" it means:
- adorned atop every page in the docs is a highly-visible banner:

  ```
  You are viewing documentation for [TOOL] version: v[VERSION]
  [TOOL] v[VERSION] documentation is no longer actively maintained.
  The version you are currently viewing is a static snapshot. For
  up-to-date documentation, see the latest version.
  ```
- once a version is frozen, as a breakable "rule" no edits are made to it.


#### Use Case: Carvel Team Deprecates a Feature

Features that are found to be made redundant or a new approach has made its presence encourage "bad" patterns of usage, they are deprecated.

To indicate that a feature is marked for removal,
- with the canonical description of the feature, a noticeable note should say so indicating in which version deprecation started, the rationale, and what replaces it.
- in mentions / uses of the feature, a simple note (this feature was deprecated) with a link to the rationale in the canonical description.


#### Use Case: Carvel Team Releases a Patch of an Existing Release

On occasion — and so far, rare at that — a bugfix results in a patch release.
(e.g. ytt v0.27.x).

In these cases as well, we'll cut a new version of the docs. Doing so keeps the overall process of maintaining documentation straightforward: there are no special cases.


#### Use Case: User Navigates into Documentation (current version)

- by default the doc site displays the latest version (e.g. if `v0.32.0` is configured as "latest", that version is the default)
- the doc site's search engine indexes _only_ the latest version of the docs.

#### Use Case: User Follows a Deep Link into Documentation (previous version)

It is often a great experience to offer a user a deep link into documentation: it places their attention directly at the relevant piece of information.

However, if a deep link is baked to a specific version, it will inevitably will become out-of-date. As a result, a user may find themselves looking at stale information or now, wrong advice.

To mitigate this outcome, document sets other than the latest should get full-page styling that signals its aged state (e.g. a very light red background to the whole page; or the version warning is implemented such that it never scrolls out of view)


#### Use Case: User Searches within Documentation

In order to avoid a whole class of undesired user experiences (such as being given search results for a different version of the tool, or the search results being cluttered with repeated results from multiple versions), it is crucial that the search engine index be faceted by version.


#### Consideration: Playgrounds

There will be only one version of playground(s): the latest released.


### Other Approaches Considered

#### Two Versions of Documentation

Another approach is to maintain exactly two versions of documentation:
1. `latest` — corresponding to the latest released version of the tool.
2. `develop` — corresponding to the version under development.

In effect, this is the "One Version" approach with a tweak: 
- that all new work is done in the `develop` version;
- when a new version of the tool is released, `latest` is replaced with `develop`

This approach continues to use "version caveat"s in order to convey what features are available in what version of the tool.  It's this exact attendant cognitive load that we wish to reduce for readers/users.


#### Multiple Live Versions of Documentation

We considered an approach where not only would we maintain the `latest`, but all previous versions of documentation to keep up their utility.

This approach was quickly rejected as the maintenance effort significantly outweighs the value of servicing multiple versions.

## Open Questions

**Q2** 

## Answered Questions

**Q1** _Can our website search engine be configured to only index the latest documentation?_ \
**A1** Yes. For example, a tag facet can be added for each version in addition to the tool name.
