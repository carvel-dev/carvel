# Carvel Governance
This document defines the project governance for Carvel.

---
# Overview
Carvel, an open source project, is committed to building an open, inclusive, productive and self-governing open source community focused on building high quality, reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes. The community is governed by this document with the goal of defining how the community should work together to achieve this goal.

---
# Code Repositories
The following code repositories are governed by the Carvel community and maintained under the `vmware-tanzu\carvel` organization.

* [Carvel](https://github.com/vmware-tanzu/carvel): Main Carvel Repo
* [Carvel-ytt](https://github.com/vmware-tanzu/carvel-ytt): Template and overlay Kubernetes configuration via YAML structures, not text documents
* [Carvel-kapp](https://github.com/vmware-tanzu/carvel-kapp): Install, upgrade, and delete multiple Kubernetes resources as one "application"
* [Carvel-kbld](https://github.com/vmware-tanzu/carvel-kbld): Build or reference container images in Kubernetes configuration in an immutable way
* [Carvel-imgpkg](https://github.com/vmware-tanzu/carvel-imgpkg): Bundle and relocate application configuration (with images) via Docker registries
* [Carvel-kapp-controller](https://github.com/vmware-tanzu/carvel-kapp-controller): Capture application deployment workflow in App CRD. Reliable GitOps experience powered by kapp
* [Carvel-vendir](https://github.com/vmware-tanzu/carvel-vendir): Declaratively state what files should be in a directory

**Experimental:**
* [kwt](https://github.com/vmware-tanzu/carvel-kwt)
* [terraform-provider-carvel](https://github.com/vmware-tanzu/terraform-provider-carvel)
* [carvel-secretgen-controller](https://github.com/vmware-tanzu/carvel-secretgen-controller)

**Installation:**
* [homebrew-carvel](https://github.com/vmware-tanzu/homebrew-carvel)
* [carvel-docker-image](https://github.com/vmware-tanzu/carvel-docker-image)
* [asdf-carvel](https://github.com/vmware-tanzu/asdf-carvel)
* [carvel-setup-action](https://github.com/vmware-tanzu/carvel-setup-action)

**Plugins:**
* [ytt.vim](https://github.com/vmware-tanzu/ytt.vim)

**Examples:**
* [carvel-simple-app-on-kubernetes](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes)
* [carvel-ytt-library-for-kubernetes](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes)
* [carvel-ytt-library-for-kubernetes-demo](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes-demo)
* [carvel-guestbook-example-on-kubernetes](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes-demo)

---
# Community Roles
* **Users:** Anyone that uses a tool within Carvel.
* **Contributors:** A contributor is anyone that contributes to one or more projects (documentation, code reviews, responding to issues, participation in proposal discussions, contributing code, etc.) or is continuously active in the Carvel community.
* **Maintainers:** The Carvel project leaders. They are responsible for the overall health and direction of the project and responsible for releases. Maintainers are responsible for one or more components within the project. Some maintainers act as a technical lead for specific components. Carvel maintainers are broken down into three sub-roles: maintainer, reviewer, approver. 
    * **Maintainer:** Maintainers are expected to contribute code and documentation, triage issues, proactively fix bugs, and perform maintenance tasks for these components.
    * **Reviewer:** They have all the responsibilities of a maintainer with additional responsibilities and permissions. A reviewer can review code for quality and correctness on a tool. They are knowledgeable about both the codebase and software engineering principles. They can approve pprovers' contributions.
    * **Approver:** They have all the responsibilities of a eviewer with additional responsibilities and permissions. An Approver can both review and approve code contributions from anyone. While code review is focused on code quality and correctness, approval is focused on holistic acceptance of a contribution including backward/forwards compatibility, adhering to API and flag conventions, subtle performance and correctness issues, interactions with other parts of the system, etc.

---
# Maintainers
New maintainers must be nominated by an existing maintainer and must be elected by a supermajority of existing maintainers. Likewise, maintainers can be removed by a supermajority of the existing maintainers or can resign by notifying one of the maintainers.

---
# Supermajority
A supermajority is defined as two-thirds of members in the group. A supermajority of Maintainers is required for certain decisions as outlined above. A supermajority vote is equivalent to the number of votes in favor of being at least twice the number of votes against. For example, if you have 5 maintainers, a supermajority vote is 4 votes. Voting on decisions can happen on the mailing list, GitHub, Slack, email, or via a voting service, when appropriate. Maintainers can either vote "agree, yes, +1", "disagree, no, -1", or "abstain". A vote passes when supermajority is met. An abstain vote equals not voting at all.

---
# Decision Making
Ideally, all project decisions are resolved by consensus. If impossible, any maintainer may call a vote. Unless otherwise specified in this document, any vote will be decided by a supermajority of maintainers.

Votes by maintainers belonging to the same company will count as one vote; e.g., 4 maintainers employed by fictional company Valerium will only have one combined vote. If voting members from a given company do not agree, the company's vote is determined by a supermajority of voters from that company. If no supermajority is achieved, the company is considered to have abstained.

---
# Proposal Process
One of the most important aspects in any open source community is the concept of proposals. Large changes to the codebase and / or new features should be preceded by a proposal in our carvel repo. This process allows for all members of the community to weigh in on the concept (including the technical details), share their comments and ideas, and offer to help. It also ensures that members are not duplicating work or inadvertently stepping on toes by making large conflicting changes.

The [project roadmap](https://github.com/vmware-tanzu/carvel/blob/develop/ROADMAP.md) is defined by accepted proposals.

Proposals should cover the high-level objectives, use cases, and technical recommendations on how to implement. In general, the community member(s) interested in implementing the proposal should be either deeply engaged in the proposal process or be an author of the proposal.

The proposal process including a [Proposal Template](https://github.com/vmware-tanzu/carvel/tree/develop/proposals#proposal-template) is covered at length within the [proposal directory](https://github.com/vmware-tanzu/carvel/tree/develop/proposals).

---
# Proposal Lifecycle
1. Author adds a proposal by creating a PR in draft mode. (Authors can save their work until ready.)
2. When the author elaborates the proposal sufficiently to withstand critique they:
    i. change the status to `in-review` and
    ii. mark the PR as "Ready for Review"
3. The community critiques the proposal by adding PR reviews in order to mature/converge on the proposal.
4. When the approvers reach [rough consensus](https://en.wikipedia.org/wiki/Rough_consensus), they:
    i. change the status to `accepted` or `rejected`,
    ii. record both majority and dissenting opinions, and
    iii. merge the PR.

For more information on proposals please refer to the [proposal directory](https://github.com/vmware-tanzu/carvel/tree/develop/proposals).

---
# Lazy Consensus
To maintain velocity in a project as busy as Carvel, the concept of [Lazy Consensus](http://en.osswiki.info/concepts/lazy_consensus) is practiced. Ideas and / or proposals should be shared by maintainers via GitHub. Out of respect for other contributors, major changes should also be accompanied by a ping on the Kubernetes Slack in [#Carvel](https://kubernetes.slack.com/archives/CH8KCCKA5) or a note on the [Carvel mailing list](carvel-dev@googlegroups.com) as appropriate. Author(s) of proposals, Pull Requests, issues, etc., will give a time period of no less than five (5) working days for comment and remain cognizant of popular observed world holidays.

Other maintainers may chime in and request additional time for review, but should remain cognizant of blocking progress and abstain from delaying progress unless absolutely needed. The expectation is that blocking progress is accompanied by a guarantee to review and respond to the relevant action(s) (proposals, PRs, issues, etc.) in short order.

Lazy Consensus is practiced for all projects in the `Carvel` org, including the main project repository and the additional repositories.

Lazy consensus does not apply to the process of:
* Removal of maintainers from Carvel

---
# Updating Governance
All substantive changes in Governance require a supermajority agreement by all maintainers.
