---
aliases: [/imgpkg/docs/latest/auth]
title: Authentication
---

# Ordering

imgpkg has multiple ways to provide authentication details to registries.

The order at which imgpkg chooses which authentication details to use is the following:

1. [Via Environment Variables](#via-environment-variables)
1. [Via IaaS](#via-iaas)
1. [Via Command Flags](#via-command-flags)
1. [Via Docker Config](#via-docker-config)

## Via Environment Variables

As of v0.7.0+, `imgpkg` can also use following environment variables:

- `IMGPKG_REGISTRY_HOSTNAME` to specify registry hostname (e.g. gcr.io, docker.io, https://gcr.io, docker.io/v2/)
  - As of v0.18.0+ `IMGPKG_REGISTRY_HOSTNAME` also supports providing glob wildcards. for e.g. `*.*.docker.io` will match `bar.foo.docker.io`. 
    - Note: if there is overlap between 2 HOSTNAMES, one using globbing and the other not, the HOSTNAME not using globbing will be applied. e.g. `IMGPKG_REGISTRY_HOSTNAME_0=*.docker.io` vs `IMGPKG_REGISTRY_HOSTNAME_1=foo.docker.io` for the image `foo.docker.io/image` will result in auth details from `IMGPKG_REGISTRY_HOSTNAME_1` being used.
  - As of v0.18.0+ `IMGPKG_REGISTRY_HOSTNAME` also supports providing the fully qualified repository. for e.g. `gcr.io/repo/image`. 
- `IMGPKG_REGISTRY_USERNAME` to specify registry username
- `IMGPKG_REGISTRY_PASSWORD` to specify registry password
- `IMGPKG_REGISTRY_IDENTITY_TOKEN` to authenticate the user and get an access token for the registry via an [oauth2 refresh token grant type](https://docs.docker.com/registry/spec/auth/oauth/).
- `IMGPKG_REGISTRY_REGISTRY_TOKEN` to specify the access token to be used in the Authorization Header as a [Bearer Token](https://docs.docker.com/registry/spec/auth/token/#using-the-bearer-token).

Since you may need to provide multiple registry credentials, the environment variables above may be specified multiple times with a suffix of 1+ alphanumeric characters,

e.g. If you had 2 registries you wish to provide authentication credentials for, you would require 2 sets of env variables.

For Registry #1:

```
IMGPKG_REGISTRY_HOSTNAME_0=hostname.for.registry.1
IMGPKG_REGISTRY_USERNAME_0=username
IMGPKG_REGISTRY_PASSWORD_0=password
```

For Registry #2:

```
IMGPKG_REGISTRY_HOSTNAME_1=hostname.for.registry.2
IMGPKG_REGISTRY_IDENTITY_TOKEN_1=token
```

When imgpkg interacts with `hostname.for.registry.1`, it will use the env variables with the suffix `_0`. And when interacting with `hostname.for.registry.2`, it will use the env variables with the suffix `_1`


Note: Credentials provided via an env variable for a specific registry will take precedence over Command Flags.

## Via IaaS

By default, `imgpkg` will **NOT** attempt to authenticate itself via the underlying IaaS:

To activate this behavior you can set the environment variable `IMGPKG_ACTIVE_KEYCHAINS` with the keychains to the IaaS that you are currently using.

*Note:* To mimic the old behavior of `imgpkg` set the environment variable as follows `export IMGPKG_ACTIVE_KEYCHAINS=gke,aks,ecr`

Below is a list of IaaS providers that `imgpkg` can authenticate with:

- [GCP](https://cloud.google.com/compute/docs/metadata/overview)

  To activate it use `export IMGPKG_ACTIVE_KEYCHAINS=gke`

- [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)

  To activate it use `export IMGPKG_ACTIVE_KEYCHAINS=ecr`
  For more information [check the helper](https://github.com/awslabs/amazon-ecr-credential-helper#configuration)

- [Azure](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-managed-identities-work-vm)

  To activate it use `export IMGPKG_ACTIVE_KEYCHAINS=aks`
  For more information check [this library](https://github.com/chrismellard/docker-credential-acr-env)

- Github

  To activate use `export IMGPKG_ACTIVE_KEYCHAINS=github`
  Requires the environment variable `GITHUB_TOKEN` to be set to connect to ghcr.io

**Deprecation:** The environment variable `IMGPKG_ENABLE_IAAS_AUTH` can be used only to activate all the keychains.
This behavior will be removed in a future version.


## Via Command Flags

You can explicitly specify credentials via command flags or associated environment variables. See `imgpkg push -h` for further details.

- `--registry-username` (or `$IMGPKG_USERNAME`)
- `--registry-password` (or `$IMGPKG_PASSWORD`)
- `--registry-token` (or `$IMGPKG_TOKEN`): to specify the access token to be used in the Authorization Header as a [Bearer Token](https://docs.docker.com/registry/spec/auth/token/#using-the-bearer-token).
- `--registry-anon` (or `$IMGPKG_ANON=true`): used for anonymous access (commonly for pulling)

## Via Docker config

Even though `imgpkg` commands use registry APIs directly, by default it uses credentials stored in `~/.docker/config.json` which are typically generated via a `docker login` command.

Example generated `~/.docker/config.json`:

```json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "dXNlcjpwYXNzd29yZA=="
    },
  },
  "HttpHeaders": {
    "User-Agent": "Docker-Client/18.09.6 (darwin)"
  }
}
```

where `dXNlcjpwYXNzd29yZA==` is `base64("username:password")`.

## gcr.io

- Create a service account with "Storage Admin" permissions for push access
  - See [Permissions and Roles](https://cloud.google.com/container-registry/docs/access-control#permissions_and_roles)
- Download a JSON service account key and place it somewhere on filesystem (e.g. `/tmp/key`)
  - See [Advanced authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#json_key_file)
- Run `cat /tmp/key | docker login -u _json_key --password-stdin https://gcr.io` to authenticate

## AWS ECR

- Create an ECR repository
- Create an IAM user with an ECR policy that allows read/write
  - See [Amazon ECR Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html)
- Run `aws configure` and specify access key ID, secret access key and region
  - To install on Ubuntu, run `apt-get install pip3` and `pip3 install awscli`
    - See [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- Run `eval $(aws ecr get-login --no-include-email)` to authenticate
  - See [get-login command](https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login.html)

Example ECR policy from [Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    }
  ]
}
```

## Harbor

You may have to provide `--registry-ca-cert-path` flag with a path to a CA certificate file for Harbor Registry API.
