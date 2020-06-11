#!/bin/bash

set -e -x -u

go fmt ./cmd/... ./pkg/...

(
	# template all playground assets
	# into a single Go file
	cd pkg/website; 

	ytt version || { echo >&2 "ytt is required for building. Install from https://github.com/k14s/ytt"; exit 1; }
	ytt \
		-f . \
		-f ../../hack/build-values.yml \
		--file-mark 'generated.go.txt:exclusive-for-output=true' \
		--dangerous-emptied-output-directory ../../tmp/
)
mv tmp/generated.go.txt pkg/website/generated.go

go build -o k14s.io ./cmd/k14s.io/...

# build aws lambda binary
export GOOS=linux GOARCH=amd64
go build -o ./tmp/main ./cmd/k14s.io-lambda-website/...
(
	cd tmp
	chmod +x main
	rm -f k14s.io-lambda-website.zip
	zip k14s.io-lambda-website.zip main
)

echo SUCCESS
