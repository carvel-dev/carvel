This document outlines the various responsibilities of contributor roles in Carvel. This is a living document and may not cover all circumstances. The intention of this document is to set contribution expectations. The maintainers will strive to act in the best interest of the project. We will plan to revisit this contributor model after six months of use.

# Community Membership
The Carvel project is currently subdivided into different subprojects, represented as individual repositories.

Responsibilities for roles are scoped to the repositories.

| Role | Responsibilities | Requirements | Defined by |
| ---- | ---------------- | ------------ | ---------- |
| member | active contributor in the community | sponsored by an approver or lead. multiple contributions to the project. | Carvel GitHub org member* |
| reviewer | review contributions from other members | sponsored by a lead. history of review and authorship in a subproject | MAINTAINERS file reviewer entry |
| approver | approve accepting contributions | sponsored by a lead. highly experienced and active reviewer + contributor to a subproject | MAINTAINERS file approver entry |
| lead | set direction and priorities for a subproject | demonstrated responsibility and excellent technical judgment for the subproject | MAINTAINERS file lead entry |

*Once Carvel is moved to its own GitHub organization. Until then, members will be added to the `carvel-writers` GitHub group.

## New contributors
New contributors should be welcomed to the community by existing members, helped with PR workflow, and directed to relevant documentation and communication channels.

## Established community members
Established community members are expected to demonstrate their adherence to the principles in this document, familiarity with project organization, roles, policies, procedures, conventions, etc., and technical and/or writing ability. Role-specific expectations, responsibilities, and requirements are enumerated below.

## Member
Members are continuously active contributors in the community. They can have issues and PRs assigned to them. Members are expected to remain active contributors to the community. Members are given the Triage GitHub role to Carvel repositories, in order to facilitate issue management and moderate discussions.

**Defined by**: Member of the Carvel GitHub organization

### Requirements
- Enabled [two-factor authentication](https://help.github.com/articles/about-two-factor-authentication) on their GitHub account.
- Have made multiple contributions to the project or community. Contributions may include, but are not limited to:
    - Authoring or reviewing PRs on GitHub
    - Filing or commenting on issues on GitHub
    - Contributing to community discussions (e.g. meetings, Slack, email discussion forums, Stack Overflow, blog posts, conference talks, etc.)
- Actively contributing to one or more subprojects.
- Sponsored by an approver or a lead. Note the following requirements for sponsors:
    - Sponsors must have close interactions with the prospective member - e.g. code/design/proposal review, coordinating on issues, etc.
    - Sponsors must be approvers in at least one MAINTAINERS file.
    - With no objections from other approvers or leads.
- Open an issue against the carvel repo.
    - Ensure your sponsors are @mentioned on the issue.
    - Complete every item on the checklist (preview the current version of the template)
    - Make sure that the list of contributions included is representative of your work on the project.
    - Have your sponsoring reviewers reply confirmation of sponsorship: `+1`
    - Once your sponsors have responded, your request will be reviewed by the project leads. Any missing information will be requested.

### Responsibilities and privileges
- Have the ability to triage GitHub issues through labeling
- Responsive to issues and PRs assigned to them
- Responsive to mentions of subprojects they are members of
- Active owner of code they have contributed (unless ownership is explicitly transferred)
- Code is well tested
- Tests consistently pass
- Addresses bugs or issues discovered after code is accepted
- Members are welcome and encouraged to review PRs and proposals.
- They can be assigned to issues and PRs, and people can ask members for reviews with a `/cc @username`.

## Reviewer
Reviewers are able to review code for quality and correctness on some part of a subproject. They are knowledgeable about both the codebase and software engineering principles.

**Defined by**: Reviewers entry in the MAINTAINERS file.

Reviewer status is scoped to a subproject’s codebase.

**Note**: Acceptance of code contributions requires at least one approver in addition to the assigned reviewers.

### Requirements
- The following apply to the part of the codebase for which one would be a reviewer in an MAINTAINERS file.
- Active community participation and support (such as GitHub, meetings, Slack, Stack Overflow) for long enough to have demonstrated knowledge and competency (such as 3 months).
- Reviewer for or author of at least 5 substantial PRs to the codebase, with the definition of substantial subject to the lead's discretion (e.g. refactors, enhancements rather than grammar correction or trivial pull requests)
- Knowledgeable about the codebase
- Sponsored by a subproject lead
    - With no objections from other maintainers
    - Done through PR to update the MAINTAINERS file
        - Ensure your sponsors are @mentioned in the PR.
        - Complete every item on the checklist (preview the current version of the template)
        - Make sure that the list of contributions included is representative of your work on the project.
        - Have your sponsoring reviewers reply confirmation of sponsorship: `+1`
        - Once your sponsors have responded, your request will be reviewed by the project leads. Any missing information will be requested.
- May either self-nominate or be nominated by an approver in the subproject

### Responsibilities and privileges
- The following apply to the part of codebase for which one would be a reviewer in an MAINTAINERS file.
- Respond to new PRs and Issues by asking clarifying questions
- Organize the backlog by applying labels, milestones, assignees, and projects
- Responsible for project quality control via code reviews
   - Focus on code quality and correctness, including testing and factoring
   - May also review for more holistic issues, but not a requirement
- Expected to be responsive to review requests
- Assigned PRs to review related to subproject of expertise
- Assigned test bugs related to subproject of expertise
- Inactivity (such as for three months) may result in a review for suspension of all privileges until active again

## Approver
Code approvers are able to both review and approve code contributions as well as help subproject leads triage issues and with project management.

While code review is focused on code quality and correctness, approval is focused on holistic acceptance of a contribution including: backwards / forwards compatibility, adhering to API and flag conventions, subtle performance and correctness issues, interactions with other parts of the system, etc.

**Defined by**: Approvers entry in the MAINTAINERS file.

Approver status is scoped to a subproject’s codebase.

### Requirements
The following apply to the part of the codebase for which one would be an approver in a MAINTAINERS file.
- Reviewer for or author of several substantial PRs to the codebase, with the definition of substantial subject to the lead's discretion (e.g. refactors, enhancements rather than grammar correction or trivial pull requests).
- Demonstrated the ability to plan and execute a track of work.
- Sponsored by a subproject lead
    - With no objections from other maintainers
    - Done through PR to update the MAINTAINERS file.
        - Ensure your sponsors are @mentioned on the issue.
        - Complete every item on the checklist (preview the current version of the template)
        - Make sure that the list of contributions included is representative of your work on the project.
        - Have your sponsoring reviewers reply confirmation of sponsorship: `+1`
        - Once your sponsors have responded, your request will be reviewed by the project leads. Any missing information will be requested.

### Responsibilities and privileges
The following apply to the part of the codebase for which one would be an approver in a MAINTAINERS file.
- Demonstrate sound technical judgment
- Responsible for project quality control via code reviews
    - Focus on holistic acceptance of contribution such as dependencies with other features, backwards / forwards compatibility, API and flag definitions, etc
- Expected to be responsive to review requests
- Mentor contributors and reviewers
- May approve and merge code contributions for acceptance
- Inactivity (such as for three months) may result in a review for suspension of all privileges until active again

## Lead
Subproject leads are the technical authority for a subproject in the Carvel project. They MUST have demonstrated both good judgment and responsibility towards the health of that subproject. Subproject leads MUST set technical direction and make or approve design decisions for their subproject - either directly or through delegation of these responsibilities.

**Defined by**: Leads entry in the MAINTAINERS file

### Requirements
Unlike the roles outlined above, the Leads of a subproject are typically limited to a relatively small group of decision makers and updated as fits the needs of the subproject.

The following apply to the subproject for which one would be a lead.
- Deep understanding of the technical goals and direction of the subproject
- Deep understanding of the domains of the subproject
- Deep understanding of the design of the subproject
- Sustained contributions to design and direction by doing all of:
    - Authoring and reviewing proposals
    - Initiating, contributing and resolving discussions (emails, GitHub issues, meetings)
    - Identifying subtle or complex issues in designs and implementation PRs
- Directly contributed to the subproject through implementation and / or review
- Sponsored by a subproject lead
    - With no objections from other maintainers
    - Done through PR to update the MAINTAINERS file.
        - Ensure your sponsors are @mentioned on the issue.
        - Complete every item on the checklist (preview the current version of the template)
        - Make sure that the list of contributions included is representative of your work on the project.
        - Have your sponsoring reviewers reply confirmation of sponsorship: `+1`
        - Once your sponsors have responded, your request will be reviewed by the project leads. Any missing information will be requested.

### Responsibilities and privileges
The following apply to the subproject for which one would be a lead.
- Make and approve technical design decisions for the subproject.
- Set technical direction and priorities for the subproject.
- Define milestones and releases.
    - Decides on when PRs are merged to control the release scope.
- Mentor and guide approvers, reviewers, and contributors to the subproject.
    - Ensure continued health of subproject
    - Adequate test coverage to confidently release
- Tests are passing reliably (i.e. not flaky) and are fixed when they fail
- Ensure a transparent and healthy process for discussion and decision making is in place.
- Work with other subproject leads to maintain the project's overall health and success holistically
- Promote and foster the community (e.g. hosting meetings, workshops, partner engagements, collaborations).
- Inactivity (such as for three months) may result in a review for suspension of all privileges until active again
- In extenuating circumstances, leads can fulfill responsibilities beyond what’s included here. For example, a lead of subproject A can perform PR reviews and merges for subproject B if other subproject B reviewers/approvers/leads are not available.

## Inactive members
Members are continuously active contributors in the community.

A core principle in maintaining a healthy community is encouraging active participation. It is inevitable that people's focuses will change over time and they are not expected to be actively contributing forever.

However, being a member of the Carvel GitHub organization comes with an elevated set of permissions. These capabilities should not be used by those that are not familiar with the current state of the Carvel project.

Therefore members with an extended period away from the project with no activity will be removed from the Carvel Github Organization and will be required to go through the org membership process again after re-familiarizing themselves with the current state.

## How inactivity is measured
Inactive members are defined as members of one of the Carvel Organization with no contributions across any organization within 12 months.

After an extended period away from the project with no activity those members would need to re-familiarize themselves with the current state before being able to contribute effectively.

## Change in membership roles
As described above, a change in membership role may be approved by the appropriate subproject lead if there are no objections from the other leads. By convention, role changes are discussed in a meeting with other approvers before being formally approved.
