---
title: "Adding support to handle OLM registryV1 bundles"
authors: [ "Varsha Prasad Narsing <varshaprasad96@gmail.com>" ]
status: "in review"
approvers: [ <TBD_Carvel Maintainers> ]
---

# Adding support to handle OLM registryV1 bundles

## Problem Statement

[Operator Lifecycle Manager][olm_doc] (OLM) is a tool that helps manage the lifecycle of operators. Some key aspects of the tool are: catalog management, installation, upgrade, dependency resolution, content discovery. It currently uses a custom packaging format called `registry+v1`. This is an OCI image with a particular directory structure, more details on which can be found [here][olm_manifest_format]. A subset of operator packages available in `registry+v1` format can be found at https://operatorhub.io/.

Kapp-controller currently does not support installing packages following OLM's `registry+v1` format. Adding support for it, will enable kapp-controller to install and manage contents of the operators that are available in the OLM supported format. 

## Proposal

### Goals and Non-goals

### Goals

1. Enable operators packaged for OLM to be installed (and reconciled) by kapp-controller through `App` CR. 

### Non-Goals

This proposal does not discuss:
1. The intention behind `registry+v1` packaging structure. 
2. The contents of operator bundle which the kapp-controller will install when this feature is available. 

### Specification

We intend to add support for the `registry+v1` format during the templating step by modifying the `App` API's spec. On introducing this, the overall process would look like:

1. Consume the contents of App's `spec.fetch.image` which could point to a `registry+v1` image.

2. Process the `registry+v1` bundle with the help of specific fields introduced in App's `spec.template` section.

The API definition would look like:

```go
// +k8s:openapi-gen=true
type AppTemplate struct {
    OLMRegistry *AppTemplateOLMRegistry `json:"olmRegistry,omitempty"`
}

type AppTemplateOLMRegistry struct {
	// BundleRoot is the path to bundle root within the source directory.
	// Default is the source directory root (optional).
	BundleRoot string `json:"bundleRoot,omitempty" protobuf:"bytes,1,opt,name=bundleRoot"`
	
    // TargetNamespaces is the list of namespaces that the bundle will be configured to target.
	// If the bundle supports AllNamespaces mode, default is all namespaces. Otherwise, if the
	// bundle supports OwnNamespaces mode, it will default to install namespace. If the bundle supports neither
	// AllNamespaces nor OwnNamespace, TargetNamespaces must be specified.
	TargetNamespaces []string `json:"targetNamespaces,omitempty" protobuf:"bytes,2,opt,name=targetNamespaces"`
}
```

With the help of the following inputs, kapp-controller can then convert the registry+v1 contents into a set of plain kubernetes manifests. 

### Templating overview:

At a high level, a `registry+v1` package contains:
1. Cluster Service Version (CSV) - A yaml that represents a particular version of a running kubernetes operator on a cluster. It includes metaqdata such as name, description, version, repository link, labels, icon etc.
2. `annotations.yaml` - Contains operator metadata information as labels that are used to annotate the `registry+v1` image. More details can be found [here][bundle_contents]. 
3. Dockerfile - Used to build an image for the bundle. 
4. CRDs relevant to the Operator.

With the help of the metadata provided in `CSV` and `annotations.yaml`, a set of plain kubernetes manifests can be generated and provided to the `kapp` deployer to apply them onto the cluster. 

## Open Questions

1. Are there any unintended consequences of introducing these API changes to other components of kapp-controller?


[olm_manifest_format]: https://github.com/operator-framework/operator-registry#manifest-format
[olm_doc]: https://olm.operatorframework.io
[bundle_contents]: https://olm.operatorframework.io/docs/tasks/creating-operator-bundle/#contents-of-annotationsyaml-and-the-dockerfile

