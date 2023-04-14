# secretgen-controller asciinema demo

The demo is all captured in a script called scenario.sh. In order to record an update to 
this video, you will need the following:

* Install asciinema: https://asciinema.org/docs/installation
* Create an asciinema account: https://asciinema.org/login/new
* Install pv: https://linux.die.net/man/1/pv
* kapp should be installed: https://carvel.dev/#whole-suite
* Access to a Kubernetes cluster with secretgen-controller installed using
    `kapp deploy -a sg -f https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml -c -y`

To record a new video, run the following script:

```
./record.sh
```

The result of this will be a `.cast` file named `demo.cast`.

This can be uploaded to the asciinema website so others can view it by doing the following:

```
# Authenticate to your asciinema account
asciinmea auth
#Upload the .cast file
asciinema upload demo.cast
```

After the video is uploaded, you should receive a url to the demo from scenario.sh that you can share.
