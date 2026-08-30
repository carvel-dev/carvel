# Carvel Governance Guide

This document outlines how our open-source community collaborates, makes decisions, and maintains project integrity.

## Overview

Carvel is committed to building an open, inclusive, productive, and self-governing open-source community focused on high-quality, reliable, single-purpose, composable tools for Kubernetes application building, configuration, and deployment.

## Code Repositories

The following repositories are governed by the Carvel community under the [`carvel-dev`](https://github.com/carvel-dev) organization. Any repo with "carvel" in its name or tagged accordingly is considered part of this governance.

- **Core Tools**  
  - [`carvel`](https://github.com/carvel-dev/carvel)  
  - [`ytt`](https://github.com/carvel-dev/ytt)  
  - [`kapp`](https://github.com/carvel-dev/kapp)  
  - [`kbld`](https://github.com/carvel-dev/kbld)  
  - [`imgpkg`](https://github.com/carvel-dev/imgpkg)  
  - [`kapp-controller`](https://github.com/carvel-dev/kapp-controller)  
  - [`vendir`](https://github.com/carvel-dev/carvel-vendir)  
  - [`secretgen-controller`](https://github.com/carvel-dev/secretgen-controller)

- **Experimental**  
  - [`kwt`](https://github.com/carvel-dev/kwt)  
  - [`terraform-provider-carvel`](https://github.com/carvel-dev/terraform-provider-carvel)

- **Installation**  
  - [`homebrew`](https://github.com/carvel-dev/homebrew)  
  - [`docker-image`](https://github.com/carvel-dev/docker-image)  
  - [`asdf`](https://github.com/carvel-dev/asdf)  
  - [`setup-action`](https://github.com/carvel-dev/setup-action)

- **Plugins**  
  - [`ytt.vim`](https://github.com/carvel-dev/ytt.vim)  
  - [`vscode-ytt`](https://github.com/carvel-dev/vscode-ytt)

- **Examples**  
  - [`simple-app-on-kubernetes`](https://github.com/carvel-dev/simple-app-on-kubernetes)  
  - [`ytt-library-for-kubernetes`](https://github.com/carvel-dev/ytt-library-for-kubernetes)  
  - [`ytt-library-for-kubernetes-demo`](https://github.com/carvel-dev/ytt-library-for-kubernetes-demo)  
  - [`guestbook-example-on-kubernetes`](https://github.com/carvel-dev/ytt-library-for-kubernetes-demo)

## Community Roles

See the [Community Membership Guide](https://github.com/carvel-dev/carvel/blob/develop/processes/community-membership.md) for role definitions. Maintainers are listed in the `MAINTAINERS.md` file.

## Supermajority

A supermajority is defined as at least twice the number of votes in favor compared to votes against. For example, with 5 maintainers, 4 votes in favor constitute a supermajority.

Voting can occur via GitHub, Slack, email, mailing list, or appropriate tools. Votes:  
- ✅ `+1` (agree)  
- ❌ `-1` (disagree)  
- ⚪ `abstain` (no vote)

## Decision Making

Decisions are ideally made by consensus. If maintainers from the same company vote, their votes count as one. If they disagree, a supermajority within that company determines the vote. If no supermajority, the company abstains.

## Proposal Process

Use the [Proposal Template](https://github.com/carvel-dev/carvel/tree/develop/proposals#proposal-template) and submit to the [Proposal Directory](https://github.com/carvel-dev/carvel/tree/develop/proposals).

## Lazy Consensus

To maintain velocity, Carvel practices [Lazy Consensus](http://en.osswiki.info/concepts/lazy_consensus).  
- Share proposals via GitHub  
- Notify via [Slack #Carvel](https://kubernetes.slack.com/archives/CH8KCCKA5) or [mailing list](mailto:cncf-carvel-users@lists.cncf.io)  
- Allow at least 5 working days for feedback  
- Avoid unnecessary delays unless review is guaranteed soon

Lazy Consensus applies to all Carvel projects except for:  
- Removal of maintainers

## Updating Governance

All substantive governance changes require supermajority approval by all maintainers.
