---
title: "Package Repository to Tar"
authors: [ "Ashish Kumar <ashishndiitr@gmail.com>" ]
status: "draft"
approvers: [ ]
---

# <Proposal Title>

## Problem Statement

Presntly imgpkg does not support the creation of tar file directly.
In order to obtain a tar file, one needs to first push the bundle image to the registry and then leverage the [command](https://carvel.dev/imgpkg/docs/v0.37.x/air-gapped-workflow/#option-2-with-intermediate-tarball) for copying as tar in the air gapped workflow.


`imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-tar /tmp/my-image.tar`

 
then copy the bundle image from the registry to the tar ( by first pulling the image from the registry as tar and then pushing it).
Kctrl depends on imgpkg to push the bundle image to the registry

Presently, imgpkg allows us to Push the bundle image only to the tar
In a scenario where the artifact that will be shared is a tar, there might not be a need to use the registry as an intermediary step.
This would allow the users to combine the commands imgpkg push + imgpkg copy --to-tar in a single command and without storing extra images in a registry

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