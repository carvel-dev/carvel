---
title: "Parameterizing Project Configuration with ytt"
slug: parameterizing-project-config-with-ytt
date: 2022-04-05
author: Garrett Cheadle
excerpt: "Want to start using ytt to manage your project's yaml files? Check out how to convert the config of a Spring Boot Application."
image: /img/ytt.svg
tags: ['Garrett Cheadle', 'ytt', 'data values', 'introduction', 'getting started']
---

If you’ve spent time learning `ytt`, you might know how extremely powerful it is, but if you are new to `ytt`, using it as your templating engine can be a daunting experience.

This blog post will cover how you can convert a simple application’s configuration into a parameterized and templated configuration with `ytt`.

### What is a Configuration File?

When using software out of the box, it will usually come with a set of default settings. These settings can be changed, and you can often save your own custom configuration in yaml. So, configuration files refer to all the configuration settings set by a group of files, often yaml files.

`ytt` is a tool that can add logic around these configuration files. As an application grows, the configuration grows, values get repeated, and it becomes harder to decipher what is being set. `ytt` can help by turning your configuration files into parameterized templates that separate the important values being set, allowing you to ignore verbose software specific configuration.


### Simple Application with Spring Boot

Imagine you are developing a [blog application with Spring Boot](https://github.com/skarware/spring-boot-blog-app). Spring Boot is used to build stand-alone and production ready spring applications. Spring Boot applications come with many properties set by default; one common way to override them and set additional properties is through the `application.properties` file:

```
server.port = 8080

### H2 DataSource properties
spring.h2.console.enabled=true
spring.h2.console.path=/h2
spring.datasource.url=jdbc:h2:mem:blog_database;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.username=sa
spring.datasource.password=
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.platform=h2
spring.datasource.schema=classpath:/sql/schema.sql
spring.datasource.data=classpath:/sql/data.sql

spring.profiles.active=dev
spring.jpa.hibernate.ddl-auto=update

### Thymeleaf settings
spring.thymeleaf.cache=false
spring.thymeleaf.check-template=true
spring.thymeleaf.check-template-location=true
spring.thymeleaf.enabled=true
spring.thymeleaf.prefix=classpath:/templates/
spring.thymeleaf.suffix=.html
spring.thymeleaf.encoding=UTF-8
spring.datasource.sql-script-encoding=UTF-8

# Log the SQL queries
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type=trace

logging.level.org.hibernate.type.descriptor.sql=TRACE
logging.level.org.springframework.web=info
logging.level.org.hibernate=info

logging.level.web=debug
logging.level.sql=debug
logging.level.root=debug

spring.jpa.properties.hibernate.format_sql=true
```

This example is not easy to understand, and you can tell that there is some repetition in the keys. Let’s improve this configuration. We can start by making the file less dense and more human-readable by converting it to yaml. Spring boot allows properties to by provided via yaml in an `application.yml` file:
```yaml
server:
  port: '8080'
spring:
  #! H2 DataSource properties
  datasource:
    data: classpath:/sql/data.sql
    driver-class-name: org.h2.Driver
    password: ''
    username: sa
    schema: classpath:/sql/schema.sql
    url: jdbc:h2:mem:blog_database;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    sql-script-encoding: UTF-8
    platform: h2
  #! Thymeleaf settings
  thymeleaf:
    cache: 'false'
    check-template: 'true'
    prefix: classpath:/templates/
    check-template-location: 'true'
    suffix: .html
    encoding: UTF-8
    enabled: 'true'
  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        format_sql: 'true'
  h2:
    console:
      path: /h2
      enabled: 'true'
  profiles:
    active: dev
#! Log the SQL queries
logging:
  level:
    org:
      hibernate:
        nodeValue: info
        type:
          nodeValue: trace
          descriptor:
            sql: TRACE
        SQL: DEBUG
      springframework:
        web: info
    web: debug
    sql: debug
    root: debug
```
The file is now longer, but since it's in yaml, we can start using `ytt`. 😎

Let’s begin by identifying the sections of configuration that are closely related, or values that change often, and extract these sections of yaml into a [ytt data values schema file](https://carvel.dev/ytt/docs/v0.40.0/how-to-use-data-values/).

`values.yml`:
```yaml
#@data/values-schema
---
port: '8080'
profile: dev
#! H2 DataSource properties
ds:
  data: classpath:/sql/data.sql
  driver-class-name: org.h2.Driver
  password: ''
  username: sa
  schema: classpath:/sql/schema.sql
  url: jdbc:h2:mem:blog_database;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
  sql-script-encoding: UTF-8
  platform: h2
#! Thymeleaf settings
tl:
  cache: 'false'
  check-template: 'true'
  prefix: classpath:/templates/
  check-template-location: 'true'
  suffix: .html
  encoding: UTF-8
  enabled: 'true'

#! add easy way to turn on/off debug mode
debug: true
```

`config.yml`:
```yaml
#@ load("@ytt:data", "data")

server:
  port: #@ data.values.port
spring:
  datasource: #@ data.values.ds
  thymeleaf: #@ data.values.tl
  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        format_sql: 'true'
  h2:
    console:
      path: /h2
      enabled: 'true'
  profiles:
    active: #@ data.values.profile
#! Log the SQL queries
logging:
  level:
    org:
      hibernate:
        nodeValue: info
        type:
          nodeValue: trace
          descriptor:
            sql: TRACE
        SQL: DEBUG
      springframework:
        web: info
    #@ if data.values.debug:
    web: debug
    sql: debug
    root: debug
    #@ end
```

Now if you were to run `ytt -f config.yml -f values.yml`, `ytt` would output the same yaml as the original yaml file, [see these files in the ytt playground](https://carvel.dev/ytt/#gist:https://gist.github.com/gcheadle-vmware/fe08e00eb2d1b3328375879e4a98437b). These files can now be used when developing your application! This can be done by templating the two `ytt` templates with `ytt`, then use the forward angle bracket to overwrite your `application.yml` file:
```ytt -f config.yml -f values.yml > application.yml```
This will update your application's congiuration with any changes that were made, and you can now simply run your normal build command.


As you continue to develop this application, it will be easier to go into the `values.yml` file and change the parameterized values. One way that we could further extract the configuration into `ytt` templates is through the use of [`ytt` libraries](https://carvel.dev/ytt/docs/v0.40.0/lang-ref-ytt-library/). Then each `ytt` library can have its own set of data values, and then be compiled, templeted, and combined into a single `application.yml`.


see the new guides and examples about data values, private libraries, and starlark modules.