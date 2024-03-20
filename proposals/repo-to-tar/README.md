---
title: "Building tarred bundles without being dependent on a OCI registry"
authors: [ "Ashish Kumar <ashishndiitr@gmail.com>" ]
status: "draft"
approvers: [ @praveenrewar @100mik @joaopapereira ]
---

# <Building tarred bundles without being dependent on a OCI registry>

## Problem Statement

Presently imgpkg does not support the creation of bundles directly to local disk for sharing purposes, so as to remove the need of a registry in between. This proposal aims to add this functionality to imgpkg.

Consider this workflow, where a user wants to create a tar file of a bundle image and then push it to a registry. <br>
In order to obtain a tar file, one needs to first push the bundle image to the registry and then leverage the [command](https://carvel.dev/imgpkg/docs/v0.37.x/air-gapped-workflow/#option-2-with-intermediate-tarball) for copying as tar in the air gapped workflow.

For example, In order to obtain a tar of bundle image of examples/basic-step-2, we need run the following commands in succession :<br>

`imgpkg push -b index.docker.io/user1/simple-app-bundle:v1.0.0 -f examples/basic-step-2` <br>
`imgpkg copy -b index.docker.io/user1/simple-app-bundle:v1.0.0 --to-tar /tmp/my-image.tar`

This has 3 fold issues : <br>
1. Dependent on using a registry to create a tar file from a bundle image.
2. The tar file is created from the bundle image, which is not required if the user just wants to create a tar file having a layer as tar with configurations/metadata.
3. The bundle or image when copied as a tar file is not OCI compliant. This proposal aims to add the possibility to create a tar that is compliant with oci image layout spec .

## Terminology / Concepts
1. Definitions of terms used in the proposal with respect to imgpkg can be found [here.](https://carvel.dev/imgpkg/docs/v0.37.x/)<br>
2. Resources regarding docker save and docker load can be found [here.](https://docs.docker.com/engine/reference/commandline/save/)<br>
3. A good article to understand OCI Artifacts can be found [here.](https://dlorenc.medium.com/oci-artifacts-explained-8f4a77945c13)
4. Read about oci-spec in detail [here.](https://github.com/opencontainers/image-spec/blob/main/image-layout.md)

## Proposal

The proposal aims to remove the 3 fold issues by giving the option to create and share a tar, which is OCI compliant and can be pushed to a registry at a later point of time. <br>

#### imgpkg

Oci Tar Creation : <br>

`--to-oci-tar` flag will be added to imgpkg push. This command will create a tar file from the bundle image. The command will be used as follows : <br>
`imgpkg push -b registry.example.com/xyz -f some-folder --to-oci-tar local-oci-format.tar`

Oci Tar Copying to the Registry : <br>

Now in order to push the tar file to the registry, we can use the already existing copy command with a new flag as follows : <br>
`imgpkg copy --oci-tar local-oci-format.tar --to-repo registry.example.com/abc`

### Goals and Non-goals and Future-goals

#### Goals
1. Making OCI Complaint tar and image : <br>
Create and save the image in oci format locally along with tar creation.
An example of directory structure formed from complying to [image spec](https://github.com/opencontainers/image-spec/blob/main/image-layout.md) : <br>

```md
├── blobs
│   └── sha256
│       ├── 45e16698e6e721de091b5ecbb811eae1243fb8f2ed5dbd04a9f40cd199c355f9
│       ├── 4da097607a3cb58407cd8c157271bb5f7462a5872d516a5bc979ec678ac30f7d
│       └── 5c2dafe3c70c13990190d643c91e9f67b8129b179257674888178868474f6511
├── index.json
└── oci-layout
```
where one of the files in sha256 is the actual file tar and others 2 are configs and manifests.<br>

2. Add a flag `--to-oci-tar` to `imgpkg push`  to be able to creata a tar while pushing a tar with imgpkg push command.
 
3. Add a flag `--oci-tar` to `imgpkg copy` to be able to copy this oci kind of tar to a registry and differentiate with the `--tar` flag.

#### Future Goals

1. An improvement would be to have only one flag `--tar` for `imgpkg copy` making no changes to flags but making it compatible and being smart enough to understand and differentiate between both kind of tars without any need for specification. <br>

2. Add an inflate option to also contain all refs images in the oci-tar as discussed [here](https://github.com/carvel-dev/imgpkg/issues/55#issuecomment-962209740). This will be useful and true to the name of the command `imgpkg copy` as it will copy all the refs images as well and create a self-sufficient oci-tar. <br>

### Specification / Use Cases

Use Cases : 
- User wants to build a local oci compatible tar that can be pushed at a later point without being dependent on a registry.
- While using a CI framework which allows users to share files between stages, user wants to pass this output so that it can be pushed/copied in the next stage rather than having a shared registry.
- User can do the above with Package and PackageRepository bundles

### Other Approaches Considered

The idea behind the usage of `imgpkg push -b my.registry.io/some-name -f some-folder --to-oci-tar local-oci-format.tar` is to concentrate in a single command all the options to create a new image, that being to the registry or directly to disk.

I had considered not do the above but modifying the `imgpkg push command` to not require `-f folder` flag and being compatible with
`imgpkg push -b my.registry.io/some-name --to-oci-tar local-oci-format.tar` to push the tar to the registry. <br><br>

The reason this was dropped was it is similar to imgpkg copy command used above, although initially I had considered it because the copy command can be misleading when a user just wants to push his oci-tar. <br><br>


## Open Questions
1. Do we need save command to be able to save a tar file from a bundle image or should we just use push command to do the same as it forms the tar ? <br> 
2. If save can create a `oci-tar` and `copy` can copy/push the tar to the repo, what is the need to make it compatible with `push` command ? <br>
3. Should we have a single flag `--tar` for `imgpkg copy` to be able to copy both kind of tars or should we have 2 flags `--tar` and `--oci-tar` ? <br>

## Answered Questions
1. The usecase for save command is when a user only need the oci compliant tar file for sharing purposes and do not have a need to push to a registry. Since push will always require a registry for pushing even for oci-tar formation. <br>
2. The idea behind the usage of `imgpkg push -b my.registry.io/some-name -f some-folder --to-oci-tar local-oci-format.tar` is to concentrate in a single command all the options to create a new image, that being to the registry or directly to disk.
3. A single flag would be better as it would be more intuitive and easy to use. <br>