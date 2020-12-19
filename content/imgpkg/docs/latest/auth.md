---
title: Authentication
---

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

## Via Command Flags

You can explicitly specify credentials via command flags or associated environment variables. See `imgpkg push -h` for further details.

- `--registry-username` (or `$IMGPKG_USERNAME`)
- `--registry-password` (or `$IMGPKG_PASSWORD`)
- `--registry-token` (or `$IMGPKG_TOKEN`): used as an alternative to username/password combination
- `--registry-anon` (or `$IMGPKG_ANON=true`): used for anonymous access (commonly for pulling)

## Via Environment Variables

As of v0.4.0+, `imgpkg` can also use following environment variables:

- `IMGPKG_REGISTRY_HOSTNAME` to specify registry hostname (e.g. gcr.io, docker.io)
- `IMGPKG_REGISTRY_USERNAME` to specify registry username
- `IMGPKG_REGISTRY_PASSWORD` to specify registry password

Since you may need to provide multiple registry credentials, the environment variables above may be specified multiple times with a suffix of 1+ alphanumeric characters, e.g. `IMGPKG_REGISTRY_HOSTNAME_0`. Be sure to use the same suffix for hostname, username and password!

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
