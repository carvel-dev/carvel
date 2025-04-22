---
aliases: [/kapp-controller/docs/latest/packaging-artifact-formats]
title: Artifact formats
---

## Package Contents Bundle

A package bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that
holds package contents such as Kubernetes YAML configuration, ytt templates,
Helm templates, etc.

Filesystem structure used for package bundle creation:

```bash
my-pkg/
└── .imgpkg/
    └── images.yml
└── config/
    └── deployment.yml
    └── service.yml
    └── ingress.yml
```

- `.imgpkg/` directory (required) is a standard directory for any imgpkg bundle
  - `images.yml` file (required) contains container image refs used by configuration (typically generated with `kbld`)
- `config/` directory (optional) should contain arbitrary package contents such as Kubernetes YAML configuration, ytt templates, Helm templates, etc.
  - Recommendations:
    - Group Kubernetes configuration into a single directory (`config/` is our
      recommendation for the name) so that it could be easily referenced in the
      Package CR (e.g. using `ytt` template step against single directory)

See [Creating a package](packaging-tutorial.md#creating-a-package) for example creation steps.

## Package Repository Bundle

A package repository bundle is an [imgpkg bundle](/imgpkg/docs/latest/resources/#bundle) that holds PackageMetadata and Package CRs.

Filesystem structure used for package repository bundle creation:

```bash
my-pkg-repo/
└── .imgpkg/
    └── images.yml
└── packages/
    └── simple-app.corp.com
        └── metadata.yml
        └── 1.0.0.yml
        └── 1.2.0.yml
```

- `.imgpkg/` directory (required) is a standard directory for any imgpkg bundle
  - `images.yml` file (required) contains package bundle refs used by Package CRs (typically generated with `kbld`)
- `packages/` directory (required) should contain zero or more YAML files describing available packages
  - Each file may contain one or more PackageMetadata or Package CRs (using standard YAML document separator)
  - Files may be grouped in directories or kept flat
  - File names do not have any special meaning
  - Recommendations:
    - Separate packages in to directories with the package name
    - Keep each PackageMetadata CR in a `metadata.yml` file in the package's
      directory.
    - Keep each versioned package in a file with the version name inside the package's
      directory
    - Always have a PackageMetadata CR if you have Package CRs

See [Creating a Package Repository](packaging-tutorial.md#creating-a-package-repository) for example creation steps.

