## CNAB image relocation mapping

CNAB spec mentions [Image Relocation](https://github.com/deislabs/cnab-spec/blob/master/103-bundle-runtime.md#image-relocation) as part of bundle runtime.

kbld supports applying `relocation-mapping.json` on top of YAML configuration via `kbld --image-map-file /cnab/app/relocation-mapping.json ...`. For example:

/cnab/app/relocation-mapping.json:

```json
{
  "gabrtv/microservice@sha256:cca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120687": "my.registry/microservice@sha256:cca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120687",
  "technosophos/helloworld:0.1.0": "my.registry/helloworld:0.1.0"
}
```

and kbld input:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: gabrtv/microservice@sha256:cca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120687
      - name: my-app2
        image: technosophos/helloworld:0.1.0
```

would result in:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbld-test1
spec:
  selector:
    matchLabels:
      app: kbld-test1
  template:
    metadata:
      labels:
        app: kbld-test1
    spec:
      containers:
      - name: my-app
        image: my.registry/microservice@sha256:cca460afa270d4c527981ef9ca4989346c56cf9b20217dcea37df1ece8120687
      - name: my-app2
        image: my.registry/helloworld:0.1.0
```
