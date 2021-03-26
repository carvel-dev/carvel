build:
	GOOS=linux GOARCH=amd64 go build -o netlify/functions/test-go netlify/functions/test-go/main.go
	GOOS=linux GOARCH=amd64 go build -o netlify/functions/count-background netlify/functions/count-background/main.go
