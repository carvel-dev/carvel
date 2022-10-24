---
aliases: [/kapp-controller/docs/latest/startup]
Title: Kapp Controller Startup
---

(v0.14.0+)

The startup of kapp controller consists of two processes:
controllerinit and controller.

## The controllerinit Process

This is the main process for the kapp controller binary. Since the binary is
the entrypoint for the docker image, kapp controller will be PID 1
and is therefore responsible for reaping any zombie processes, so the process
begins by starting a thread to reap any zombies that appear. More on PID 1 and
zombie processes can be found [here][1].

Next, the process will look for the [controller Secret or ConfigMap][2] and apply any system level
configuration specified within.

Finally, the process will fork to the same binary with a new flag, `--internal-controller`,
starting a second process, which runs the actual kubernetes controller.

## The controller Process

This process is responsible for running the app reconciler, which handles the fetch,
template, and deploy aspects of kapp controller.

[1]: https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
[2]: controller-config.md
