---
title: Sops
---

Available in v0.11.0+.

Storing _encrypted_ secrets next to your configuration (within a Git repo or other artifacts) is one way to manage secret lifecycle. kapp-controller integrates with [Mozilla's SOPS](https://github.com/mozilla/sops) to decrypt secret material in fetched configuration.

## Prepate GPG installation

```bash
$ gpg --gen-key
...

$ gpg --list-secret-keys --keyid-format LONG
/root/.gnupg/secring.gpg
------------------------
sec   4096R/B464DFD255C6B9F8 2020-10-03
uid                          test test (test) <test@test.com>
ssb   4096R/FEE37B8E2098EDFC 2020-10-03
```

(Note: `B464DFD255C6B9F8` is the ID to be used later)

## Encrypt contents

kapp-controller expects that encrypted files have `.sops.yml` extension (or `.sops.yml`).

```bash
# Unencrypted file
$ cat secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: my-sec
data:
  password: my-password

# Encrypt file to be later decrypted by kapp-controller
$ sops --encrypt --pgp B464DFD255C6B9F8 secret.yml > secret.sops.yml

# Delete unencrypted file
$ rm secret.yml
```

## Import private key into Kubernetes

Extract PGP private key from your GPG installation and import into your Kubernetes cluster. It will be referenced by App CR.

```bash
$ gpg --armor --export-secret-keys B464DFD255C6B9F8 > my.pk
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pgp-key
  namespace: default
stringData:
  # value of this is contents of my.pk
  my.pk: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: GnuPG v1
    ...
```

## Decrypt in App CR

Configure App CR to decrypt contents. Assuming, in this example, your git repo contains `secret.sops.yml`, it would be decrypted into `secret.yml` file.

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: config-with-sops
  namespace: default
spec:
  serviceAccountName: default-ns
  fetch:
  - git:
      ...
  template:
  - sops:
      pgp:
        privateKeysSecretRef:
          name: pgp-key
  - ytt: {}
  deploy:
  - kapp: {}
```
