# asciinema demos

This folder contains assets that are used to maintain asciinema demos for Carvel tools. 
Uploaded demos to asciinema:
- [demo for kapp-controller](https://asciinema.org/a/hhZwxyDcXEGiPD9RDHTb3e9QL).

* Install asciinema: https://asciinema.org/docs/installation
* Create an asciinema account: https://asciinema.org/login/new
* Install pv: https://linux.die.net/man/1/pv



To record a new video, run the following script to record for all tools:

```shell
./record.sh
```

if you want to record a single tool run the following script:

```shell
./record.sh kbld
```

The result of this will be a `.cast` file named `demo.cast`.

This can be uploaded to the asciinema website so others can view it by doing the following:

```shell
# Authenticate to your asciinema account
asciinmea auth
#Upload the .cast file
asciinema upload demo.cast
```

After the video is uploaded, you should receive a url to the demo from scenario.sh that you can share.

The other option is to generate a gif from the demo file. To do that you can use the tool [agg](https://github.com/asciinema/agg)

and run the following command in each folder:

```shell
agg demo.cast tool-name.gif
```
