---
title: "Getting started with contributing to Open-Source Projects like Carvel"
slug: contributing-to-open-source-projects
date: 2022-06-09
author: Varsha Munishwar
excerpt: "How to get started with contributing to open-source projects like Carvel"
image: /img/logo.svg
tags: ['ytt', 'open-source', 'devops']
---


Contributing to open-source projects like **Carvel** for the first time can be overwhelming and difficult to know where to begin. Few years back, I was working as a software engineer building enterprise applications using Java, Spring Framework, and REST APIs. We would deploy the applications using Jenkins and Maven configurations along with other CI/CD tools.

I took a break for family reasons. After a couple of years, I returned to work through a returnship opportunity at VMware (Carvel team). My new work was in a completely different domain, and I needed to start from the basics. I was overwhelmed and a bit lost in the myriad of information. With the new technologies, programming and configuration languages, and the new open-source community experience, I was not sure where to start and had so many questions. I can share my experience and a few ideas with you to help you get started with contributing to open source projects.

### Stepping out of comfort zone and taking the first step is crucial to success!
Diving into open source was entirely out of my comfort zone. I took a first step to understand where I stood and started gathering answers to all the questions I had:


- What are [open-source projects](https://blogs.vmware.com/opensource/2020/02/06/open-source-software/)?
- What are the [advantages of contributing to open-source projects](https://blogs.vmware.com/opensource/2020/08/25/boost-your-career-t)?
- What is an [open-source community](https://blogs.vmware.com/opensource/)?
- What are [Containers, Docker](https://vmware.github.io/vic-product/assets/files/html/1.4/vic_overview/intro_to_containers.html) and [Kubernetes](https://www.vmware.com/topics/glossary/content/kubernetes.html)?
- What is the [Carvel](https://carvel.dev/) all about?
- How to work with [Git](https://learngitbranching.js.org/) and [GitHub](https://docs.github.com/en/get-started/quickstart/git-and-github-learning-resources)?
- What is the difference between [GitHub and GitLab](https://www.zdnet.com/article/github-vs-gitlab-the-key-differences/)?

It was all new and yes, too much to digest all at once. Fortunately, I got a very knowledgeable mentor who enjoyed teaching. Alongside, I got help from my manager to put together a plan to ramp up. He also provided helpful resources such as [kube academy](https://kube.academy/courses) courses and tutorials.

But, if you do not have a mentor, fear not! The **Open-Source Community** is very welcoming and happy to help new contributors learn how to contribute.


#### What I learned about “**learning**” in this journey

Thinking back, here are some things I learned:
- **Staying organized** is a critical part of the learning process.
- **Keeping accessible notes** on various topics (e.g. Go, Git, Kubernetes, Starlark, Yaml, Carvel, ytt) in different formats such as screenshots, recordings, writeups, etc., help extract the important contents.
- Persistence in seeking to **understand "why?"** helps with thorough understanding
- **Keep going forward** amidst the ambiguity and deep dive enough in one area to solve the problem at hand.
- It’s not always enough to only read or listen, **doing it myself** is the most important aspect of learning.
- **Nothing is impossible** if I put my mind at it.
- **Hard work, patience and perseverance** can help climb any steep learning curve.

##### It’s **OK** to start small!

When I started exploring Carvel and its features, I found a couple of places in documentation that needed updates/typo corrections. I mentioned this to my team and got a green signal to make the change. I set up my local environment, understood the basics of Git to raise PRs, got my changes reviewed, and committed them to the repo. This was my first contribution. The following contributions included bug fixes and feature implementations.

#### **Why** 

It is not easy to get started contributing to Open-Source Software. But there are a number of benefits:
- Open-source contributions help you **get feedback** to improve your technical skills
- **Learn the programming patterns** used by experienced developers
- **Get hands on experience** with the code
- **Improve the product usability** for your needs as well as for other users
- **Participate** in the community
- With these contributions, you **learn a lot** about yourself/code/product.

#### **Where** 

Here are some suggestions where you can contribute:
- **Improve documentation** by adding information/summary/missing steps
- **Add examples** to [repo](https://github.com/carvel-dev/ytt/tree/develop/examples)
- **Raise issues**/bugs
- **Check for issues** labeled with [Good first issue](https://github.com/search?q=repo%3Acarvel-dev%2Fytt+repo%3Acarvel-dev%2Fkapp+repo%3Acarvel-dev%2Fimgpkg+repo%3Acarvel-dev%2Fkapp-controller+repo%3Acarvel-dev%2Fkbld+repo%3Acarvel-dev%2Fvendir+repo%3Acarvel-dev%2Fkapp-controller+label%3A%22good+first+issue%22&type=issues)
- **Add FAQs** or “How to” section for a common problem/scenario


#### **How** 


**New to Carvel**? Don’t worry, we have got a lot of resources to help you out:
- Visit the [Carvel product homepage](https://carvel.dev/) to learn about the product
- Take the [ Product Tour](https://tanzu.vmware.com/developer/workshops/lab-getting-started-with-carvel/)
(note: VMware's Tanzu products use Carvel, but you do not have to learn anything about Tanzu to use Carvel, yourself)
- Visit the [Contributing Doc](https://carvel.dev/shared/docs/latest/contributing/) for reference
- Fork and clone a repo - e.g. [carvel-ytt](https://github.com/carvel-dev/ytt)
- Make the appropriate changes and raise a Pull Request (PR)  
- Reach out to us via [Carvel's Slack Channel](https://kubernetes.slack.com/archives/CH8KCCKA5) in the Kubernetes Slack Workspace for any support you need.\
  _(visit http://slack.k8s.io/ to join the Kubernetes Slack workspace if you are not already there.)_

Looking forward to seeing your first contribution!



_This is the first blog in a series on how you can contribute to open-source projects like Carvel. So, stay tuned ..._


{{< blog_footer >}}