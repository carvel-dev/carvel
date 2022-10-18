# Carvel Adopters

If you're using Carvel and want to add your organization to this
list, [follow these directions](#adding-your-organization-to-the-list-of-adopters)!

## Organizations using Carvel

(in alphabetical order)

<a href="https://beam.lu/" border="0" target="_blank"><img alt="BEAM" src="logos/BEAM-SARL.png" height="50"></a>

<a href="https://www.fabrique.social.gouv.fr/" border="0" target="_blank"><img alt="fabrique" src="logos/fabrique.png" height="50"></a>

<a href="https://www.opt.nc/" border="0" target="_blank"><img alt="OPT-NC" src="logos/OPT-NC.png" height="50"></a>

<a href="https://rev.ng/" border="0" target="_blank"><img alt="Revng" src="logos/revng.svg" height="50"></a>

<a href="https://www.terasky.com/" border="0" target="_blank"><img alt="TERASKY" src="logos/terasky.png" height="50"></a>

<a href="https://www.twilio.com/" border="0" target="_blank"><img alt="Twilio, Inc." src="logos/twilio.svg" height="50"></a>

<a href="https://www.vmware.com" border="0" target="_blank"><img alt="VMware" src="logos/vmware.svg" height="50"></a>

## Solutions built with Carvel

(in alphabetical order)

Below is a list of solutions where Carvel is being used as a component.

**[BEAM](https://beam.lu/)**

BEAM is a consulting company based in Luxembourg and specialized in DevOps, Cloud and automation. BEAM supports their customers in their workload and delivery optimizations and helps them transition from traditional IT models to DevOps.

**[Fabrique Numérique des Ministères Sociaux](https://www.fabrique.social.gouv.fr/)**

Fabrique Numérique des Ministères Sociaux uses kapp CLI as deployer for their CI/CD tooling that they are developing and implementing actively: [Kontinuous](https://socialgouv.github.io/kontinuous/). The project started as a wrapper around Helm and Kapp, then evolved to offer more abstraction and a rich plugins system.

**[Office des Postes et Télécommunications de Nouvelle-Calédonie](https://www.opt.nc/)**

Office des Postes et Télécommunications de Nouvelle-Calédonie uses vendir to sync repos to build docker images, ytt to instanciate templates and are currently working on packaging services as applications with kapp. They are prototyping on an onPrem Tanzu instance. They are using Github.com and GH Actions to automate the whole thing and are evaluating Harbor vs. Artifactory vs. Github Container Registry to store/release their images.

**[Revng](https://rev.ng/)**

Revng is a small company with expertise in compilers, emulation and binary analysis. Revng uses ytt as a flexible templating tool to generate the configuration for [orchestra](https://github.com/revng/orchestra), their meta build system/package manager.

**[TeraSky](https://terasky.com/)**

TeraSky is an Advanced Technology Solutions Provider. We utilize the carvel suite in order to streamline k8s configuration and deployment by many of our customers. We also utilize ytt to manage additional yaml based systems such as vRealize Automation and CloudFoundry.

**[Twilio](https://www.twilio.com)**

Today’s leading companies trust Twilio’s Customer Engagement Platform (CEP) to build direct, personalized relationships with their customers everywhere in the world. Twilio enables companies to use communications and data to add intelligence to every step of the customer journey, from sales to marketing to growth, customer service and many more engagement use cases in a flexible, programmatic way.

Twilio uses Carvel to package and deliver reliable, predictable, and consistent infrastructure across its fleet of Kubernetes clusters.

**[VMware](https://www.vmware.com)**

VMware uses Carvel as their package management tooling for [their Kubernetes offerings](https://tanzu.vmware.com/products), such as [Tanzu Mission Control](https://tanzu.vmware.com/mission-control) (TMC) and [Tanzu Kubernetes Grid](https://tanzu.vmware.com/kubernetes-grid) (TKG). 

## Adding your organization to the list of adopters

If you are using Carvel and would like to be included in the list of Carvel Adopters, add an SVG version of your logo to the `logos` directory in this repo and submit a pull request with your change. Name the image file something that reflects your company (e.g., if your company is called Acme, name the image acme.svg). See [this PR](https://github.com/vmware-tanzu/carvel/pull/280) for an example.
