---
title: "Saying the Quiet Part Loud: Open Source Projects Are Suffering From Attrition"
slug: Carvel-Help-Wanted
date: 2023-08-08
author: Nanci Lancaster
excerpt: "For the last year, Carvel has faced a significant amount of loss from maintainers leaving due to moving onto other companies. After my experience at KubeCon in April, I realized that we are not the only project in need of maintainers and a different approach must be done to gain new contributors."
image: /img/help-wanted.jpeg
tags: ['maintainers', 'contributors', 'kubecon']
---
Before arriving in Amsterdam for [KubeCon + CloudNativeCon Europe](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/) this past April, we discussed as a team that our focus and messaging would be centered around getting more contributors, especially ones interested in eventually becoming a maintainer. For our [in-person project meeting](https://sched.co/1JWTN), we brought this to attendees’ attention and were very transparent in the attrition that Carvel has faced and our desire to have more people from outside of VMware join our efforts.

What I thought was a unique issue to Carvel I quickly learned that maintainers leaving projects when acquiring a new role at a different company is something that is happening across all projects.

We approached this goal with the way things have always been: If a project is interesting enough, people will want to work on it. If this was actually true, then, why did our maintainers not stay on the project, even after leaving VMware?

The common response from other projects I received was, “People just aren’t going to work on a project unless they are being paid to do so, no matter how much they love the project.”

The state of open source projects as it once was is changing. Seemingly, long gone are the days in which folks are eager to work on an open source project free of charge for several hours a day. Sure, there are still those that have this drive, but it isn’t like the old days of everyone working on a project, regardless of how it related to the role they were being paid to do.

Was it the pandemic that’s changed our ways of living and working in this space, lessening the passion behind our work? Are open source projects a victim of our new approach to managing workloads, i.e. my least favorable term, ‘quiet quitting?’ Regardless of the reason, we need to rethink our approach to gaining more contributors and maintainers to save open source software.

### A new approach to gaining new contributors and maintainers
Since my time in Amsterdam, I’ve been thinking a lot about how to change our approach to getting more contributors. What I’ve concluded is that we need to partner with companies who have adopted Carvel and are interested in getting more involved in open source. Partnering directly with a company who is going to pay for their employees to work on an open source project releases the responsibility on an individual to find time to work on the project and places it on the company.

Rather than a project living in a silo, working on releases that are directly tied to the sponsor company’s goals, partnering companies can work together to create common goals for the benefit of the project and community as a whole. Cross-functional collaboration between two or more companies would bring expertise, talent, and ideas to a project that would elevate it in ways that would be difficult to achieve on an individual basis.

### Let's work together
As a [Cloud Native Computing Foundation Sandbox project](https://www.cncf.io/sandbox-projects/), we are a vendor-neutral project and are eager to have others from outside of VMware join us. If you work at a company that uses any of the Carvel tools (imgpkg, kapp, kapp-controller, kbld, secretgen-controller, vendir, or ytt), we would love to talk with you! You don’t have to know or use ALL of the Carvel tools to become a contributor or maintainer; you can have a specific tool to focus on. You can also simply be only interested in providing feedback for our roadmap while not actively working on the items.

If you are a company using any of the Carvel tools and would like to become more involved in open source software development, this is a great opportunity.

We’ve created [this short form](https://forms.gle/nWzNdEnpPYp68Lyy9)(form no longer accessible due to Broadcom acquisition; was lost in the data transfer) to gather details for those that are interested in working with the Carvel team, whether you are an individual or representing a company. If you have any questions, please [email us](https://lists.cncf.io/g/cncf-carvel-users/join) or find us in the [#carvel channel](https://kubernetes.slack.com/archives/CH8KCCKA5) in the Kubernetes Slack workspace.

### A few of the top issues we wish we could work on now
1. Carvel Overall: [Signature and SLSA attestation for all Carvel artefacts #619](https://github.com/carvel-dev/carvel/issues/619)
2. imgpkg: [Ability to extract images from bundles into a registry #60](https://github.com/carvel-dev/imgpkg/issues/60)
3. kapp: [Conflict on weird fields #573](https://github.com/carvel-dev/kapp/issues/573)
4. kapp: [use kapp as a Go module #564](https://github.com/carvel-dev/kapp/issues/564)
5. kapp-controller: [Add ability to fetch resources from the cluster #410](https://github.com/carvel-dev/kapp-controller/issues/410)
6. kbld: [[builder] add kpack integration for building #30](https://github.com/carvel-dev/kbld/issues/30)
7. secretgen-controller: [SecretTemplate supports ytt templating #70](https://github.com/carvel-dev/secretgen-controller/issues/70)
8. vendir: [figure out how to integrate with sigstore/cosign to verify fetched content #92](https://github.com/carvel-dev/vendir/issues/92)
9. vendir: [How to effectively sync multiple directories ? #101](https://github.com/carvel-dev/vendir/issues/101)
10. ytt: [[lang] support emitting comments in resulting YAML #63](https://github.com/carvel-dev/ytt/issues/63)

If there is something not listed above that you feel is most important please tell us!

### Links to resources
* [Video overview of the Carvel tools](https://www.youtube.com/live/gsyGOv_Nwb0?feature=share)
* [GitHub Repositories](https://github.com/orgs/carvel-dev/repositories)
* [Roadmap](https://github.com/carvel-dev/carvel/blob/develop/ROADMAP.md)
* [Processes](https://github.com/carvel-dev/carvel/tree/develop/processes)
* [How to Contribute](https://carvel.dev/shared/docs/latest/contributing/)
* [Governance](https://github.com/carvel-dev/carvel/blob/develop/GOVERNANCE.md)

### Ideal scenario
We would love to onboard as many people from the community as possible to become active contributors and maintainers. An ideal scenario would be weekly collaboration in Working Group meetings, bi-weekly community meetings ([example of our current agenda](https://hackmd.io/G8dN30WvQl-8Sirnp8AgRA)), and daily communication in Slack that leads to developing new features and pushing out releases more consistently. If there is enough interest and engagement, we would like to eventually develop a Technical Oversight Committee (TOC) consisting of a few folks representing different companies to help drive the success of the Carvel tools. When it comes to events, like KubeCon, while optional, we would want folks who could speak on Carvel as well as be willing to engage with the community onsite in various ways, i.e. at a booth.

### Other ways to help Carvel succeed
If you are unable to participate but still want to help Carvel succeed, here are other ways to show support:

* Share details about how you and/or your company uses the Carvel tools as well as your company logo in this [pinned issue](https://github.com/carvel-dev/carvel/issues/213).
* Write a blog post, talk at an event, record a webinar covering any of the Carvel tools, and let us know you’re doing so by [filling out this doc](https://github.com/carvel-dev/carvel/blob/develop/processes/weekly-content-sharing.md).
* Star all of our repos! The reality is that this metric is a prime indicator of stability for others who are coming across new projects. The more stars we have, the better. So if you’re a fan of the Carvel tools and haven’t starred the repos yet, go ahead and do so now :)
* Join our [Slack channel](https://kubernetes.slack.com/archives/CH8KCCKA5) and follow us on [Twitter](https://twitter.com/carvel_dev) (X? Twixer?).
* Last, but certainly not least, attend our community meetings! Details on when and how to attend can be found [here](https://carvel.dev/community/).

Thank you and we look forward to working together!