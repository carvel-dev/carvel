## Authentication

### Via Docker config

Even though `kbld` commands use registry APIs directly, by default it uses credentials stored in `~/.docker/config.json` which are typically generated via `docker login` command.

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

### Via Environment Variables

As of v0.23.0+, kbld can also use following environment variables:

- `KBLD_REGISTRY_HOSTNAME` to specify registry hostname (e.g. gcr.io, docker.io)
- `KBLD_REGISTRY_USERNAME` to specify registry username
- `KBLD_REGISTRY_PASSWORD` to specify registry password

Since you may need to provide multiple registry credentials, above environment variables multiple times with a suffix like so `KBLD_REGISTRY_HOSTNAME_0` (suffix can be 1+ alphanumeric characters). Use same suffix for hostname, username and password.

Currently credentials provided via environment variables do not apply when building images with Docker. Continue using `docker login` to authenticate Docker daemon.

### gcr.io

- Create service account with "Storage Admin" for push access
  - See [Permissions and Roles](https://cloud.google.com/container-registry/docs/access-control#permissions_and_roles)
- Download JSON service account key and place it somewhere on filesystem (e.g. `/tmp/key`)
  - See [Advanced authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#json_key_file)
- Run `cat /tmp/key | docker login -u _json_key --password-stdin https://gcr.io` to authenticate

### AWS ECR

- Create ECR repository
- Create IAM user with ECR policy that allows to read/write
  - See [Amazon ECR Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html)
- Run `aws configure` and specify access key ID, secret access key and region
  - To install on Ubuntu, run `apt-get install pip3` and `pip3 install awscli`
    - See [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- Run `eval $(aws ecr get-login --no-include-email)` to authenticate
  - See [get-login command](https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login.html)

Example ECR policy from https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html:

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

### Harbor

You may have to provide `--registry-ca-cert-path` flag with a path to a CA certificate file for Harbor Registry API.
