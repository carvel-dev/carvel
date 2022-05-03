build:
	mkdir -p netlify/functions
	GOOS=linux
	GOARCH=amd64
	GO111MODULE=on
	GOBIN=${PWD}/netlify/functions/ go get ./...
	GOBIN=${PWD}/netlify/functions/ go install ./...
