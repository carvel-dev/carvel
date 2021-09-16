echo "# kapp-controller is a package management and continuous delivery experience for Kubernetes " | pv -qL 12
echo "# kapp-controller makes these experiences native to your cluster through Kubernetes Custom Resource Definitions (CRD) " | pv -qL 12
echo ''
echo "# Let's start by making some software packages available on your cluster " | pv -qL 12
echo "# You can add one or more Packages to your cluster via a PackageRepository " | pv -qL 12
echo ''
echo 'cat packagerepo-crd.yml' | pv -qL 12
cat packagerepo-crd.yml
sleep 4
clear
echo ''
echo "# Now create the PackageRepository and associated Packages with kapp " | pv -qL 12
echo ''
echo 'kapp deploy -a repo -f packagerepo-crd.yml -y ' | pv -qL 12
kapp deploy -a repo -f packagerepo-crd.yml -y --warnings=false
sleep 4
clear
echo ''
echo '# View the available versions of the Package on your cluster ' | pv -qL 12
echo ''
echo 'kubectl get packages ' | pv -qL 12
kubectl get packages
sleep 4
clear
echo ''
echo "# Next you can install a Package using a PackageInstall " | pv -qL 12
echo "# Simply select a version and configure available properties " | pv -qL 12
echo "# In this case, we'll provide a Secret with values to configure " | pv -qL 12
echo ''
echo 'cat packageinstall.yml' | pv -qL 12
cat packageinstall/packageinstall.yml
sleep 4
clear
echo ''
echo '# Install the Package using kapp ' | pv -qL 12
echo ''
echo 'kapp deploy -a simple-app -f packageinstall.yml' | pv -qL 12
kapp deploy -a simple-app -f packageinstall/packageinstall.yml -f packageinstall/rbac.yml --warnings=false -y
sleep 4
clear
echo ''
echo '# You can see what Packages have been installed ' | pv -qL 12
echo ''
echo 'kubectl get packageinstalls'
kubectl get packageinstalls
sleep 4
clear
echo ''
echo '# The Package should be installed on your cluster ' | pv -qL 12
echo '# We can verify by pinging the app that was installed ' | pv -qL 12
echo ''
echo 'kubectl port-forward svc/simple-app 3000:80' | pv -qL 12
kubectl port-forward svc/simple-app 3000:80 &
sleep 2
clear
echo ''
echo 'curl localhost:3000' | pv -qL 12
curl localhost:3000
