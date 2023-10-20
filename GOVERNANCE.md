# Carvel Governance
This document defines the project governance for Carvel.

# Overview
Carvel, an open source project, is committed to building an open, inclusive, productive and self-governing open source community focused on building high quality, reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes. The community is governed by this document with the goal of defining how the community should work together to achieve this goal.

# Code Repositories
The following code repositories are governed by the Carvel community and maintained under the `carvel-dev\carvel` organization. We'll do our best to maintain this list of repositories but generally any repository under the [carvel-dev](https://github.com/carvel-dev/) organization with the word "carvel" in its name or is tagged with "carvel" should be included in this governance structure.

* [carvel](https://github.com/carvel-dev/carvel): Main Carvel Repo
* [ytt](https://github.com/carvel-dev/ytt): Template and overlay Kubernetes configuration via YAML structures, not text documents
* [kapp](https://github.com/carvel-dev/kapp): Install, upgrade, and delete multiple Kubernetes resources as one "application"
* [kbld](https://github.com/carvel-dev/carl-kbld): Build or reference container images in Kubernetes configuration in an immutable way
* [imgpkg](https://github.com/carvel-dev/imgpkg): Bundle and relocate application configuration (with images) via Docker registries
* [kapp-controller](https://github.com/carvel-dev/kapp-controller): Capture application deployment workflow in App CRD. Reliable GitOps experience powered by kapp
* [vendir](https://github.com/carvel-dev/carvel-vendir): Declaratively state what files should be in a directory
* [secretgen-controller](https://github.com/carvel-dev/secretgen-controller) - Provides CRDs to specify what secrets need to be on a cluster (generated or not).

**Experimental:**
* [kwt](https://github.com/carvel-dev/kwt)
* [terraform-provider-carvel](https://github.com/carvel-dev/terraform-provider-carvel)

**Installation:**
* [homebrew](https://github.com/carvel-dev/homebrew)
* [docker-image](https://github.com/carvel-dev/docker-image)
* [asdf](https://github.com/carvel-dev/asdf)
* [setup-action](https://github.com/carvel-dev/setup-action)

**Plugins:**
* [ytt.vim](https://github.com/carvel-dev/ytt.vim)
* [vscode-ytt](https://github.com/carvel-dev/vscode-ytt)

**Examples:**
* [simple-app-on-kubernetes](https://github.com/carvel-dev/simple-app-on-kubernetes)
* [ytt-library-for-kubernetes](https://github.com/carvel-dev/ytt-library-for-kubernetes)
* [ytt-library-for-kubernetes-demo](https://github.com/carvel-dev/ytt-library-for-kubernetes-demo)
* [guestbook-example-on-kubernetes](https://github.com/carvel-dev/ytt-library-for-kubernetes-demo)

# Community Roles
Please see [the description of the community roles](processes/community-membership.md). For a full list of maintainers and their roles, please go to the MAINTAINERS doc.

# Supermajority
A supermajority is defined as two-thirds of members in the group. A supermajority of Maintainers is required for certain decisions as outlined above. A supermajority vote is equivalent to the number of votes in favor of being at least twice the number of votes against. For example, if you have 5 maintainers, a supermajority vote is 4 votes. Voting on decisions can happen on the mailing list, GitHub, Slack, email, or via a voting service, when appropriate. Maintainers can either vote "agree, yes, +1", "disagree, no, -1", or "abstain". A vote passes when supermajority is met. An abstain vote equals not voting at all.

---
# Decision Making
Ideally, all project decisions are resolved by consensus. If impossible, any maintainer may call a vote. Unless otherwise specified in this document, any vote will be decided by a supermajority of maintainers.

Once we have maintainers from other companies, votes by maintainers belonging to the same company will count as one vote; e.g., 4 maintainers employed by fictional company Valerium will only have one combined vote. If voting members from a given company do not agree, the company's vote is determined by a supermajority of voters from that company. If no supermajority is achieved, the company is considered to have abstained.

# Proposal Process
The proposal process, including a [Proposal Template](https://github.com/carvel-dev/carvel/tree/develop/proposals#proposal-template), is covered at length within the [proposal directory](https://github.com/carvel-dev/carvel/tree/develop/proposals).

# Lazy Consensus
To maintain velocity in a project as busy as Carvel, the concept of [Lazy Consensus](http://en.osswiki.info/concepts/lazy_consensus) is practiced. Ideas and / or proposals should be shared by maintainers via GitHub. Out of respect for other contributors, major changes should also be accompanied by a ping on the Kubernetes Slack in [#Carvel](https://kubernetes.slack.com/archives/CH8KCCKA5) or a note on the [Carvel mailing list](carvel-dev@googlegroups.com) as appropriate. Author(s) of proposals, Pull Requests, issues, etc., will give a time period of no less than five (5) working days for comment and remain cognizant of popular observed world holidays.

Other maintainers may chime in and request additional time for review, but should remain cognizant of blocking progress and abstain from delaying progress unless absolutely needed. The expectation is that blocking progress is accompanied by a guarantee to review and respond to the relevant action(s) (proposals, PRs, issues, etc.) in short order.

Lazy Consensus is practiced for all projects in the `Carvel` org, including the main project repository and the additional repositories.

Lazy consensus does not apply to the process of:
* Removal of maintainers from Carvel

# Updating Governance
All substantive changes in Governance require a supermajority agreement by all maintainers.
