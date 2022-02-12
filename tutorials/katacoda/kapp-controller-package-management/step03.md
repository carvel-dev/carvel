## Optional: explore kapp

Before we install kapp-controller with [kapp](https://carvel.dev/kapp/), you may be interested in seeing
a different example of how kapp works.

You can skip this step if you want to get straight to kapp-controller.

First pull down the yaml for this example:

```bash
wget https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp/5886f388900ce66e4318220025ca77d16bfaa488/examples/jobs/cron-job.yml
```{{execute}}

Then deploy a CronJob to the Kubernetes cluster in this environment:

```bash
kapp deploy -a hellocron -f cron-job.yml -y
```{{execute}}

Now take a look at the Kubernetes resources being managed by kapp:

```bash
kapp ls
```{{execute}}

```bash
kapp inspect -a hellocron --tree
```{{execute}}

We scheduled our CronJob to output a hello message every minute, so if you're
patient you'll see new messages appended to the logs:

```bash
kapp logs -f -a hellocron
```{{execute}}

When you're done watching the logs you can use control-c (`^C`{{execute ctrl-seq}}) to quit.

Because this was an optional interlude, we can use kapp to uninstall the CronJob before proceeding:
```bash
kapp delete -a hellocron -y
```{{execute}}
