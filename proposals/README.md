# Carvel Proposals
This directory serves as the home for Carvel proposals. A proposal is a design
document that describes a new feature for a Carvel project. The new feature
can span multiple projects or introduce a new project. A proposal must be
sponsored by at least one Carvel maintainer. Proposals can be worked by anyone
in the community.

# When to Create a Proposal
The Carvel proposal process is intended for "big" or complex features. _If there
is significant risk with a potential feature or track of work (such as
complexity, cost to implement, product viability, etc.)_, then we recommend
creating a proposal for feedback and approval. _If a potential feature is well
understood and doesn't impose risk_, then we reccomend a standard GH issue to
clarify the details.

# Submit a Proposal
To create a proposal, submit a PR to this directory under the appropriate
project with a terse name (for example, `ytt/001-schemas/`). If the proposal
concerns multiple projects or is intended for the entire Carvel suite then
please create the proposal at the root of the `proposals` directory (for
example, `./010-carvel-cli/`).

In that directory, create a `README.md` containing the core proposal. Include
other files (e.g. sets of example artifacts, if necessary) to help support
understanding of the feature.  When creating the proposal, please add a `Status:
Draft` line at the top of the proposal to indicate its state.

## Proposal Template
The below template is an example. Other than the high-level details (such as
title, proposal status, author, and approvers), please use whichever sections
make the most sense for your proposal.

```md
---
title: "Writing a Proposal"
authors: [ "Aaron Hurley <ahurley@vmware.com>" ]
status: "draft"
approvers: [ "Cari Dean <cdean@vmware.com", "Dmitriy Kalinin <dkalinin@vmware.com>" ]
---

# <Proposal Title>

## Problem Statement
_This is a short summary of the problem that exists, why it needs to be
solved: what specific needs are being met. Compelling problem statements
include concrete examples (even if only by reference). How exactly the proposal
would meet those needs should be located in the "Proposal" section, not this one.
The goal of this section is to help readers quickly empathize with the target users'
current experience to motivate the proposed change.

## Terminology / Concepts
_Define any terms or concepts that are used throughout this proposal._

## Proposal
_This is the primary content of the proposal explaining how the problem(s) will
be addressed._

### Goals and Non-goals
_A short list of what the goals of this proposal are and are not._

### Specification / Use Cases
_Detailed explanation of the proposal's design._

### Other Approaches Considered
_Mention of other reasonable ways that the problem(s)
could be addressed with rationale for why they were less
desirable than the proposed approach._

## Open Questions
_A list of questions that need to be answered._

## Answered Questions
_A list of questions that have been answered._
```

# Proposal Review
Once a proposal PR is submitted, project maintainers will review the proposal.
The goal of the review is to gain an understanding of the problem being solved
and the design of the proposed solution.

# Proposal States
| Status | Definition |
| --- | --- |
| Draft | The proposal is actively being written by the proposer. |
| In Review | The proposal is being reviewed by project maintainers. |
| Accepted | The proposal has been accepted by the project maintainers. |
| Rejected | The proposal has been rejected by the project maintainers. |

# Lifecycle of a Proposal
1. Author adds a proposal by creating a PR in draft mode. (Authors can save their work until ready.)
1. When the author elaborates the proposal sufficiently to withstand critique they:
   1. change the status to `in-review` and
   1. mark the PR as "Ready for Review"
1. The community critiques the proposal by adding PR reviews in order to mature/converge on the proposal.
1. When the approvers reach [rough consensus](https://en.wikipedia.org/wiki/Rough_consensus), they:
   1. change the status to `accepted` or `rejected`,
   1. record both majority and dissenting opinions, and
   1. merge the PR.
