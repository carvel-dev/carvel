## Creating a Package: Templating our config

We will be using [ytt](https://carvel.dev/ytt/) templates that describe a simple Kubernetes Deployment and Service.
These templates will install a simple greeter app with a templated hello message.

Create a config.yml:

```
cat > config.yml << EOF
#@ load("@ytt:data", "data")

#@ def labels():
simple-app: ""
#@ end

---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: simple-app
spec:
  ports:
  - port: #@ data.values.svc_port
    targetPort: #@ data.values.app_port
  selector: #@ labels()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: simple-app
spec:
  selector:
    matchLabels: #@ labels()
  template:
    metadata:
      labels: #@ labels()
    spec:
      containers:
      - name: simple-app
        image: docker.io/dkalinin/k8s-simple-app@sha256:4c8b96d4fffdfae29258d94a22ae4ad1fe36139d47288b8960d9958d1e63a9d0
        env:
        - name: HELLO_MSG
          value: #@ data.values.hello_msg
EOF
```{{execute}}

and a values.yml:

```
cat > values.yml <<- EOF
#@data/values
---
svc_port: 80
app_port: 80
hello_msg: stranger
EOF
```{{execute}}


