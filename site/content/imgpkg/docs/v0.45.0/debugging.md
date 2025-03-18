---
aliases: [/imgpkg/docs/latest/debugging]
title: Debugging
---

## Debugging

In the process of communicating with remote OCI registries, it is possible that an error will occur. In order to help debug an error situation, use the `--debug` command line argument. Specifying this argument will output detailed logs of all communications between `imgpkg` and the OCI registries.

> This feature is available in v0.20.0 and later

As an example, consider this pull command along with the additional information logged. The record of all HTTP communication will be displayed to assist in resolving a problem or error condition.

```bash-plain
imgpkg pull -b registry.example.com/foo/bar:latest -o temp --debug

2021/09/21 20:50:12 --> GET https://registry.example.com/v2/
2021/09/21 20:50:12 GET /v2/ HTTP/1.1
Host: registry.example.com
User-Agent: Go-http-client/1.1
Accept-Encoding: gzip

2021/09/21 20:50:12 <-- 401 https://registry.example.com/v2/ (207.596107ms)
2021/09/21 20:50:12 HTTP/1.1 401 Unauthorized
Content-Length: 76
Connection: keep-alive
Content-Type: application/json; charset=utf-8
Date: Wed, 22 Sep 2021 02:50:12 GMT
Docker-Distribution-Api-Version: registry/2.0
Set-Cookie: sid=f9752c01ce47ab50791d4a845a78d996; Path=/; HttpOnly; Secure
Strict-Transport-Security: max-age=31536000; includeSubDomains
Www-Authenticate: Bearer realm="https://registry.example.com/service/token",service="harbor-registry"
X-Request-Id: 2fe97b25-ca40-4012-9105-bbf8284995b6

{"errors":[{"code":"UNAUTHORIZED","message":"unauthorized: unauthorized"}]}

2021/09/21 20:50:12 --> GET https://registry.example.com/service/token?scope=repository%3Afoo%2Fbar%3Apull&service=harbor-registry [body redacted: basic token response contains credentials]
2021/09/21 20:50:12 GET /service/token?scope=repository%3Afoo%2Fbar%3Apull&service=harbor-registry HTTP/1.1
Host: registry.example.com
User-Agent: go-containerregistry/v0.6.0
Authorization: <redacted>
Accept-Encoding: gzip
...
``` 

> Note that sensitive information, such as basic authentication parameters and Authorization strings, are not displayed.
