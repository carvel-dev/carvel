---
aliases: [/kbld/docs/latest/auth]
title: Authentication
---

## Via Docker config

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

## Via Environment Variables

As of v0.23.0+, kbld can also use following environment variables:

- `KBLD_REGISTRY_HOSTNAME` to specify registry hostname (e.g. gcr.io, docker.io)
- `KBLD_REGISTRY_USERNAME` to specify registry username
- `KBLD_REGISTRY_PASSWORD` to specify registry password

Since you may need to provide multiple registry credentials, above environment variables multiple times with a suffix like so `KBLD_REGISTRY_HOSTNAME_0` (suffix can be 1+ alphanumeric characters). Use same suffix for hostname, username and password.

Currently credentials provided via environment variables do not apply when building images with Docker. Continue using `docker login` to authenticate Docker daemon.

## gcr.io

- Create service account with "Storage Admin" for push access
  - See [Permissions and Roles](https://cloud.google.com/container-registry/docs/access-control#permissions_and_roles)
- Download JSON service account key and place it somewhere on filesystem (e.g. `/tmp/key`)
  - See [Advanced authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#json_key_file)
- Run `cat /tmp/key | docker login -u _json_key --password-stdin https://gcr.io` to authenticate

## Amazon Web Services Elastic Container Registry (AWS ECR)

- Create an ECR repository \
  _(see [Amazon ECR User Guide: Getting started](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-console.html))_
- Create an IAM user with an ECR policy that allows to read/write \
  _(see [Amazon ECR User Guide: Private repository policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html))_ \
  Example:
  ```
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
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings",
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

- To authenticate from _the command line_, use the AWS CLI to generate a docker authentication token. \
  _(see [Amazon ECR User Guide: Private registry authentication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html))_ \
  Example:
  ```
  $ aws ecr get-login-password --region us-east-1 \
      | docker login \
          --username AWS \
          --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
  ```
- To authenticate from _a GitHub Action_, setup Carvel, AWS authentication, and ECR login. \
  _(see [Amazon ECR "Login" Action for GitHub Actions](https://github.com/aws-actions/amazon-ecr-login))_ \
   Example:

   ```
   ...
    - name: carvel-setup-action
      uses: carvel-dev/setup-action@v1.3.0

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
   ...
   ```



## Harbor

You may have to provide `--registry-ca-cert-path` flag with a path to a CA certificate file for Harbor Registry API.
