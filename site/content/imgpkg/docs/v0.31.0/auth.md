---

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

As of v0.18.0+, `imgpkg` will attempt to authenticate itself via the underlying IaaS:

This auth feature can be enabled/disabled via a feature flag (enabled by default): `IMGPKG_ENABLE_IAAS_AUTH=true|false`

Below is a list of IaaS providers that imgpkg will authenticate with:

- [GCP](https://cloud.google.com/compute/docs/metadata/overview)
- [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) Note: If the AWS_SDK_LOAD_CONFIG environment variable is set to a truthy value the shared config file (~/.aws/config) will
also be loaded in addition to the shared credentials file (~/.aws/credentials).
- [Azure](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-managed-identities-work-vm)

Note: When using Azure, a required configuration file needs to be provided via the flag `--registry-azure-cr-config <path-to-config>` or via the env variable `IMGPKG_REGISTRY_AZURE_CR_CONFIG=<path-to-config>`

See below the various configuration options allowed:
```yaml
{
  # The cloud environment identifier. Takes values from https://github.com/Azure/go-autorest/blob/ec5f4903f77ed9927ac95b19ab8e44ada64c1356/autorest/azure/environments.go#L13
  "cloud": "",
  # The AAD Tenant ID for the Subscription that the cluster is deployed in
  "tenantId": "TenantID",
  # The ClientID for an AAD application with RBAC access to talk to Azure RM APIs
  "aadClientId": "AADClientID",
  # The ClientSecret for an AAD application with RBAC access to talk to Azure RM APIs
  "aadClientSecret": "AADClientSecret",
  # The path of a client certificate for an AAD application with RBAC access to talk to Azure RM APIs
  "aadClientCertPath": "AADClientCertPath",
  # The password of the client certificate for an AAD application with RBAC access to talk to Azure RM APIs
  "aadClientCertPassword": "AADClientCertPassword",
  # Use managed service identity for the virtual machine to access Azure ARM APIs
  "useManagedIdentityExtension": false,
  # UserAssignedIdentityID contains the Client ID of the user assigned MSI which is assigned to the underlying VMs. If empty the user assigned identity is not used.
  # More details of the user assigned identity can be found at: https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview
  # For the user assigned identity specified here to be used, the UseManagedIdentityExtension has to be set to true.
  "userAssignedIdentityID": "UserAssignedIdentityID",
  # The ID of the Azure Subscription that the cluster is deployed in
  "subscriptionId": "SubscriptionID",
  # IdentitySystem indicates the identity provider. Relevant only to hybrid clouds (Azure Stack).
  # Allowed values are 'azure_ad' (default), 'adfs'.
  "identitySystem": "IdentitySystem",
  # ResourceManagerEndpoint is the cloud's resource manager endpoint. If set, cloud provider queries this endpoint
  # in order to generate an autorest.Environment instance instead of using one of the pre-defined Environments.
  "resourceManagerEndpoint": "ResourceManagerEndpoint",
  # The AAD Tenant ID for the Subscription that the network resources are deployed in
  "networkResourceTenantID": "NetworkResourceTenantID",
  # The ID of the Azure Subscription that the network resources are deployed in
  "networkResourceSubscriptionID": "NetworkResourceSubscriptionID"
}
```


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
