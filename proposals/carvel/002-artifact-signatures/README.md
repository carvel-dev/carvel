---
title: "Maintaining Carvel Documentation"
authors: [ "Thomas Vitale <ThomasVitale@users.noreply.github.com>" ]
status: "draft"
approvers: []
---

# Signatures for Carvel Artifacts

## Problem Statement

Securing the software supply chain is a critical activity for each organization, especially when using third-party software. As explained in the [CNCF Software Supply Chain White Paper](https://github.com/cncf/tag-security/tree/main/supply-chain-security/supply-chain-security-paper), one of the key tenets of supply chain security is the _verification_ of the provenance and integrity of each software component part of the chain.

Organizations using Carvel that want to secure their software supply chain require a way to _verify_ that each Carvel artifact (CLI tool or container image) is "drawn from a trusted source and have not been tampered with" (CNCF Software Supply Chain White Paper).

A first step in enabling users to verify the integrity of the Carvel artifacts is cryptographically signing each of them upon release, which is the focus of this document. Subsequent papers will propose further actions to strengthen the security posture of Carvel by introducing provenance attestations and SBOMs.

## Terminology / Concepts

* _Digital Signature_. "The result of a cryptographic transformation of data that, when properly implemented, provides a mechanism for verifying origin authentication, data integrity and signatory non-repudiation." ([NIST Digital Signature Standard](https://csrc.nist.gov/pubs/fips/186-4/final))
* _Keyless Signing_. "Identity-based signing, associating an ephemeral signing key with an identity from an OpenID Connect provider". ([Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/)) This approach eliminates the need for managing, rotating, and securing keys.

## Proposal

The proposed solution to cryptographically sign all released Carvel artifacts is based on the keyless signing feature provided by the [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/) project.

### Goals and Non-goals

**Goals:**
- Users of Carvel can verify the integrity of each Carvel artifact via a cryptographic signature.

**Non-Goals**
- Users of Carvel can verify the provenance of each Carvel artifact. _It will be handled in a separate paper._
- Users of Carvel can verify the materials included in each Carvel artifact (SBOM). _It will be handled in a separate paper._

### Specification / Use Cases

Sigstore Cosign allows to sign software artifacts and verify signatures in _keyless_ mode relying on OpenID Connect as the authentication protocol. When the signing operation is performed as part of a pipeline using GitHub Actions, the signing identity will be the one of the specific Workflow reference.

This section describes how to use Cosign to sign and verify container images and binary artifacts, and how to integrate those steps in a pipeline based on GitHub Actions. It also includes an example of signature verification on Kubernetes using the Kyverno project.

#### Signing and verifying OCI artifacts

When signing OCI artifacts, Cosign attaches the signature to the specific container image and publishes it to the same container registry by default. Notice that signatures are attached to container images via digest. Tags cannot be used in this regard.

For example, given the `ghcr.io/carvel-dev/kapp-controller` container image, the set of artifacts released would be the following:

* `ghcr.io/carvel-dev/kapp-controller@sha256:<digest>`
* `ghcr.io/carvel-dev/kapp-controller@sha256:<digest>.sig`

> [!NOTE]
> The Cosign strategy for attaching signatures to OCI artifacts will change in the future based on the new features introduced by the OCI Distribution Spec 1.1. Such a change will be transparent to users and will not change the process that the Carvel project will use to sign container images. For more context, refer to the information included in https://github.com/carvel-dev/imgpkg/issues/547.

Using the Cosign CLI, signing a container image works as follows:

```shell script
cosign sign \
  ghcr.io/carvel-dev/kapp-controller@sha256:<digest>
```

The command will generate a signature and publish it as an OCI artifact to the same container registry as the container image, using the same digest for identification.

An example of this approach can be seen in the [Flux](https://fluxcd.io/flux/security/#signed-container-images) project.

Users can verify the signature for an OCI artifact using the Cosing CLI. The snippet assumes that the signing process has been performed as part of a pipeline based on GitHub Actions using the Workflow reference as the identity.

```shell script
cosign verify \
  ghcr.io/carvel-dev/kapp-controller@sha256:<digest> \
  --certificate-identity-regexp=https://github.com/carvel-dev \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

For more information about signing container images with Cosign, refer to the [official documentation](https://docs.sigstore.dev/cosign/signing_with_containers/).

##### OCI artifacts to sign

The proposal is for signing all the artifacts included in the following Carvel projects.

**kapp-controller**:

* `ghcr.io/carvel-dev/kapp-controller`
* `ghcr.io/carvel-dev/kapp-controller-package-bundle`

**secretgen-controller**:

* `ghcr.io/carvel-dev/secretgen-controller`
* `ghcr.io/carvel-dev/secretgen-controller-package-bundle`

#### Signing and verifying binary artifacts

When signing binary artifacts, Cosign produces signature and certificate information that can be stored and distributed together with the binary artifacts either as separate files, or in a bundled text file. Sigstore recommends using a bundle in order to minimize the number of files to distribute. However, several CNCF projects that have adopted Sigstore decided to use separate files for signature and certificate for better clarity (for example, Kyverno and Knative), so we'll consider this strategy going forward to align with them.

For example, given the binary `imgpkg-darwin-arm64`, the set of artifacts released would be the following:

* `imgpkg-darwin-arm64`: the binary artifact;
* `imgpkg-darwin-arm64.pem`: the certificate that Cosign will use to verify the signature;
* `imgpkg-darwin-arm64.sig`: signature that Cosign will verify.

The binary artifacts released by each Carvel project are currently associated with a checksum, which users should still validate after having verified the signature. The `checksums.txt` file gathers the checksums for all binaries part of the release and can also be signed with Cosign. The result would be as follows:

* `checksums.txt`: a text file containing the SHA256 hashes for the binary artifacts included in the release; 
* `checksums.txt.pem`: the certificate that Cosign will use to verify the signature;
* `checksums.txt.sig`: signature that Cosign will verify.

An example of this approach can be seen in the [Kyverno](https://github.com/kyverno/kyverno/releases/tag/v1.10.2) project.

Using the Cosign CLI, signing a binary artifact works as follows:

```shell script
cosign sign-blob \
  imgpkg-darwin-arm64 \
  --output-certificate imgpkg-darwin-arm64.pem \
  --output-signature imgpkg-darwin-arm64.sig
```

The command will output certificate and signature in the specified files, which must be distributed together with the binary artifact. Users can verify the signature for a given binary artifact using the Cosing CLI. The snippet assumes that the signing process has been performed as part of a pipeline based on GitHub Actions using the Workflow reference as the identity.

```shell script
cosign verify-blob \
  --cert imgpkg-darwin-arm64.pem \
  --signature imgpkg-darwin-arm64.sig \
  --certificate-identity-regexp=https://github.com/carvel-dev \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  imgpkg-darwin-arm64
```

If the signature is valid for both the binary artifact and the `checksums.txt` file, users can proceed verifying the `SHA256` sums match the downloaded binary as they would usually do. For example, using the `shasum` utility.

```shell script
shasum -a 256 imgpkg-darwin-arm64
```

For more information about signing blobs with Cosign, refer to the [official documentation](https://docs.sigstore.dev/cosign/signing_with_blobs/).

##### Binary artifacts to sign

The proposal is for signing all the artifacts included in the following Carvel projects.

**imgpkg**:

* imgpkg-darwin-amd64
* imgpkg-linux-amd64
* imgpkg-windows-amd64.exe
* imgpkg-darwin-arm64
* imgpkg-linux-arm64
* checksums.txt

**kapp**:

* kapp-darwin-amd64
* kapp-linux-amd64
* kapp-windows-amd64.exe
* kapp-darwin-arm64
* kapp-linux-arm64
* checksums.txt

**kapp-controller**:

* kctrl-darwin-amd64
* kctrl-linux-amd64
* kctrl-windows-amd64.exe
* kctrl-darwin-arm64
* kctrl-linux-arm64
* checksums.txt

**kbld**:

* kbld-darwin-amd64
* kbld-linux-amd64
* kbld-windows-amd64.exe
* kbld-darwin-arm64
* kbld-linux-arm64
* kbld-windows-arm64.exe
* checksums.txt

**vendir**:

* vendir-darwin-amd64
* vendir-linux-amd64
* vendir-windows-amd64.exe
* vendir-darwin-arm64
* vendir-linux-arm64
* checksums.txt

**ytt**:

* ytt-darwin-amd64
* ytt-linux-amd64
* ytt-windows-amd64.exe
* ytt-darwin-arm64
* ytt-windows-arm64.exe
* ytt-linux-arm64
* checksums.txt

#### Using the Sigstore GitHub Action

The Sigstore project provides an official Action to set up Cosign in a pipeline based on GitHub Actions: [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer).

Example using a container image:

```yaml
name: Commit Stage
on: push

jobs:
  build:
    name: Build
    runs-on: ubuntu-22.04
    permissions:
      contents: read
      packages: write
      id-token: write # Required by Cosign to authenticate with GitHub via OIDC
    steps:
      - name: Install Cosign
        uses: sigstore/cosign-installer@v3
      - name: Sign image
        run: |
          # The --yes argument is necessary to disable the interactive mode.
          cosign sign --yes "ghcr.io/carvel-dev/kapp-controller@sha256:<digest>"
```

#### Verifying the signatures with Kyverno

Artifacts signed by Cosign can be verified via the Cosign CLI as previously described. A few different projects integrate with Cosign and offer features to verify artifact signatures. For example, [Kyverno](https://kyverno.io/docs/writing-policies/verify-images/sigstore/#keyless-signing-with-github-workflows) offers a convenient way to validate the signature of container images on Kubernetes and deny their deployment in case the given policy doesn't match.

Example of a Kyverno policy verifying the signature on a container image signed as part of a pipeline based on GitHub Actions:

```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: verify-image
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-signature
      match:
        any:
        - resources:
            kinds:
              - Pod
      verifyImages:
      - imageReferences:
        - "ghcr.io/carvel-dev/*"
        attestors:
        - entries:
          - keyless:
              subject: "https://github.com/carvel-dev/*"
              issuer: "https://token.actions.githubusercontent.com"
```

### Other Approaches Considered

Besides keyless signing, Sigstore Cosign supports signing artifacts using key pairs. That would be a less desirable approach for:

* the Carvel maintainers that would need to deal explicitly with key management (issuance, renewals, revokations, security) and public key distribution;
* the Carvel users that would need to get the public key in order to verify the signature on the Carvel OCI artifacts.

Projects in the cloud native ecosystem that adopted Sigstore Cosign are using different approaches. Keyless signing is used by Kubernetes, Knative, and Flux. Traditional signing is used by cert-manager and Tekton.

Other tools could be used for signing the Carvel artifacts, but Sigstore can now be considered the de-facto standard in the cloud native space. It's sponsored by the Open Source Security Foundation (OSSF), which maintains a [Landscape](https://landscape.openssf.org/sigstore) overview with all the tools integrating with Sigstore or using Sigstore for signing their artifacts.

## References

* [CNCF Software Supply Chain White Paper](https://github.com/cncf/tag-security/tree/main/supply-chain-security/supply-chain-security-paper) (Securing the Materials, Securing the Build, Securing the Artefacts)
* [NIST Secure Software Development Framework](https://csrc.nist.gov/Projects/ssdf) (PO.1.3, PO.3.1, PO.3.2, PS.1.1, PS.2.1, PS.3.1, PW.4.1, PW.4.4)
* [OWASP Top 10 CI/CD Security Risks](https://owasp.org/www-project-top-10-ci-cd-security-risks/) (CICD-SEC-9)
* [Secure Supply Chain Consumption Framework](https://github.com/ossf/s2c2f) (AUD-3)
* [US President’s Executive Order (EO) 14028 - Improving the Nation's Cybersecurity](https://www.federalregister.gov/documents/2021/05/17/2021-10460/improving-the-nations-cybersecurity) (4e-x)

## Open Questions

_Add questions here_

## Answered Questions

_Add answers here_
