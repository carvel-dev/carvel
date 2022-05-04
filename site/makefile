build:
	wget -O- https://carvel.dev/install.sh > install.sh
	bash install.sh
	vendir version
	vendir sync

	mkdir -p netlify/functions
	GOOS=linux
	GOARCH=amd64
	GO111MODULE=on
	cd playground-src/github.com/wmware-tanzu/carvel-ytt && ./hack/build.sh
	cp playground-src/github.com/wmware-tanzu/carvel-ytt/tmp/ytt-lambda-website.zip netlify/functions
