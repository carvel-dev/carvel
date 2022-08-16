# Issue Triage

## What is triaging?
Triaging is a process where maintainers review, respond to, and organize GitHub issues and pull requests. Triaging involves categorizing issues and pull requests based on factors such as kind (bug, enhancement, etc.) and priority/urgency. At the end of this process, new issues will be categorized appropriately and team leaders will be able to make backlog prioritization decisions, as needed.

## Why is triaging important?
Triaging is important because it:
- promotes a responsive and inclusive community
- leads to greater transparency, better discussions, and more collaborative, informed decision-making
- speeds up issue management
- prevents work from lingering endlessly
- helps build prioritization, negotiation, and decision-making skills, which are critical to most tech roles.

## Who is responsible?
The responsibility is open to anyone. If no one volunteers to triage issues, it falls on the maintainers of each tool/repo. Maintainers are listed in [`MAINTAINERS.md`](https://github.com/vmware-tanzu/carvel/blob/develop/MAINTAINERS.md).

## When do we triage?
Triage can happen asynchronously and continuously, or at regularly scheduled times. It's left up to the maintainers of each repo to figure out what's best for them.

Some good practices:
- enable GitHub notifications so that you're notified of activity
  - filter these notifications appropriately so that you're not overwhelmed
- schedule regular blocks of time on your calendar to triage (for example, block 30 minutes every morning or 1-2 hours on Tuesdays and Thursdays)
- consider assigning a triager for a day or week at a time

## How do we triage?
1. [Respond to Newly Created Issues and PRs](#1-respond-to-newly-created-prs-and-issues)
2. [Triage Issues by Type](#2-triage-issues-by-type)
3. [Define Priority](#3-define-priority)

### 1. Respond to Newly Created PRs and Issues
Labels are the primary tools for triaging. New issues are automatically assigned a `carvel triage` label. Issues with the `carvel triage` label indicate that the issue is awaiting triage.

1. Respond to new _PRs_ for the repos you're focused on. If you're using the [GitHub Project board](https://github.com/orgs/vmware-tanzu/projects/16), these will show up in the Needs Review column.
1. If a PR has not been acknowledged,
    1. thank the submitter for their contribution
    1. assign a `kind` label (if you're comfortable doing so)
    1. assign a `priority` label ([see these steps](#3-define-priority))
    1. assign a reviewer (found in MAINTAINERS.md)
    1. @-mention the reviewer in a comment
    1. remove the `carvel triage` label
    1. set the GitHub Project column, accordingly
1. If a PR has been acknowledged,
    1. ensure that the submitter is not waiting on a reviewer, @-mention the reviewer if needed
    1. ensure that `kind` and `priority` labels are assigned
    1. remove the `carvel triage` label
    1. set the GitHub Project column, accordingly
1. Filter the _issues_ with a `carvel triage` label. If you're using the GitHub Project board, these will show up in the New Issues column.
1. If an issue has not yet been assigned `kind` and `priority` labels,
    1. thank the submitter for their contribution
    1. attempt to understand the issue being raised
        1. if you understand the issue, assign `kind` and `priority` labels and remove `carvel triage`
        1. if you do not understand, ask the submitter questions to clarify
        1. if you're not sure which questions to ask, ask a reviewer for assistance and leave the `carvel triage` label in place

### 2. Triage Issues by Type
For all issues, `kind` labels are generally supplied by the submitter. Ensure that the correct label is applied and update it when necessary.

#### Enhancement
1. Read the issue and try to understand the ask.
1. If information is missing or something is not clear, reply to the issue asking for further clarification. Add the `triage/needs-more-information` label. You should keep tabs on this issue until triage is complete.
1. If the issue looks like a good improvement for the tool,
    1. add a comment explaining your reasoning
    1. define its priority
    1. change the label to `carvel accepted` from `carvel triage`
    1. if appropriate, add the `good first issue` label
    1. set the GitHub Project column, accordingly
1. If the issue does not look like a good fit for the tool, add a comment explaining your reasoning and close the issue.

#### Bug
1. Try to replicate the issue.
1. If you're able to replicate the issue,
    1. Define its priority
    1. change the label to `carvel accepted` from `carvel triage`
    1. set the GitHub Project column, accordingly
1. If you're unable to replicate the issue,
    1. add the `triage/not-reproducible` label
    1. ask the submitter for more information
    1. if both parties agree that the issue can't be reproduced then close the issue

### 3. Define Priority
We use labels for prioritization. If an issue lacks a priority label then it has not been reviewed and prioritized completely, yet.

We aim for consistency across the entire project. If you notice an issue that you believe to be incorrectly prioritized, please leave a comment offering your counter-proposal and we will evaluate it.

| Priority label | What it means | Examples |
|---|---|---|
| `priority/critical-urgent` | Team leaders are responsible for making sure that these issues (in their area) are being actively worked on (i.e., drop what you're doing). These should be fixed before the next release. | user-visible bugs in core features <br> broken builds or tests <br> critical security vulnerabilities |
| `priority/important-soon` | Must be staffed and worked on either currently or very soon. Ideally, this will be done in time for the next release. Important, but wouldn't block a release. | Work to consider for the current or next release  |
| `priority/important-longterm` | Important over the long term, but may not be currently staffed and/or may require multiple releases to complete. Wouldn't block a release. | Work to consider for the roadmap (1+ quarters out) |
| `priority/unprioritized-backlog` | General agreement that this is a nice-to-have, but no one is allocated to work on it anytime soon. |  |
| `priority/awaiting-more-evidence` | Possibly useful but not yet enough support to actually incorporate it. | Placeholders for potentially good ideas so that they don't get completely forgotten. |

A couple of notes:
- If you're categorizing an issue as a `priority/critical-urgent`, please inform a team leader even if you plan to start working on it immediately.
- If you're unsure which priority to assign then provide your thinking in a comment so that team leaders can share their feedback and thoughts.

## Sources
This process is inspired by [Kubernetes issue triage process](https://github.com/kubernetes/community/blob/master/contributors/guide/issue-triage.md#how-to-triage-a-step-by-step-flow).
