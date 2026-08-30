clear
echo "# secretgen-controller enables the user to specify what secrets need to be on cluster (generated or not)." | pv -qL 12
echo " - supports generating certificates, passwords, RSA keys and SSH keys" | pv -qL 12
echo " - supports exporting and importing secrets across namespaces" | pv -qL 12
echo " - exporting/importing registry secrets across namespaces" | pv -qL 12
echo " - supports generating secrets from data residing in other Kubernetes resources" | pv -qL 12
sleep 5
clear
echo "How to create a complex secret" | pv -qL 12

echo "Using the following YAML" | pv -qL 12
cat generate-secrets.yml

echo ''
echo "Apply it to the cluster using: kapp deploy -a secret -f generate-secrets.yml" | pv -qL 12
kapp deploy -a secret -f generate-secrets.yml -y | cat > /dev/null

echo "The secret complex-password is created" | pv -qL 12
kubectl get secret complex-password -oyaml

sleep 5

clear

echo "How to copy a secret between namespaces" | pv -qL 12
echo "cat secret-to-export.yml" | pv -qL 12
echo "---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: registry1-creds
  namespace: user1
spec:
  toNamespaces:
    - user2
    - user3
"
sleep 2
echo "kapp deploy -a copy-secrets -f export-secrets.yml -y" | pv -qL 12
kapp deploy -a copy-secrets -f export-secrets.yml -y | cat > /dev/null

echo ''
echo "We can import the secret to another namespace" | pv -qL 12
pullSecret=$(echo "---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretImport
metadata:
  name: registry1-creds
  namespace: user3
spec:
  fromNamespace: user1
")

echo "cat import-secret.yml
$pullSecret"
sleep 2

echo "kapp deploy -a import-secrets -f import-secrets.yml -y" | pv -qL 12
echo "$pullSecret"| kapp deploy -a import-secret -f- -y  | cat > /dev/null

sleep 5
echo "kubectl get secret -n user3 registry1-creds -oyaml" | pv -qL 12
kubectl get secret -n user3 registry1-creds -oyaml
sleep 5

clear

echo ''
echo "We can import the secret as a pull-secret" | pv -qL 12
pullSecret=$(echo "---
apiVersion: v1
kind: Secret
metadata:
  name: default-registry-creds
  namespace: user2
  annotations:
    secretgen.carvel.dev/image-pull-secret: \"\"
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: \"e30K\"")

echo "cat pull-secret.yml
$pullSecret"
sleep 2

echo "kapp deploy -a copy-secrets -f export-secrets.yml -y" | pv -qL 12
echo "$pullSecret"| kapp deploy -a secret-as-pull-secret -f- -y | cat > /dev/null

sleep 5
echo "kubectl get secret -n user2 default-registry-creds -oyaml" | pv -qL 12
kubectl get secret -n user2 default-registry-creds -oyaml
sleep 5
