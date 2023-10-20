---
title: "Parameterizing Project Configuration with ytt"
slug: parameterizing-project-config-with-ytt
date: 2022-04-13
author: Garrett Cheadle
excerpt: "Want to start using ytt to manage your project's yaml files? Check out how to convert the configuration for an example application."
image: /img/ytt.svg
tags: ['Garrett Cheadle', 'ytt', 'data values', 'introduction', 'getting started']
---

If you’ve spent time learning `ytt`, you might know how extremely powerful it is, but if you are new to `ytt`, using it as your templating engine can be a daunting experience.

This blog post will cover how you can convert a simple application’s configuration into a parameterized and templated configuration with `ytt`.

### What is a Configuration File?

When using software out of the box, it will usually come with a set of default settings. These settings can be changed, and you can often save your own custom configuration in yaml. So, configuration files refer to all the configuration settings set by a group of files, often yaml files.

`ytt` is a tool that can add logic around these configuration files. As an application grows, the configuration grows, values get repeated, and it becomes harder to decipher what is being set. `ytt` can help by turning your configuration files into parameterized templates that separate the important values being set, allowing you to ignore verbose software specific configuration.

### Example Configuration 

Let’s begin by taking a look a single snippet from a YAML configuration file for a "Backstage" application ([Github repo](https://github.com/backstage/backstage)):
```yaml
#! config.yaml

app:
  title: Backstage Example App
  baseUrl: http://localhost:3000
  support:
    url: https://github.com/backstage/backstage/issues
    items:
      - title: Issues
        icon: github
        links:
          - url: https://github.com/backstage/backstage/issues
            title: GitHub Issues
      - title: Discord Chatroom
        icon: chat
        links:
          - url: https://discord.gg/MUpMjP2
            title: '#backstage'
organization:
  name: My Company
techdocs:
  builder: local
  generator:
    runIn: docker
  publisher:
    type: local
lighthouse:
  baseUrl: http://localhost:3003
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters: []
kafka:
  clientId: backstage
  clusters:
    - name: cluster
      brokers:
        - http://localhost:9092
catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration
  rules:
    - allow:
        - Component
        - API
        - Resource
        - Group
        - User
        - Template
        - System
        - Domain
        - Location
  locations:
    - type: file
      target: ../catalog-model/examples/all-components.yaml
    - type: file
      target: ../../plugins/github-actions/examples/sample.yaml
    - type: file
      target: ../../plugins/techdocs-backend/examples/documented-component/catalog-info.yaml
    - type: file
      target: ../catalog-model/examples/all-apis.yaml
    - type: file
      target: ../catalog-model/examples/all-resources.yaml
    - type: file
      target: ../catalog-model/examples/all-systems.yaml
    - type: file
      target: ../catalog-model/examples/all-domains.yaml
    - type: file
      target: ../../plugins/scaffolder-backend/sample-templates/all-templates.yaml
    - type: file
      target: ../catalog-model/examples/acme-corp.yaml
    - type: file
      target: ../../cypress/e2e-fixture.catalog.info.yaml
auth:
  environment: development
  providers:
    google:
      development:
        clientId: ${AUTH_GOOGLE_CLIENT_ID}
        clientSecret: ${AUTH_GOOGLE_CLIENT_SECRET}
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        enterpriseInstanceUrl: ${AUTH_GITHUB_ENTERPRISE_INSTANCE_URL}
    gitlab:
      development:
        clientId: ${AUTH_GITLAB_CLIENT_ID}
        clientSecret: ${AUTH_GITLAB_CLIENT_SECRET}
    okta:
      development:
        clientId: ${AUTH_OKTA_CLIENT_ID}
        clientSecret: ${AUTH_OKTA_CLIENT_SECRET}
        audience: ${AUTH_OKTA_AUDIENCE}
    oauth2:
      development:
        clientId: ${AUTH_OAUTH2_CLIENT_ID}
        clientSecret: ${AUTH_OAUTH2_CLIENT_SECRET}
        tokenUrl: ${AUTH_OAUTH2_TOKEN_URL}
    oidc:
      development:
        metadataUrl: ${AUTH_OIDC_METADATA_URL}
        clientId: ${AUTH_OIDC_CLIENT_ID}
        clientSecret: ${AUTH_OIDC_CLIENT_SECRET}
        tokenUrl: ${AUTH_OIDC_TOKEN_URL}
        tokenSignedResponseAlg: ${AUTH_OIDC_TOKEN_SIGNED_RESPONSE_ALG}
        scope: ${AUTH_OIDC_SCOPE}
        prompt: ${AUTH_OIDC_PROMPT}
    auth0:
      development:
        clientId: ${AUTH_AUTH0_CLIENT_ID}
        clientSecret: ${AUTH_AUTH0_CLIENT_SECRET}
        domain: ${AUTH_AUTH0_DOMAIN}
    microsoft:
      development:
        clientId: ${AUTH_MICROSOFT_CLIENT_ID}
        clientSecret: ${AUTH_MICROSOFT_CLIENT_SECRET}
        tenantId: ${AUTH_MICROSOFT_TENANT_ID}
    onelogin:
      development:
        clientId: ${AUTH_ONELOGIN_CLIENT_ID}
        clientSecret: ${AUTH_ONELOGIN_CLIENT_SECRET}
        issuer: ${AUTH_ONELOGIN_ISSUER}
    bitbucket:
      development:
        clientId: ${AUTH_BITBUCKET_CLIENT_ID}
        clientSecret: ${AUTH_BITBUCKET_CLIENT_SECRET}
    atlassian:
      development:
        clientId: ${AUTH_ATLASSIAN_CLIENT_ID}
        clientSecret: ${AUTH_ATLASSIAN_CLIENT_SECRET}
        scopes: ${AUTH_ATLASSIAN_SCOPES}
homepage:
  clocks:
    - label: UTC
      timezone: UTC
    - label: NYC
      timezone: America/New_York
    - label: STO
      timezone: Europe/Stockholm
    - label: TYO
      timezone: Asia/Tokyo
```
This YAML is long, repetitive, and tedious to adjust during the development process.

### Applying `ytt` Templating

`ytt` is a powerful tool. You can to annotate your YAML with annotations that are interpreted as code. `ytt` annotations begin with `#@`, and they allow you to escape into a pythonic language, called starlark, within your YAML templates.
This allows you to write code inline with your yaml! We can use loops, conditionals, functions, and much more to organize our YAML into configurable pieces. Let's show some examples using the YAML above:

- The map contained in `auth.providers` has a repetitive structure, we can write a function to help the construction of these environment variables references. 
```yaml
#@ def create_auth_env_var(domain, varName):
  #@ return 'AUTH_' + domain.upper() + '_' + varName.replace(' ', '_').upper()
#@ end
```

- There are also several URLs that follow the format: `localhost:port`. We can extract the creation of these URLs into a function call, making them easy to change in the future.  
```yaml
#@ def build_local_URL(port):
  #@ return "http://localhost:" + str(port)
#@ end 
```

- At the bottom of the configuration file, there is a list of time zones. We can store this information in a map, and then use a for-loop to template the list:
```yaml
#@ timezones = {'UTC':'UTC', 'NYC':'America/New_York', 'STO':'Europe/Stockholm', 'TYO':'Asia/Tokyo'}
#@ for k in timezones:
- label: #@ k 
  timezone: #@ timezones[k]
#@ end
```

Including these functions and for-loops in our configuration file allows for easier and more targeted changes.  

### Parameterizing with `ytt`

One of the major benefits when using `ytt` is the ability to separate boilerplate configuration from the configuration values that are actually being set. 
We can use the [`ytt` data values feature](https://carvel.dev/ytt/docs/latest/ytt-data-values/) to separate non boilerplate configuration:
```yaml
#! dataValues.yaml

#@data/values
---
catalogLocations:
  - ../catalog-model/examples/all-components.yaml
  - ../../plugins/github-actions/examples/sample.yaml
  - ../../plugins/techdocs-backend/examples/documented-component/catalog-info.yaml
  - ../catalog-model/examples/all-apis.yaml
  - ../catalog-model/examples/all-resources.yaml
  - ../catalog-model/examples/all-systems.yaml
  - ../catalog-model/examples/all-domains.yaml
  - ../../plugins/scaffolder-backend/sample-templates/all-templates.yaml
  - ../catalog-model/examples/acme-corp.yaml
  - ../../cypress/e2e-fixture.catalog.info.yaml

providersEnvironment: development
providers:
  google: ['client Id', 'client Secret']
  github: ['client Id', 'client Secret', 'enterprise Instance Url']
  gitlab: ['client Id', 'client Secret']
  okta: ['client Id', 'client Secret', 'audience']
  oauth2: ['client Id', 'client Secret', 'token Url']
  oidc: ['client Id', 'client Secret', 'metadata Url', 'token Url', 'token Signed Response Alg', 'scope', 'prompt']
  auth0: ['client Id', 'client Secret', 'domain']
  microsoft: ['client Id', 'client Secret', 'tenant Id']
  onelogin: ['client Id', 'client Secret', 'issuer']
  bitbucket: ['client Id', 'client Secret']
  atlassian: ['client Id', 'client Secret', 'scopes']
```  
By extracting this configuration into a separate `ytt` data values file, we have parameterized our configuration.
Now, instead of finding the correct place to edit in the large config file, we can simply open the data values file to make changes to `providers`, and `catalogLocations`.
Also, we easily can find which environment variables each provider needs for authentication, since the variables are now listed next to the corresponding provider. 

Next, the configuration file needs to utilize the parametrization that we set up with data values.
This is done by loading the data values into the configuration file (`#@ load("@ytt:data", "data")`), and adding logic that uses these values: 
```yaml
#! config.yaml

#@ load("@ytt:data", "data")

#@ def build_local_URL(port):
#@   return "http://localhost:" + str(port)
#@ end 

app:
  title: Backstage Example App
  baseUrl: #@ build_local_URL(3000)
  support:
    url: https://github.com/backstage/backstage/issues
    items:
      - title: Issues
        icon: github
        links:
          - url: https://github.com/backstage/backstage/issues
            title: GitHub Issues
      - title: Discord Chatroom
        icon: chat
        links:
          - url: https://discord.gg/MUpMjP2
            title: '#backstage'
organization:
  name: My Company
techdocs:
  builder: local
  generator:
    runIn: docker
  publisher:
    type: local
lighthouse:
  baseUrl: #@ build_local_URL(3003)
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters: []
kafka:
  clientId: backstage
  clusters:
    - name: cluster
      brokers:
        - #@ build_local_URL(9092)
catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration
  rules:
    - allow:
        - Component
        - API
        - Resource
        - Group
        - User
        - Template
        - System
        - Domain
        - Location
  locations:
    #@ for c in data.values.catalogLocations:
    - type: file
      target: #@ c
    #@ end

#@ def create_auth_env_var(name, variable):
#@   return '${AUTH_' + name.upper() + '_' + variable.replace(' ', '_').upper() + "}"
#@ end

auth:
  environment: #@ data.values.providersEnvironment
  providers:
    #@ for/end pr in data.values.providers:
    #@yaml/text-templated-strings
    (@= pr @):
      #@yaml/text-templated-strings
      (@= data.values.providersEnvironment @):
        #@ for/end val in data.values.providers[pr]:
        (@= val.replace(' ','') @): #@ create_auth_env_var(pr, val)

homepage:
  clocks:
    #@ timezones = {'UTC':'UTC', 'NYC':'America/New_York', 'STO':'Europe/Stockholm', 'TYO':'Asia/Tokyo'}
    #@ for k in timezones:
    - label: #@ k 
      timezone: #@ timezones[k]
    #@ end
```

We can now use `ytt` to template the `dataValues.yaml` and `config.yaml` files into a single configuration YAML file. 
The command `ytt -f config.yaml -f dataValues.yaml` outputs the original YAML configuration from before. [Take a look at these `ytt` templates in the playground.](https://carvel.dev/ytt/#gist:https://gist.github.com/gcheadle-vmware/fe08e00eb2d1b3328375879e4a98437b)

As you continue to work with this application, it will be easier to go into the `dataValues.yaml` file and change the parameterized values.
To ensure that our edits to the Data Values are made correctly, we could add a [Data Values Schema file](https://carvel.dev/ytt/docs/latest/how-to-write-schema/).
A Data Values Schema file declares a Data Value's name, default value, and type.
To learn more about the power of `ytt`, you can [see documentation about how to modularize with ytt.](https://carvel.dev/ytt/docs/develop/how-to-modularize/)

{{< blog_footer >}}