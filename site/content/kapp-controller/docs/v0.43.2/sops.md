---
aliases: [/kapp-controller/docs/latest/sops]
title: Sops
---

Available in v0.11.0+.

Storing _encrypted_ secrets next to your configuration (within a Git repo or other artifacts) is one way to manage secret lifecycle. kapp-controller integrates with [Mozilla's SOPS](https://github.com/mozilla/sops) to decrypt secret material in fetched configuration.

## Prepare your keys
Sops shipped with kapp-controller includes support for encryption via both [GPG](https://gnupg.org/) and [age](https://github.com/FiloSottile/age).
Note that the Sops project recommends Age.

### using GPG

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

### using Age
You may find [this screencast](https://asciinema.org/a/431605) helpful.
```bash
$ age-keygen -o key.txt
Public key: age12345...

$ chmod 600 key.txt
```
(Note: the public key `age12345...` will be used later)

## Encrypt contents

kapp-controller expects that encrypted files have `.sops.yml` extension (or `.sops.yaml`).

You can start by creating an unencrypted yaml:
```bash
# Unencrypted file
$ cat secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: my-sec
data:
  password: my-password
```

Then encrypt file with your public key from the previous step, to be later decrypted by kapp-controller.

### using GPG
```bash
$ sops --encrypt --pgp B464DFD255C6B9F8 secret.yml > secret.sops.yml

# Delete unencrypted file
$ rm secret.yml
```

### using Age
```bash
$ SOPS_AGE_KEY_FILE=./key.txt  sops --encrypt --age age12345... secret.yml > secret.sops.yml
```

## Import private key into Kubernetes
Make a secret that includes the private key and import it into your 
cluster. It will be referenced by App CR.

### using GPG
Extract PGP private key from your GPG installation:

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

### using Age
Cat the contents of your local key.txt to the body of a stringData block also named
key.txt:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: age-key
stringData:
  key.txt: |
    # created: <timestamp>
    # public key: age12345...
    AGE-SECRET-KEY-HUNTER2ORSOMETHINGWHENEVERYOUTYPEYOURPASSWORDIJUSTSEEHUNTER2
```

## Decrypt in App CR

Configure App CR to decrypt contents. Assuming, in this example, your git repo contains `secret.sops.yml`, it would be decrypted into `secret.yml` file.

### using GPG
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

### using Age
Nearly identical to the example above, but with a sops.age key:
```yaml
spec:
  template:
  - sops:
      age:
        privateKeysSecretRef:
          name: age-key
```
